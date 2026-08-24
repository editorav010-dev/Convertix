# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.


## Project

Convertix — Flutter (Android/iOS) media & document converter, live on Play Store as
`com.allformat.converter`. Verified toolchain: Flutter 3.47.0 / Dart 3.13.0, Gradle 8.14,
AGP 8.11.1, Kotlin 2.2.20, JDK 17.

`docs/` holds an extensive doc system (`AGENT_RULES.md`, `AGENTS.md`, `ARCHITECTURE.md`,
`STATE.md`, `SPEC.md`, `SETUP.md`, `ROADMAP.md`, `CONTRIBUTING.md`). Read `docs/AGENT_RULES.md`
and `docs/STATE.md` before starting work — they encode the user's hard constraints and workflow
expectations. **But parts of the docs have drifted from the code** (see Doc drift below); when
they conflict, the code and this file are authoritative.

## Commands

```bash
flutter pub get
flutter analyze                       # must be "No issues found!" — verified clean baseline
flutter test                          # 1 smoke test, passes
flutter test test/widget_test.dart --plain-name 'App loads successfully'   # single test
flutter run                           # Android device; also -d windows for UI-only work
flutter build apk --debug
flutter build appbundle --release     # requires signing — see Blockers
```

`flutter analyze` and `flutter test` both pass on a clean tree. Never report analyze output you
did not actually run, and never stack several changes before analyzing — the user's rules require
analyze after each change.

### `.env` is required to build

`main.dart` calls `dotenv.load(fileName: ".env")` and `pubspec.yaml` declares `.env` as a Flutter
**asset**, but `.env` is gitignored. A fresh clone fails at asset resolution until it exists:

```
BACKEND_BASE_URL=https://pandeypratham-libreoffice-converter.hf.space
```

Never print, commit, or modify `.env`, `*.jks`, `*.pem`, or `key.properties`.

### Backend

```bash
cd backend && pip install -r requirements.txt && python app.py   # Gradio on :7860
```

**There are two Spaces. Know which one matters:**

| Space | Gradio | Hardware | Used by the app? |
|---|---|---|---|
| `pandeypratham/libreoffice-converter` | **4.36.0** (`sdk: docker`) | cpu-basic | **Yes** — this is what `.env` points at |
| `darkframeshzn/convertix-backend` | 6.24.0 (`sdk: gradio`) | zero-a10g | No — unused, and ZeroGPU-quota-gated |

`backend/` mirrors the **pandeypratham** Space: its `Dockerfile`, `app.py`, and pins correspond to
that deployment. `backend/requirements.txt` is the single source of version truth —
`backend/Dockerfile` installs from it. Don't bump Gradio there without re-reading the protocol notes
below. Kept awake by an external cron ping.

## Architecture

### Two processing paths that must never cross

| Path | Mechanism | Network |
|---|---|---|
| 5 media tools | `ffmpeg_kit_flutter_new` on-device (`FFmpegKit.execute`) | none |
| 5 document tools | Gradio REST/SSE call to the HF Space | required |

Never route a media tool through the backend or a document tool through FFmpegKit.
**Exception worth knowing:** image conversion does *not* use FFmpeg — `image_converter_provider.dart`
decodes/encodes with pure-Dart `package:image`.

### Service chokepoints (currently respected — keep them that way)

- All FFmpeg → `core/services/ffmpeg_service.dart`. Providers call `ffmpegService`, never `FFmpegKit`.
- All HTTP → `core/services/backend_service.dart`. It is the only file importing `package:dio`.
- All file I/O and paths → `core/services/file_service.dart` (via `path_provider`, never hardcoded).

Each is exported as a top-level singleton (`ffmpegService`, `backendService`, `fileService`).

### Feature pattern

Every feature is `lib/features/<tool>/<tool>_provider.dart` + `<tool>_screen.dart`, with a Riverpod
`AsyncNotifierProvider<Notifier, ConversionResult?>`; `build()` returns `null`, `convert()` sets
`AsyncLoading` then `AsyncValue.guard(...)`, `cancel()` resets to `AsyncData(null)`. Screens hold no
business logic. Temp cleanup happens in a `finally` on both success and failure paths.

The **five media screens are thin config wrappers** over the shared
`lib/features/media_tools/media_tool_screen.dart` — it owns the whole picker → format → options →
convert → progress/success/error UI, driven by `show*` booleans and a `MediaToolSettings` callback.
Add a media option there, not in individual screens. FFmpeg codec/scale/resolution mapping lives in
`media_tools/media_conversion_utils.dart`.

### Output paths — `buildOutputPath` returns a bare filename

`fileService.buildOutputPath()` returns `name_timestamp.ext` **with no directory**. It must be joined
with `await fileService.getOutputDir()`, or writes resolve against a read-only CWD. This caused a
real bug (fixed in `110bc57`); document providers now carry an explicit comment about it. Media
providers get this right via `buildFullOutputPath()` in `media_conversion_utils.dart` — prefer that helper.

Outputs: `getApplicationDocumentsDirectory()/convertix/outputs/`. Temp: `getTemporaryDirectory()/convertix/<jobId>/`.

### Gradio protocol (read before touching either side)

`backend_service.dart` drives Gradio's REST API. **The route prefix is auto-detected, not
hardcoded** — Gradio 4 serves these at the root, Gradio 5+ under `/gradio_api`. `_prefix()` probes
`GET /gradio_api/info` once per process (200 → use the prefix, 404 → root) and caches the answer, so
the app works against either Space. Shown below at the root, which is what the live 4.36.0 backend uses:

```
POST /upload                          -> ["/tmp/gradio/.../file.pdf", ...]
POST /call/<api_name>  {"data":[...]} -> {"event_id": "..."}
GET  /call/<api_name>/<event_id>      -> SSE: heartbeat|generating|error|complete
GET  /file=<FileData.path>            -> output bytes
```

Calls are keyed by **`api_name`**, via `_apiNames` — logical endpoint (`/document-convert`) →
Gradio name (`convert`). These names come from `api_name=` on each `.click()` in `backend/app.py`,
so reordering or inserting Gradio tabs is safe. **Renaming** an `api_name` still requires updating
`_apiNames`. `GET <prefix>/info` lists the live names and parameter order. `/call/<api_name>` works
on both Gradio 4.36 and 6.x — verified against both Spaces.

Positional argument order in `_buildRequestData` must still match each handler's `inputs=[...]`.
File arguments are wrapped as `{"path": ..., "meta": {"_type": "gradio.FileData"}}` — a bare map
for single-file inputs, a list of them for `image_to_pdf` and `merge_pdf`.

SSE parsing tracks the `event:` line and only acts on `complete` (payload is a JSON array,
element 0 is the output `FileData`) and `error` (payload is `{"title","error"}`). Don't reintroduce
a bare `catch` around `jsonDecode` here — that's what previously hid the real failure.

### Build the download URL from `path`, never `url`

Gradio 4.36 returns a **malformed `url`** in its output `FileData` when the job was submitted via
`/call/<api_name>`: it mis-trims the route, producing `/c/file=...` for `convert`, `/cal/file=...`
for `merge_pdf`, `/call/i/file=...` for `image_to_pdf` — the corruption length tracks the api_name
length. Those 404. Verified on the live Space:

```
url field       -> HTTP 404
path-built      -> HTTP 200, 22,159 bytes, %PDF-
```

`_downloadResult` therefore builds `<prefix>/file=<path>` from `path` and only falls back to `url`
if `path` is absent. Do not "simplify" this back to preferring `url`.

Note: the original pre-migration client used the `/queue/join` + `fn_index` protocol, which did
*not* trigger this bug — which is why preferring `url` worked before and broke after the move to
`/call/<api_name>`.

## Hard constraints

- `applicationId = "com.allformat.converter"` — Play Store identity, never change.
  (The Android `namespace` is deliberately different: `com.allformat.convertix`. Don't "fix" it.)
- `compileSdk` / `targetSdk` = **36**, `minSdk` = 24. Play requires API 36 from Aug 31, 2026.
- `versionCode` only increments; currently 16 / `1.0.9` (Store has 15 / 1.0.8).
- `lib/features/video_compression/log_profiles.dart` — LOG/HDR filter chains are tested; never
  invent, guess, or edit a chain. Output color space is always BT.709.
- AdMob is part of the product; never remove it or skip init. Init stays guarded by
  `Platform.isAndroid || Platform.isIOS` (desktop has no AdMob).
- Don't change Gradle/AGP versions, swap core deps (ffmpeg, riverpod, go_router, dio), or create new
  doc files without asking — each has broken this project before.
- Don't write Python/shell scripts to bulk-fix Dart errors; fix them directly.
- Never push, and only commit when explicitly asked. Conventional commits, e.g.
  `fix(backend-service): use /gradio_api prefix for Gradio 6`.

`ad_constants.dart` still holds Google's **test** banner IDs — production IDs are needed before
submission.

## Blockers (see `docs/STATE.md`)

1. Release signing — the original upload keystore is lost; a Play Console upload-key reset must be
   approved before any release AAB. `build.gradle.kts` release currently signs with debug keys.

Document tools are **working**: all 5 verified against the live Space via the API (correct page
counts, valid `%PDF`/`PK` magic) and confirmed manually on-device (RMX3998, Android 16).

## Android version compatibility (API 24–36)

Verified, not assumed:

- Effective `minSdkVersion` after manifest merge is **24**; `ffmpeg_kit_flutter_new` also declares
  24, so no plugin raises the floor.
- Backend TLS is `CN=hf.space` ← Amazon RSA 2048 M01 ← Amazon Root CA 1, cross-signed by Starfield
  Services Root G2 — in the Android CA store since well before API 24. TLS 1.2 with
  ECDHE-RSA-AES128-GCM-SHA256, both default-enabled from API 21+. No old-Android TLS problem.
- File input goes through `file_picker` → Storage Access Framework, which needs **no runtime
  permission on any API level**. Outputs go to app-private storage. That combination is why the app
  is portable across versions.

**Landmine:** `core/services/permission_service.dart` is dead code (never called) and is broken.
`_getAndroidVersion()` regexes `Platform.operatingSystemVersion` for `Android (\d+)`, which yields
the *release* number (7…16), never the API level (24…36) — so `androidInfo >= 33` is always false
and it always takes the legacy `Permission.storage` branch. On API 33+ `READ_EXTERNAL_STORAGE` is
not grantable, so wiring this into any flow would break file picking on Android 13/14/15/16. Either
delete the file or get `sdkInt` properly (`device_info_plus` — a new dependency, so ask first).

## Doc drift to be aware of

`docs/ARCHITECTURE.md`, `docs/SETUP.md`, `docs/STATE.md`, and `docs/AGENT_RULES.md` were corrected
for the real backend (pandeypratham / Gradio 4.36.0). Remaining known drift: `docs/STATE.md`
Confirmed Facts still records Gradle 8.5 / AGP 8.3.2 (actual: 8.14 / 8.11.1), and `docs/SPEC.md`
§Overview says the backend is FastAPI and that media tools use `ffmpeg_kit_flutter` (actual: Gradio,
and `ffmpeg_kit_flutter_new`). SPEC.md §"Cross-Cutting Constraints" also says "No advertising",
which contradicts the AdMob requirement in the same file.

**Lesson worth keeping:** `AGENT_RULES.md` §6 previously listed the `darkframeshzn` Space as the
backend. Trusting that instead of reading `.env` led to a full misdiagnosis — the wrong Space was
probed, and a working client was "fixed" into a broken one. Read `.env`'s `BACKEND_BASE_URL` (just
that key) to learn which backend is live; don't infer it from docs.
