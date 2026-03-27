# Story 2.4: Start Match Session

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a room owner,
I want to start the match session from the lobby,
So that all connected players are moved to the active match screen simultaneously.

## Acceptance Criteria

1. **Given** the lobby screen with at least 2 connected players and the current user is the room owner  
   **When** the owner taps "Lancer le match"  
   **Then** the room document's `status` is updated to `active` and `currentRound` is set to `1`  
   **And** all connected clients detect the status change via Firestore stream and navigate to the match screen (`AppShell`)

2. **Given** any connected client with an active Firestore `streamRoom` listener  
   **When** `room.status` transitions to `active`  
   **Then** the client auto-navigates to `AppShell` via `Navigator.pushReplacement`  
   **And** no manual user action is required to trigger the navigation

3. **Given** a non-owner player in the lobby  
   **When** they view the lobby screen  
   **Then** the "Lancer le match" button is NOT visible (conditionally hidden for non-owners)

## Tasks / Subtasks

- [x] Task 1 — Add `startMatch()` and `currentUserId` to `RoomRepository` (AC: #1)
  - [x] Add a `currentUserId` getter to `RoomRepository` that returns `_auth.currentUser?.uid`
  - [x] Add `startMatch(String roomId)` async method:
    - Call `FirestorePaths.room(roomId).update({'status': 'active', 'currentRound': 1})`
    - Wrap in try/catch: rethrow `RoomException`, convert other errors to `RoomException('Failed to start match: $e')`
    - No local ownership check needed — Firestore Security Rules already restrict `status` updates to `createdBy` UID

- [x] Task 2 — Make `_AppShell` public in `app.dart` (AC: #2)
  - [x] Rename `_AppShell` → `AppShell` (remove leading underscore) in `mobile/lib/app/app.dart`
  - [x] `_AppShellState` kept private (only class visibility changes) — consistent with story spec
  - [x] No parameter changes needed for this story — `AppShell` stays parameterless for scope of 2.4

- [x] Task 3 — Wire "Lancer le match" button and owner detection in `_buildLobbyPhase()` (AC: #1, #3)
  - [x] Add `bool _isStartLoading = false` field to `_LobbyScreenState`
  - [x] Add `_startMatch()` async method with `!mounted` guards and SnackBar error handling
  - [x] `isOwner = room.createdBy == _repo.currentUserId` and `canStart = isOwner && connectedCount >= 2 && !_isStartLoading` computed in builder
  - [x] `if (isOwner)` conditional wrapping button — non-owners see no button
  - [x] `Opacity` + `CircularProgressIndicator` while loading, disabled when `!canStart`

- [x] Task 4 — Auto-navigate all clients when `room.status == active` (AC: #2)
  - [x] `addPostFrameCallback` pattern in outer `StreamBuilder<RoomModel?>` after null guard
  - [x] Returns `SizedBox.shrink()` while navigation defers
  - [x] `import '../../../app/app.dart'` added at top of `lobby_screen.dart`

- [x] Task 5 — Verify `flutter analyze` reports zero errors (AC: all)
  - [x] `flutter analyze` run from `mobile/` — **No issues found!** (ran in 1.7s)

## Dev Notes

### Starting Point — State of Repository at Story 2.4 Start

These files are CONFIRMED present and fully implemented (from Stories 2.1–2.3):

| File | Status | Notes |
|------|--------|-------|
| `mobile/lib/features/room/presentation/lobby_screen.dart` | ✅ Complete | Phases: home (create+join) + lobby (post-create/join). `_buildLobbyPhase()` has TODO(story-2.4) on `onPressed: null` of "Lancer le match". Button wrapped in `Opacity(opacity: connectedCount < 2 ? 0.38 : 1.0)`. `_AppShell` reference in `app.dart` is preserved for this story. |
| `mobile/lib/features/room/data/room_repository.dart` | ✅ Complete | `createRoom()`, `joinRoom()`, `streamRoom()`, `streamPlayers()` implemented. Missing: `startMatch()` and `currentUserId`. |
| `mobile/lib/features/room/domain/models.dart` | ✅ Complete | `RoomStatus` enum with `waiting/active/closed`, `RoomModel` (id, code, status, currentRound, createdBy, createdAt), `PlayerModel`, `RoleEnum`. No changes needed. |
| `mobile/lib/core/firebase/firestore_paths.dart` | ✅ Complete | `room(roomId)` path helper already available — used by `startMatch()`. |
| `mobile/lib/app/app.dart` | ✅ Complete | `App` widget uses `home: const LobbyScreen()`. `_AppShell` (private) with 4-tab skeleton is preserved and ready to be made public (Task 2). |
| `mobile/pubspec.yaml` | ✅ Complete | `cloud_firestore: ^5.6.7`, `firebase_auth: ^5.5.2`, `firebase_core: ^3.13.1` — **no new packages needed** |
| `mobile/analysis_options.yaml` | ✅ Active | `avoid_print: true` enforced |

**Files to MODIFY in this story:**
- `mobile/lib/features/room/data/room_repository.dart` — add `currentUserId` getter + `startMatch()` method
- `mobile/lib/features/room/presentation/lobby_screen.dart` — wire button, owner check, auto-navigate
- `mobile/lib/app/app.dart` — rename `_AppShell` → `AppShell`

**Files NOT to touch (zero changes):**
- `mobile/lib/features/room/domain/models.dart`
- `mobile/lib/features/room/presentation/widgets/player_presence_badge.dart`
- `mobile/lib/core/firebase/firestore_paths.dart`
- `mobile/pubspec.yaml`
- `mobile/lib/main.dart`

---

### Task 1 — Exact Code for `RoomRepository`

Add after the `streamPlayers()` method:

```dart
// ── Current user ─────────────────────────────────────────────────────────

/// Returns the current authenticated user's UID, or null if unauthenticated.
String? get currentUserId => _auth.currentUser?.uid;

// ── Match lifecycle ───────────────────────────────────────────────────────

/// Updates the room status to active, setting currentRound to 1.
/// Throws [RoomException] if the update fails.
Future<void> startMatch(String roomId) async {
  try {
    await FirestorePaths.room(roomId).update({
      'status': 'active',
      'currentRound': 1,
    });
  } on RoomException {
    rethrow;
  } catch (e) {
    throw RoomException('Failed to start match: $e');
  }
}
```

> **Why no ownership check in Dart?** Firestore Security Rules already enforce that only the room creator (`request.auth.uid == resource.data.createdBy`) can update `rooms/{roomId}.status`. The button is also conditionally hidden for non-owners in the UI. Adding a third redundant check in the repository would be non-idiomatic for MVP. Firestore is the authoritative gate.

---

### Task 2 — Exact Diff for `app.dart`

```dart
// BEFORE:
class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {

// AFTER:
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
```

> **Note:** `_AppShellState` can remain private (leading underscore) — only `AppShell` needs to be public for `lobby_screen.dart` to instantiate it.

---

### Task 3 — `_startMatch()` Method

Add to `_LobbyScreenState` (alongside `_createRoom()` and `_joinRoom()`):

```dart
Future<void> _startMatch() async {
  setState(() => _isStartLoading = true);
  try {
    await _repo.startMatch(_roomId!);
    // Navigation handled by StreamBuilder reaction (Task 4) — no setState needed here
  } on RoomException catch (e) {
    if (!mounted) return;
    setState(() => _isStartLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  } catch (e) {
    debugPrint('startMatch unexpected error: $e');
    if (!mounted) return;
    setState(() => _isStartLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible de démarrer le match.')),
    );
  }
}
```

Add field declaration alongside other state fields:
```dart
bool _isStartLoading = false;
```

---

### Task 3 — "Lancer le match" Button Replacement

**Current code block to REPLACE** (bottom of `_buildLobbyPhase()` inner Column, inside both StreamBuilders):

```dart
// Player count label
Text(
  '$connectedCount joueur(s) connecté(s)',
  ...
),
const SizedBox(height: 12),
// Launch button
Opacity(
  opacity: connectedCount < 2 ? 0.38 : 1.0,
  child: FilledButton(
    // TODO(story-2.4): wire navigation to match screen
    onPressed: null,
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF4FC3F7),
      foregroundColor: const Color(0xFF0D0F14),
      minimumSize: const Size.fromHeight(48),
    ),
    child: const Text('Lancer le match'),
  ),
),
```

**Replace with:**

```dart
// Player count label
Text(
  '$connectedCount joueur(s) connecté(s)',
  textAlign: TextAlign.center,
  style: const TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    color: Color(0xFFE8EAF0),
  ),
),
const SizedBox(height: 12),
// Launch button — owner only
if (isOwner)
  Opacity(
    opacity: canStart ? 1.0 : 0.38,
    child: SizedBox(
      height: 48,
      width: double.infinity,
      child: FilledButton(
        onPressed: canStart ? _startMatch : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF4FC3F7),
          foregroundColor: const Color(0xFF0D0F14),
          minimumSize: const Size.fromHeight(48),
        ),
        child: _isStartLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0D0F14),
                ),
              )
            : const Text('Lancer le match'),
      ),
    ),
  ),
```

---

### Task 4 — Auto-Navigation Trigger (status == active)

Insert **before** the existing `return SingleChildScrollView(...)` block in the inner `StreamBuilder<List<PlayerModel>>` — but this check belongs in the **outer** `StreamBuilder<RoomModel?>` builder, right after `room` is confirmed non-null:

Actually, the status check should be placed at the **outer** `StreamBuilder<RoomModel?>` level, immediately after the `if (room == null)` check:

```dart
// In StreamBuilder<RoomModel?> builder, after the null guard:
if (room == null) {
  return const Center(
    child: Text(
      'La room a été supprimée.',
      style: TextStyle(color: Color(0xFFE8EAF0)),
    ),
  );
}

// ── NEW: Auto-navigate when match starts ──────────────────────────────────
if (room.status == RoomStatus.active) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    }
  });
  return const SizedBox.shrink(); // brief blank frame while navigation fires
}
// ─────────────────────────────────────────────────────────────────────────
```

**Import to add at the top of `lobby_screen.dart`:**

```dart
import '../../../app/app.dart';
```

> **Why `addPostFrameCallback`?** Calling `Navigator.pushReplacement` directly inside a `build()` / `builder` callback causes a Flutter assertion error ("setState() or markNeedsBuild() called during build"). The post-frame callback defers the navigation until after the current frame completes, which is the correct pattern.

> **Why this placement (outer StreamBuilder)?** The outer `StreamBuilder<RoomModel?>` fires on every room document update. When `status` changes to `active`, this builder runs, detects it, and defers navigation. All clients listening to `streamRoom(_roomId!)` will receive this update and navigate simultaneously.

> **No `connectedCount` check needed for navigation:** The navigation triggers on `room.status == active` for ALL participants (owner and non-owners alike), so the `players` snapshot is not needed at this point.

---

### Owner Detection Pattern

In `_buildLobbyPhase()` → inside `StreamBuilder<List<PlayerModel>>` builder, after `final players = playersSnapshot.data ?? []`:

```dart
final players = playersSnapshot.data ?? [];
final connectedCount = players.where((p) => p.connected).length;
final isOwner = room.createdBy == _repo.currentUserId;
final canStart = isOwner && connectedCount >= 2 && !_isStartLoading;
```

> **Use `room.createdBy` from the outer snapshot vs `players` list.** `room.createdBy` is the canonical owner UID stored on the room document. This is more reliable than inferring ownership from `PlayerModel.role` (which could theoretically drift). `_repo.currentUserId` exposes `FirebaseAuth.instance.currentUser?.uid` from the repository layer — avoids importing `firebase_auth` directly in screen files.

---

### Architecture Constraints

- **No direct Firebase imports in screen files** — use `_repo.currentUserId` not `FirebaseAuth.instance.currentUser?.uid` directly
- **Feature boundary**: `lobby_screen.dart` is in `features/room/` — it may import from `app/` (`AppShell`) as the app shell is above the feature layer in the dependency graph (features are consumed by app, not vice versa, but this import direction is acceptable for navigation)
- **State management**: `StreamBuilder` native on Firestore streams — no external state management (no Riverpod, no Provider, no BLoC)
- **Logging**: `debugPrint()` is permitted. `print()` is FORBIDDEN (`avoid_print` lint is active)
- **No new packages**: All needed APIs already in the project
- **currentRound**: `createRoom()` already sets `currentRound: 1`. `startMatch()` also sets it to `1` for idempotency, but this is not a reset — it's a confirmation of the initial round

### `_AppShell` Preservation Note

`_AppShell` was intentionally kept private in Story 2.2 because its internal routing logic wasn't ready. In Story 2.4:
- Only the class visibility changes (underscore removed)
- No tab routing logic, no roomId parameter, no screen content changes
- Stories 2.5 and 2.6 will populate the `Joueurs` and `Room` tabs respectively
- Story 3.x will populate the `Match` tab

### Scope Boundary — What NOT to Do in This Story

| ❌ Don't | ✅ Reason |
|----------|-----------|
| Implement `AppShell` tab routing / screen content | Scope of Stories 2.5, 2.6, 3.x |
| Pass `roomId` to `AppShell` constructor | Not needed until Stories 2.5/2.6 when tabs need room context |
| Add "Terminer le match" / close room | Scope of Story 2.5 |
| Handle `room.status == closed` navigation from lobby | Scope of Story 2.5 |
| Add ownership transfer | Scope of Story 2.5 |
| Add player "Quitter la room" action | Scope of Story 2.5 |
| Implement `Players` tab content | Scope of Story 2.6 |
| Check ownership server-side in Dart before `startMatch()` | Firestore Security Rules handle this — no double-gating |
| Add `print()` calls | `avoid_print` lint is active — use `debugPrint()` only |
| Change `LobbyScreen` home phase | No changes to home (create/join) flow |

### Learnings from Stories 2.2 & 2.3

- `!mounted` guard is MANDATORY after every `await` in async methods within `StatefulWidget`
- `debugPrint()` for unexpected errors, NEVER `print()`
- `flutter analyze` must report zero issues (`No issues found!`) before marking story done
- `WidgetsBinding.instance.addPostFrameCallback` is the correct pattern for navigation triggered inside a builder callback — never call `Navigator` directly inside `build()` or a StreamBuilder `builder`
- `FilledButton` with `onPressed: null` is the Flutter-correct way to disable a button (not pointer-absorber hacks)
- Existing `_hexToColor()` private static helper is in `_LobbyScreenState` — do NOT add a duplicate
- No need to import `dart:async` (caused issues in Story 2.1 — Stream types available transitively)
- `const` constructors reduce rebuild cost — use `const` on all stateless child widgets

### Design Token Reference

| Token | Value | Usage in this story |
|-------|-------|---------------------|
| `surface-bg` | `Color(0xFF0D0F14)` | Scaffold background (no change) |
| `accent-p1` | `Color(0xFF4FC3F7)` | "Lancer le match" button color |
| `text-inverted` | `Color(0xFF0D0F14)` | Button foreground text |
| `sync-error` | `Color(0xFFF44336)` | SnackBar error text (via default SnackBar) |

### Git Context (recent commits at story start)

- `2-3-join-room-by-code.md` was the last story completed (2026-03-27)
- Recent commit added join section UI + `_UpperCaseTextFormatter` to `lobby_screen.dart`

### References

- Story AC source: [epics.md — Epic 2, Story 2.4](_bmad-output/planning-artifacts/epics.md)
- Current LobbyScreen: [lobby_screen.dart](../../mobile/lib/features/room/presentation/lobby_screen.dart)
- App shell (to make public): [app.dart](../../mobile/lib/app/app.dart)
- RoomRepository (to extend): [room_repository.dart](../../mobile/lib/features/room/data/room_repository.dart)
- Firestore paths: [firestore_paths.dart](../../mobile/lib/core/firebase/firestore_paths.dart)
- Architecture: [architecture.md](_bmad-output/planning-artifacts/architecture.md)
- Previous story dev notes: [2-3-join-room-by-code.md](./2-3-join-room-by-code.md)

---

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6 (GitHub Copilot)

### Debug Log References

No blockers encountered. All tasks completed in single execution.

### Completion Notes List

- ✅ Task 1: Added `currentUserId` getter and `startMatch()` method to `RoomRepository`. No direct ownership check in Dart — Firestore Security Rules are the authoritative gate (as per story spec).
- ✅ Task 2: Renamed `_AppShell` → `AppShell` in `app.dart`. Added `{super.key}` to constructor. `_AppShellState` remains private.
- ✅ Task 3: Added `_isStartLoading` field and `_startMatch()` async method with `!mounted` guards and SnackBar error handling. Button conditionally shown only for owner, disabled when `!canStart`.
- ✅ Task 4: Auto-navigation via `addPostFrameCallback` on `room.status == RoomStatus.active` in outer `StreamBuilder<RoomModel?>`. Returns `SizedBox.shrink()` as placeholder widget. Import `../../../app/app.dart` added.
- ✅ Task 5: `flutter analyze` → **No issues found!** Zero lint or compile errors.

### File List

- `mobile/lib/features/room/data/room_repository.dart` — added `currentUserId` getter + `startMatch()` method
- `mobile/lib/features/room/presentation/lobby_screen.dart` — added import, `_isStartLoading` field, `_startMatch()` method, owner detection, conditional button, auto-navigate on active
- `mobile/lib/app/app.dart` — renamed `_AppShell` → `AppShell`, added `{super.key}`

## Change Log

| Date | Change |
|------|--------|
| 2026-03-27 | Story created by create-story workflow |
| 2026-03-27 | Story implemented by dev agent — `startMatch()`, owner-gated button, auto-navigation on `room.status == active`. All ACs satisfied. `flutter analyze`: No issues found. |
