# Story 1.1: Initialize Flutter Android Project

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want to initialize the Flutter project using the exact architecture-specified command,
so that the codebase starts from a clean, correctly configured Android-first foundation.

## Acceptance Criteria

1. **Given** a machine with Flutter stable SDK installed  
   **When** the following command is executed:  
   `flutter create --org com.vartus --template=app --platforms=android --description="Warhammer 40K Match Companion" mobile`  
   **Then** a `mobile/` directory is created at the project root with a valid Flutter project structure  
   **And** `mobile/android/` exists and builds a runnable APK via `flutter run`  
   **And** `mobile/analysis_options.yaml` is configured with the Flutter recommended linting ruleset  
   **And** `mobile/pubspec.yaml` contains the correct `description` ("Warhammer 40K Match Companion") and `name` fields

2. **Given** the initialized project  
   **When** `flutter analyze` is run  
   **Then** zero lint errors are reported

3. **Given** `mobile/analysis_options.yaml`  
   **When** a Dart file contains a call to `print()`  
   **Then** the linter flags it as an error or warning (lint rule `avoid_print` enabled)

## Tasks / Subtasks

- [x] Task 1 — Run the exact Flutter init command (AC: #1)
  - [x] From the `cursor_project/` root, run:
    ```bash
    flutter create \
      --org com.vartus \
      --template=app \
      --platforms=android \
      --description="Warhammer 40K Match Companion" \
      mobile
    ```
  - [x] Verify `mobile/` directory exists at project root
  - [x] Verify `mobile/android/` exists
  - [x] Verify `mobile/pubspec.yaml` has `name:` and `description: "Warhammer 40K Match Companion"`

- [x] Task 2 — Configure `analysis_options.yaml` for strict linting (AC: #2, #3)
  - [x] Open `mobile/analysis_options.yaml`
  - [x] Ensure `include: package:flutter_lints/flutter.yaml` is present
  - [x] Add `avoid_print: true` under `linter: rules:` to forbid `print()` calls
  - [x] Run `flutter analyze` and confirm zero errors

- [x] Task 3 — Validate build (AC: #1)
  - [x] Run `flutter build apk --debug` inside `mobile/` and confirm no build errors
  - [x] (Optional physical / emulator check) Run `flutter run` and confirm app launches

## Dev Notes

### Critical Implementation Constraint — Exact Init Command

The architecture mandates the **exact** following command. Do not alter flags:

```bash
flutter create \
  --org com.vartus \
  --template=app \
  --platforms=android \
  --description="Warhammer 40K Match Companion" \
  mobile
```

- `--org com.vartran` → sets the Android application ID prefix (`com.vartrus.cursor_project` or similar — accept what Flutter generates)
- `--platforms=android` → Android-only target; do NOT add iOS, web, etc.
- `--template=app` → standard app template; ensures `lib/main.dart` scaffold is generated
- Command must be run from `cursor_project/` root (not inside `mobile/`)

### Scope of This Story — What NOT to Do

This story is **initialization only**. The following are explicitly deferred to later stories:

| Deferred | Story |
|----------|-------|
| Firebase packages (`firebase_core`, `firebase_auth`, `cloud_firestore`) | 1.2 |
| `firebase_options.dart` (FlutterFire CLI) | 1.2 |
| Feature-first directory structure (`features/room/`, `features/game/`, etc.) | 1.4 |
| `core/firebase/firestore_paths.dart` | 1.4 |
| `app/app.dart` with MaterialApp dark theme + bottom nav | 1.4 |
| Test mirror structure (`test/`, `integration_test/`) | 1.4 |
| Firestore Security Rules | 1.3 |
| APK release distribution pipeline | 1.5 |

**Do not implement anything from the above table in this story.**

### `analysis_options.yaml` — Required Configuration

After `flutter create`, the generated `analysis_options.yaml` typically already includes the Flutter recommended linting rules via `flutter_lints`. Verify and add `avoid_print` to ensure `print()` calls are flagged:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: true
```

> **Rule:** Throughout the entire codebase, `print()` is forbidden. Use `debugPrint()` in development contexts instead. This rule is enforced from day one by the linter.

### `pubspec.yaml` — Expected Fields

After `flutter create`, `pubspec.yaml` will contain auto-generated content. Verify:
- `name:` is set (Flutter generates it from the directory name — `mobile` → `name: mobile` is acceptable for MVP)
- `description: "Warhammer 40K Match Companion"` must match the `--description` flag value exactly
- **Do NOT** add Firebase packages to `pubspec.yaml` in this story (Story 1.2 scope)

### Project Structure After This Story

```
cursor_project/
└── mobile/
    ├── pubspec.yaml              ← name + description set, no Firebase yet
    ├── analysis_options.yaml     ← Flutter recommended + avoid_print: true
    ├── android/
    │   └── app/
    │       └── ...               ← standard Android Gradle structure
    ├── lib/
    │   └── main.dart             ← generated Flutter scaffold
    └── test/
        └── widget_test.dart      ← generated widget test (keep as-is)
```

### Architecture Guardrails

- **Language:** Dart 3 with null-safety enforced (Flutter stable SDK; all generated code is null-safe)
- **State management:** No external state management packages at this stage (and throughout MVP: `StreamBuilder` native only)
- **Platform:** Android-only (`--platforms=android`); do not add iOS or web
- **Naming conventions (established for all future stories):**
  - Classes/Models/Widgets: `PascalCase`
  - Files: `snake_case.dart`
  - Variables/functions: `camelCase`
  - Constants: `SCREAMING_SNAKE_CASE`
- **`print()` is forbidden** project-wide — configure `avoid_print: true` in `analysis_options.yaml`

### NFRs Applicable to This Story

| NFR | Relevance |
|-----|-----------|
| NFR5 — Data in transit encrypted | Foundation only; actual Firebase TLS enforced in Story 1.2 |
| NFR9 — Internal/private distribution only | No store publication at any point in MVP |
| NFR14 — Support growth without redesign | Feature-first structure defined in Story 1.4 builds on this init |
| NFR20 — Firebase integration | Wired in Story 1.2; this story creates the app that will host it |

### FRs Covered by This Story

- FR40: The product can be distributed through internal/private channels for MVP validation.
- FR41: A tester can install and run MVP builds without public store publication.

### Project Context Notes

- Project key: `cursor_project`
- All implementation artifacts are stored in `_bmad-output/implementation-artifacts/`
- All planning artifacts are in `_bmad-output/planning-artifacts/`
- This is an Android-first Flutter + Firebase app (Warhammer 40K Match Companion)
- No CI/CD pipeline for MVP — local builds only

### References

- Exact init command: [architecture.md — Starter Template section](../planning-artifacts/architecture.md)
- Linting rules: [architecture.md — Implementation Patterns & Consistency Rules](../planning-artifacts/architecture.md)
- Feature structure (deferred to 1.4): [architecture.md — Complete Project Directory Structure](../planning-artifacts/architecture.md)
- Story requirements source: [epics.md — Story 1.1](../planning-artifacts/epics.md)
- `avoid_print` lint rule: `flutter_lints` package — `package:flutter_lints/flutter.yaml`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (GitHub Copilot)

### Debug Log References

- **Java SSL Issue**: Gradle wrapper failed to download `gradle-8.10.2-all.zip` due to Java 24 empty truststore (`trustAnchors parameter must be non-empty`). Downloaded manually via curl and extracted successfully.
- **ZoneInfoFile Error**: Android Studio JBR (OpenJDK 17) is missing `lib/tzdb.dat`. Could not write to Program Files (permission denied). Fixed by: (1) configuring `flutter config --jdk-dir "C:/Program Files/Java/jdk-20"`, and (2) adding `org.gradle.java.home=C\:\\Program Files\\Java\\jdk-20` to `android/gradle.properties`. JDK 20 has `tzdb.dat` and is compatible with Gradle 8.10.2.
- **Gradle daemon caching**: After each JDK change, needed to run `gradlew --stop` to kill cached daemon running wrong JDK.

### Completion Notes List

- Flutter 3.29.1 stable used; Dart 3.7.0.
- `flutter create` generated 35 files. Application ID: `com.vartus.mobile`. `pubspec.yaml` name set to `mobile` (Flutter uses directory name).
- `analysis_options.yaml`: `avoid_print: true` activated under `linter: rules:`. `flutter analyze` → **No issues found**.
- `flutter build apk --debug` → **✓ Built** `build/app/outputs/flutter-apk/app-debug.apk` (222s).
- Environment workarounds required: JDK 20 set via `flutter config --jdk-dir` and `org.gradle.java.home` in `gradle.properties` due to Android Studio JBR missing `tzdb.dat` and Java 24 SSL truststore issues in this dev environment. These are machine-specific settings; other developers may not need them.
- Gradle distribution `gradle-8.10.2-all` downloaded via curl (218MB) because Java SSL was broken in this environment.

### File List

- `mobile/` (entire new directory — 35 files generated by flutter create)
- `mobile/pubspec.yaml`
- `mobile/analysis_options.yaml`
- `mobile/lib/main.dart`
- `mobile/android/`
- `mobile/android/gradle/wrapper/gradle-wrapper.properties`
- `mobile/android/gradle.properties`

### Change Log

- **2026-03-25**: Story 1.1 implemented. Flutter project initialized at `mobile/` with exact architecture command (`--org com.vartus --platforms=android --description="Warhammer 40K Match Companion"`). `avoid_print: true` added to `analysis_options.yaml`. `flutter analyze` → zero errors. `flutter build apk --debug` → success. `org.gradle.java.home=jdk-20` added to `android/gradle.properties` to work around missing `tzdb.dat` in Android Studio JBR on this machine.
