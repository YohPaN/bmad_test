# Internal APK Distribution — WH40K Match Companion (MVP)

**Distribution scope:** Internal testers only. Not for public release (NFR9 — private distribution mandate).  
**Application ID:** `com.vartus.mobile`  
**Current version:** 1.0.0 (build 1)

---

## Build Prerequisites (Developer Machine)

- Flutter stable channel installed and on PATH
- Android SDK with `adb` on PATH
- JDK 20 (configured via `android/gradle.properties`)
- Firebase project `whcompagnion` access (for production builds)

---

## Build the APK

```bash
cd mobile
flutter analyze          # Must report zero errors
flutter test             # Must pass all tests
flutter build apk --release
```

Output: `mobile/build/app/outputs/flutter-apk/app-release.apk`

---

## Install on Android Device

### Prerequisites (Tester Device)

- Android 6.0+ (API level 23 or higher)
- USB debugging enabled (`Settings > Developer Options > USB Debugging`)
- "Install from unknown sources" enabled (required for sideloading)

### Install via ADB (USB)

```bash
adb install -r mobile/build/app/outputs/flutter-apk/app-release.apk
```

The `-r` flag reinstalls without data loss (safe for iterative testing).

### Install via File Transfer (No Developer Machine)

1. Copy `app-release.apk` to the tester's device (via USB file transfer, email, or Slack)
2. Open the APK file on the device — Android will prompt to install
3. Approve "Install from unknown sources" if prompted

---

## Expected Behavior on First Launch

- App opens within 10 seconds (cold start)
- No login screen — anonymous session established silently
- Bottom navigation bar shows 4 tabs: Match / Historique / Joueurs / Room
- Tabs display placeholder content ("coming soon")

---

## Known Limitations (MVP)

- Signed with debug keystore — cannot be uploaded to Play Store
- No automatic update mechanism — testers must manually install new APK builds
- Firebase Anonymous Auth means no persistent identity across reinstalls
