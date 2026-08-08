# Convertix — Coding Agent Prompts
# Phase-by-phase execution prompts for Antigravity AI (or equivalent coding agent)

---

# HOW TO USE THIS FILE

Give ONE phase prompt at a time. Verify the output before moving to the next phase.
Never skip phases or combine them.

## Pre-Development Checklist (Complete Before Any Phase Prompt)

Before giving ANY prompt to the coding agent, confirm:

- [ ] Play App Signing enrollment verified in Play Console
- [ ] Upload key reset approved by Google (if needed)
- [ ] New upload keystore (`new-upload-key.jks`) generated and stored securely
- [ ] New `convertix` GitHub repository created and pulled locally
- [ ] AdMob ad unit IDs retrieved from AdMob console (admob.google.com)

---

# ─────────────────────────────────────────────
# PHASE 0 — PROJECT INITIALIZATION
# ─────────────────────────────────────────────

```
You are initializing the Convertix Flutter project from scratch.
This is a rebuild of an existing Play Store app. Read these rules carefully
before writing a single line of code.

## Non-negotiable constraints

Package (applicationId): com.allformat.converter — MUST match exactly. Never change.
Version code: 16 (one higher than the current live app, version code 15)
Version name: 1.0.9
minSdkVersion: 24 (Android 7.0)
targetSdkVersion: 36 (Android 16) — Google Play REQUIRES this by August 31, 2026
compileSdkVersion: 36
AdMob App ID: ca-app-pub-2093403233028868~6019383556 — must be in AndroidManifest.xml

## Step 1: Initialize the Flutter project

Run inside the repository root:
  flutter create --org com.allformat --project-name convertix .

Then MANUALLY set applicationId in android/app/build.gradle:
  defaultConfig {
      applicationId "com.allformat.converter"
      minSdkVersion 24
      targetSdkVersion 36
      compileSdkVersion 36  (add at android {} level)
      versionCode 16
      versionName "1.0.9"
  }

Confirm applicationId is exactly "com.allformat.converter" before continuing.

## Step 2: AndroidManifest.xml

Remove usesCleartextTraffic if present. App uses HTTPS only.

Add permissions:
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
  <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
  <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
  <uses-permission android:name="android.permission.WAKE_LOCK" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

Inside <application> tag, add AdMob:
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-2093403233028868~6019383556"/>

## Step 3: pubspec.yaml dependencies

Under dependencies:
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.3
  ffmpeg_kit_flutter_full_gpl: ^6.0.3
  google_mobile_ads: ^5.x
  dio: ^5.7.0
  image_picker: ^1.1.2
  file_picker: ^8.1.7
  path_provider: ^2.1.5
  permission_handler: ^11.3.1
  open_file: ^3.5.8
  share_plus: ^10.1.4
  image: ^4.3.0
  lucide_icons: ^0.257.0
  flutter_dotenv: ^5.2.1
  shared_preferences: ^2.3.x

Run: flutter pub get. Confirm zero errors.

## Step 4: Create folder structure

Create these Dart files (empty placeholders, just a comment inside each):

lib/main.dart
lib/app/app.dart
lib/app/router.dart
lib/app/theme.dart

lib/features/home/home_screen.dart
lib/features/home/home_provider.dart
lib/features/image_converter/image_converter_screen.dart
lib/features/image_converter/image_converter_provider.dart
lib/features/video_to_audio/video_to_audio_screen.dart
lib/features/video_to_audio/video_to_audio_provider.dart
lib/features/audio_converter/audio_converter_screen.dart
lib/features/audio_converter/audio_converter_provider.dart
lib/features/video_converter/video_converter_screen.dart
lib/features/video_converter/video_converter_provider.dart
lib/features/video_compression/video_compression_screen.dart
lib/features/video_compression/video_compression_provider.dart
lib/features/video_compression/log_profiles.dart
lib/features/image_to_pdf/image_to_pdf_screen.dart
lib/features/image_to_pdf/image_to_pdf_provider.dart
lib/features/document_convert/document_convert_screen.dart
lib/features/document_convert/document_convert_provider.dart
lib/features/greyscale_pdf/greyscale_pdf_screen.dart
lib/features/greyscale_pdf/greyscale_pdf_provider.dart
lib/features/merge_pdf/merge_pdf_screen.dart
lib/features/merge_pdf/merge_pdf_provider.dart
lib/features/split_pdf/split_pdf_screen.dart
lib/features/split_pdf/split_pdf_provider.dart
lib/features/settings/licenses_screen.dart

lib/core/services/ffmpeg_service.dart
lib/core/services/backend_service.dart
lib/core/services/file_service.dart
lib/core/services/permission_service.dart
lib/core/models/conversion_job.dart
lib/core/models/conversion_result.dart
lib/core/widgets/file_picker_button.dart
lib/core/widgets/conversion_progress.dart
lib/core/widgets/format_dropdown.dart
lib/core/widgets/error_card.dart
lib/core/widgets/success_card.dart
lib/core/utils/file_utils.dart
lib/core/utils/format_utils.dart

lib/shared/constants/api_constants.dart
lib/shared/constants/format_constants.dart
lib/shared/constants/ad_constants.dart

## Step 5: Implement main.dart

Wire up in order:
1. WidgetsFlutterBinding.ensureInitialized()
2. await MobileAds.instance.initialize()   ← AdMob must init before runApp
3. runApp(ProviderScope(child: ConvertixApp()))

## Step 6: Implement ad_constants.dart

During development, use test ad unit IDs:
  const String androidBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  const String iosBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';

Add a clear comment: "Replace with production ad unit IDs before Play Store submission."

## Step 7: Implement router.dart

go_router with named routes for all 12 screens:
  / → HomeScreen
  /image-convert → ImageConverterScreen
  /video-to-audio → VideoToAudioScreen
  /audio-convert → AudioConverterScreen
  /video-convert → VideoConverterScreen
  /video-compress → VideoCompressionScreen
  /image-to-pdf → ImageToPdfScreen
  /doc-convert → DocumentConvertScreen
  /greyscale-pdf → GreyscalePdfScreen
  /merge-pdf → MergePdfScreen
  /split-pdf → SplitPdfScreen
  /licenses → LicensesScreen

## Step 8: Implement theme.dart

Clean, minimal Material 3 theme.
Use Lucide Icons.
Brand accent: deep teal (#00796B) or your closest match.
Light mode only in v1.

## Step 9: Implement home_screen.dart

Scrollable home with two sections:
"Media Tools" → 5 tiles: Image Converter, Video to Audio, Audio Converter, Video Converter, Video Compression
"Document Tools" → 5 tiles: Image to PDF, Document Convert, Greyscale PDF, Merge PDF, Split PDF

Each tile: Lucide icon + tool name. Tap navigates to the tool's route.
No banner ad on the home screen — only on tool screens.

## Step 10: iOS initial setup

In ios/Podfile: platform :ios, '16.0'
In ios/Runner/Info.plist add:
  <key>GADApplicationIdentifier</key>
  <string>ca-app-pub-2093403233028868~6019383556</string>

## Verify

Run: flutter analyze — zero issues required.
Run on Android device: home screen shows all 10 tiles, navigation works.
Report: flutter analyze output + confirmation that the app launches.
```

---

# ─────────────────────────────────────────────
# PHASE 1A — CORE SERVICES
# ─────────────────────────────────────────────

```
Implement the core services layer. No feature screens yet.
Read ARCHITECTURE.md for the full pattern.

## conversion_result.dart
Fields: outputPath (String), outputFormat (String), fileSizeBytes (int),
        durationMs (int), success (bool), errorMessage (String?)

## conversion_job.dart
Fields: jobId (String, UUID), toolName (String), inputPath (String),
        progress (double, 0.0–1.0),
        status (enum: queued, running, success, failed, cancelled)

## file_service.dart
Methods:
  Future<String> getTempDir() → getTemporaryDirectory()/convertix/
  Future<String> getOutputDir() → getApplicationDocumentsDirectory()/convertix/outputs/
  Future<String> copyToTemp(String sourcePath, String jobId)
    → copies to getTempDir()/[jobId]/input.[ext], returns temp path
  String buildOutputPath(String inputName, String targetExt)
    → [outputDir]/[basename]_[timestamp].[targetExt]
  Future<void> cleanTempForJob(String jobId) → deletes getTempDir()/[jobId]/
  Future<void> cleanAllTemp() → deletes and recreates getTempDir()
    Call this on app startup.

## permission_service.dart
  Future<bool> requestStoragePermission()
    → Android 13+: request READ_MEDIA_IMAGES, READ_MEDIA_VIDEO, READ_MEDIA_AUDIO
    → Android <13: request READ_EXTERNAL_STORAGE
    → iOS: no runtime permission needed for document picker
    → return true if all needed permissions granted

## ffmpeg_service.dart
  Future<ConversionResult> execute({
    required String command,
    required String jobId,
    required String outputPath,
    void Function(double progress)? onProgress,
  })
  Future<void> cancelSession(String jobId)
  
  All FFmpegKit calls go here. No other file should call FFmpegKit directly.
  On success: ReturnCode.isSuccess() → ConversionResult(success: true, ...)
  On failure: ConversionResult(success: false, errorMessage: ...)
  Always clean temp in finally block.

## backend_service.dart
  Using Dio. Base URL from flutter_dotenv: Env.env['BACKEND_BASE_URL']

  Future<ConversionResult> uploadAndConvert({
    required String endpoint,
    required Map<String, dynamic> fields,
    required List<String> filePaths,
    required String outputPath,
    required String outputFilename,
  })
  Timeout: 60 seconds. Retry: 2 attempts on network failure (not on 4xx).
  On 200: write response bytes to outputPath, return success ConversionResult.
  Error messages must be human-readable (no raw exceptions to the user).

  Future<bool> checkHealth() → GET /health, timeout 5s, return true if 200

## ad_constants.dart (already created in Phase 0 — verify it exists)
## api_constants.dart
  const int backendTimeoutSeconds = 60;
  const int healthCheckTimeoutSeconds = 5;
  const int maxFileSizeMb = 50;

## format_constants.dart
  const imageInputFormats = ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'tiff'];
  const imageOutputFormats = ['jpg', 'png', 'webp', 'bmp', 'tiff'];
  const videoInputFormats = ['mp4', 'mkv', 'avi', 'mov', 'webm', 'flv', 'ts', '3gp', 'm4v', 'wmv'];
  const videoOutputFormats = ['mp4_h264', 'mp4_h265', 'mkv', 'mov', 'webm', 'avi', 'ts', '3gp'];
  const audioInputFormats = ['mp3', 'aac', 'm4a', 'wav', 'flac', 'ogg', 'opus', 'aiff', 'wma', 'amr'];
  const audioOutputFormats = ['mp3', 'aac', 'wav', 'flac', 'ogg', 'opus', 'aiff'];
  const videoToAudioOutputFormats = ['mp3', 'aac', 'wav', 'flac', 'ogg'];
  const audioBitrateOptions = [64, 128, 192, 320];
  const defaultAudioBitrate = 192;
  const videoResolutionOptions = ['original', '2160p', '1440p', '1080p', '720p', '480p'];

Run: flutter analyze — zero issues.
```

---

# ─────────────────────────────────────────────
# PHASE 1B — SHARED WIDGETS + BANNER AD WIDGET
# ─────────────────────────────────────────────

```
Implement the 5 shared UI widgets plus the banner ad widget.

## file_picker_button.dart
Opens FilePicker. Props: allowedExtensions (List<String>), label (String),
onFilePicked (Function(String path)).
Shows selected filename below button after selection.

## conversion_progress.dart
States: idle (dashed border, "Select a file to begin"), loading (progress + Cancel),
success (Open File + Share buttons), error (message + Retry button).

## format_dropdown.dart
Dropdown for output format selection.
Props: formats (List<String>), selectedFormat (String), onChanged (Function(String)).
Displays formats in uppercase.

## error_card.dart
Card with red left border, error message, Retry button.

## success_card.dart
Card with green left border, filename, file size, Open File + Share + Convert Another buttons.

## banner_ad_widget.dart (NEW — AdMob)
A reusable widget that loads and displays a BannerAd.
Uses ad_constants.dart to get the correct ad unit ID based on Platform.isAndroid/isIOS.
Handles AdWidget lifecycle (dispose on widget dispose).
Shows nothing (SizedBox.shrink()) if the ad fails to load — do not show error UI for ad failures.
Props: none (self-contained).

Usage in tool screens: place at the bottom of the scaffold body,
hidden (SizedBox.shrink()) when conversion is in progress (AsyncLoading state).

Run: flutter analyze — zero issues.
```

---

# ─────────────────────────────────────────────
# PHASE 1C — MEDIA TOOL IMPLEMENTATION
# ─────────────────────────────────────────────

```
Implement all 5 media tool features.
All media tools are on-device. No backend calls.
All FFmpeg calls go through ffmpeg_service.dart.
Every tool screen includes a BannerAdWidget at the bottom (hidden during conversion).

## Riverpod pattern for every tool provider

class [Tool]Notifier extends AsyncNotifier<ConversionResult?> {
  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({required File inputFile, required [Tool]Config config}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _run(inputFile, config));
  }

  void cancel() { /* cancel FFmpeg session, reset state to AsyncData(null) */ }
}

## Tool 1: Image Converter
Use `image` package (not FFmpegKit).
Load → decode → re-encode to target format → save.
Outputs: JPG, PNG, WEBP, BMP, TIFF.
Quality slider for lossy formats (10–100, default 90).

## Tool 2: Video to Audio
FFmpeg: -i [input] -vn -c:a [codec] -b:a [bitrate]k [output]
Codec mapping: mp3→libmp3lame, aac/m4a→aac, wav→pcm_s16le, flac→flac, ogg→libvorbis

## Tool 3: Audio Converter
FFmpeg: -i [input] -c:a [codec] -b:a [bitrate]k [output]
Same codec mapping. Lossless formats (wav, flac): no bitrate selector shown.

## Tool 4: Video Converter
FFmpeg: -i [input] -c:v [vcodec] -c:a copy -vf "scale=[w]:[h]" [output]
Codec: mp4_h264→libx264+ext=mp4, mp4_h265→libx265+ext=mp4, mkv→libx264,
       mov→libx264, webm→libvpx-vp9, avi→libx264, ts→libx264, 3gp→libx264
Resolution scaling: original→omit -vf, 2160p→scale=3840:-2, 1440p→scale=2560:-2,
                    1080p→scale=1920:-2, 720p→scale=1280:-2, 480p→scale=854:-2

## Tool 5: Video Compression (Standard + LOG/HDR)

### Standard
FFmpeg: -i [input] -c:v [libx264|libx265] -crf [18|23|28] -preset medium -c:a copy [output]
Quality presets: High→CRF 18, Balanced→CRF 23, Small→CRF 28

### LOG/HDR (log_profiles.dart)

class LogProfile {
  final String id;
  final String displayName;
  final String filterChain; // use {w} and {h} as placeholders
}

At runtime, replace {w} and {h} based on resolution:
  original → iw and ih
  2160p → 3840 and -2
  1440p → 2560 and -2
  1080p → 1920 and -2
  720p → 1280 and -2

Profiles to define in logProfiles list:

standard: 'scale={w}:{h},format=yuv420p'

slog2 (S-Log2, Sony):
  'zscale=transfer=linear:npl=100,format=gbrpf32le,zscale=p=bt709,
   tonemap=hable:desat=0,zscale=transfer=bt709:matrix=bt709:range=tv,
   format=yuv420p,scale={w}:{h}'

slog3 (S-Log3, Sony): same filter chain as slog2

dlog (D-Log, DJI):
  'zscale=transfer=linear,format=gbrpf32le,zscale=p=bt709,
   tonemap=reinhard:desat=0,zscale=transfer=bt709:matrix=bt709:range=tv,
   format=yuv420p,scale={w}:{h}'

dlogm (D-Log M, DJI newer): same as dlog

clog (C-Log, Canon):
  'zscale=transfer=linear:npl=100,format=gbrpf32le,zscale=p=bt709,
   tonemap=hable:desat=0,zscale=transfer=bt709:matrix=bt709:range=tv,
   format=yuv420p,scale={w}:{h}'

clog2 (C-Log2, Canon): same as clog with npl=200 in first zscale
clog3 (C-Log3, Canon): same as clog

vlog (V-Log, Panasonic): same as clog
vlogl (V-Log L, Panasonic): same as clog

hlg (HLG, broadcast/iPhone):
  'zscale=transfer=linear:npl=1000,format=gbrpf32le,zscale=p=bt709,
   tonemap=reinhard:param=3.0:desat=0,zscale=transfer=bt709:matrix=bt709:range=tv,
   format=yuv420p,scale={w}:{h}'

hdr10 (HDR10):
  'zscale=transfer=linear:npl=1000,format=gbrpf32le,zscale=p=bt709,
   tonemap=hable:desat=0,zscale=transfer=bt709:matrix=bt709:range=tv,
   format=yuv420p,scale={w}:{h}'

Full FFmpeg command for LOG compression:
  -i [input] -vf "[resolvedFilterChain]" -c:v [libx264|libx265] -crf [crf] -preset medium -c:a copy [output]

User workflow for Video Compression screen:
1. Pick file
2. Select LOG profile (dropdown, Standard is default)
3. Select quality preset (3 segmented buttons: High / Balanced / Small)
4. Select resolution (dropdown)
5. Select codec (segmented button: H.264 / H.265)
6. Tap Compress
7. BannerAdWidget hidden during conversion

Run: flutter analyze — zero issues.
Test each tool on Android. Confirm valid output files produced.
```

---

# ─────────────────────────────────────────────
# PHASE 2A — BACKEND DEPLOYMENT
# ─────────────────────────────────────────────

```
Create and deploy the Convertix document processing backend on Hugging Face Spaces.

## Create a new Hugging Face Space
Type: Docker — Name: convertix-backend — Visibility: Public

## Dockerfile
FROM python:3.11-slim
RUN apt-get update && apt-get install -y libreoffice libreoffice-writer \
    libreoffice-calc libreoffice-impress python3-pip && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]

## requirements.txt
fastapi==0.115.0
uvicorn==0.30.6
python-multipart==0.0.12
Pillow==10.4.0
PyMuPDF==1.24.10

## main.py endpoints:
GET /health → {"status": "ok"}
POST /image-to-pdf → Pillow images[] → PDF binary
POST /document-convert → LibreOffice soffice --headless → file binary
POST /greyscale-pdf → PyMuPDF grayscale reconstruction → PDF binary
POST /merge-pdf → PyMuPDF page merge → PDF binary
POST /split-pdf → PyMuPDF split by range or pages → PDF binary or ZIP

## File lifecycle (critical):
Every endpoint saves to /tmp/[uuid]/, processes, sends response,
then schedules async cleanup within 25 seconds of response sent.

import asyncio, shutil
async def cleanup_after_delay(path: str, delay: int = 25):
    await asyncio.sleep(delay)
    shutil.rmtree(path, ignore_errors=True)
# call: asyncio.create_task(cleanup_after_delay(job_dir)) before return

## Error format:
{"detail": "human-readable message"} with correct HTTP status codes.

## After deployment:
- Test GET /health → 200
- Set up cron-job.org: ping /health every 15 minutes
- Update BACKEND_BASE_URL in project .env file
```

---

# ─────────────────────────────────────────────
# PHASE 2B — DOCUMENT TOOL SCREENS
# ─────────────────────────────────────────────

```
Implement all 5 document tool screens and providers.
All document tools call backend via backend_service.dart.
Never use FFmpegKit for document tools.
Every tool screen includes BannerAdWidget at bottom, hidden during conversion.

## Tool 6: Image to PDF
Multiple image picker, Convert → POST /image-to-pdf (field: images[])
Output: [name]_[timestamp].pdf

## Tool 7: Document Convert
Single file picker, output format dropdown
Input: DOCX, XLSX, PPTX, ODT, ODS, ODP, RTF, TXT, CSV
Output: same set + PDF
POST /document-convert (fields: file, target_format)
Output: [name]_[timestamp].[targetFormat]

## Tool 8: Greyscale PDF
Single PDF picker → POST /greyscale-pdf (field: file)
Output: [name]_greyscale_[timestamp].pdf

## Tool 9: Merge PDF
Multiple PDF picker, ordered list → POST /merge-pdf (field: files[])
Output: merged_[timestamp].pdf

## Tool 10: Split PDF
Single PDF picker, mode toggle (Range / Pages)
Range: start+end page pairs
Pages: comma-separated page numbers
POST /split-pdf (fields: file, mode, params as JSON string)
Single output → save as PDF. Multiple outputs → save as ZIP.

After implementing:
- flutter analyze → zero issues
- Test each tool end-to-end with deployed backend
- Confirm backend log shows temp cleanup happening
```

---

# ─────────────────────────────────────────────
# PHASE 3 — iOS + OPEN SOURCE LICENSES + STORE PREP
# ─────────────────────────────────────────────

```
## iOS Setup
In ios/Podfile: platform :ios, '16.0'
Run: cd ios && pod install

## iOS AdMob
Confirm Info.plist has GADApplicationIdentifier set (should already be there from Phase 0).

## Test all tools on physical iPhone

## Open Source Licenses screen (lib/features/settings/licenses_screen.dart)
Add /licenses route. Include attribution for:
- FFmpeg (LGPL/GPL) — link to ffmpeg.org/legal
- ffmpeg_kit_flutter — GitHub
- All Flutter packages (use showLicensePage() or LicenseRegistry)
This screen is REQUIRED for App Store submission (LGPL compliance).

## Privacy notice for document tools
One-time dialog on first use of any document tool:
"Your file is sent to a secure server for conversion. It is automatically
deleted within 30 seconds of completion. Nothing is stored or shared."
Store dismissal state in SharedPreferences.

## App icon
Add icons for all densities:
- Android: android/app/src/main/res/mipmap-*/ic_launcher.png
- iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/
Use flutter_launcher_icons for automation.

## Play Store v1.0.9 Submission
Before signing release AAB, confirm:
1. Google has approved the upload key reset (email confirmation received)
2. google's activation timestamp has passed
3. android/key.properties points to new-upload-key.jks
4. versionCode 16, versionName 1.0.9, targetSdkVersion 36 in build.gradle
5. Production AdMob ad unit IDs set in ad_constants.dart

Build: flutter build appbundle --release
Submit AAB to Play Console.
MUST pass Google Play's API 36 policy check.

## iOS App Store
Build: flutter build ios --release
Archive in Xcode → distribute to App Store Connect.
```
