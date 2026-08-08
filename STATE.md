# Project State

## Current Phase

Phase 0 — Pre-Development: Foundation & Blockers

## Status

🔴 Not started — active blockers must be resolved before Flutter project is initialized

---

## ⚠️ URGENT: API Level Deadline — 23 Days

**Google Play Policy Violation (ACTIVE)**

- Current target: Android 15 (API 35)
- Required target: Android 16 (API 36) or higher
- **Deadline: August 31, 2026**
- After this date, no updates can be submitted if targetSdkVersion < 36
- All build.gradle and pubspec changes must target `compileSdkVersion 36` and `targetSdkVersion 36`

**Action required immediately:**
v1.0.9 (the next release) MUST target API 36 or Google Play will block the submission.

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
- In the worst case, this would force creating a new app listing under a new package name

### What You Must Do First (Before Coding Starts)

1. Open Play Console (play.google.com/console)
2. Go to: your app → Release → Setup → App integrity
3. Check if Play App Signing is shown as "protected" or "enrolled"
4. If enrolled: follow the recovery process above
5. If NOT enrolled: contact Google Play Support immediately via Play Console Help

**This must be confirmed and resolved before submitting v1.0.9.**

### Current Status

❓ Enrollment status unknown — you must check Play Console
⬜ New upload keystore not yet generated
⬜ PEM not yet exported
⬜ Reset request not yet submitted

---

## 🔴 BLOCKER 2: GitHub Repository Decision

The existing repository `github.com/editorav010-dev/mediadoc-studio` was created for the previous Formatica/MediaDoc-Studio project. That project used Tauri + React + TypeScript + Rust for desktop — completely different from Convertix (Flutter + Dart mobile).

**Recommendation: Create a new repository named `convertix`.**

Reasons:
- The old repo's git history belongs to a different project and different tech stack
- Reusing it would leave Tauri/React/Rust artifacts in git history permanently
- A clean `convertix` repo gives agents unambiguous context: everything in the repo belongs to Convertix
- Repository identity matters for coding agents — a repo named `mediadoc-studio` with Convertix code inside it creates confusion

**Action required:**
- Create a new GitHub repository named `convertix` (or `convertix-app`)
- Keep `mediadoc-studio` as an archive reference if needed
- Pull the new repo locally
- Drop the documentation files into it as the starting commit

---

## Confirmed Facts (from APK analysis of v1.0.8)

| Item | Value | Source |
|---|---|---|
| Play Store package name | `com.allformat.converter` | APK manifest |
| Current version | 1.0.8 (version code 15) | APK manifest |
| Next version | 1.0.9 (version code 16) | Decision |
| Original min SDK | 24 (Android 7.0) | APK manifest |
| v1.0.9 min SDK | 24 (maintained) | Decision — not raised |
| v1.0.9 target SDK | **36 (Android 16) — MANDATORY** | Google Play policy |
| v1.0.9 compile SDK | 36 | Required |
| Framework | Flutter + Dart | APK libs |
| Media library | `ffmpeg_kit_flutter` | APK libs |
| Icons | Lucide Icons | APK font manifest |
| Ads | Google AdMob (confirmed) | APK manifest |
| AdMob App ID | `ca-app-pub-2093403233028868~6019383556` | APK manifest |
| File sharing | `open_file` + `share_plus` | APK manifest |
| Backend | New Hugging Face Space | Decision |

---

## Active Decisions Made

| Decision | Choice |
|---|---|
| AdMob | ✅ Keep — ad-supported model retained |
| Backend | ✅ New Hugging Face Space (separate from Formatica) |
| minSdkVersion | ✅ Keep at 24 (Android 7.0) — match original |
| targetSdkVersion | ✅ 36 (Android 16) — mandatory by Aug 31, 2026 |
| iOS | ✅ Planned — after Android is stable |
| LOG/HDR compression | ✅ v1 requirement |
| GitHub repo | ✅ New repository recommended |

---

## What Needs to Happen (in order)

- [ ] Check Play App Signing enrollment in Play Console
- [ ] If enrolled: generate new upload key and submit reset request
- [ ] Create new `convertix` GitHub repository
- [ ] Initialize Flutter project with `applicationId com.allformat.converter`
- [ ] Set compileSdkVersion 36, targetSdkVersion 36, minSdkVersion 24
- [ ] Add all pubspec.yaml dependencies (including google_mobile_ads)
- [ ] Create folder structure per ARCHITECTURE.md
- [ ] Drop documentation files as first commit
- [ ] Begin development phases
