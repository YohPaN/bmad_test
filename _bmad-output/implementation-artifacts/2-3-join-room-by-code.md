# Story 2.3: Join Room by Code

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player,
I want to join an existing room by entering its code,
so that I can participate in a match session created by another player.

## Acceptance Criteria

1. **Given** the home screen  
   **When** a player enters a valid room code and their name and taps "Rejoindre"  
   **Then** a `PlayerModel` is created for that player in `rooms/{id}/players/{uid}` with `role: player` and `color: '#EF5350'`  
   **And** the player is navigated to the lobby phase showing existing participants

2. **Given** a player attempts to join with an invalid or non-existent room code  
   **When** the join action is submitted  
   **Then** an inline error message is shown (no blocking dialog)  
   **And** the player remains on the home screen

3. **Given** a player tries to join a room whose `status` is `active`  
   **When** the join action is submitted  
   **Then** the inline error "Match déjà en cours" is shown

4. **Given** a player tries to join a room whose `status` is `closed`  
   **When** the join action is submitted  
   **Then** the inline error "Room fermée" is shown

## Tasks / Subtasks

- [x] Task 1 — Update `RoomRepository.joinRoom()` with status-specific errors (AC: #3, #4)
  - [x] In `mobile/lib/features/room/data/room_repository.dart`, replace the single `RoomException('Room is not open for joining')` with status-aware messages:
    - `RoomStatus.active` → `RoomException('Match déjà en cours')`
    - `RoomStatus.closed` → `RoomException('Room fermée')`
    - Any other non-waiting status → `RoomException('Room non disponible')`

- [x] Task 2 — Extend `LobbyScreen` home phase with a join section (AC: #1, #2, #3, #4)
  - [x] In `mobile/lib/features/room/presentation/lobby_screen.dart`:
    - Add two new `TextEditingController` fields: `_codeController` and `_joinNameController`
    - Add two new state fields: `bool _isJoinLoading = false` and `String? _joinErrorMessage`
    - Dispose `_codeController` and `_joinNameController` in `dispose()`
  - [x] Add `_joinRoom()` async method:
    - Validate `_codeController.text.trim()` not empty (set `_joinErrorMessage` inline, return early)
    - Validate `_joinNameController.text.trim()` not empty (set `_joinErrorMessage` inline, return early)
    - `setState(() { _isJoinLoading = true; _joinErrorMessage = null; })`
    - Call `await _repo.joinRoom(_codeController.text.trim().toUpperCase(), _joinNameController.text.trim())`
    - On success: `setState(() { _roomId = id; _isJoinLoading = false; })`
    - On `RoomException catch (e)`: `setState(() { _joinErrorMessage = e.message; _isJoinLoading = false; })`
  - [x] In `_buildHomePhase()`, add after the existing "Créer une room" section:
    - A `Row` with a `Divider` on each side and "OU" text in `text-muted` (`#5C6478`) centered between them — visual separator
    - A join section label "CODE DE ROOM" in `Roboto Condensed 11sp` uppercase `text-muted`
    - `TextFormField` for room code (label: "Code de la room", `textCapitalization: TextCapitalization.characters`, `maxLength: 6`, `inputFormatters: [UpperCaseTextFormatter()]` or via `onChanged: (v) => _codeController.text = v.toUpperCase()`)
    - `TextFormField` for player name (label: "Votre nom", same styling as the create section name field)
    - `FilledButton` "Rejoindre" full-width 48dp, same color `#4FC3F7` as "Créer une room"
    - If `_isJoinLoading`, show `CircularProgressIndicator` instead of the button
    - If `_joinErrorMessage != null`, show inline error text in `#F44336` below the join button

- [x] Task 3 — Upper-case input formatter for the code field (AC: #1)
  - [x] Add a private `_UpperCaseTextFormatter` class inside `lobby_screen.dart` (or use `onChanged` callback approach — see Dev Notes for recommended pattern)

- [x] Task 4 — Verify `flutter analyze` reports zero errors (AC: all)
  - [x] Run `flutter analyze` from `mobile/` directory
  - [x] Confirm 0 issues: no `avoid_print`, no unused imports, no missing const

## Dev Notes

### Starting Point — State of Repository at Story 2.3 Start

These files are CONFIRMED present and fully implemented (from Story 2.2):

| File | Status | Notes |
|------|--------|-------|
| `mobile/lib/features/room/presentation/lobby_screen.dart` | ✅ Complete | Two-phase: home (create room) + lobby (post-create with StreamBuilders). `_roomId` = null means home phase. |
| `mobile/lib/features/room/presentation/widgets/player_presence_badge.dart` | ✅ Complete | Avatar + online dot + OWNER label, 48×48dp min touch |
| `mobile/lib/features/room/data/room_repository.dart` | ✅ Complete | `createRoom()`, `joinRoom()`, `streamRoom()`, `streamPlayers()` — `joinRoom()` needs status-specific errors |
| `mobile/lib/features/room/domain/models.dart` | ✅ Complete | `RoomStatus`, `RoomModel`, `PlayerModel`, `RoleEnum` |
| `mobile/lib/core/firebase/firestore_paths.dart` | ✅ Complete | Firestore path helpers |
| `mobile/lib/app/app.dart` | ✅ Complete | `home: LobbyScreen()` — `_AppShell` preserved for Story 2.4 |
| `mobile/pubspec.yaml` | ✅ Complete | `cloud_firestore: ^5.6.7`, `firebase_auth: ^5.5.2`, `firebase_core: ^3.13.1` — **no new packages needed** |
| `mobile/analysis_options.yaml` | ✅ Active | `avoid_print: true` enforced |

**Files to MODIFY in this story:**
- `mobile/lib/features/room/data/room_repository.dart` — update `joinRoom()` error messages
- `mobile/lib/features/room/presentation/lobby_screen.dart` — extend home phase with join section

**Files NOT to touch (zero changes):**
- `mobile/lib/features/room/domain/models.dart`
- `mobile/lib/features/room/presentation/widgets/player_presence_badge.dart`
- `mobile/lib/app/app.dart`
- `mobile/pubspec.yaml`
- `mobile/lib/main.dart`

### Repository Change — Exact Diff

**Current code in `room_repository.dart` (around line 73):**
```dart
if (roomStatus != RoomStatus.waiting) {
  throw const RoomException('Room is not open for joining');
}
```

**Replace with:**
```dart
if (roomStatus == RoomStatus.active) {
  throw const RoomException('Match déjà en cours');
} else if (roomStatus == RoomStatus.closed) {
  throw const RoomException('Room fermée');
} else if (roomStatus != RoomStatus.waiting) {
  throw const RoomException('Room non disponible');
}
```

### Uppercase Input for Room Code — Recommended Pattern

Use `TextInputFormatter` to force uppercase as-you-type. The cleanest approach without adding packages:

```dart
import 'package:flutter/services.dart'; // already imported for Clipboard

// Private formatter class — add at the bottom of lobby_screen.dart, outside the widget class
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
```

Usage in field:
```dart
TextFormField(
  controller: _codeController,
  keyboardType: TextInputType.text,
  textCapitalization: TextCapitalization.characters,
  inputFormatters: [_UpperCaseTextFormatter()],
  maxLength: 6,
  decoration: InputDecoration(
    labelText: 'Code de la room',
    counterText: '', // hide character counter display
    ...
  ),
)
```

### LobbyScreen State Extensions

Add to `_LobbyScreenState` fields (alongside existing fields):
```dart
// Existing fields (do not change):
String? _roomId;
bool _isLoading = false;
String? _errorMessage;
final _nameController = TextEditingController();
final _repo = RoomRepository();

// New fields for join:
bool _isJoinLoading = false;
String? _joinErrorMessage;
final _codeController = TextEditingController();
final _joinNameController = TextEditingController();
```

Update `dispose()`:
```dart
@override
void dispose() {
  _nameController.dispose();
  _codeController.dispose();       // new
  _joinNameController.dispose();   // new
  super.dispose();
}
```

### `_joinRoom()` Method

```dart
Future<void> _joinRoom() async {
  final code = _codeController.text.trim().toUpperCase();
  final name = _joinNameController.text.trim();

  if (code.isEmpty) {
    setState(() => _joinErrorMessage = 'Veuillez entrer le code de la room.');
    return;
  }
  if (name.isEmpty) {
    setState(() => _joinErrorMessage = 'Veuillez entrer votre nom.');
    return;
  }

  setState(() {
    _isJoinLoading = true;
    _joinErrorMessage = null;
  });

  try {
    final id = await _repo.joinRoom(code, name);
    if (!mounted) return;
    setState(() {
      _roomId = id;
      _isJoinLoading = false;
    });
  } on RoomException catch (e) {
    if (!mounted) return;
    setState(() {
      _joinErrorMessage = e.message;
      _isJoinLoading = false;
    });
  } catch (e) {
    debugPrint('joinRoom unexpected error: $e');
    if (!mounted) return;
    setState(() {
      _joinErrorMessage = 'Une erreur inattendue est survenue.';
      _isJoinLoading = false;
    });
  }
}
```

### Home Phase Layout Extension

The new `_buildHomePhase()` layout becomes:

```
──────────────────────────────────────────────────────────────
 HOME PHASE (updated for Story 2.3)
──────────────────────────────────────────────────────────────
 ┌─────────────────────────────────────┐
 │  WH40K MATCH COMPANION              │
 │  (RobotoCondensed 20sp muted)       │
 │                                     │
 │  ┌──────────────────────────────┐   │
 │  │ Votre nom...  (create)       │   │
 │  └──────────────────────────────┘   │
 │  [CRÉER UNE ROOM ───────────────]   │
 │  Error if any                       │
 │                                     │
 │  ──── OU ────                       │  ← separator Row/Divider
 │                                     │
 │  CODE DE ROOM  (muted label 11sp)   │
 │  ┌──────────────────────────────┐   │
 │  │ Code de la room (uppercase)  │   │
 │  └──────────────────────────────┘   │
 │  ┌──────────────────────────────┐   │
 │  │ Votre nom...  (join)         │   │
 │  └──────────────────────────────┘   │
 │  [REJOINDRE ────────────────────]   │
 │  Error if any                       │
 └─────────────────────────────────────┘
```

### OR Separator Pattern

```dart
Row(
  children: const [
    Expanded(child: Divider(color: Color(0xFF2A2F3E))),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'OU',
        style: TextStyle(
          fontFamily: 'RobotoCondensed',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Color(0xFF5C6478),
        ),
      ),
    ),
    Expanded(child: Divider(color: Color(0xFF2A2F3E))),
  ],
),
```

### Lobby Phase — No Changes Required

The existing `_buildLobbyPhase()` already works for a joined room: it uses `_roomId` to stream the room and players, regardless of whether the user created or joined. **Do not modify `_buildLobbyPhase()`.**

### Architecture Constraints

- **Feature boundary**: `lobby_screen.dart` may only import from `features/room/` — NEVER from `features/game/`.
- **Firestore paths**: `RoomRepository` already abstracts all Firestore operations — `lobby_screen.dart` only calls repository methods. Never import `FirestorePaths` directly in screen files.
- **State management**: `StreamBuilder` native on Firestore streams — no external state management (no Riverpod, no Provider, no BLoC).
- **Logging**: `debugPrint()` is permitted. `print()` is FORBIDDEN (`avoid_print` lint is active).
- **No new packages**: All needed APIs are already in the project.
- **Do NOT import `dart:async`**: Stream types are available via `flutter/material.dart` transitively. Explicitly importing `dart:async` caused issues in Story 2.1.

### Player Color Assignment

Story 2.3 does NOT change color assignment — the repository hardcodes `#EF5350` for all joined players. This is the expected behavior per the architecture (`color: assigné à la création de room — #4FC3F7 joueur 1, #EF5350 joueur 2, extensible post-MVP`). Multi-player color extension is deferred to post-MVP.

### Design Token Reference

| Token | Value | Usage in this story |
|-------|-------|---------------------|
| `surface-bg` | `Color(0xFF0D0F14)` | Scaffold background |
| `surface-card` | `Color(0xFF161920)` | Field containers |
| `border-subtle` | `Color(0xFF2A2F3E)` | Field borders, dividers |
| `text-primary` | `Color(0xFFE8EAF0)` | Input text |
| `text-muted` | `Color(0xFF5C6478)` | Labels, section headers, "OU" separator |
| Player 2 accent | `Color(0xFFEF5350)` | Join button color (matches player 2 color) — OR keep `#4FC3F7` for consistency per UX |
| `sync-error` | `Color(0xFFF44336)` | Inline error messages |

> **Note on join button color**: Both `#4FC3F7` (create) and `#EF5350` (join / player 2) are valid choices. Prefer `#4FC3F7` for visual consistency on the home screen — both buttons are the same primary action type.

### RoomRepository API Available

```dart
// Story 2.3 uses joinRoom:
Future<String> joinRoom(String code, String playerName)
    → finds room by code, creates PlayerModel with role: player, color: '#EF5350'
    → returns roomId on success
    → throws RoomException('Code introuvable') if no room found   [currently: 'Room not found']
    → throws RoomException('Match déjà en cours') if room.status == active  [UPDATED in Task 1]
    → throws RoomException('Room fermée') if room.status == closed          [UPDATED in Task 1]

// Already used for lobby phase — no changes:
Stream<RoomModel?> streamRoom(String roomId)
Stream<List<PlayerModel>> streamPlayers(String roomId)
```

> **Note on 'Room not found' message**: The existing `RoomException('Room not found')` English text will bubble up to the UI as-is. If you want French user-facing text, also change it to `RoomException('Room introuvable')` in Task 1.

### Scope Boundary — What NOT to Do in This Story

| ❌ Don't | ✅ Reason |
|----------|-----------|
| Change the lobby phase | Already works for joined rooms via `_roomId` |
| Wire "Lancer le match" button | Scope of Story 2.4 |
| Implement player color selection | Post-MVP; colors are hardcoded per architecture |
| Add navigation away from lobby after joining | Lobby is the correct destination; match start is Story 2.4 |
| Add any packages to `pubspec.yaml` | No new packages needed |
| Remove `_AppShell` | Preserved for Story 2.4 |
| Add `print()` calls | `avoid_print` lint is active — use `debugPrint()` only |
| Implement room code QR scanning | Out of scope for MVP |

### Learnings from Story 2.2

- Pattern for `!mounted` guard after `await` is established and must be used: `if (!mounted) return;`
- `StatefulWidget` with multiple loading/error state fields is the pattern (not global state)
- `TextEditingController.dispose()` must be called for every controller added
- `debugPrint` for unexpected errors, never `print`
- `flutter analyze` must report zero issues before marking story done
- The `_hexToColor()` private static helper is already in `_LobbyScreenState` — do NOT add a duplicate

### Git Context (recent commits at story start)

- `bd78f8f` — implement story 2.2 (LobbyScreen home+lobby phases, PlayerPresenceBadge)
- `65ae57d` — resolve dette tech (Color fix in app.dart)
- `b336e66` — implement story 2.1 (full models + repo + 21 tests)

### Project Structure Notes

**No new files created in this story** — only modifications to existing files.

**Feature-first compliance:**
- Both modified files live in `features/room/` — correct
- No cross-feature imports introduced

### References

- Story AC source: [epics.md — Epic 2, Story 2.3](_bmad-output/planning-artifacts/epics.md)
- RoomRepository join implementation: [room_repository.dart](../../mobile/lib/features/room/data/room_repository.dart)
- LobbyScreen current state: [lobby_screen.dart](../../mobile/lib/features/room/presentation/lobby_screen.dart)
- Design tokens: [ux-design-specification.md — Color Palette](_bmad-output/planning-artifacts/ux-design-specification.md#color-palette)
- UX home phase layout: [ux-design-specification.md — Screen Architecture](_bmad-output/planning-artifacts/ux-design-specification.md#screen-architecture)
- Previous story dev notes: [2-2-create-room-lobby-screen.md](./2-2-create-room-lobby-screen.md)

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `flutter analyze`: 0 issues after all changes.

### Completion Notes List

- Task 1: Updated `joinRoom()` in `room_repository.dart`. Status-aware exceptions: `active` → 'Match déjà en cours', `closed` → 'Room fermée', other non-waiting → 'Room non disponible'. Also updated 'Room not found' → 'Room introuvable' for consistent French UX.
- Task 2: Extended `_LobbyScreenState` with `_codeController`, `_joinNameController`, `_isJoinLoading`, `_joinErrorMessage`. Added `_joinRoom()` method with `!mounted` guards. Extended `_buildHomePhase()` with OR divider + join form + inline error display.
- Task 3: Added `_UpperCaseTextFormatter` class at bottom of `lobby_screen.dart`. Used via `inputFormatters: [_UpperCaseTextFormatter()]` on code field.
- Task 4: `flutter analyze` reported `No issues found!` (0 issues).

### File List

- `mobile/lib/features/room/data/room_repository.dart` — Modified: status-specific RoomException messages in `joinRoom()`
- `mobile/lib/features/room/presentation/lobby_screen.dart` — Modified: join section UI + `_joinRoom()` + `_UpperCaseTextFormatter`

## Change Log

| Date | Change |
|------|--------|
| 2026-03-27 | Task 1: `joinRoom()` now throws status-specific French error messages (`Match déjà en cours`, `Room fermée`, `Room non disponible`, `Room introuvable`). |
| 2026-03-27 | Task 2/3: `LobbyScreen` home phase extended with join section (OR separator, code field with uppercase enforcer, player name field, "Rejoindre" button, inline error display). `_joinRoom()` method added with `!mounted` guards. `_UpperCaseTextFormatter` added. |
