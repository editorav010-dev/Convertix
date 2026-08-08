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
│   │   ├── file_service.dart         # temp + output file management; cleanup logic
│   │   └── permission_service.dart   # storage + media permissions (Android + iOS)
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

```
1. User selects file(s)
         ↓
2. permission_service.dart — check + request permission
         ↓
3. backend_service.dart — build multipart FormData with file(s) + params
         ↓
4. Dio POST to BACKEND_BASE_URL/[endpoint]
   — timeout: 60 seconds
   — retry: 2 attempts on network failure (not on 4xx)
         ↓
5. Backend processes with LibreOffice / Pillow / PyMuPDF
         ↓
6. Response: binary file stream (or ZIP for multi-output split)
         ↓
7. backend_service.dart — write response bytes to output file
   path: getApplicationDocumentsDirectory()/convertix/outputs/[filename].[ext]
         ↓
8. state = AsyncData(ConversionResult) → success_card renders
```

---

## Backend Architecture

**Host:** Hugging Face Spaces (Docker)
**Framework:** FastAPI + uvicorn
**Conversion engine:** LibreOffice headless (`soffice --headless --convert-to`)
**PDF engine:** PyMuPDF (`fitz`) for greyscale + split
**Image engine:** Pillow for image-to-PDF

### File Lifecycle on Backend

```
POST received
   ↓
Save to /tmp/[uuid]/input/   ← job-scoped temp directory
   ↓
Process → save to /tmp/[uuid]/output/
   ↓
Stream output bytes to client
   ↓
Schedule deletion of /tmp/[uuid]/ ← runs within 30 seconds of response sent
```

### Backend Response Format

- **Single file output:** raw binary response with correct `Content-Type` header
- **Multi-file output (split PDF):** `application/zip` binary response
- **Error:** JSON `{"detail": "human-readable message"}` with appropriate HTTP status

---

## Output File Naming

```dart
// file_service.dart
String buildOutputPath(String inputName, String targetExt) {
  final base = path.basenameWithoutExtension(inputName);
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return '${outputDir}/${base}_${timestamp}.${targetExt}';
}
```

Pattern: `[original_name]_[timestamp].[ext]`
Example: `interview_video_1720000000000.mp3`

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
