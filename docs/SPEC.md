# Convertix — Product Specification

## App Identity

| Field | Value |
|---|---|
| App name | Convertix |
| Package name | `com.allformat.converter` |
| Play Store version | 1.0.9 (version code 16) |
| Target SDK | 36 (Android 16) — mandatory by Aug 31, 2026 |
| Min SDK | 24 (Android 7.0) |
| Monetisation | Google AdMob (app-level App ID: `ca-app-pub-2093403233028868~6019383556`) |

## Overview

Convertix is a media and document conversion utility for Android and iOS.

- **Media tools** run entirely on-device using `ffmpeg_kit_flutter`. No files leave the device.
- **Document tools** send files to a FastAPI backend (Hugging Face, LibreOffice) over TLS. Files are deleted from the server within 30 seconds of job completion.
- **Monetisation** is handled by Google AdMob. Banner ads appear on tool screens. The ad model is non-intrusive and does not gate features behind paywalls.

---

## Media Tools (On-Device)

### 1. Image Converter

**Processing:** `image` Dart package (no FFmpeg needed)

| | Formats |
|---|---|
| Input | JPG, JPEG, PNG, WEBP, BMP, TIFF |
| Output | JPG, PNG, WEBP, BMP, TIFF |

- Preserves EXIF metadata where the output format supports it
- No batch conversion in v1
- Quality slider for lossy formats (JPG, WEBP): 10–100%, default 90%

---

### 2. Video to Audio

**Processing:** `ffmpeg_kit_flutter`

| | Formats |
|---|---|
| Input | MP4, MKV, AVI, MOV, WEBM, FLV, TS, 3GP, M4V |
| Output | MP3, AAC (M4A), WAV, FLAC, OGG |

- Bitrate options for MP3/AAC: 64 / 128 / 192 / 320 kbps — default 192
- WAV and FLAC: lossless, no bitrate selector shown
- Extracts first audio track by default

---

### 3. Audio Converter

**Processing:** `ffmpeg_kit_flutter`

| | Formats |
|---|---|
| Input | MP3, AAC, M4A, WAV, FLAC, OGG, OPUS, AIFF, WMA, AMR |
| Output | MP3, AAC (M4A), WAV, FLAC, OGG, OPUS, AIFF |

- Bitrate options: 64 / 128 / 192 / 320 kbps — shown only for lossy output formats
- WAV and FLAC output: lossless, no bitrate selector

---

### 4. Video Converter

**Processing:** `ffmpeg_kit_flutter`

| | Formats |
|---|---|
| Input | MP4, MKV, AVI, MOV, WEBM, FLV, TS, 3GP, M4V, WMV |
| Output | MP4 (H.264), MP4 (H.265), MKV, MOV, WEBM, AVI, TS, 3GP |

- Resolution options: Original / 4K (2160p) / 2K (1440p) / 1080p / 720p / 480p
- Audio track: preserved from input (copy, no re-encode) unless format incompatibility requires re-encode
- No framerate selector in v1

---

### 5. Video Compression

**Processing:** `ffmpeg_kit_flutter` with tone mapping filter chains

**This is the key differentiating feature of Convertix.**

#### Purpose
Reduce file size of large, high-quality video files while keeping quality loss invisible.
Primary target: LOG footage and HDR footage from cameras and drones.
Output is optimised for social media upload and smooth playback on low-spec devices.

#### Supported LOG / HDR Profiles

| Profile | Source |
|---|---|
| Standard | Regular video (no LOG, no HDR) |
| S-Log2 | Sony cameras (A7, FX series) |
| S-Log3 | Sony cameras (A7, FX series) |
| D-Log | DJI drones and cameras |
| D-Log M | DJI newer models |
| C-Log | Canon Cinema, R series |
| C-Log2 | Canon Cinema EOS |
| C-Log3 | Canon Cinema EOS |
| V-Log | Panasonic Lumix, GH series |
| V-Log L | Panasonic (reduced dynamic range variant) |
| HLG | Hybrid Log Gamma — broadcast, iPhone Cinematic |
| HDR10 | Generic HDR10 content |

#### Tone Mapping
All LOG/HDR profiles are tone-mapped to **BT.709** (standard color space for social media, YouTube, Instagram, TikTok) using FFmpeg `zscale` + `tonemap` filter chains.

Each profile has a distinct, tested filter chain defined in `lib/features/video_compression/log_profiles.dart`.

#### Quality Presets

| Preset | CRF | Use Case |
|---|---|---|
| High Quality | 18 | Near-lossless visual result, social media archives |
| Balanced | 23 | Instagram, TikTok, YouTube — best size/quality ratio |
| Small | 28 | WhatsApp, messaging apps, email |

#### Output Options
- **Codec:** H.264 (broad compatibility) or H.265 (smaller file, newer devices)
- **Resolution:** Original / 4K / 2K / 1080p / 720p

#### User Workflow
1. Select video file
2. Select LOG profile (or "Standard" if not LOG/HDR footage)
3. Select quality preset
4. Select output resolution
5. Select output codec (H.264 / H.265)
6. Tap Compress

---

## Document Tools (Backend — Internet Required)

### 6. Image to PDF

**Backend endpoint:** `POST /image-to-pdf`

- Input: JPG, PNG, WEBP, BMP, TIFF — one or multiple images
- Output: single PDF
- Multi-image order: determined by file selection order in v1 (drag-to-reorder in v2)
- Page size: A4, images auto-scaled to fit with aspect ratio preserved

---

### 7. Document Convert

**Backend endpoint:** `POST /document-convert`

| | Formats |
|---|---|
| Input | DOCX, XLSX, PPTX, ODT, ODS, ODP, RTF, TXT, CSV |
| Output | DOCX, XLSX, PPTX, PDF, ODT, ODS, ODP, RTF, TXT, CSV |

- Conversion engine: LibreOffice headless
- Preserves text, tables, images, colors, formatting (best effort)
- Known limitation: complex layouts and custom fonts may have minor rendering differences
- `target_format` parameter accepts lowercase extension string: `"pdf"`, `"docx"`, etc.

---

### 8. Greyscale PDF

**Backend endpoint:** `POST /greyscale-pdf`

- Input: any color PDF
- Output: grayscale PDF
- Preserves all text, vector graphics, images (converted to grayscale)
- No compression applied — output quality maintained
- Engine: PyMuPDF (fitz)

---

### 9. Merge PDF

**Backend endpoint:** `POST /merge-pdf`

- Input: 2 or more PDF files
- Output: single combined PDF
- Page order: determined by upload order
- Backend input size limit: 50 MB total across all files

---

### 10. Split PDF

**Backend endpoint:** `POST /split-pdf`

- Input: single PDF
- Split modes:
  - `range`: split into segments by page range — e.g., `{"ranges": [[1,5],[6,10]]}`
  - `pages`: extract specific pages — e.g., `{"pages": [3,7,12]}`
- Output: single PDF (one range/page set) or ZIP archive (multiple outputs)
- `params` field is a JSON string passed as a multipart form field

---

## File Selection (Phase 5B)

Choosing an input never shows a wall of unrelated apps. Convertix offers only sources that are
installed and can actually supply the required file type.

| Tool(s) | Sources offered |
|---|---|
| Image Converter | Photos (Android Photo Picker), Files, plus any installed Gallery / Photos app |
| Video Converter, Video Compression, Video to Audio | Photos, Files, plus any installed video-capable app |
| Audio Converter | Files and file-manager apps — not Photos |
| All 5 document tools, including Image to PDF | Files and file-manager apps — not Photos |

Guaranteed behaviour:

- The list reflects what is actually installed — an app that is absent is never shown, and an app
  that cannot supply the required type is never offered
- When only one source exists, no chooser appears — the tool opens it directly
- Backing out of a picker cancels quietly; it is not reported as an error
- Selecting a file needs **no storage permission** on any supported Android version
- If a chosen app has been uninstalled since the list was built, the user is told and can pick another

Remembering a preferred source ("Don't ask again") is Phase 5C.

---

## Output Locations (Phase 5A)

Every tool saves its result to a predictable public folder, visible in Gallery / Photos / Files
without the user moving anything.

| Tool | Output folder |
|---|---|
| Image Converter | `DCIM/Images (Convertix)/` |
| Video Converter, Video Compression | `Movies/Videos (Convertix)/` |
| Audio Converter, Video to Audio | `Music/Audio (Convertix)/` |
| Image to PDF | `Documents/Convertix/Image to PDF/` |
| Document Converter | `Documents/Convertix/Document Converter/` |
| Greyscale PDF | `Documents/Convertix/Greyscale PDF/` |
| Merge PDF | `Documents/Convertix/Merge PDF/` |
| Split PDF | `Documents/Convertix/Split PDF/` |

Guaranteed behaviour:

- Filenames follow `[original_name]_[timestamp].[ext]` — predictable, never random
- The folder is created automatically, including after the user deletes it
- An existing file is never overwritten — ` (1)`, ` (2)`… is appended
- A failed save leaves the source intact; the user's output is never silently lost
- Media indexing is asynchronous, so a new file may take a moment to appear in Gallery

Implementation is `OutputLocationService` over a MediaStore platform channel — see
`ARCHITECTURE.md` §Output File Naming & Placement. Split PDF produces a `.zip`, which Gallery
correctly does not index.

---

## Cross-Cutting Constraints

- Media tools: zero network activity, all processing local
- Document tools: files transmitted over TLS 1.3; deleted from server ≤ 30 seconds post-response
- No user accounts or sign-in
- No file contents stored beyond the active job
- Analytics: opt-in only, no PII, no file names or URLs collected
- Outputs are written to public media collections, never to app-private storage
- Advertising: AdMob banner ads on tool screens — see §Monetisation (AdMob)

---

## Out of Scope — v1

- Batch media conversion (multiple files at once)
- Custom LUT file import for Video Compression
- Drag-to-reorder in Image to PDF
- OCR (scanned PDF to editable text)
- Video editing, trimming, or clip cutting
- Password-protected PDF operations
- Subtitle extraction or download
- Cloud sync or conversion history
- Dark mode

---

## v2 Backlog

- Custom LUT import (.cube files) for Video Compression
- Batch conversion for all media tools
- Drag-to-reorder in Image to PDF
- Conversion history log (local)
- Dark mode
- Background task processing (conversion continues when app is backgrounded)
- Split PDF by blank page detection
- OCR via backend

---

## Monetisation (AdMob)

**Ad model:** Ad-supported. Free app with banner ads. No paywalls or feature gates.

**AdMob App ID:** `ca-app-pub-2093403233028868~6019383556`
(This is the same App ID from the original v1.0.8 app. The AdMob account must be accessible to retrieve individual ad unit IDs.)

**Ad placement rules:**
- Banner ads shown at the bottom of tool screens
- Ads do not cover the file picker, conversion progress, or result areas
- Ads are not shown during active conversion (progress phase) to avoid obscuring status
- No interstitials or rewarded ads in v1.0.9 (can be added in v1.1)

**Ad unit IDs:** TODO — retrieve from AdMob console (`admob.google.com`) under the existing app. The App ID is known; individual ad unit IDs are stored in the AdMob account.

**Ad initialisation:**
Call `MobileAds.instance.initialize()` in `main.dart` before `runApp()`.

**What the coding agent must NOT do:**
- Remove AdMob from pubspec
- Remove the meta-data tag from AndroidManifest.xml
- Comment out ad initialisation code
- Skip AdMob on iOS
