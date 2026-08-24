# Convertix — Architecture

## System Diagram

```
┌─────────────────────────────────────────────────────────┐
│                     User Device                         │
│                                                         │
│  Flutter App                                            │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Media Tools                                      │  │
│  │  (Image / Video / Audio)                          │  │
│  │           │                                       │  │
│  │           ▼                                       │  │
│  │  ffmpeg_kit_flutter  /  image (Dart package)      │  │
│  │  ← 100% on-device, zero network ─────────────→   │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Document Tools                                   │  │
│  │  (PDF / Document)                                 │  │
│  │           │                                       │  │
│  │           ▼                                       │  │
│  │  backend_service.dart → multipart POST over TLS   │  │
│  └─────────────────────┬─────────────────────────────┘  │
└────────────────────────│────────────────────────────────┘
                         │
                         ▼
          ┌──────────────────────────────┐
          │  FastAPI Backend             │
          │  Hugging Face Spaces         │
          │                              │
          │  LibreOffice (headless)      │
          │  Pillow                      │
          │  PyMuPDF (fitz)              │
          │                              │
          │  Files deleted ≤ 30s         │
          └──────────────────────────────┘
```

---

## Frontend — Flutter

**Framework:** Flutter (Dart)
**State management:** Riverpod (`flutter_riverpod`)
**Navigation:** go_router
**HTTP client:** Dio (with retry interceptor)
**Ads:** Google AdMob (`google_mobile_ads`)
**Target SDK:** 36 (Android 16) — mandatory
**Version:** 1.0.9 (version code 16)

---

## Folder Structure

```
lib/
├── main.dart
│
├── app/
│   ├── app.dart              # MaterialApp.router root widget
│   ├── router.dart           # go_router route definitions (all 10 tool routes)
│   └── theme.dart            # ColorScheme, TextTheme, component themes
│
├── features/
│   │
│   ├── home/
│   │   ├── home_screen.dart         # tool grid — 5 media + 5 document tiles
│   │   └── home_provider.dart
│   │
│   ├── image_converter/
│   │   ├── image_converter_screen.dart
│   │   └── image_converter_provider.dart
│   │
│   ├── video_to_audio/
│   │   ├── video_to_audio_screen.dart
│   │   └── video_to_audio_provider.dart
│   │
│   ├── audio_converter/
│   │   ├── audio_converter_screen.dart
│   │   └── audio_converter_provider.dart
│   │
│   ├── video_converter/
│   │   ├── video_converter_screen.dart
│   │   └── video_converter_provider.dart
│   │
│   ├── video_compression/
│   │   ├── video_compression_screen.dart
│   │   ├── video_compression_provider.dart
│   │   └── log_profiles.dart        # LOG/HDR profile definitions + FFmpeg filter chains
│   │
│   ├── image_to_pdf/
│   │   ├── image_to_pdf_screen.dart
│   │   └── image_to_pdf_provider.dart
│   │
│   ├── document_convert/
│   │   ├── document_convert_screen.dart
│   │   └── document_convert_provider.dart
│   │
│   ├── greyscale_pdf/
│   │   ├── greyscale_pdf_screen.dart
│   │   └── greyscale_pdf_provider.dart
│   │
│   ├── merge_pdf/
│   │   ├── merge_pdf_screen.dart
│   │   └── merge_pdf_provider.dart
│   │
│   └── split_pdf/
│       ├── split_pdf_screen.dart
│       └── split_pdf_provider.dart
│
├── core/
│   ├── services/
│   │   ├── ffmpeg_service.dart       # wraps ffmpeg_kit_flutter; all media tool calls go here
│   │   ├── backend_service.dart      # Dio-based client for all document tool API calls
│   │   ├── file_service.dart         # temp file management; bare output FILENAME generation
│   │   ├── file_source_service.dart  # WHERE input comes from — installed picker enumeration
│   │   ├── output_location_service.dart  # WHERE outputs land — MediaStore public collections
│   │   └── permission_service.dart   # DEAD CODE, and broken — see STATE.md open question 8
│   │
│   ├── models/
│   │   ├── conversion_job.dart       # job ID, tool name, status, progress (0.0–1.0), timestamps
│   │   └── conversion_result.dart    # output file path, output format, success/error
│   │
│   ├── widgets/
│   │   ├── file_picker_button.dart   # unified file picker UI (uses image_picker / file_picker)
│   │   ├── conversion_progress.dart  # progress bar + percentage + cancel button
│   │   ├── format_dropdown.dart      # reusable format selection dropdown
│   │   ├── error_card.dart           # error state UI with message + retry button
│   │   └── success_card.dart         # success state UI with Open + Share buttons
│   │
│   └── utils/
│       ├── file_utils.dart           # extension extraction, size formatting, output path builder
│       └── format_utils.dart         # format compatibility checks, MIME type mapping
│
└── shared/
    └── constants/
        ├── api_constants.dart        # BACKEND_BASE_URL, timeout values, max file sizes
        └── format_constants.dart     # supported input/output format lists per tool
```

---

## State Management Pattern

Every feature follows a single Riverpod `AsyncNotifier` pattern.
Do not deviate without updating this file.

```dart
// lib/features/[tool]/[tool]_provider.dart

final [tool]Provider = AsyncNotifierProvider<[Tool]Notifier, ConversionResult?>(
  [Tool]Notifier.new,
);

class [Tool]Notifier extends AsyncNotifier<ConversionResult?> {
  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required File inputFile,
    required [Tool]Config config,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _runConversion(inputFile, config));
  }

  void cancel() {
    // calls ffmpegService.cancelSession() or cancels Dio request
    state = const AsyncData(null);
  }
}
```

---

## Media Tool Execution Flow

```
1. User selects file
         ↓
2. permission_service.dart — check + request storage permission
         ↓
3. file_service.dart — copy input to temp directory
   path: getTemporaryDirectory()/convertix/[uuid]/input.[ext]
         ↓
4. [tool]_provider.dart — build FFmpegKit command string or image package call
         ↓
5. ffmpeg_service.dart — executeAsync(command, progressCallback)
         ↓
6. Progress updates → state = AsyncLoading() with progress value → UI redraws
         ↓
7. ffmpeg_service returns output file path on ReturnCode.isSuccess()
         ↓
8. file_service.dart — move output from temp → Documents
   path: getApplicationDocumentsDirectory()/convertix/outputs/[filename].[ext]
         ↓
9. state = AsyncData(ConversionResult) → success_card renders
         ↓
10. file_service.dart — delete temp directory for this job
```

---

## Video Compression — LOG/HDR Filter Chain Design

`lib/features/video_compression/log_profiles.dart` defines:

```dart
class LogProfile {
  final String id;          // e.g. 'slog2'
  final String displayName; // e.g. 'S-Log2 (Sony)'
  final String filterChain; // full FFmpeg -vf value, parameterised by resolution
}

// Example: Standard (no LOG)
LogProfile(
  id: 'standard',
  displayName: 'Standard',
  filterChain: 'scale={width}:{height},format=yuv420p',
)

// Example: S-Log2
LogProfile(
  id: 'slog2',
  displayName: 'S-Log2 (Sony)',
  filterChain:
    'zscale=transfer=linear:npl=100,'
    'format=gbrpf32le,'
    'zscale=p=bt709,'
    'tonemap=hable:desat=0,'
    'zscale=transfer=bt709:matrix=bt709:range=tv,'
    'format=yuv420p,'
    'scale={width}:{height}',
)

// {width} and {height} are replaced at runtime based on selected resolution preset
```

All LOG profiles are defined in this file. Agents must not invent or modify filter chains
outside of this file without explicit instruction.

---

## Document Tool Execution Flow

The backend is **Gradio**, not FastAPI multipart. `backend_service.dart` drives Gradio's REST API.
`<prefix>` below is **auto-detected** by `_prefix()`: empty on Gradio 4 (the live Space), or
`/gradio_api` on Gradio 5+.

```
1. User selects file(s) via file_picker (Storage Access Framework — no runtime permission)
         ↓
2. backend_service.dart — POST <prefix>/upload (multipart, field name "files")
   → responds with a JSON array of server-side temp paths
         ↓
3. POST <prefix>/call/[api_name]  body: {"data": [ ...positional args... ]}
   — api_name comes from _apiNames, keyed by logical endpoint
   — file args are wrapped as {"path": ..., "meta": {"_type": "gradio.FileData"}}
   → responds with {"event_id": "..."}
         ↓
4. GET <prefix>/call/[api_name]/[event_id]  ← SSE stream
   — "event: heartbeat" / "event: generating"  → ignored, keeps connection alive
   — "event: error"     → data is {"title": ..., "error": ...}  → surfaced to the user
   — "event: complete"  → data is a JSON array; element 0 is the output FileData
         ↓
5. Backend processes with LibreOffice / PyMuPDF
         ↓
6. GET <prefix>/file=[FileData.path]   ← built from `path`, NOT from FileData.url
         ↓
7. backend_service.dart — write response bytes to output file
   path: getApplicationDocumentsDirectory()/convertix/outputs/[filename].[ext]
         ↓
8. state = AsyncData(ConversionResult) → success_card renders
```

> **Step 6 is load-bearing.** Gradio 4.36 returns a malformed `url` in the output FileData for jobs
> submitted via `/call/<api_name>` (`/c/file=`, `/cal/file=`, … — the corruption length tracks the
> api_name length) and those 404. `path` is always correct. See STATE.md → Backend Facts.

### Endpoint mapping — names, not indices

`_apiNames` in `backend_service.dart` maps each logical endpoint to the Gradio `api_name`
declared by the matching `.click(..., api_name=...)` in `backend/app.py`:

| Logical endpoint | Gradio `api_name` |
|---|---|
| `/health` | `health` |
| `/document-convert` | `convert` |
| `/split-pdf` | `split` |
| `/image-to-pdf` | `image_to_pdf` |
| `/greyscale-pdf` | `greyscale_pdf` |
| `/merge-pdf` | `merge_pdf` |

Because these are names, reordering or inserting Gradio tabs in `app.py` no longer misroutes
calls. **Renaming** an `api_name` still requires updating this map. `GET <prefix>/info` lists
the live names and each handler's parameter order.

Positional argument order inside `_buildRequestData` must still match each handler's
`inputs=[...]` list.

---

## Backend Architecture

**Host:** Hugging Face Spaces — `pandeypratham/libreoffice-converter`
**Framework:** Gradio **4.36.0** (`gr.Blocks`), `sdk: docker`, hardware `cpu-basic`
**Conversion engine:** LibreOffice headless (`libreoffice --headless --convert-to`)
**PDF/image engine:** PyMuPDF (`pymupdf`) for greyscale, split, merge, and image-to-PDF

> Pillow is **not** used; image-to-PDF goes through PyMuPDF's `convert_to_pdf()`.

### Deployment mode

The live Space is a **Docker** Space built from `Dockerfile` + `app.py`. `backend/requirements.txt`
is the single source of version truth and the Dockerfile installs from it.

A second Space, `darkframeshzn/convertix-backend` (Gradio 6.24.0, `sdk: gradio`, ZeroGPU), exists
but is **not** used by the app — its handlers carry `@spaces.GPU` and its quota is exhausted.

### File Lifecycle on Backend

Each handler creates a job-scoped `tempfile.mkdtemp()`, writes its output into the process temp
directory, and removes the job directory in a `finally`. Gradio serves the returned file from its
own temp area and reaps it on restart.

### Backend Response Format

All results come back through the SSE stream as Gradio `FileData` objects — never as a raw binary
HTTP body:

- **Single file output:** `{"path": ..., "url": ..., "orig_name": ..., "size": ...}`
- **Multi-file output (split PDF):** the same shape, pointing at a server-built `.zip`
- **Error:** `event: error` with `{"title": ..., "error": ...}`

---

## File Source Selection (Phase 5B)

All 10 tools take input through one widget — `core/widgets/file_picker_button.dart`. It asks
`FileSourceService` which sources exist, shows a chooser only when there is more than one, then
launches the chosen source.

### Nothing is hardcoded to a vendor

`FileSourceResolver.kt` discovers sources with `queryIntentActivities`. Google Photos, Files, and
any Gallery app appear because they resolved, not because they are named in code — if they are not
installed they simply do not appear.

**This requires the `<queries>` block in `AndroidManifest.xml`.** On API 30+ package visibility
means an undeclared intent returns an *incomplete* list, so removing those entries silently hides
installed apps rather than producing an error.

### Three mechanisms, ordered best-first

| Mechanism | What it is | Offered for |
|---|---|---|
| `photo_picker` | Android Photo Picker (`ACTION_PICK_IMAGES`) | image + video only |
| `open_document` | System SAF document picker | every kind — always present on API 24+ |
| `get_content` | A resolved third-party `ACTION_GET_CONTENT` activity | every kind |

The Photo Picker is offered for image and video only — it cannot supply audio or documents. It is
native on API 33+; on 30–32 it arrives via a Play system update, so presence is **probed**, not
assumed. Below API 30 the device falls back to SAF and `GET_CONTENT`, which always work.

### Per-tool mapping

`FileSourceKind` decides which sources are *enumerated*; `allowedExtensions` decides what is
*selectable*. They are separate on purpose:

| Tool(s) | Kind |
|---|---|
| Image Converter | `image` |
| Video Converter, Video Compression, Video to Audio | `video` |
| Audio Converter | `audio` — file-manager first, no Photo Picker |
| All 5 document tools **including Image to PDF** | `document` |

Image to PDF passes `document` despite taking images: the brief specifies file managers for the
document tools, while the image extensions still restrict what can be chosen. Do not "fix" this
to `image`.

### Why this stays permission-free

Every mechanism is a picker intent, so **no runtime storage permission is needed on any API
level**. That is the reason the app works unchanged from API 24 to 36. Replacing any of these with
a direct filesystem read would reintroduce the permission problem described in
`STATE.md` → `permission_service.dart`.

### Picked files become real paths

Media tools hand input to FFmpegKit and document tools upload it via Dio — both need a readable
file, not a URI. `FilePickerDelegate` copies each picked content URI into
`cacheDir/convertix_picks/`, preserving the provider-reported display name so the extension (which
drives format detection downstream) survives.

An empty result means **the user cancelled** — a normal outcome, not an error. Genuine failures
surface as `FileSourceException` with codes `source_unavailable`, `copy_failed`,
`pick_in_progress`, `bad_source`.

> **Kotlin gotcha, learned the hard way:** Kotlin block comments **nest**. Writing a MIME wildcard
> like image-slash-star inside a `/** … */` comment opens a nested comment and swallows the rest of
> the file, producing a cascade of unrelated "unresolved reference" errors. Keep MIME wildcards in
> string literals or `//` line comments.

---

## Output File Naming & Placement

Two separate concerns, and conflating them has caused a real bug:

### 1. Filename — `file_service.dart`

```dart
String buildOutputPath(String inputName, String targetExt) {
  final baseName = path.basenameWithoutExtension(inputName);
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return '${baseName}_$timestamp.$targetExt';   // BARE FILENAME — no directory
}
```

Pattern: `[original_name]_[timestamp].[ext]` — e.g. `interview_video_1720000000000.mp3`

**This returns a bare filename with no directory.** Treating it as a full path resolves writes
against a read-only CWD — the bug fixed in `110bc57`. Never prefix it yourself.

### 2. Placement — `output_location_service.dart` (Phase 5A)

`OutputLocationService.publish()` is the single chokepoint for *where* an output lands. Tools pass
the bare filename and their `ConvertixTool` value; the service owns the destination.

| Tool | Collection | Folder |
|---|---|---|
| Image Converter | images | `DCIM/Images (Convertix)/` |
| Video Converter, Video Compression | video | `Movies/Videos (Convertix)/` |
| Audio Converter, Video to Audio | audio | `Music/Audio (Convertix)/` |
| Image to PDF | documents | `Documents/Convertix/Image to PDF/` |
| Document Converter | documents | `Documents/Convertix/Document Converter/` |
| Greyscale PDF | documents | `Documents/Convertix/Greyscale PDF/` |
| Merge PDF | documents | `Documents/Convertix/Merge PDF/` |
| Split PDF | documents | `Documents/Convertix/Split PDF/` |

Returns a `SavedOutput` carrying a **`content://` URI**, the final display name, and the relative
directory. Phase 5D's Open / Show in Folder / Share consume the URI — never a raw path.

### Platform channel — `com.allformat.convertix/media_store`

`MediaStoreWriter.kt` implements one method, `saveToCollection`. Two write paths, because no single
mechanism spans minSdk 24 → targetSdk 36:

| API range | Mechanism |
|---|---|
| 29+ | `MediaStore` insert with `RELATIVE_PATH`; `IS_PENDING` guards the partial file |
| 24–28 | Direct write under the external storage root + `MediaScannerConnection` scan |

Behaviour that is deliberate, not incidental:

- **Folder creation** — implicit from `RELATIVE_PATH` on 29+, `mkdirs()` on legacy. A folder the
  user deletes is recreated on the next save.
- **Collisions** — existing files are never overwritten; ` (1)`, ` (2)`… is appended.
- **Failure** — a failed write deletes the pending MediaStore row so no phantom entry is indexed,
  and the source file is left intact so the conversion result is never lost.
- **Errors** surface as `PlatformException` codes → `OutputSaveException` with a user-facing message:
  `insufficient_storage`, `permission_denied`, `io_error`, `source_missing`, `mkdir_failed`,
  `insert_failed`, `no_external_storage`.
- **Non-Android** falls back to app-private storage with `isPublic: false`, so `flutter run -d windows`
  keeps working. iOS gets its own implementation in Phase 3.

Temp files remain at `getTemporaryDirectory()/convertix/<jobId>/`, cleaned in a `finally`.

---

## Navigation (go_router)

```dart
// app/router.dart

GoRoute(path: '/',             builder: HomeScreen)
GoRoute(path: '/image-convert', builder: ImageConverterScreen)
GoRoute(path: '/video-to-audio', builder: VideoToAudioScreen)
GoRoute(path: '/audio-convert', builder: AudioConverterScreen)
GoRoute(path: '/video-convert', builder: VideoConverterScreen)
GoRoute(path: '/video-compress', builder: VideoCompressionScreen)
GoRoute(path: '/image-to-pdf', builder: ImageToPdfScreen)
GoRoute(path: '/doc-convert',  builder: DocumentConvertScreen)
GoRoute(path: '/greyscale-pdf', builder: GreyscalePdfScreen)
GoRoute(path: '/merge-pdf',    builder: MergePdfScreen)
GoRoute(path: '/split-pdf',    builder: SplitPdfScreen)
```

---

## Platform Notes

### Android
- `minSdkVersion 26`, `targetSdkVersion 34`
- FFmpegKit via JNI — no subprocess, no external binary
- Scoped storage: use `MediaStore` API for saving to shared Downloads

### iOS
- Minimum deployment target: iOS 16.0
- `ffmpeg_kit_flutter` ships as a compiled framework — App Store compliant
- LGPL/GPL attribution screen required in Settings → Open Source Licenses
- No raw `ffmpeg` binary is distributed

---

## AdMob Integration

**App ID:** `ca-app-pub-2093403233028868~6019383556`

**Initialisation (main.dart):**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(ProviderScope(child: ConvertixApp()));
}
```

**Ad unit ID storage:** `lib/shared/constants/ad_constants.dart`

```dart
// Use test IDs during development; replace with production IDs before release
const String androidBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // test
const String iosBannerAdUnitId     = 'ca-app-pub-3940256099942544/2934735716'; // test
// Production IDs: retrieve from AdMob console for com.allformat.converter
```

**Banner placement rule:** Banner at bottom of each tool screen.
Hidden while a conversion is in progress (AsyncLoading state). Shown in idle, success, and error states.

---

## Build Target Requirements

```groovy
// android/app/build.gradle
android {
    compileSdkVersion 36       // Android 16 — required by Google Play from Aug 31 2026
    defaultConfig {
        applicationId "com.allformat.converter"
        minSdkVersion 24
        targetSdkVersion 36    // mandatory
        versionCode 16
        versionName "1.0.9"
    }
}
```
