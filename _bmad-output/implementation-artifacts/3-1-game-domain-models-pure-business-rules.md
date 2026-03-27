# Story 3.1: Game Domain Models & Pure Business Rules

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want `GameState`, `game_rules.dart` pure functions, and `event_repository.dart` scaffolded,
So that all match logic is testable in isolation before any UI is built.

## Acceptance Criteria

1. **Given** `mobile/lib/features/game/domain/game_rules.dart`  
   **When** it is created  
   **Then** it contains pure functions:
   - `canMutate(actorId, roomCreatedBy, targetPlayerId)` → `bool`
   - `vpTotal(Map<String, Map<String, int>> vpByRound)` → `int`
   - `autoIncrementCp(PlayerModel player)` → `PlayerModel` (adds +1 CP)  
   **And** zero Firestore imports exist in this file  
   **And** unit tests in `mobile/test/features/game/game_rules_test.dart` cover: ownership enforcement, host override, vpTotal derivation from vpByRound, +1 CP on round advance

2. **Given** `mobile/lib/features/game/domain/game_state.dart`  
   **When** it is created  
   **Then** it exposes a `GameState` class derived from a `RoomModel` snapshot + list of events  
   **And** `GameState` exposes: `currentRound`, `players` (with derived VP totals), `activeRound`

3. **Given** `mobile/lib/features/game/data/event_repository.dart`  
   **When** it is created  
   **Then** it exposes: `appendEvent(roomId, eventData)` and `streamEvents(roomId)`  
   **And** `appendEvent` writes to `rooms/{roomId}/events/` via `firestore_paths.dart`  
   **And** Firestore errors are caught at repository level

## Tasks / Subtasks

- [ ] Task 1 — Create `EventModel` in `game_state.dart` (AC: #2, #3)
  - [ ] Define `EventModel` with fields: `id` (String), `type` (String), `actorId` (String), `targetPlayerId` (String?), `before` (Map<String, dynamic>?), `after` (Map<String, dynamic>?), `timestamp` (Timestamp), `undone` (bool)
  - [ ] Implement `EventModel.fromMap(String id, Map<String, dynamic> data)` factory
  - [ ] Implement `EventModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc)` factory
  - [ ] Implement `EventModel.toMap()` method

- [ ] Task 2 — Create `GameState` class in `game_state.dart` (AC: #2)
  - [ ] Define `GameState` class with fields: `room` (RoomModel), `players` (List<PlayerModel> with derived VP totals), `events` (List<EventModel>)
  - [ ] Add computed getter `currentRound` → `room.currentRound`
  - [ ] Add computed getter `activeRound` → `room.currentRound` (same as currentRound — single source of truth)
  - [ ] Add factory `GameState.fromStreams(RoomModel room, List<PlayerModel> players, List<EventModel> events)` — applies `game_rules.vpTotal()` per player

- [ ] Task 3 — Create `game_rules.dart` (AC: #1)
  - [ ] Create `mobile/lib/features/game/domain/game_rules.dart`
  - [ ] **Zero Firestore/Firebase imports** — this is a pure Dart file
  - [ ] Implement `canMutate(String actorId, String roomCreatedBy, String targetPlayerId)` → `bool`
    - Returns `true` if `actorId == targetPlayerId` (self-mutation) OR `actorId == roomCreatedBy` (owner override)
    - Returns `false` otherwise
  - [ ] Implement `vpTotal(Map<String, Map<String, int>> vpByRound)` → `int`
    - Sums all `prim` and `sec` values across all rounds
    - Returns 0 for empty map
  - [ ] Implement `autoIncrementCp(PlayerModel player)` → `PlayerModel`
    - Returns `player.copyWith(cp: player.cp + 1)`
    - Pure function — no side effects, no Firestore

- [ ] Task 4 — Create `event_repository.dart` (AC: #3)
  - [ ] Create `mobile/lib/features/game/data/event_repository.dart`
  - [ ] Import only `cloud_firestore` and `../../../core/firebase/firestore_paths.dart` and `../domain/game_state.dart`
  - [ ] Implement `Future<void> appendEvent(String roomId, Map<String, dynamic> eventData)` — writes to `FirestorePaths.events(roomId).add(eventData)`, catches `FirebaseException` → throws `GameException`
  - [ ] Implement `Stream<List<EventModel>> streamEvents(String roomId)` — listens to `FirestorePaths.events(roomId).orderBy('timestamp').snapshots()`, maps to `List<EventModel>`
  - [ ] Declare `GameException` class in the same file (mirrors `RoomException` pattern)

- [ ] Task 5 — Write unit tests for `game_rules.dart` (AC: #1)
  - [ ] Create `mobile/test/features/game/game_rules_test.dart`
  - [ ] Test `canMutate`: returns true when `actorId == targetPlayerId`
  - [ ] Test `canMutate`: returns true when `actorId == roomCreatedBy` (owner override, different targetPlayerId)
  - [ ] Test `canMutate`: returns false when `actorId != targetPlayerId` AND `actorId != roomCreatedBy`
  - [ ] Test `vpTotal`: returns 0 for empty map
  - [ ] Test `vpTotal`: correctly sums `prim + sec` values across multiple rounds
  - [ ] Test `vpTotal`: handles rounds with only `prim` key (no `sec`)
  - [ ] Test `autoIncrementCp`: returns new `PlayerModel` with `cp` incremented by 1
  - [ ] Test `autoIncrementCp`: original `PlayerModel` is unchanged (pure function)

- [ ] Task 6 — Verify `flutter analyze` reports zero errors (AC: all)
  - [ ] Run `flutter analyze` from `mobile/` — must report `No issues found!`

## Dev Notes

### Architecture Compliance — CRITICAL RULES

This story establishes the Game feature domain layer. The following rules are **absolute** and must not be violated:

| Rule | Detail | Source |
|------|--------|--------|
| `game_rules.dart` = pure Dart | Zero Firestore/Firebase imports allowed | [Source: architecture.md#Implementation Patterns] |
| Feature isolation | `features/game` must NOT import from `features/room` directly | [Source: architecture.md#Structure Patterns] |
| Cross-feature models | `PlayerModel` and `RoomModel` live in `features/room/domain/models.dart` — import them from there | [Source: architecture.md] |
| `firestore_paths.dart` only | `event_repository.dart` must use `FirestorePaths.events(roomId)` — never construct path strings directly | [Source: architecture.md#Structure Patterns] |
| Undo = soft delete | `undone: true` flag — **never** `delete()` an event document | [Source: architecture.md#Undo pattern] |
| No `print()` | Use `debugPrint()` if any debug logging needed; `print()` is forbidden | [Source: analysis_options.yaml `avoid_print: true`] |
| Test mirror structure | Tests go in `mobile/test/features/game/` — mirrors `mobile/lib/features/game/` | [Source: architecture.md] |

### Project Structure — Files Overview

```
mobile/
├── lib/
│   └── features/
│       └── game/
│           ├── data/
│           │   └── event_repository.dart        ← CREATE (Task 4)
│           └── domain/
│               ├── game_rules.dart              ← CREATE (Task 3) — pure functions only
│               └── game_state.dart              ← CREATE (Tasks 1 & 2) — EventModel + GameState
└── test/
    └── features/
        └── game/
            └── game_rules_test.dart             ← CREATE (Task 5)
```

**Scaffold stubs already exist** (from Story 1.4):
- `mobile/lib/features/game/data/.gitkeep` → replace with `event_repository.dart`
- `mobile/lib/features/game/domain/.gitkeep` → create `game_rules.dart` + `game_state.dart`
- `mobile/lib/features/game/presentation/.gitkeep` → **do NOT touch** (used in Epic 3 stories 3.2–3.5)
- `mobile/test/features/game/` directory **does not yet exist** — create `game_rules_test.dart` and the parent folder

### Confirmed Existing Files Used by This Story (do NOT modify)

| File | Status | What this story uses |
|------|--------|---------------------|
| `mobile/lib/features/room/domain/models.dart` | ✅ Complete | `PlayerModel` (with `copyWith`, `vpByRound`, `cp`, `id`), `RoomModel` (with `currentRound`, `createdBy`) |
| `mobile/lib/core/firebase/firestore_paths.dart` | ✅ Complete | `FirestorePaths.events(roomId)` → events subcollection ref |
| `mobile/pubspec.yaml` | ✅ Complete | `cloud_firestore: ^5.6.7` already present — no new packages needed |

### Key Model Details (from Story 2.6 & models.dart)

**`PlayerModel`** (already in `features/room/domain/models.dart`):
```dart
class PlayerModel {
  final String id;
  final String name;
  final RoleEnum role;
  final int cp;
  final Map<String, Map<String, int>> vpByRound; // {'1': {'prim': 3, 'sec': 7}, ...}
  final bool connected;
  final String color;
  // has copyWith(...)
}
```

**`RoomModel`** (already in `features/room/domain/models.dart`):
```dart
class RoomModel {
  final String id;
  final String code;
  final RoomStatus status;
  final int currentRound;
  final String createdBy;
  final Timestamp createdAt;
}
```

### EventModel Schema (Firestore document `rooms/{roomId}/events/{eventId}`)

```
type          : String  — 'score_update' | 'cp_adjust' | 'turn_advance' | 'player_join' | 'undo'
actorId       : String  — uid of the player who performed the action
targetPlayerId: String? — uid of the affected player (nullable for turn_advance)
before        : Map<String, dynamic>? — state before the mutation
after         : Map<String, dynamic>? — state after the mutation
timestamp     : Timestamp — Firestore server timestamp
undone        : bool — false by default, set to true on undo (NEVER delete)
```

For `score_update`, `before`/`after` contain `{round: String, type: 'prim'|'sec', value: int}`.  
For `cp_adjust`, `before`/`after` contain `{cp: int}`.  
For `turn_advance`, no `targetPlayerId` — affects all players.

### `canMutate` Logic

```
canMutate(actorId, roomCreatedBy, targetPlayerId):
  → true  if actorId == targetPlayerId           (player modifies own resource)
  → true  if actorId == roomCreatedBy            (room owner override — FR11, FR19)
  → false otherwise
```

This mirrors the Firestore Security Rules: `request.auth.uid == resource.data.actorId || request.auth.uid == get(/databases/$(database)/documents/rooms/$(roomId)).data.createdBy`.

### `vpTotal` Logic

```dart
int vpTotal(Map<String, Map<String, int>> vpByRound) {
  // Sum all values in all nested maps (prim + sec per round)
  return vpByRound.values.fold(0, (acc, roundMap) =>
    acc + roundMap.values.fold(0, (a, v) => a + v));
}
```

Edge cases: empty outer map → 0. Round with only `prim` (no `sec`) → handle gracefully.

### mutation flow (for future stories)

```
UI widget
   ↓  game_rules.canMutate() guard
   ↓  event_repository.appendEvent()
   ↓  Firestore write → triggers realtime stream update
   ↓  StreamBuilder rebuilds UI
```

This story only scaffolds layers 2 and 3 (game_rules + event_repository). Layer 1 (UI) starts in Story 3.2.

### Previous Story Intelligence (Epic 2 learnings)

From Stories 2.1–2.6 patterns:
- **Repository exception class**: each repository defines its own `XxxException implements Exception` with a `String message`. Follow the exact same pattern: `GameException` in `event_repository.dart`.
- **Firestore error wrapping**: wrap all Firestore calls in `try { ... } on GameException { rethrow; } catch (e) { throw GameException('...'); }` — same pattern as `RoomException` in `room_repository.dart`.
- **Stream mapping pattern**: `streamPlayers` in `room_repository.dart` maps `QuerySnapshot` → `List<PlayerModel>` via `.map((doc) => PlayerModel.fromFirestore(doc)).toList()`. Use the same pattern in `streamEvents`.
- **No `print()`**: all prior stories used `debugPrint()`. Enforce.
- **Tests use `flutter_test` only** — no Mockito or Fake Firebase in game_rules_test (pure functions need no mocks). `event_repository_test.dart` is NOT required in this story (it is called out in Story 4.2's AC).

### Files NOT to touch (zero changes permitted)

- `mobile/lib/features/room/domain/models.dart` — `PlayerModel` and `RoomModel` are complete
- `mobile/lib/core/firebase/firestore_paths.dart` — `events(roomId)` is already defined
- `mobile/lib/app/app.dart` — UI wiring happens in Stories 3.2–3.5
- `mobile/lib/features/room/data/room_repository.dart` — no changes needed

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.1]
- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture]
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#Process Patterns]
- [Source: mobile/lib/features/room/domain/models.dart — PlayerModel, RoomModel]
- [Source: mobile/lib/core/firebase/firestore_paths.dart — FirestorePaths.events()]
- [Source: mobile/lib/features/room/data/room_repository.dart — RoomException pattern]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6 (GitHub Copilot)

### Debug Log References

### Completion Notes List

### File List
