# AGENTS.md — AI Agent Context & Guardrails

## Project Identity

**App name:** Convertix
**Play Store package name:** `com.allformat.converter` ← NEVER CHANGE THIS
**Current Play Store version:** 1.0.8 (version code 15)
**Next version:** 1.0.9 (version code 16)
**Type:** Mobile-only (Android + iOS) media and document conversion utility
**Framework:** Flutter (Dart)
**State management:** Riverpod
**Navigation:** go_router

## Where to Look First

When starting work on any task:

1. `STATE.md` — read current blockers and what is actively confirmed
2. `SPEC.md` — read exact feature requirements before writing code
3. `ARCHITECTURE.md` — read correct file locations and data flows
4. The relevant feature folder in `lib/features/[tool-name]/`

## HARD RULES — Never Violate These

### 1. Package Name
`applicationId "com.allformat.converter"` in `android/app/build.gradle`.
This is the Play Store identity. Changing it makes the app appear as a new, different app to Google Play.
Do not suggest renaming it, do not change it, do not touch it.

### 2. API Target
`targetSdkVersion 36` and `compileSdkVersion 36` — mandatory.
Google Play will reject any release targeting API < 36 after August 31, 2026.
If any file shows targetSdkVersion 35 or lower, fix it immediately.

### 3. Version
Version code must be ≥ 16 (higher than current 15).
Version name for next release: `1.0.9`.
Never submit a build with versionCode 15 or lower.

### 4. Media vs Document Routing
**Media tools → on-device via `ffmpeg_kit_flutter`** — never network calls.
**Document tools → backend via `backend_service.dart`** — never FFmpegKit.
Do not mix these. Do not route a media tool through the backend.

### 5. FFmpegKit Usage
All FFmpeg calls go through `core/services/ffmpeg_service.dart`.
Never call `FFmpegKit` directly from a screen widget, provider, or any file other than `ffmpeg_service.dart`.

### 6. Backend Usage
All backend calls go through `core/services/backend_service.dart`.
Always use multipart/form-data for file uploads — never base64.
Always handle: timeout, network failure, non-200 response.
Backend deletes files within 30 seconds — never assume persistence.

### 7. Signing / Release Builds
Do not generate a new keystore and use it for release builds without explicit user confirmation.
The upload key reset process requires Google's approval (24–48 hours).
Builds for testing can use debug signing.
Builds for Play Store submission require the approved upload key.
See STATE.md → BLOCKER 1 for the full keystore situation.

### 8. AdMob
Google AdMob is part of the product — it is not optional.
AdMob App ID: `ca-app-pub-2093403233028868~6019383556`
The `google_mobile_ads` Flutter package must be in pubspec.yaml.
The AdMob APPLICATION_ID meta-data must be in AndroidManifest.xml and iOS Info.plist.
Do not remove ads. Do not comment out ad code.

## APK-Derived Context (Original App v1.0.8)

The original app was already built with Flutter and used:
- `ffmpeg_kit_flutter` (confirmed by APK native libs: libffmpegkit.so, libavcodec.so, etc.)
- `open_file` (com.crazecoder.openfile FileProvider in manifest)
- `share_plus` (dev.fluttercommunity.plus.share provider in manifest)
- Lucide Icons (lucide.ttf in font manifest)
- Google AdMob (com.google.android.gms.ads.* in manifest + meta-data)
- WorkManager (androidx.work.* services in manifest) — used for background tasks
- Room database (androidx.room service in manifest) — local persistence

These facts confirm our stack decisions. The v1.0.9 rebuild must match or extend this stack.

## Video Compression — LOG/HDR Guardrails

All LOG/HDR filter chains are defined only in `lib/features/video_compression/log_profiles.dart`.
Never invent a filter chain outside this file. Never guess a profile's filter parameters.
If a profile is missing from the file, mark it TODO and ask.
Output color space is always BT.709.
`Standard` profile = regular video, no tone mapping, just scale and encode.

## State Management Pattern

Every feature uses the same Riverpod AsyncNotifier pattern.
Do not deviate from this pattern without updating ARCHITECTURE.md.
See ARCHITECTURE.md for the full pattern definition.

## Output File Convention

- Output: `getApplicationDocumentsDirectory()/convertix/outputs/`
- Temp: `getTemporaryDirectory()/convertix/`
- Naming: `[original_name]_[timestamp].[ext]`
- Clean temp files in both success and failure paths

## Uncertainty Handling

If something is unclear:
- Check SPEC.md first for feature scope
- Check ARCHITECTURE.md for file locations and patterns
- If still unclear: mark as TODO and note what needs clarification
- Never silently invent answers
