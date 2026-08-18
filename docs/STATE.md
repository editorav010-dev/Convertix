# Project State

## Current Phase

Phase 1 — COMPLETED ✅
Phase 2A — NEXT (Backend Deployment)

## Status

🟢 Phase 1 complete — Android build verified on device (RMX3998), `flutter analyze` clean, all scaffolding in place.

---

## Completed Milestones

### ✅ Pre-Phase: Foundation
- [x] GitHub repository created (`editorav010-dev/Convertix`)
- [x] Repository cloned locally to `C:\Users\avspn\Desktop\projects\Convertix`

### ✅ Phase 0 — Project Initialization
- [x] Flutter project initialized with `applicationId = "com.allformat.converter"`
- [x] compileSdk 36, targetSdk 36, minSdk 24
- [x] versionCode 16, versionName "1.0.9"
- [x] All pubspec.yaml dependencies added
- [x] AndroidManifest.xml configured (permissions + AdMob meta-data)
- [x] go_router configured with all 11 routes (10 tools + licenses)
- [x] Riverpod ProviderScope set up
- [x] Theme implemented (Lucide icons, ColorScheme, TextTheme)
- [x] Home screen implemented — tool grid (5 media + 5 document tiles)
- [x] Shared services implemented (file_service, permission_service, ffmpeg_service, backend_service)
- [x] Shared widgets implemented (file_picker_button, conversion_progress, format_dropdown, error_card, success_card, banner_ad_widget)
- [x] AdMob initialized (conditional: Android/iOS only, skipped on desktop)

### ✅ Phase 1A — Windows Desktop Build Verification
- [x] `flutter run -d windows` succeeded
- [x] AdMob initialization wrapped with `Platform.isAndroid || Platform.isIOS` guard

### ✅ Phase 1B — Android Device Build & Dependency Fixes
- [x] Gradle downgraded to 8.5 (bypasses Windows file-lock bug in 8.6+)
- [x] AGP downgraded to 8.3.2
- [x] `resolutionStrategy` added forcing compatible AndroidX versions (activity:1.8.2, core:1.13.1)
- [x] `ffmpeg_kit_flutter_full_gpl` replaced with `ffmpeg_kit_flutter_new` (original Maven binaries deleted April 2025)
- [x] Android build succeeded: `√ Built build\app\outputs\flutter-apk\app-debug.apk`
- [x] App installed and launched on RMX3998 via Impeller (Vulkan)
- [x] `flutter analyze` — zero issues

---

## 🔴 BLOCKER 1: Lost Android Signing Keystore

### What Is Known

The original `.jks` signing keystore from the previous workspace is lost.
The app (`com.allformat.converter`, version 1.0.8, version code 15) is live on the Play Store.
The next update must be version 1.0.9 (version code 16) targeting API 36.

### Two Possible Situations

**Situation A — Play App Signing IS enabled (most likely)**

Google Play App Signing (PASSigning) has been mandatory for all new apps since August 2021.
The app was published after this date, so it almost certainly has Play App Signing enabled.

If this is the case:
- Google holds the actual signing key (the key used on user devices)
- The lost `.jks` is only the *upload key* (used to authenticate uploads to Play Console)
- The upload key CAN be reset without losing your app or user base
- The actual app signing key is safe on Google's servers regardless

**Recovery Process (if Play App Signing is enabled):**

1. Verify enrollment: Go to Play Console → your app → Release → Setup → App integrity
   - If it shows "App signing key certificate" and a SHA-1 fingerprint → enrolled ✅
2. Generate a new upload keystore on any machine:
   ```
   keytool -genkeypair -v \
     -keystore new-upload-key.jks \
     -alias upload \
     -keyalg RSA -keysize 2048 -validity 10000
   ```
3. Export the public certificate (PEM):
   ```
   keytool -export -rfc \
     -keystore new-upload-key.jks \
     -alias upload \
     -file upload_certificate.pem
   ```
4. In Play Console → App integrity → scroll to "Request upload key reset"
   - You must be logged in as the **account owner** (not just an admin)
   - Upload the `upload_certificate.pem` file
   - Submit the request
5. Google approves in 24–48 hours and emails a confirmation with an activation timestamp
6. Do NOT upload a new AAB until Google's activation timestamp has passed
7. After activation: configure `android/key.properties` with the new keystore credentials
8. All future releases use the new `new-upload-key.jks`

**Situation B — Play App Signing is NOT enabled (unlikely)**

If your app was published without enrolling in Play App Signing (possible only for very old apps):
- The original `.jks` IS the signing key
- Without it, new uploads signed with a different key will be rejected
- Recovery options are extremely limited and would require contacting Google Support directly

### Current Status

❓ Enrollment status unknown — you must check Play Console
⬜ New upload keystore not yet generated
⬜ PEM not yet exported
⬜ Reset request not yet submitted

---

## ⚠️ API Level Deadline

**Google Play Policy**

- Current target: Android 16 (API 36) ✅ Already configured
- **Deadline: August 31, 2026**
- v1.0.9 targets API 36 — compliant ✅

---

## Confirmed Facts

| Item | Value | Source |
|---|---|---|
| Play Store package name | `com.allformat.converter` | APK manifest / build.gradle.kts |
| Current version | 1.0.9 (version code 16) | pubspec.yaml + build.gradle.kts |
| min SDK | 24 (Android 7.0) | build.gradle.kts |
| target SDK | **36 (Android 16)** | build.gradle.kts |
| compile SDK | 36 | build.gradle.kts |
| Framework | Flutter + Dart | pubspec.yaml |
| Media library | `ffmpeg_kit_flutter_new` (v4.6.2) | pubspec.yaml |
| Icons | Lucide Icons | pubspec.yaml |
| Ads | Google AdMob | pubspec.yaml + AndroidManifest.xml |
| AdMob App ID | `ca-app-pub-2093403233028868~6019383556` | AndroidManifest.xml |
| File sharing | `open_file` + `share_plus` | pubspec.yaml |
| Backend | New Hugging Face Space (Phase 2) | Decision |
| Gradle version | 8.5 | gradle-wrapper.properties |
| AGP version | 8.3.2 | settings.gradle.kts |

---

## Active Decisions Made

| Decision | Choice |
|---|---|
| AdMob | ✅ Keep — ad-supported model retained |
| Backend | ✅ New Hugging Face Space (Phase 2) |
| minSdkVersion | ✅ Keep at 24 (Android 7.0) |
| targetSdkVersion | ✅ 36 (Android 16) — mandatory by Aug 31, 2026 |
| iOS | ✅ Planned — after Android is stable (Phase 3) |
| LOG/HDR compression | ✅ v1 requirement |
| FFmpeg package | ✅ `ffmpeg_kit_flutter_new` (community fork, 199 likes, 160/160 pub points) |
| Gradle/AGP | ✅ Gradle 8.5 + AGP 8.3.2 (bypasses Windows file-lock bug) |

---

## What Needs to Happen Next

- [ ] **Phase 2A** — Deploy FastAPI backend to Hugging Face Space
- [ ] **Phase 2B** — Implement 5 document tool screens with backend integration
- [ ] Check Play App Signing enrollment in Play Console
- [ ] If enrolled: generate new upload key and submit reset request
