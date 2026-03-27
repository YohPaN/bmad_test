# Story 1.2: Firebase Integration & Anonymous Authentication

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want to wire Firebase into the Flutter app with anonymous authentication,
so that every app session has a unique, authenticated user identity required for Firestore ownership rules.

## Acceptance Criteria

1. **Given** the initialized Flutter project from Story 1.1  
   **When** `firebase_core`, `firebase_auth`, and `cloud_firestore` are added to `pubspec.yaml` and FlutterFire CLI generates `firebase_options.dart`  
   **Then** `mobile/lib/core/firebase/firebase_options.dart` exists with valid Android configuration  
   **And** `mobile/android/app/google-services.json` is present

2. **Given** the app launches on an Android device or emulator  
   **When** `main.dart` calls `Firebase.initializeApp()` and `FirebaseAuth.instance.signInAnonymously()`  
   **Then** a non-null `uid` is available via `FirebaseAuth.instance.currentUser`  
   **And** the same `uid` persists across hot-restarts within the same session  
   **And** no authentication error is thrown under normal network conditions

3. **Given** the app launches with no network connection  
   **When** Firebase initialization runs  
   **Then** the app does not crash and displays a graceful error state

## Tasks / Subtasks

- [ ] Task 1 — Add Firebase packages to `pubspec.yaml` (AC: #1)
  - [ ] Add to `dependencies:` in `mobile/pubspec.yaml`:
    ```yaml
    firebase_core: ^3.x.x      # use latest stable
    firebase_auth: ^5.x.x      # use latest stable
    cloud_firestore: ^5.x.x    # use latest stable
    ```
  - [ ] Run `flutter pub get` inside `mobile/` to resolve packages

- [ ] Task 2 — Connect Firebase project via FlutterFire CLI (AC: #1)
  - [ ] Ensure `firebase-tools` and `flutterfire_cli` are installed (`dart pub global activate flutterfire_cli`)
  - [ ] From `mobile/` root, run: `flutterfire configure --platforms=android`
  - [ ] Verify `mobile/lib/core/firebase/firebase_options.dart` is generated (move to `core/firebase/` if FlutterFire places it at `lib/` root — see note below)
  - [ ] Verify `mobile/android/app/google-services.json` is present

- [ ] Task 3 — Create `core/firebase/` directory structure (AC: #1)
  - [ ] Create `mobile/lib/core/` directory
  - [ ] Create `mobile/lib/core/firebase/` directory
  - [ ] Move `firebase_options.dart` to `mobile/lib/core/firebase/firebase_options.dart` if not already there
  - [ ] Update any import path in `main.dart` to reference the correct location

- [ ] Task 4 — Wire Firebase init and anonymous auth in `main.dart` (AC: #2, #3)
  - [ ] Replace the generated `main()` in `mobile/lib/main.dart` with:
    ```dart
    import 'package:firebase_core/firebase_core.dart';
    import 'package:firebase_auth/firebase_auth.dart';
    import 'package:flutter/material.dart';
    import 'core/firebase/firebase_options.dart';

    void main() async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await FirebaseAuth.instance.signInAnonymously();
      } catch (e) {
        debugPrint('Firebase init error: $e');
        // Graceful error state handled in app.dart / MyApp
      }
      runApp(const MyApp());
    }
    ```
  - [ ] Enable Firestore offline persistence immediately after `Firebase.initializeApp()`:
    ```dart
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    ```
  - [ ] Keep the existing `MyApp` widget from the generated scaffold (do NOT add feature-first structure yet — that is Story 1.4 scope)

- [ ] Task 5 — Validate (AC: #2, #3)
  - [ ] Run `flutter analyze` inside `mobile/` → zero lint errors
  - [ ] Run on emulator or device: confirm `FirebaseAuth.instance.currentUser?.uid` is non-null in debug output (`debugPrint`)
  - [ ] Kill app (full stop), relaunch: confirm same `uid` is returned across hot-restarts in the same install
  - [ ] (Optional) Put device in airplane mode before launch: confirm no crash, graceful error displayed

## Dev Notes

### Starting Point — What Exists After Story 1.1

From the completed Story 1.1, the `mobile/` directory contains:

```
mobile/
├── pubspec.yaml              ← name: mobile, description: "Warhammer 40K Match Companion", no Firebase
├── analysis_options.yaml     ← flutter_lints + avoid_print: true
├── lib/
│   └── main.dart             ← plain Flutter counter scaffold (generated)
├── android/
│   ├── app/                  ← standard Gradle structure (no google-services.json yet)
│   └── gradle.properties     ← may contain org.gradle.java.home workaround from Story 1.1
└── test/
    └── widget_test.dart      ← generated widget test
```

**Critical environment note from Story 1.1:** JDK 20 is configured via `flutter config --jdk-dir` and `org.gradle.java.home` in `android/gradle.properties` to work around Java 24 SSL issues and Android Studio JBR missing `tzdb.dat`. **Do not change these settings.**

### FlutterFire CLI — Exact File Placement

By default, `flutterfire configure` places `firebase_options.dart` at `mobile/lib/firebase_options.dart`. The architecture mandates it must live at `mobile/lib/core/firebase/firebase_options.dart`.

**Steps to ensure correct placement:**
1. Run `flutterfire configure --platforms=android` from `mobile/`
2. If the file is generated at `mobile/lib/firebase_options.dart`, manually move it:
   ```
   mkdir -p mobile/lib/core/firebase/
   mv mobile/lib/firebase_options.dart mobile/lib/core/firebase/firebase_options.dart
   ```
3. Update the import in `main.dart`:
   ```dart
   import 'core/firebase/firebase_options.dart';
   ```
4. Do NOT create any other files under `core/firebase/` in this story — `firestore_paths.dart` is Story 1.4 scope.

### `main.dart` — Complete Revised File

Replace the entire generated scaffold `main.dart` (keep `MyApp` and `MyHomePage` widgets as-is from generated code, only rewrite `main()`):

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    await FirebaseAuth.instance.signInAnonymously();
    debugPrint('Signed in anonymously: ${FirebaseAuth.instance.currentUser?.uid}');
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(const MyApp());
}

// Keep the rest of main.dart (MyApp, MyHomePage) exactly as generated by flutter create.
// Story 1.4 will replace MyApp with app/app.dart featuring the dark theme + bottom nav.
```

**Key points:**
- `WidgetsFlutterBinding.ensureInitialized()` is mandatory before any `await` in `main()`
- `DefaultFirebaseOptions.currentPlatform` references the generated `firebase_options.dart`
- Offline persistence enabled here (architecture: `PersistenceSettings(cacheSizeBytes: CACHE_SIZE_UNLIMITED)`)
- `await signInAnonymously()` must complete before `runApp()` so `uid` is available immediately
- Catch block ensures no crash on network failure (AC #3)
- Use `debugPrint()` only — `print()` is forbidden (`avoid_print` lint rule active)

### Scope of This Story — What NOT to Do

| Deferred | Story |
|----------|-------|
| Feature-first directory structure (`features/room/`, `features/game/`, etc.) | 1.4 |
| `firestore_paths.dart` | 1.4 |
| `app/app.dart` — dark theme + bottom nav | 1.4 |
| Firestore Security Rules (`firestore.rules`) | 1.3 |
| `firebase.json` / `.firebaserc` | 1.3 |
| APK release build pipeline | 1.5 |
| Any domain models or repositories | 2.1+ |

**Do NOT** restructure `MyApp` or `MyHomePage` in `main.dart`. That is Story 1.4 scope. Only rewrite `main()` in this story.

### `pubspec.yaml` — Packages to Add

Under `dependencies:`, add the three Firebase packages. Use the latest stable versions at time of implementation:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^3.13.1      # check pub.dev for latest
  firebase_auth: ^5.5.2       # check pub.dev for latest
  cloud_firestore: ^5.6.7     # check pub.dev for latest
```

> **Check pub.dev** at implementation time for the latest stable versions of each package. The versions above are approximate — always use the newest compatible stable release.

### Project Structure After This Story

```
mobile/
├── pubspec.yaml                          ← + firebase_core, firebase_auth, cloud_firestore
├── analysis_options.yaml                 ← unchanged
├── lib/
│   ├── main.dart                         ← Firebase init + anon auth + offline persistence
│   └── core/
│       └── firebase/
│           └── firebase_options.dart     ← FlutterFire generated (Android config)
├── android/
│   └── app/
│       ├── google-services.json          ← FlutterFire generated (NEW)
│       └── ...
└── test/
    └── widget_test.dart                  ← unchanged
```

### Architecture Guardrails

- **`core/firebase/`** is the ONLY directory permitted to contain Firebase initialization logic and path strings. Nothing else in the project imports from Firebase SDK directly except through this layer and `main.dart`.
- **`firestore_paths.dart`** — not created in this story; belongs to Story 1.4.
- **State management:** `StreamBuilder` native only throughout MVP — no external state management packages.
- **`print()` forbidden** — use `debugPrint()` exclusively.
- **Offline persistence** must be enabled in this story at `Firebase.initializeApp()` time, not later: `Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)`.
- **Anonymous auth** is the sole auth mechanism for MVP — no email/password, no social login.
- **`uid` availability:** After Story 1.2, `FirebaseAuth.instance.currentUser?.uid` is guaranteed non-null on every app start (assuming Firebase init succeeds). All ownership logic in later stories depends on this.

### Security Notes

- `google-services.json` contains non-secret Firebase project identifiers (API keys for Firebase are **not** server secrets — they identify the project but are protected by Security Rules). Committing this file to the repo is standard practice for Android Firebase apps.
- `firebase_options.dart` is similarly safe to commit.
- **No real user data** is stored in this story — anonymous auth only creates a session UID.
- Actual data-access security is enforced via Firestore Security Rules (Story 1.3), not by hiding config files.

### NFRs Applicable to This Story

| NFR | Relevance |
|-----|-----------|
| NFR3 — App startup < 10 seconds | Firebase init and anonymous sign-in must not block cold start beyond 10s; async init should be fast under normal network |
| NFR5 — Data in transit encrypted | Firebase SDK enforces TLS for all communication by default; no additional configuration needed |
| NFR6 — Data at rest protected | Firestore managed encryption at rest; enabled by default |
| NFR10 — Offline resilience | Firestore offline persistence (`Settings.CACHE_SIZE_UNLIMITED`) enabled in this story |
| NFR20 — Firebase integration | Core deliverable of this story |

### FRs Covered by This Story

- **FR40/FR41** (via foundation): Anonymous auth enables all subsequent ownership-based features.
- All FR1–FR39 indirectly depend on the `uid` provided by this story's anonymous auth.

### Previous Story Learnings (from Story 1.1)

- **JDK environment:** JDK 20 is configured (`flutter config --jdk-dir` + `org.gradle.java.home` in `android/gradle.properties`). Do not alter. Gradle daemon may need restart after any Gradle-related changes: run `cd mobile/android && ./gradlew --stop`.
- **Gradle distribution:** `gradle-8.10.2-all` was manually downloaded. If Gradle re-download is triggered, be aware of the Java 24 SSL issue — use curl as workaround if needed.
- **Application ID:** `com.vartus.mobile` (generated by Story 1.1). This must match what Firebase project expects in `google-services.json` — verify the package name when configuring FlutterFire.
- **Flutter version:** 3.29.1 stable, Dart 3.7.0.
- **`flutter analyze`** must remain at zero errors after this story.
- **`flutter build apk --debug`** should still succeed after Firebase packages are added.

### References

- Story requirements: [epics.md — Story 1.2](../planning-artifacts/epics.md)
- `main.dart` responsibility: [architecture.md — Data Flow section](../planning-artifacts/architecture.md)
- Offline persistence: [architecture.md — Integration Points](../planning-artifacts/architecture.md)
- Project directory structure: [architecture.md — Complete Project Directory Structure](../planning-artifacts/architecture.md)
- FlutterFire CLI: https://firebase.flutter.dev/docs/cli
- `firebase_core` package: https://pub.dev/packages/firebase_core
- `firebase_auth` package: https://pub.dev/packages/firebase_auth
- `cloud_firestore` package: https://pub.dev/packages/cloud_firestore

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (GitHub Copilot)

### Debug Log References

### Completion Notes List

### File List
