# Convertix Roadmap

## Pre-Phase: Foundation (Current — Must Complete Before Development)

**Status:** 🔴 Active blockers exist

- [ ] Verify Play App Signing enrollment in Play Console
- [ ] If enrolled: generate new upload key + submit PEM reset request to Google
- [ ] Wait for Google's 24–48 hour approval email
- [ ] Create new `convertix` GitHub repository
- [ ] Pull repository locally

---

## Phase 0 — Project Initialization

**Goal:** Working Flutter scaffold with correct applicationId, API 36 target, AdMob, dependencies, folder structure, and navigation shell
**Status:** 🔴 Not started — awaiting pre-phase completion

- [ ] Initialize Flutter project; set `applicationId = "com.allformat.converter"`
- [ ] Set compileSdkVersion 36, targetSdkVersion 36, minSdkVersion 24
- [ ] Set versionCode 16, versionName "1.0.9"
- [ ] Add all pubspec.yaml dependencies (including google_mobile_ads)
- [ ] Configure AndroidManifest.xml (permissions + AdMob meta-data)
- [ ] Configure iOS Info.plist (AdMob App ID)
- [ ] Create folder structure per ARCHITECTURE.md
- [ ] Configure go_router with all 11 routes (10 tools + licenses)
- [ ] Set up Riverpod ProviderScope
- [ ] Implement theme (Lucide icons, ColorScheme, TextTheme)
- [ ] Implement home screen — tool grid (5 media + 5 document tiles)
- [ ] Implement shared services (file_service, permission_service)
- [ ] Implement shared widgets (file_picker_button, conversion_progress, format_dropdown, error_card, success_card)
- [ ] Initialize AdMob (MobileAds.instance.initialize())
- [ ] Test launch on Android device — home screen visible

---

## Phase 1 — Media Tools (On-Device, Android)

**Goal:** All 5 media tools functional on Android
**Status:** 🔴 Not started

- [ ] `ffmpeg_service.dart` — FFmpegKit wrapper with progress and cancellation
- [ ] Image Converter (using `image` Dart package, no FFmpeg)
- [ ] Video to Audio
- [ ] Audio Converter
- [ ] Video Converter
- [ ] Video Compression — Standard (no LOG)
- [ ] Video Compression — LOG/HDR (`log_profiles.dart` + all 12 profile filter chains)
- [ ] Ad placement: banner ads on tool screens (not covering progress/results)

---

## Phase 2 — Document Tools (Backend)

**Goal:** All 5 document tools functional via FastAPI backend
**Status:** 🔴 Not started

- [ ] Hugging Face Space created and deployed
- [ ] Backend: `/health`, `/image-to-pdf`, `/document-convert`, `/greyscale-pdf`, `/merge-pdf`, `/split-pdf`
- [ ] cron-job.org keep-alive configured
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
