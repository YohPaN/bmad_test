# Story 2.1: Room Domain Models & Repository

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want the `RoomModel`, `PlayerModel`, and `room_repository.dart` implemented,
so that all room-related data operations have a typed, testable foundation before any UI is built.

## Acceptance Criteria

1. **Given** `mobile/lib/features/room/domain/models.dart`  
   **When** it is created  
   **Then** `RoomModel` contains: `id`, `status` (enum: waiting/active/closed), `currentRound`, `createdBy`, `createdAt`  
   **And** `PlayerModel` contains: `id`, `name`, `role` (RoleEnum: owner/player), `cp`, `vpByRound` (`Map<String, Map<String, int>>`), `connected`, `color` (hex String)  
   **And** `RoleEnum` has values `owner` and `player`  
   **And** both models have `fromFirestore()` and `toMap()` methods

2. **Given** `mobile/lib/features/room/data/room_repository.dart`  
   **When** it is created  
   **Then** it exposes: `createRoom(String ownerName)`, `joinRoom(String code, String playerName)`, `streamRoom(String roomId)`, `streamPlayers(String roomId)`  
   **And** all Firestore paths are imported from `firestore_paths.dart` — no hardcoded strings  
   **And** Firestore errors are caught at repository level and never propagated raw to the UI

3. **Given** unit tests in `mobile/test/features/room/models_test.dart`  
   **When** `flutter test` is run  
   **Then** all tests pass — covering `fromFirestore` / `toMap` roundtrip for both models, `RoomStatus` enum parsing, `RoleEnum` parsing, and `vpByRound` round-trip fidelity

4. **Given** `flutter analyze` is run on the full project  
   **Then** zero lint errors are reported

## Tasks / Subtasks

- [ ] Task 1 — Create `RoomStatus` enum and `RoomModel` in `mobile/lib/features/room/domain/models.dart` (AC: #1)
  - [ ] Create the file with the `RoomStatus` enum: values `waiting`, `active`, `closed`; add `fromString` factory / static helper for Firestore deserialization
  - [ ] Create `RoomModel` as an immutable class (all fields `final`): `id` (String), `code` (String — 6-char readable room code, stored in Firestore as `code` field), `status` (RoomStatus), `currentRound` (int), `createdBy` (String — owner uid), `createdAt` (Timestamp)
  - [ ] Implement `RoomModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc)` factory: read `doc.id` for `id`, parse `code`, `currentRound`, `createdBy`, `createdAt` (native Firestore `Timestamp`), `status` via `RoomStatus.fromString`
  - [ ] Implement `RoomModel.toMap()` → `Map<String, dynamic>`: serialize all fields; `status` as string value (`'waiting'`/`'active'`/`'closed'`); `createdAt` as Firestore `Timestamp` — never String ISO
  - [ ] Add `copyWith` method to `RoomModel` for immutable updates (required by `streamRoom` consumer pattern)

- [ ] Task 2 — Create `RoleEnum` and `PlayerModel` in the same `models.dart` file (AC: #1)
  - [ ] Create `RoleEnum` enum: values `owner`, `player`; add `fromString` helper
  - [ ] Create `PlayerModel` as an immutable class: `id` (String), `name` (String), `role` (RoleEnum), `cp` (int), `vpByRound` (`Map<String, Map<String, int>>` — outer key = round number as String e.g. `'1'`, inner keys: `'prim'` and `'sec'`), `connected` (bool — native Dart bool, never 0/1 or null), `color` (String hex, e.g. `'#4FC3F7'`)
  - [ ] Implement `PlayerModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc)` factory: read `doc.id` for `id`, cast `vpByRound` map carefully (Firestore returns `Map<String, dynamic>` at every level — requires explicit casting to `Map<String, Map<String, int>>`)
  - [ ] Implement `PlayerModel.toMap()` → `Map<String, dynamic>`: serialize all fields; `role` as string value; `connected` as Dart native bool; ensure `vpByRound` nested map is properly serialized
  - [ ] Add `copyWith` method to `PlayerModel`

- [ ] Task 3 — Create `mobile/lib/features/room/data/room_repository.dart` (AC: #2)
  - [ ] Create `RoomRepository` class with a private `_firestore = FirebaseFirestore.instance` field and `_auth = FirebaseAuth.instance` field
  - [ ] Implement `Future<String> createRoom(String ownerName)`:
    - Generate a 6-character human-readable room code using private helper `_generateRoomCode()` — use `dart:math` `Random`, characters from set `'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'` (no O/0/I/1 to avoid confusion)
    - Create room document via `FirestorePaths.rooms().add({...})` with fields: `code`, `status: 'waiting'`, `currentRound: 1`, `createdBy: uid`, `createdAt: Timestamp.now()`
    - Create owner player document via `FirestorePaths.player(roomId, uid).set({...})` with fields: `name: ownerName`, `role: 'owner'`, `cp: 0`, `vpByRound: {}`, `connected: true`, `color: '#4FC3F7'`
    - Return the new room document ID
    - Wrap in `try/catch`, convert exceptions to a `RoomException` (define inline in the same file) — never rethrow raw `FirebaseException`
  - [ ] Implement `Future<String> joinRoom(String code, String playerName)`:
    - Query `FirestorePaths.rooms().where('code', isEqualTo: code).limit(1).get()`
    - If no results → throw `RoomException('Room not found')`
    - If room `status` is not `'waiting'` → throw `RoomException('Room is not open for joining')`
    - Create player document via `FirestorePaths.player(roomId, uid).set({...})` with `role: 'player'`, `color: '#EF5350'` (2nd player color, later stories handle N>2), `cp: 0`, `vpByRound: {}`, `connected: true`
    - Return the room document ID
    - Wrap in `try/catch` → `RoomException`
  - [ ] Implement `Stream<RoomModel?> streamRoom(String roomId)`:
    - Return `FirestorePaths.room(roomId).snapshots().map((snap) => snap.exists ? RoomModel.fromFirestore(snap) : null)`
    - Do NOT add error handling on the stream itself — errors from Firestore streams surface as stream errors and are handled by the consumer `StreamBuilder`
  - [ ] Implement `Stream<List<PlayerModel>> streamPlayers(String roomId)`:
    - Return `FirestorePaths.players(roomId).snapshots().map((snap) => snap.docs.map((d) => PlayerModel.fromFirestore(d)).toList())`
  - [ ] Define `RoomException` class at the bottom of the file: `class RoomException implements Exception { final String message; const RoomException(this.message); @override String toString() => 'RoomException: $message'; }`
  - [ ] Verify: zero hardcoded Firestore path strings in this file — all paths via `FirestorePaths.*`

- [ ] Task 4 — Write unit tests in `mobile/test/features/room/models_test.dart` (AC: #3)
  - [ ] Test `RoomModel.fromFirestore` with a mock `DocumentSnapshot`:
    - All fields correctly parsed including nested `code`, `status: 'waiting'` → `RoomStatus.waiting`
    - `createdAt` is Firestore `Timestamp`, not null
  - [ ] Test `RoomModel.toMap()` roundtrip: `toMap()` output has expected keys; `status` is serialized as String; `createdAt` is `Timestamp`
  - [ ] Test `RoomStatus.fromString` edge cases: `'waiting'`/`'active'`/`'closed'` → correct enum values; unknown string → fallback or throws (define and test chosen behavior)
  - [ ] Test `PlayerModel.fromFirestore` with vpByRound data: `{'1': {'prim': 3, 'sec': 7}, '2': {'prim': 5, 'sec': 2}}` → parsed as `Map<String, Map<String, int>>` correctly
  - [ ] Test `PlayerModel.toMap()` roundtrip: `connected` is bool; `role` is String; `vpByRound` nested map preserved
  - [ ] Test `RoleEnum.fromString`: `'owner'` → `RoleEnum.owner`, `'player'` → `RoleEnum.player`
  - [ ] Run `flutter test test/features/room/models_test.dart` — all tests green

- [ ] Task 5 — Verify `flutter analyze` reports zero errors (AC: #4)
  - [ ] Run `flutter analyze` from `mobile/` directory
  - [ ] Confirm 0 issues — in particular: no `avoid_print` violations, no missing `const`, no unused imports

## Dev Notes

### Starting Point — State of Repository at Story 2.1 Start

The following files/assets are CONFIRMED present and must NOT be modified by this story:

| File | Status | Notes |
|------|--------|-------|
| `mobile/lib/core/firebase/firestore_paths.dart` | ✅ Complete | Exposes `rooms()`, `room(id)`, `players(id)`, `player(id, uid)`, `events(id)`, `event(id, eid)` |
| `mobile/lib/main.dart` | ✅ Complete | Firebase init + `PersistenceSettings(cacheSizeBytes: CACHE_SIZE_UNLIMITED)` + anon auth |
| `mobile/lib/app/app.dart` | ✅ Complete | MaterialApp dark theme + 4 bottom nav tabs (Match/Historique/Joueurs/Room) |
| `mobile/lib/features/room/domain/` | ✅ Directory exists | Empty (from Story 1.4) |
| `mobile/lib/features/room/data/` | ✅ Directory exists | Empty (from Story 1.4) |
| `mobile/test/features/room/` | ✅ Directory exists | Empty (from Story 1.4) |
| `mobile/pubspec.yaml` | ✅ Complete | `cloud_firestore: ^5.6.7`, `firebase_auth: ^5.5.2`, `firebase_core: ^3.13.1` |
| `mobile/analysis_options.yaml` | ✅ Active | `avoid_print: true` enforced |

**Files to CREATE in this story:**
- `mobile/lib/features/room/domain/models.dart`
- `mobile/lib/features/room/data/room_repository.dart`
- `mobile/test/features/room/models_test.dart`

**No UI changes. No screen creation. No widget creation. Pure data/domain layer.**

### Architecture Constraints

- **Feature boundary**: `features/room` must NOT import from `features/game`. Models defined here are shared via domain layer only.
- **Firestore paths**: every collection/document reference MUST go through `FirestorePaths.*` — never construct path strings manually.
- **Logging**: `debugPrint()` is permitted. `print()` is FORBIDDEN (`avoid_print` lint).
- **Timestamps**: use `Timestamp` from `cloud_firestore` — never `DateTime.now().toIso8601String()` for Firestore fields.
- **Booleans**: `true`/`false` Dart native — never `1`/`0` or `null` as boolean stand-in.
- **Undo flag**: every event document MUST have a `bool undone` field (not modeled in this story, but the pattern is established here for consistency: all Firestore booleans are native booleans).
- **Error surface**: `RoomException` is the only error type surfaced from `room_repository.dart`. Raw `FirebaseException` must never escape the repository boundary.

### Firestore Schema (this story touches)

**`rooms/{roomId}` document fields:**
```
code:         String    — 6-char uppercase alphanumeric (e.g., 'AB3K7M'), never Firestore doc ID
status:       String    — 'waiting' | 'active' | 'closed'
currentRound: int       — starts at 1 (set on createRoom; updated by future Epic 3 story)
createdBy:    String    — owner uid (FirebaseAuth.instance.currentUser!.uid)
createdAt:    Timestamp — Firestore server timestamp equivalent (Timestamp.now() is acceptable for MVP)
```

**`rooms/{roomId}/players/{uid}` document fields:**
```
name:       String                           — display name entered by user
role:       String                           — 'owner' | 'player'
cp:         int                              — Command Points; starts at 0
vpByRound:  Map<String, Map<String, int>>    — e.g. {'1': {'prim': 3, 'sec': 7}}; empty map {} on creation
connected:  bool                             — true when player is in session
color:      String                           — hex color, '#4FC3F7' for owner/P1, '#EF5350' for P2
```

**Note on `vpByRound` typing:** Firestore returns `Map<String, dynamic>` for nested maps. Cast explicitly:
```dart
final raw = data['vpByRound'] as Map<String, dynamic>? ?? {};
final vpByRound = raw.map(
  (round, value) => MapEntry(
    round,
    (value as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    ),
  ),
);
```

### Room Code Generation

Room codes are used for human-to-human sharing (verbal or written). Requirements:
- 6 characters, uppercase alphanumeric
- Exclude visually ambiguous characters: `O`, `0`, `I`, `1`
- Character set: `'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'` (31 chars, ~1 billion combinations at 6 chars)
- Generated client-side in `createRoom()` — acceptable for MVP small-group usage

```dart
import 'dart:math';

String _generateRoomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random();
  return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
}
```

**No collision detection needed at MVP scale** (small groups, short session lifetime).

### Testing Approach for Repository

`room_repository.dart` makes live Firestore calls. For unit tests in this story, **test only models (`models_test.dart`)** — not the repository. Repository integration tests are explicitly deferred to a later story.

To mock `DocumentSnapshot` in `models_test.dart`, use a simple map-based fake:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
// Use DocumentSnapshot's data() method contract:
// Create a fake snapshot using FakeDocumentSnapshot or pass data Map directly to fromFirestore.
// Recommended: refactor fromFirestore to accept Map<String, dynamic> + String id as named constructor
// so tests don't need to mock DocumentSnapshot directly.
```

**Recommended pattern** — add a `fromMap` constructor alongside `fromFirestore`:
```dart
factory RoomModel.fromMap(String id, Map<String, dynamic> data) { ... }
factory RoomModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
    RoomModel.fromMap(doc.id, doc.data()!);
```
This makes unit tests trivially easy without any mock framework.

### JDK Build Environment (from Epic 1 learnings)

If build issues arise with Gradle on this machine, the JDK configuration is in `mobile/android/gradle.properties`:
```
org.gradle.java.home=<path-to-JDK-20>
```
This is pre-configured from Epic 1 and should not need changes for this story (no Gradle changes involved).

### What NOT to Do in This Story

| ❌ Don't | ✅ Reason |
|----------|-----------|
| Create any UI screens or widgets | Scope: data/domain layer only. Story 2.2 handles lobby UI. |
| Write to Firestore in tests | Models tests use in-memory map data only. |
| Add `code` field generation to lobby UI | Room code display is Story 2.2 scope. |
| Import `features/game` from `features/room` | Feature boundary violation per Architecture. |
| Hardcode `'rooms'`, `'players'`, `'events'` strings | Use `FirestorePaths.*` exclusively. |
| Use `print()` | `avoid_print` lint is active — use `debugPrint()`. |
| Fix the `app.dart` Color workaround | Epic 1 retro action item A2 — NOT this story's scope. |
| Add `fake_cloud_firestore` or other mock packages | Not needed if `fromMap` pattern is used for models. |
| Store derived VP total as a Firestore field | `vpTotal` is always computed from `vpByRound` by `game_rules.vpTotal()` — NEVER stored. |
| Use `DateTime` for `createdAt` | Always use Firestore `Timestamp`. |

### References

- Story AC source: [epics.md — Epic 2, Story 2.1](..//planning-artifacts/epics.md)
- Firestore schema: [architecture.md — Data Architecture](../planning-artifacts/architecture.md#data-architecture)
- Naming conventions: [architecture.md — Naming Patterns](../planning-artifacts/architecture.md#naming-patterns)
- Feature-first boundaries: [architecture.md — Architectural Boundaries](../planning-artifacts/architecture.md#architectural-boundaries)
- FirestorePaths implementation: [firestore_paths.dart](../../mobile/lib/core/firebase/firestore_paths.dart)
- Epic 1 learnings (Dev Notes pattern, JDK env): [epic-1-retro-2026-03-27.md](./epic-1-retro-2026-03-27.md)
- Color assignment for players: P1 = `#4FC3F7`, P2 = `#EF5350` — [architecture.md Firestore schema](../planning-artifacts/architecture.md#data-architecture)
