# Setup Guide

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter SDK | 3.x latest stable | `flutter --version` to check |
| Dart SDK | 3.x | Included with Flutter |
| Android Studio | Latest | Required for Android SDK 36 |
| Xcode | 15+ | macOS only; required for iOS |
| Java / JDK | 17+ | Required by Gradle |
| Git | Any | |

---

## ⚠️ Critical Build Target Requirement

**targetSdkVersion MUST be 36 (Android 16).**
Google Play will reject any update targeting API < 36 after August 31, 2026.
Compile SDK and target SDK must both be 36.

---

## 1. Clone the Repository

```bash
git clone https://github.com/[org]/convertix.git
cd convertix
```

---

## 2. Confirm the Application ID

Before any build, verify `android/app/build.gradle` has:

```groovy
android {
    defaultConfig {
        applicationId "com.allformat.converter"   // MUST match exactly
        minSdkVersion 24
        targetSdkVersion 36                        // MUST be 36
        compileSdkVersion 36                       // MUST be 36
        versionCode 16
        versionName "1.0.9"
    }
}
```

The `applicationId` must be exactly `com.allformat.converter`.
Changing it breaks the Play Store update path.

---

## 3. Configure Signing (key.properties)

Create `android/key.properties` (never commit this file):

```
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../path/to/new-upload-key.jks
```

> ⚠️ The original signing keystore was lost. See STATE.md → BLOCKER 1 for the upload key reset process.
> Do not sign release builds until the Play Console upload key reset is approved by Google.

Reference this in `android/app/build.gradle`:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

## 4. Configure Environment

Create `.env` in the project root (never commit this):

```
BACKEND_BASE_URL=https://[your-hf-space-name].hf.space
```

---

## 5. Install Flutter Dependencies

```bash
flutter pub get
```

---

## 6. Configure AdMob

The app uses Google AdMob. The AdMob App ID from the original app is:
`ca-app-pub-2093403233028868~6019383556`

In `android/app/src/main/AndroidManifest.xml`, inside the `<application>` tag:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-2093403233028868~6019383556"/>
```

For iOS, add to `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-2093403233028868~6019383556</string>
```

---

## 7. Run the App

```bash
# Android
flutter run

# iOS (Mac + Xcode required)
flutter run -d ios
```

---

## 8. Backend Setup (Document Tools)

The document tools backend is a separate **Gradio** app hosted on Hugging Face Spaces.

**Live Space:** `pandeypratham/libreoffice-converter` → `https://pandeypratham-libreoffice-converter.hf.space`
Space card: `sdk: docker`, `app_port: 7860`, hardware `cpu-basic`, Gradio **4.36.0**.

> A second Space exists — `darkframeshzn/convertix-backend` (Gradio 6.24.0, `sdk: gradio`,
> ZeroGPU). It is **not** used by the app. Its handlers all carry `@spaces.GPU`, so its CPU-only
> workload is gated behind an exhausted ZeroGPU quota. Confirm which Space `.env` points at before
> debugging anything backend-related.

**Deploy to Hugging Face:**
1. Create a Space → **Docker** SDK → name it `libreoffice-converter`
2. Push `Dockerfile`, `app.py`, and `requirements.txt` from `backend/` to the Space repo
3. Note the Space URL: `https://[username]-libreoffice-converter.hf.space`
4. Update `.env` with this URL
5. Set up cron-job.org to ping the Space root every ~10 minutes (free tier sleep prevention)

**Run locally:**
```bash
cd backend
pip install -r requirements.txt   # gradio 4.36.0
python app.py                     # serves on http://0.0.0.0:7860
```

`backend/requirements.txt` is the **single source of version truth** — `backend/Dockerfile` installs
from it instead of duplicating pins. Change versions there and nowhere else.

**Endpoints** — Gradio `api_name`s, not REST paths. All calls go through the Gradio protocol
(see ARCHITECTURE.md → Document Tool Execution Flow):

| Gradio `api_name` | Handler | Description |
|---|---|---|
| `health` | `health_check` | Liveness → `"ok"` |
| `convert` | `convert_document` | Document format conversion (LibreOffice) |
| `split` | `split_pdf` | Split a PDF → ZIP of parts |
| `image_to_pdf` | `image_to_pdf` | Image(s) → single PDF |
| `greyscale_pdf` | `greyscale_pdf` | Colour PDF → greyscale |
| `merge_pdf` | `merge_pdf` | Multiple PDFs → single PDF |

Inspect the live contract (names + parameter order) with:
```bash
# Gradio 4 serves this at the root; Gradio 5+ under /gradio_api
curl -s https://pandeypratham-libreoffice-converter.hf.space/info
```

---

## 9. Key Flutter Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.3
  ffmpeg_kit_flutter_new: ^4.6.0    # NOT _full_gpl — original retired Apr 2025
  google_mobile_ads: ^5.3.0         # AdMob
  dio: ^5.7.0
  image_picker: ^1.1.2
  file_picker: ^8.1.7
  path_provider: ^2.1.5
  permission_handler: ^11.3.1
  open_file: ^3.5.8
  share_plus: ^10.1.4
  image: ^4.3.0
  lucide_icons_flutter: ^3.1.15
  flutter_dotenv: ^5.2.1
  shared_preferences: ^2.3.2
  cupertino_icons: ^1.0.8
  uuid: ^4.5.1
  path: ^1.9.0

dev_dependencies:
  flutter_lints: ^6.0.0
  flutter_test:
    sdk: flutter
```

> This table mirrors `pubspec.yaml`. Keep them in sync — a stale list here has previously led to
> agents "restoring" the retired `ffmpeg_kit_flutter_full_gpl` package.

---

## 10. Android 16 (API 36) Compatibility Notes

Targeting API 36 requires attention to:
- **Edge-to-edge display**: Enforced on Android 16. Use `WindowCompat.setDecorFitsSystemWindows(window, false)`. Flutter handles this automatically with recent versions.
- **Predictive Back**: If using custom back handling, confirm compatibility with `OnBackInvokedCallback`.
- **No cleartext traffic**: Do not add `usesCleartextTraffic: true` to the manifest. Backend must be HTTPS.

---

## 11. iOS Notes

- Minimum deployment target: iOS 16.0
- `ffmpeg_kit_flutter` ships as a compiled framework — App Store compliant
- LGPL/GPL attribution screen required in Settings → Open Source Licenses
- AdMob for iOS requires the `GADApplicationIdentifier` in Info.plist (see step 6)

---

## 12. Android Min SDK Notes

- `minSdkVersion 24` (Android 7.0) — matches the original app
- Scoped storage permissions (Android 10+) handled by `permission_handler`
- Granular media permissions (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`) used for Android 13+
- `READ_EXTERNAL_STORAGE` with `maxSdkVersion="32"` for Android 9–12
