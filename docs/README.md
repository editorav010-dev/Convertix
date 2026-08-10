# Convertix

Media and document conversion app for Android and iOS.

**Play Store:** `com.allformat.converter` · **Version:** 1.0.9 (version code 16) · **Status:** Active rebuild

---

## What It Does

### Media Tools — on-device, no internet required

| Tool | Description |
|---|---|
| Image Converter | Convert images between JPG, PNG, WEBP, BMP, TIFF |
| Video to Audio | Extract audio from any video file |
| Audio Converter | Convert audio between MP3, AAC, WAV, FLAC, OGG, OPUS, AIFF |
| Video Converter | Convert video between MP4 (H.264/H.265), MKV, MOV, WEBM, AVI, TS, 3GP |
| Video Compression | Compress video with LOG/HDR tone mapping — S-Log, D-Log, C-Log, V-Log, HLG, HDR10 |

### Document Tools — via backend, internet required

| Tool | Description |
|---|---|
| Image to PDF | Combine one or more images into a single PDF |
| Document Convert | Convert between DOCX, XLSX, PDF, PPTX, ODT, RTF, CSV, TXT |
| Greyscale PDF | Convert a colored PDF to high-quality black and white |
| Merge PDF | Combine multiple PDFs into one document |
| Split PDF | Split a PDF by page range or specific page numbers |

---

## Platform

- **Android** 7.0+ (minSdk 24) · **Target:** Android 16 (API 36)
- **iOS** 16+

---

## Architecture

Media tools → `ffmpeg_kit_flutter` (on-device, zero network).
Document tools → FastAPI + LibreOffice backend (Hugging Face Spaces).
Monetisation → Google AdMob (banner ads, non-intrusive).

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State management | Riverpod |
| Navigation | go_router |
| Media processing | ffmpeg_kit_flutter_full_gpl |
| Backend client | Dio |
| Ads | Google AdMob (google_mobile_ads) |
| Icons | Lucide Icons |

---

## Documentation

| File | Purpose |
|---|---|
| [SETUP.md](SETUP.md) | Local dev setup, build instructions, signing, AdMob config |
| [SPEC.md](SPEC.md) | Feature scope, format lists, tool behavior, constraints |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System design, folder structure, data flows, patterns |
| [AGENTS.md](AGENTS.md) | AI agent guardrails, hard rules, uncertainty handling |
| [STATE.md](STATE.md) | Current blockers, confirmed facts, what needs to happen next |
| [ROADMAP.md](ROADMAP.md) | Milestones, release phases, future features |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Git workflow, commit rules, doc sync requirements |

---

## Current Status

See [STATE.md](STATE.md) for active blockers before starting any development.

Two blockers must be resolved first:
1. **Play Store signing** — original upload keystore lost; Play App Signing enrollment must be confirmed and upload key reset requested via Play Console
2. **API 36 deadline** — Google Play requires targetSdkVersion 36 by August 31, 2026; all builds must target API 36

---

## Quick Start (after blockers resolved)

```bash
git clone https://github.com/[org]/convertix.git
cd convertix
flutter pub get
flutter run
```

Full setup: see [SETUP.md](SETUP.md).
