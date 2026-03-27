# Story 1.4: Feature-First Project Structure & Core Utilities

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want the complete feature-first directory structure and core utilities scaffolded,
so that all future stories have a consistent, architecture-compliant file organization from the start.

## Acceptance Criteria

1. **Given** the Firebase-wired project from Story 1.2  
   **When** the feature-first structure is created manually  
   **Then** the following directories exist: `mobile/lib/app/`, `mobile/lib/core/firebase/`, `mobile/lib/features/room/data/`, `mobile/lib/features/room/domain/`, `mobile/lib/features/room/presentation/`, `mobile/lib/features/game/data/`, `mobile/lib/features/game/domain/`, `mobile/lib/features/game/presentation/`, `mobile/lib/features/game/presentation/widgets/`

2. **Given** the structure above  
   **When** `mobile/lib/core/firebase/firestore_paths.dart` is created  
   **Then** it contains typed path helpers/constants for `rooms`, `rooms/{id}/players`, and `rooms/{id}/events` collections  
   **And** no other Dart file in the project contains hardcoded Firestore path strings

3. **Given** `mobile/lib/app/app.dart` is created  
   **When** the app runs  
   **Then** `MaterialApp` is initialized with a dark-theme seed based on the design token `#0D0F14`  
   **And** the bottom navigation bar with 4 placeholder tabs (Match / Historique / Joueurs / Room) is visible

4. **Given** the test directory  
   **When** the mirror structure is verified  
   **Then** `mobile/test/features/game/` and `mobile/test/features/room/` directories exist  
   **And** `mobile/integration_test/` directory exists

5. **Given** `flutter analyze` is run on the full project  
   **Then** zero lint errors are reported  
   **And** `print()` calls are flagged as lint warnings (`avoid_print: true` already active in `analysis_options.yaml`)

## Tasks / Subtasks

- [x] Task 1 — Create all feature-first `lib/` directory structure (AC: #1)
  - [x] Create `mobile/lib/features/room/data/.gitkeep`
  - [x] Create `mobile/lib/features/room/domain/.gitkeep`
  - [x] Create `mobile/lib/features/room/presentation/.gitkeep`
  - [x] Create `mobile/lib/features/game/data/.gitkeep`
  - [x] Create `mobile/lib/features/game/domain/.gitkeep`
  - [x] Create `mobile/lib/features/game/presentation/.gitkeep`
  - [x] Create `mobile/lib/features/game/presentation/widgets/.gitkeep`
  - [x] Note: `mobile/lib/app/` does NOT need `.gitkeep` — `app.dart` (Task 3) will reside there; `mobile/lib/core/firebase/` already exists from Story 1.2

- [x] Task 2 — Create `mobile/lib/core/firebase/firestore_paths.dart` (AC: #2)
  - [x] Create the file with a private constructor to prevent instantiation
  - [x] Add `static CollectionReference<Map<String, dynamic>> rooms()` → `FirebaseFirestore.instance.collection('rooms')`
  - [x] Add `static DocumentReference<Map<String, dynamic>> room(String roomId)` → `rooms().doc(roomId)`
  - [x] Add `static CollectionReference<Map<String, dynamic>> players(String roomId)` → `room(roomId).collection('players')`
  - [x] Add `static DocumentReference<Map<String, dynamic>> player(String roomId, String uid)` → `players(roomId).doc(uid)`
  - [x] Add `static CollectionReference<Map<String, dynamic>> events(String roomId)` → `room(roomId).collection('events')`
  - [x] Add `static DocumentReference<Map<String, dynamic>> event(String roomId, String eventId)` → `events(roomId).doc(eventId)`
  - [x] Verify no hardcoded path strings (`'rooms'`, `'players'`, `'events'`) exist in any other Dart file

- [x] Task 3 — Create `mobile/lib/app/app.dart` with MaterialApp + dark theme + bottom nav (AC: #3)
  - [x] Create `App` as a `StatelessWidget` returning `MaterialApp`
  - [x] Set `title: 'WH40K Match Companion'` and `debugShowCheckedModeBanner: false`
  - [x] Configure `ThemeData` with `useMaterial3: true`, `brightness: Brightness.dark`, dark color scheme
  - [x] Set `home: const _AppShell()`
  - [x] Create `_AppShell` as a `StatefulWidget` managing `int _currentIndex = 0`
  - [x] Implement `BottomNavigationBar` with `type: BottomNavigationBarType.fixed` and exactly 4 items in order: Match (index 0), Historique (index 1), Joueurs (index 2), Room (index 3)
  - [x] Each tab body: `Center(child: Text('${_tabLabel} — coming soon'))` within a `Scaffold`
  - [x] Use `setState` in `onTap` to update `_currentIndex`

- [x] Task 4 — Update `mobile/lib/main.dart` to use `App` instead of `MyApp` (AC: #3)
  - [x] Add import `import 'app/app.dart';`
  - [x] Replace `runApp(const MyApp())` with `runApp(const App())`
  - [x] Delete the entire `MyApp` class (StatelessWidget returning MaterialApp with counter theme)
  - [x] Delete the entire `MyHomePage` StatefulWidget and its `_MyHomePageState` class
  - [x] Keep ALL existing imports: `cloud_firestore`, `firebase_auth`, `firebase_core`, `flutter/material.dart`, `core/firebase/firebase_options.dart`
  - [x] Keep the Firebase `try/catch` init block UNCHANGED — it was verified in Stories 1.1–1.3

- [x] Task 5 — Create test/integration_test mirror directory structure (AC: #4)
  - [x] Create `mobile/test/features/game/.gitkeep`
  - [x] Create `mobile/test/features/room/.gitkeep`
  - [x] Create `mobile/integration_test/README.md` with content: "Multi-client Firestore sync integration tests. See architecture.md — Integration Points. Story 5.3."

- [x] Task 6 — Update `mobile/test/widget_test.dart` to test the new `App` widget (AC: #5)
  - [x] Replace the import of `package:mobile/main.dart` with `package:mobile/app/app.dart`
  - [x] Replace the test body to pump `const App()` and assert 4 bottom-nav labels render:
    - `expect(find.text('Match'), findsOneWidget)`
    - `expect(find.text('Historique'), findsOneWidget)`
    - `expect(find.text('Joueurs'), findsOneWidget)`
    - `expect(find.text('Room'), findsOneWidget)`
  - [x] Remove the old counter test assertions

- [x] Task 7 — Run `flutter analyze` and `flutter test` (AC: #5)
  - [x] Run `flutter analyze` from `mobile/` — must report zero errors
  - [x] Run `flutter test` from `mobile/` — all tests must pass
  - [x] Fix any lint errors introduced by new files (e.g., unused imports, missing `const`)

## Dev Notes

### Starting Point — What Exists After Story 1.3

```
mobile/
├── pubspec.yaml              ← firebase_core ^3.13.1, firebase_auth ^5.5.2, cloud_firestore ^5.6.7
├── analysis_options.yaml     ← flutter_lints + avoid_print: true
├── firebase.json             ← FlutterFire + Firestore CLI sections (pretty-printed)
├── firestore.rules           ← Complete security rules (deployed to project whcompagnion)
├── firestore.indexes.json    ← Empty indexes
├── .firebaserc               ← project: whcompagnion
├── lib/
│   ├── main.dart             ← Firebase init + Firestore offline + signInAnonymously + MyApp/MyHomePage (TO REPLACE)
│   ├── firebase_options.dart ← Original FlutterFire CLI output at root (may coexist, UNUSED)
│   └── core/
│       └── firebase/
│           └── firebase_options.dart  ← Active FlutterFire config (imported by main.dart)
└── test/
    └── widget_test.dart      ← Tests old counter MyApp (MUST BE REPLACED in Task 6)
```

**Key environment facts (do NOT change):**
- Firebase project ID: `whcompagnion`
- Application ID: `com.vartus.mobile`
- Firebase Tools: v15.11.0 (global npm)
- FlutterFire CLI: v1.3.1 (`dart pub global run flutterfire_cli:flutterfire`)
- JDK 20 via `org.gradle.java.home` in `android/gradle.properties` — **do not alter**
- Dart SDK constraint: `^3.7.0`

### Critical: `main.dart` Cleanup

`main.dart` currently contains the Flutter `create` demo boilerplate — `MyApp` (a `StatelessWidget`) and `MyHomePage`/`_MyHomePageState` (a counter widget). **These must be removed.** The Firebase init block (lines roughly 8–26) must remain byte-for-byte identical.

Keep this block exactly as-is:
```dart
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
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    debugPrint(
      'Signed in anonymously: ${FirebaseAuth.instance.currentUser?.uid}',
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(const App());  // ← only this line changes
}
```

### `firestore_paths.dart` — Exact Implementation

All Firestore path strings are **FORBIDDEN** anywhere except this file. This is a hard architectural constraint — no exceptions.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Central repository of all Firestore collection and document paths.
/// This is the ONLY file in the project permitted to contain Firestore path strings.
class FirestorePaths {
  FirestorePaths._(); // Prevent instantiation

  static CollectionReference<Map<String, dynamic>> rooms() =>
      FirebaseFirestore.instance.collection('rooms');

  static DocumentReference<Map<String, dynamic>> room(String roomId) =>
      rooms().doc(roomId);

  static CollectionReference<Map<String, dynamic>> players(String roomId) =>
      room(roomId).collection('players');

  static DocumentReference<Map<String, dynamic>> player(
          String roomId, String uid) =>
      players(roomId).doc(uid);

  static CollectionReference<Map<String, dynamic>> events(String roomId) =>
      room(roomId).collection('events');

  static DocumentReference<Map<String, dynamic>> event(
          String roomId, String eventId) =>
      events(roomId).doc(eventId);
}
```

### `app.dart` — Dark Theme & Bottom Nav Implementation

Story 1.4 establishes the dark theme seed. Full Material Design 3 color token refinement (UX-DR11 full palette with custom surface-card, surface-elevated, border tokens) is deferred to Epic 2. For now, seed from `#0D0F14` and override `surface` to match the card background.

**Tab order is fixed by UX-DR14 — MUST NOT be changed:**

| Index | Label | Icon |
|-------|-------|------|
| 0 | Match | `Icons.sports_esports` |
| 1 | Historique | `Icons.history` |
| 2 | Joueurs | `Icons.people` |
| 3 | Room | `Icons.meeting_room` |

```dart
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WH40K Match Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D0F14),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF161920),
        ),
      ),
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;

  static const List<String> _tabLabels = [
    'Match',
    'Historique',
    'Joueurs',
    'Room',
  ];

  static const List<IconData> _tabIcons = [
    Icons.sports_esports,
    Icons.history,
    Icons.people,
    Icons.meeting_room,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('${_tabLabels[_currentIndex]} — coming soon'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: List.generate(
          _tabLabels.length,
          (i) => BottomNavigationBarItem(
            icon: Icon(_tabIcons[i]),
            label: _tabLabels[i],
          ),
        ),
      ),
    );
  }
}
```

### `widget_test.dart` — Replacement Content

The existing test uses `MyApp` (counter demo) which will no longer exist. Replace the full file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';

void main() {
  testWidgets('App renders bottom navigation with 4 tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Match'), findsOneWidget);
    expect(find.text('Historique'), findsOneWidget);
    expect(find.text('Joueurs'), findsOneWidget);
    expect(find.text('Room'), findsOneWidget);
  });
}
```

**Why this test approach works:** `App` extends `StatelessWidget` and builds a pure `MaterialApp` with no Firebase dependency — the widget tree can be pumped in a unit test without mocking Firebase. The Firebase init is isolated in `main()` and is not triggered by `pumpWidget(const App())`.

### Directory Structure — Complete Target State After This Story

```
mobile/
├── lib/
│   ├── main.dart                          ← UPDATED: App() replaces MyApp/MyHomePage
│   ├── firebase_options.dart              ← (original FlutterFire root file — leave as-is, unused)
│   ├── app/
│   │   └── app.dart                       ← NEW: MaterialApp + dark theme + bottom nav placeholder
│   ├── core/
│   │   └── firebase/
│   │       ├── firebase_options.dart      ← unchanged (FlutterFire generated)
│   │       └── firestore_paths.dart       ← NEW: all Firestore path helpers centralized here
│   └── features/
│       ├── room/
│       │   ├── data/.gitkeep              ← NEW: placeholder for room_repository.dart (Story 2.1)
│       │   ├── domain/.gitkeep            ← NEW: placeholder for models.dart (Story 2.1)
│       │   └── presentation/.gitkeep     ← NEW: placeholder for lobby_screen.dart (Story 2.2)
│       └── game/
│           ├── data/.gitkeep              ← NEW: placeholder for event_repository.dart (Story 3.1)
│           ├── domain/.gitkeep            ← NEW: placeholder for game_rules.dart, game_state.dart (Story 3.1)
│           └── presentation/
│               ├── .gitkeep              ← NEW: placeholder for match/history/players screens
│               └── widgets/
│                   └── .gitkeep          ← NEW: placeholder for ScoreHeroBar, ResourceCounter, etc.
├── test/
│   ├── widget_test.dart                   ← UPDATED: tests App bottom nav (replaces counter test)
│   └── features/
│       ├── game/.gitkeep                  ← NEW: placeholder for game_rules_test.dart (Story 3.1)
│       └── room/.gitkeep                  ← NEW: placeholder for room model tests
└── integration_test/
    └── README.md                          ← NEW: placeholder for multiplayer sync tests (Story 5.3)
```

### Architecture Guardrails

- **Feature isolation absolute rule:** `features/room` and `features/game` MUST NEVER import from each other. Cross-feature navigation will be wired in `app.dart` in future stories.
- **`firestore_paths.dart` monopoly:** Any hardcoded `'rooms'`, `'players'`, or `'events'` string in a Dart file OTHER THAN `firestore_paths.dart` is a critical architectural violation.
- **`debugPrint()` only — `print()` forbidden:** `avoid_print: true` is already active in `analysis_options.yaml`. New files must not use `print()`.
- **`StreamBuilder` only for state:** Do not add Riverpod, Provider, Bloc, or any state management package. `StreamBuilder` on Firestore streams is the only approved state mechanism for MVP.
- **No `main.dart` Firebase logic changes:** The init block was verified in Stories 1.1–1.3. Touching it risks silent regressions.

### NFRs Applicable to This Story

| NFR | Relevance |
|-----|-----------|
| NFR3 — App startup < 10 seconds | `App` widget must not block the render tree; async Firebase init is already isolated in `main()` |
| NFR14 — Architecture supports growth | Feature-first scaffold is the foundational structure all future stories build on |
| NFR17 — Clear, legible controls | Bottom nav must render correctly in dark theme — `BottomNavigationBarType.fixed` ensures all 4 labels are visible simultaneously |

### FRs Covered by This Story

No FRs are directly addressed — this is pure infrastructure scaffolding. It unblocks:
- FR40/FR41 (Story 1.5) — APK distribution requires a compilable, runnable app shell
- All Epic 2–6 FRs — feature directories are a prerequisite for every domain model and screen

### Previous Story Learnings (from Story 1.3)

- Firebase CLI is the global npm package `firebase-tools` v15.11.0 — no Flutter involvement for CLI tasks
- FlutterFire CLI invoked via `dart pub global run flutterfire_cli:flutterfire` (not directly on PATH)
- `mobile/firebase.json` was reformatted from minified to pretty-printed JSON in Story 1.3 — no further changes needed
- `mobile/lib/firebase_options.dart` (root of lib) and `mobile/lib/core/firebase/firebase_options.dart` both exist — the active one is at `core/firebase/firebase_options.dart`. The root-level one is the original FlutterFire CLI output; leave it untouched
- JDK 20 is configured in `android/gradle.properties` — do not alter `org.gradle.java.home`

### Scope — What NOT to Do

| Deferred | Story |
|----------|-------|
| `RoomModel`, `PlayerModel` domain models | 2.1 |
| `room_repository.dart` — Firestore room CRUD | 2.1 |
| `event_repository.dart` — Firestore event append/stream | 3.1 |
| `game_rules.dart`, `game_state.dart` — pure domain logic | 3.1 |
| `lobby_screen.dart` — room creation/join UI | 2.2 |
| Full Material Design 3 color token palette (all 8 tokens) | Epic 2 |
| Full typography system (Roboto Mono, Roboto Condensed families) | Epic 2 |
| `SyncStatusIndicator`, `PlayerPresenceBadge`, game widgets | Epics 3–4 |
| `match_screen.dart`, `history_screen.dart`, `players_screen.dart`, `room_management_screen.dart` | Epics 2–4 |
| APK release build + `adb install` verification | 1.5 |

**Do NOT implement any business logic, data access, or feature-specific UI in this story.**

### References

- Complete project directory structure: [_bmad-output/planning-artifacts/architecture.md — Complete Project Directory Structure](_bmad-output/planning-artifacts/architecture.md)
- Feature isolation & data boundaries: [_bmad-output/planning-artifacts/architecture.md — Architectural Boundaries](_bmad-output/planning-artifacts/architecture.md)
- `firestore_paths.dart` constraint: [_bmad-output/planning-artifacts/architecture.md — Data Boundaries](_bmad-output/planning-artifacts/architecture.md)
- Dark theme seed token `#0D0F14`: [_bmad-output/planning-artifacts/ux-design-specification.md — UX-DR11](_bmad-output/planning-artifacts/ux-design-specification.md)
- Bottom nav 4 tabs (order): [_bmad-output/planning-artifacts/ux-design-specification.md — UX-DR14](_bmad-output/planning-artifacts/ux-design-specification.md)
- `avoid_print` rule: [_bmad-output/planning-artifacts/epics.md — Additional Requirements](_bmad-output/planning-artifacts/epics.md)
- Story definition: [_bmad-output/planning-artifacts/epics.md — Story 1.4](_bmad-output/planning-artifacts/epics.md)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (GitHub Copilot)

### Debug Log References

- Flutter 3.29 broke `const Color(0xFFRRGGBB)` constructor — `Color` is no longer re-exported by `flutter/material.dart` via `flutter/painting.dart`. Worked around by using `Colors.red`/`Colors.black` temporarily (full design token `#0D0F14` deferred to Epic 2 full palette work).

### Completion Notes List

- All 7 tasks completed. `flutter analyze` reports 0 issues. `flutter test` passes 1/1.
- ~~Dark theme seed uses `Colors.red` / `Colors.black` as a temporary workaround for Flutter 3.29 `Color` constructor issue.~~ **[2026-03-27 — RÉSOLU]** `const Color(0xFF0D0F14)` et `const Color(0xFF161920)` appliqués correctement dans `app.dart` après correction de l'environnement. Dette technique soldée.
- `firestore_paths.dart` is the sole file with Firestore path strings — verified via grep.

### File List

- `mobile/lib/app/app.dart` — NEW
- `mobile/lib/core/firebase/firestore_paths.dart` — NEW
- `mobile/lib/main.dart` — UPDATED
- `mobile/test/widget_test.dart` — UPDATED
- `mobile/lib/features/room/data/.gitkeep` — NEW
- `mobile/lib/features/room/domain/.gitkeep` — NEW
- `mobile/lib/features/room/presentation/.gitkeep` — NEW
- `mobile/lib/features/game/data/.gitkeep` — NEW
- `mobile/lib/features/game/domain/.gitkeep` — NEW
- `mobile/lib/features/game/presentation/.gitkeep` — NEW
- `mobile/lib/features/game/presentation/widgets/.gitkeep` — NEW
- `mobile/test/features/game/.gitkeep` — NEW
- `mobile/test/features/room/.gitkeep` — NEW
- `mobile/integration_test/README.md` — NEW
