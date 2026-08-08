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

The document tools backend is a separate FastAPI app hosted on Hugging Face Spaces.

**Deploy to Hugging Face:**
1. Create a new Space → Docker type → name it `convertix-backend`
2. Push the `backend/` directory to the Space repo
3. Note the Space URL: `https://[username]-convertix-backend.hf.space`
4. Update `.env` with this URL
5. Set up cron-job.org to ping `GET /health` every 15 minutes (free tier sleep prevention)

**Backend endpoints:**

| Method | Path | Description |
|---|---|---|
| GET | `/health` | Health check → `{"status": "ok"}` |
| POST | `/image-to-pdf` | Image(s) → PDF |
| POST | `/document-convert` | Document format conversion |
| POST | `/greyscale-pdf` | Color PDF → grayscale |
| POST | `/merge-pdf` | Multiple PDFs → single PDF |
| POST | `/split-pdf` | Split PDF by page range or page numbers |

---

## 9. Key Flutter Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.3
  ffmpeg_kit_flutter_full_gpl: ^6.0.3
  google_mobile_ads: ^5.x          # AdMob
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

dev_dependencies:
  flutter_lints: ^4.x
  flutter_test:
    sdk: flutter
```

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
