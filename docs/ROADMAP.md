# Convertix Roadmap

## Pre-Phase: Foundation ✅ COMPLETED

- [x] Verify Play App Signing enrollment in Play Console → ❓ still pending user action
- [x] Create GitHub repository (`editorav010-dev/Convertix`)
- [x] Pull repository locally

---

## Phase 0 — Project Initialization ✅ COMPLETED

**Goal:** Working Flutter scaffold with correct applicationId, API 36 target, AdMob, dependencies, folder structure, and navigation shell

- [x] Initialize Flutter project; set `applicationId = "com.allformat.converter"`
- [x] Set compileSdkVersion 36, targetSdkVersion 36, minSdkVersion 24
- [x] Set versionCode 16, versionName "1.0.9"
- [x] Add all pubspec.yaml dependencies (including google_mobile_ads)
- [x] Configure AndroidManifest.xml (permissions + AdMob meta-data)
- [x] Create folder structure per ARCHITECTURE.md
- [x] Configure go_router with all 11 routes (10 tools + licenses)
- [x] Set up Riverpod ProviderScope
- [x] Implement theme (Lucide icons, ColorScheme, TextTheme)
- [x] Implement home screen — tool grid (5 media + 5 document tiles)
- [x] Implement shared services (file_service, permission_service, ffmpeg_service, backend_service)
- [x] Implement shared widgets (file_picker_button, conversion_progress, format_dropdown, error_card, success_card)
- [x] Initialize AdMob (conditionally on Android/iOS only)
- [x] Test launch on Android device — home screen visible ✅

---

## Phase 1 — Media Tools Scaffolding ✅ COMPLETED

**Goal:** All 5 media tool screens scaffolded and building on Android
**Status:** ✅ Completed — Android build verified on RMX3998

- [x] `ffmpeg_service.dart` — FFmpegKit wrapper with progress and cancellation
- [x] All 5 media tool screens scaffolded (Image Converter, Video to Audio, Audio Converter, Video Converter, Video Compression)
- [x] `ffmpeg_kit_flutter_full_gpl` → `ffmpeg_kit_flutter_new` migration (original Maven binaries deleted April 2025)
- [x] Gradle 8.5 + AGP 8.3.2 configured (bypasses Windows file-lock bug)
- [x] AndroidX resolutionStrategy added for compatibility
- [x] `flutter analyze` — zero issues
- [x] Android APK built and launched on device

### Build Fixes Applied
- Gradle: `8.5` (gradle-wrapper.properties) — bypasses Windows transform lock bug in 8.6+
- AGP: `8.3.2` (settings.gradle.kts)
- resolutionStrategy: `activity:1.8.2`, `core:1.13.1`, `navigationevent:1.0.0` (build.gradle.kts)
- AdMob: wrapped in `Platform.isAndroid || Platform.isIOS` guard (main.dart)

---

## Phase 1C — Media Tools Implementation 🔜 NEXT (after Phase 2)

**Goal:** All 5 media tools fully functional with FFmpeg processing
**Status:** 🟡 Pending — tool screens are scaffolded, FFmpeg logic to be implemented

- [ ] Image Converter (using `image` Dart package, no FFmpeg)
- [ ] Video to Audio — FFmpeg extraction
- [ ] Audio Converter — FFmpeg transcoding
- [ ] Video Converter — FFmpeg transcoding
- [ ] Video Compression — Standard (no LOG)
- [ ] Video Compression — LOG/HDR (`log_profiles.dart` + all 12 profile filter chains)
- [ ] Ad placement: banner ads on tool screens (not covering progress/results)

---

## Phase 2 — Document Tools (Backend) 🔜 NEXT

**Goal:** All 5 document tools functional via FastAPI backend
**Status:** 🟡 Ready to start

### Phase 2A — Backend Deployment
- [ ] Hugging Face Space created and deployed
- [ ] Backend: `/health`, `/image-to-pdf`, `/document-convert`, `/greyscale-pdf`, `/merge-pdf`, `/split-pdf`
- [ ] cron-job.org keep-alive configured

### Phase 2B — Flutter Integration
- [ ] `backend_service.dart` — Dio client with retry and timeout
- [ ] Image to PDF
- [ ] Document Convert
- [ ] Greyscale PDF
- [ ] Merge PDF
- [ ] Split PDF

---

## Phase 3 — iOS Build, Polish & Store Submission

**Goal:** Full feature parity on iOS; Play Store + App Store ready
**Status:** 🔴 Not started

- [ ] iOS project configured (deployment target iOS 16.0)
- [ ] All media tools verified on physical iOS device
- [ ] All document tools verified on iOS
- [ ] Open Source Licenses screen (LGPL/GPL attribution for ffmpeg_kit)
- [ ] Privacy notice for document tools (files sent to server disclosure)
- [ ] AdMob iOS configuration verified
- [ ] App icon (Android + iOS all densities)
- [ ] Splash screen
- [ ] **Play Store: upload key reset approved** → sign AAB with new upload key → submit v1.0.9 targeting API 36
- [ ] App Store: first submission

---

## Phase 4 — v1.1 / v2 Features

**Status:** Future — requires Phase 1–3 stable

- Custom LUT import (.cube) for Video Compression
- Batch conversion for media tools
- Drag-to-reorder in Image to PDF
- Conversion history log (local)
- Dark mode
- Background task processing (conversion continues when app is backgrounded)
- Split PDF by blank page detection
- OCR (scanned PDF to searchable text)
- Rewarded or interstitial ad improvements

---

## Release Constraints Summary

| Item | Constraint | Deadline |
|---|---|---|
| targetSdkVersion | Must be 36 | Aug 31, 2026 |
| versionCode | Must be ≥ 16 | Before any Play Store submission |
| Upload key | Must complete reset process | Before Play Store submission |
| AdMob | Must be configured on both platforms | Before any store submission |
