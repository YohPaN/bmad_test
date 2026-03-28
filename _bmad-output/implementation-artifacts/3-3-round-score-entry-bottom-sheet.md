# Story 3.3: Round Score Entry Bottom Sheet

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player,
I want to tap my active round cell and enter VP Primaires and VP Secondaires in a bottom sheet,
So that I can declare my round score in under 3 gestures.

## Acceptance Criteria

1. **Given** the match screen with `currentRound = N`
   **When** a player taps their own active `RoundScoreCell`
   **Then** a `ModalBottomSheet` opens with two numeric input fields: "VP Primaires" and "VP Secondaires"
   **And** the numeric keyboard is shown automatically (`keyboardType: TextInputType.number`)
   **And** each field has a minimum height of 56dp with 12dp padding (UX-DR4)
   **And** a single full-width confirmation button "Confirmer Round N" is shown in the player's accent color

2. **Given** the bottom sheet is open and valid values are entered
   **When** the player taps the confirmation button
   **Then** a `score_update` event is appended to `rooms/{id}/events/` with `type: 'score_update'`, `actorId`, `targetPlayerId`, `before`, `after` (containing `{round, vpPrim, vpSec}`)
   **And** `PlayerModel.vpByRound` is updated in Firestore for that round (`'vpByRound.$round': {'prim': X, 'sec': Y}`)
   **And** the bottom sheet closes
   **And** the `RoundScoreCell` transitions to `filled` state (via Firestore stream)

3. **Given** a non-owner player taps a cell belonging to another player
   **When** the tap is registered
   **Then** `OwnershipLockFeedback.trigger(context)` fires: `HapticFeedback.selectionClick()` + brief `SnackBar` message
   **And** the bottom sheet does NOT open

4. **Given** the room owner taps any player's active `RoundScoreCell`
   **When** the tap is registered
   **Then** the bottom sheet opens normally for that player's data (owner can enter score on behalf of any player)

5. **Given** the bottom sheet is open and the user taps outside or uses back button
   **When** the dismissal gesture is registered
   **Then** the bottom sheet closes without any Firestore write

## Tasks / Subtasks

- [x] Task 1 — Create `OwnershipLockFeedback` utility (AC: #3)
  - [x] Create `mobile/lib/features/game/presentation/widgets/ownership_lock_feedback.dart`
  - [x] Declare `abstract final class OwnershipLockFeedback` (static-only utility, non-instantiable)
  - [x] Implement `static void trigger(BuildContext context)`:
    - Call `HapticFeedback.selectionClick()` (from `flutter/services.dart`)
    - Call `ScaffoldMessenger.of(context).clearSnackBars()` then `.showSnackBar(SnackBar(...))`
    - SnackBar content: `'Vous ne pouvez pas modifier cette cellule'`
    - `duration: const Duration(seconds: 2)`, `behavior: SnackBarBehavior.floating`
    - Background color: `Color(0xFF2A2F3E)` (border-subtle token — matches dark theme)
  - [x] Import `package:flutter/services.dart` for `HapticFeedback`
  - [x] Import `package:flutter/material.dart` for `BuildContext`, `ScaffoldMessenger`, `SnackBar`

- [x] Task 2 — Create `RoundScoreEntrySheet` bottom sheet widget (AC: #1, #2, #5)
  - [x] Create `mobile/lib/features/game/presentation/widgets/round_score_entry_sheet.dart`
  - [x] Declare `class RoundScoreEntrySheet extends StatefulWidget`
  - [x] Constructor parameters:
    ```dart
    final int roundNumber;
    final String playerName;          // displayed in the sheet title
    final Color playerColor;           // accent color for confirm button
    final int? vpPrimInitial;          // null if cell was empty
    final int? vpSecInitial;           // null if cell was empty
    final Future<void> Function(int vpPrim, int vpSec) onConfirm;
    ```
  - [x] Implement static `Future<void> show(BuildContext context, { ... })` factory method that calls `showModalBottomSheet<void>`:
    ```dart
    static Future<void> show(
      BuildContext context, {
      required int roundNumber,
      required String playerName,
      required Color playerColor,
      int? vpPrimInitial,
      int? vpSecInitial,
      required Future<void> Function(int vpPrim, int vpSec) onConfirm,
    }) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,  // prevents keyboard overlap
        backgroundColor: const Color(0xFF161920),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        ),
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: RoundScoreEntrySheet(
            roundNumber: roundNumber,
            playerName: playerName,
            playerColor: playerColor,
            vpPrimInitial: vpPrimInitial,
            vpSecInitial: vpSecInitial,
            onConfirm: onConfirm,
          ),
        ),
      );
    }
    ```
  - [x] In `_RoundScoreEntrySheetState`, declare:
    - `final TextEditingController _vpPrimController`
    - `final TextEditingController _vpSecController`
    - `bool _isLoading = false`
    - `String? _errorMessage`
  - [x] Initialize controllers in `initState()` with `vpPrimInitial` and `vpSecInitial` (convert from int? → String, empty string if null)
  - [x] Dispose controllers in `dispose()`
  - [x] Build layout (single `Padding(padding: EdgeInsets.all(16))` wrapping a `Column`):
    - Title row: `Text('Round ${roundNumber} — ${playerName}')` in Roboto Condensed 11sp uppercase (UX-DR12)
    - 8dp gap
    - `TextFormField` for "VP Primaires": `keyboardType: TextInputType.number`, `autofocus: true`, constraints `minHeight: 56dp` via `InputDecoration` with padding `EdgeInsets.all(12)` (UX-DR4)
    - 8dp gap
    - `TextFormField` for "VP Secondaires": `keyboardType: TextInputType.number`, same height constraints (UX-DR4)
    - 8dp gap
    - If `_errorMessage != null`: `Text(_errorMessage!, style: TextStyle(color: Color(0xFFF44336)))` — sync error feedback color
    - 16dp gap
    - Full-width `ElevatedButton` "Confirmer Round $roundNumber" in `playerColor` (UX-DR4):
      ```dart
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: playerColor, ...),
          onPressed: _isLoading ? null : _handleConfirm,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Text('Confirmer Round $roundNumber'),
        ),
      )
      ```
    - 16dp gap (bottom padding — doubled safe area padding)
  - [x] `_handleConfirm()` method:
    - Parse `_vpPrimController.text` as `int` (default 0 if empty or non-numeric)
    - Parse `_vpSecController.text` as `int` (same)
    - `setState(() { _isLoading = true; _errorMessage = null; })`
    - `await widget.onConfirm(vpPrim, vpSec)` wrapped in try/catch
    - On success: `if (mounted) Navigator.of(context).pop()`
    - On `GameException` catch: `setState(() { _isLoading = false; _errorMessage = e.message; })`
  - [x] No `print()` calls — use `debugPrint()` if needed
  - [x] Touch target: button min height 48dp (UX-DR19)
  - [x] Border radius 4dp on button / sheet (UX-DR20)

- [x] Task 3 — Add `submitScoreUpdate()` to `EventRepository` (AC: #2)
  - [x] Modify `mobile/lib/features/game/data/event_repository.dart`
  - [x] Add `import 'package:cloud_firestore/cloud_firestore.dart'` — already present
  - [x] Add `Future<void> submitScoreUpdate({...})` using a Firestore batch for atomicity:
    ```dart
    Future<void> submitScoreUpdate({
      required String roomId,
      required String actorId,
      required String targetPlayerId,
      required int round,
      required Map<String, int>? beforeVp,  // {'prim': X, 'sec': Y} or null if first entry
      required int vpPrimAfter,
      required int vpSecAfter,
    }) async {
      try {
        final batch = FirebaseFirestore.instance.batch();

        // 1. Create auto-ID event document ref (batch.set supports this)
        final eventRef = FirestorePaths.events(roomId).doc();
        batch.set(eventRef, {
          'type': 'score_update',
          'actorId': actorId,
          'targetPlayerId': targetPlayerId,
          'before': {
            'round': round,
            'vpPrim': beforeVp?['prim'],
            'vpSec': beforeVp?['sec'],
          },
          'after': {
            'round': round,
            'vpPrim': vpPrimAfter,
            'vpSec': vpSecAfter,
          },
          'timestamp': FieldValue.serverTimestamp(),
          'undone': false,
        });

        // 2. Update player's vpByRound for this specific round using dot-notation
        //    This preserves other rounds' data (Firestore field merge via dot-path)
        final playerRef = FirestorePaths.player(roomId, targetPlayerId);
        batch.update(playerRef, {
          'vpByRound.$round': {'prim': vpPrimAfter, 'sec': vpSecAfter},
        });

        await batch.commit();
      } on FirebaseException catch (e) {
        throw GameException('Failed to submit score update: ${e.message}');
      } catch (e) {
        throw GameException('Failed to submit score update: $e');
      }
    }
    ```
  - [x] **CRITICAL**: Use `FirestorePaths.events(roomId).doc()` (no arg = auto-ID) + `batch.set()` — do NOT call `.add()` (which can't be batched with `.update()`)
  - [x] **CRITICAL**: Dot notation `'vpByRound.$round'` updates ONLY that round's map without erasing other rounds

- [x] Task 4 — Wire `MatchScreen` to show bottom sheet and lock feedback (AC: #1–#4)
  - [x] Modify `mobile/lib/features/game/presentation/match_screen.dart`
  - [x] Add imports:
    ```dart
    import 'package:flutter/services.dart';                     // for HapticFeedback (if used directly)
    import '../../../features/game/domain/game_rules.dart';     // wait — same feature, use relative:
    import '../../domain/game_rules.dart';
    import '../../data/event_repository.dart';
    import 'widgets/ownership_lock_feedback.dart';
    import 'widgets/round_score_entry_sheet.dart';
    ```
  - [x] **Import depth**: `match_screen.dart` is at `lib/features/game/presentation/` — so `game_rules.dart` is at `../domain/game_rules.dart` (1 level up), `event_repository.dart` is at `../data/event_repository.dart`
  - [x] Add private `_handleCellTap` method to `MatchScreen` (static or extracted for clarity):
    ```dart
    void _handleCellTap(
      BuildContext context,
      String playerId,
      int round,
      RoomModel room,
      List<PlayerModel> players,
    ) {
      final canMutate = game_rules_canMutate(
        currentUserId,
        room.createdBy,
        playerId,
      );

      if (!canMutate) {
        OwnershipLockFeedback.trigger(context);
        return;
      }

      final player = players.firstWhere((p) => p.id == playerId);
      final roundData = player.vpByRound[round.toString()];

      RoundScoreEntrySheet.show(
        context,
        roundNumber: round,
        playerName: player.name,
        playerColor: _parseColor(player.color),
        vpPrimInitial: roundData?['prim'],
        vpSecInitial: roundData?['sec'],
        onConfirm: (vpPrim, vpSec) => EventRepository().submitScoreUpdate(
          roomId: room.id,
          actorId: currentUserId,
          targetPlayerId: playerId,
          round: round,
          beforeVp: roundData != null
              ? {'prim': roundData['prim'] ?? 0, 'sec': roundData['sec'] ?? 0}
              : null,
          vpPrimAfter: vpPrim,
          vpSecAfter: vpSec,
        ),
      );
    }
    ```
  - [x] Add `static Color _parseColor(String hex)` helper (or reuse — check if one already exists in codebase):
    ```dart
    static Color _parseColor(String hex) {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    ```
    **NOTE**: Check if `PlayerModel` or any existing widget already has this helper before adding a new one — do NOT duplicate.
  - [x] Wrap `ScoreGridWidget` in a `Builder` widget to get a context properly scoped inside the Scaffold body (required for `showModalBottomSheet` and `ScaffoldMessenger`):
    ```dart
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Builder(
          builder: (innerContext) => ScoreGridWidget(
            players: players,
            activeRound: room.currentRound,
            currentUserId: currentUserId,
            isOwner: isOwner,
            onCellTap: (playerId, round) =>
                _handleCellTap(innerContext, playerId, round, room, players),
          ),
        ),
      ),
    ),
    ```
  - [x] Remove the old `debugPrint('Cell tapped: ...')` placeholder
  - [x] Import for `canMutate` — the function is in `game_rules.dart`. Import it and call `canMutate(...)` directly (it's a top-level function, not a class method)

- [x] Task 5 — Write widget tests (AC: #1–#5)
  - [x] Create `mobile/test/features/game/widgets/round_score_entry_sheet_test.dart`
  - [x] Test: bottom sheet renders "VP Primaires" and "VP Secondaires" fields
  - [x] Test: full-width "Confirmer Round N" button is present
  - [x] Test: tapping confirm with values calls `onConfirm` with correct parsed ints
  - [x] Test: `vpPrimInitial` and `vpSecInitial` pre-populate the text fields
  - [x] Test: loading spinner shown when `onConfirm` is in progress (`_isLoading = true`)
  - [x] Create `mobile/test/features/game/widgets/ownership_lock_feedback_test.dart` (optional: simple smoke test)
  - [x] Create `mobile/test/features/game/presentation/match_screen_cell_tap_test.dart`
  - [x] Test: when `isOwner = false` and `currentUserId != playerId` → OwnershipLockFeedback triggers (and bottom sheet does NOT appear)
  - [x] Test: when `currentUserId == playerId` → `RoundScoreEntrySheet` is shown

- [x] Task 6 — Verify `flutter analyze` + all tests pass (AC: all)
  - [x] Run `flutter analyze` from `mobile/` — must report `No issues found!`
  - [x] Run `flutter test test/features/game/widgets/` — all tests pass
  - [x] Existing tests in `test/features/game/widgets/round_score_cell_test.dart` and `score_grid_widget_test.dart` MUST still pass

## Dev Notes

### Architecture Compliance — CRITICAL RULES

| Rule | Detail | Source |
|------|--------|--------|
| Feature isolation | `features/game` must NOT import from `features/room` directly — use relative imports within the same feature | [Source: architecture.md#Architectural Boundaries] |
| `game_rules.dart` guard at UI | Mutation must be gated via `canMutate(actorId, roomCreatedBy, targetPlayerId)` BEFORE calling `EventRepository` | [Source: architecture.md#Data Flow step 4] |
| `firestore_paths.dart` only | `submitScoreUpdate()` must use `FirestorePaths.events()` and `FirestorePaths.player()` — NO raw path strings | [Source: architecture.md#Data Boundaries] |
| Batch write for atomicity | Append event + update vpByRound in a single `WriteBatch` to prevent partial state | [Source: architecture.md#Implementation Patterns] |
| Dot-notation for vpByRound | Use `'vpByRound.$round': {...}` to avoid erasing other rounds | Firestore partial update pattern |
| VP total = derived | Never store a scalar VP total — always compute via `game_rules.vpTotal(player.vpByRound)` | [Source: architecture.md#Data Architecture] |
| Undo = soft delete | `appendEvent` / `submitScoreUpdate` events have `undone: false` — undo in story 4.2 will set `undone: true` | [Source: architecture.md#Undo pattern] |
| No `print()` | `debugPrint()` only | [Source: analysis_options.yaml `avoid_print: true`] |
| StreamBuilder native | No external state management — no Provider/Riverpod/BLoC | [Source: architecture.md#State Management] |
| 1-tap confirm | Score entry is NOT destructive — no 2-step confirmation (UX-DR4). `TwoStepConfirmButton` is reserved for undo only (story 4.2) | [Source: UX-DR4, architecture.md] |
| Test mirror structure | Widget tests in `mobile/test/features/game/widgets/`, presentation tests in `mobile/test/features/game/presentation/` | [Source: architecture.md] |

### Project Structure — Files to Create / Modify

```
mobile/
├── lib/
│   └── features/
│       └── game/
│           ├── data/
│           │   └── event_repository.dart       ← MODIFY: add submitScoreUpdate()
│           └── presentation/
│               ├── match_screen.dart            ← MODIFY: wire onCellTap, add _handleCellTap
│               └── widgets/
│                   ├── ownership_lock_feedback.dart  ← CREATE (Task 1)
│                   └── round_score_entry_sheet.dart  ← CREATE (Task 2)
└── test/
    └── features/
        └── game/
            ├── presentation/
            │   └── match_screen_cell_tap_test.dart  ← CREATE (Task 5)
            └── widgets/
                ├── round_score_entry_sheet_test.dart ← CREATE (Task 5)
                ├── round_score_cell_test.dart        ← DO NOT MODIFY (21 tests pass from 3.2)
                └── score_grid_widget_test.dart       ← DO NOT MODIFY (tests pass from 3.2)
```

**Already exists — do NOT recreate or break:**
- `mobile/lib/features/game/presentation/widgets/round_score_cell.dart` — leave untouched
- `mobile/lib/features/game/presentation/widgets/score_grid_widget.dart` — leave untouched
- `mobile/lib/features/game/data/event_repository.dart` — ADD method only, do NOT modify existing `appendEvent` or `streamEvents`

### Import Paths — Critical Depth Reference

`match_screen.dart` is at `mobile/lib/features/game/presentation/`:
- `../../domain/game_rules.dart`           → `lib/features/game/domain/game_rules.dart`
- `../../data/event_repository.dart`       → `lib/features/game/data/event_repository.dart`
- `../../room/data/room_repository.dart`   → `lib/features/room/data/room_repository.dart` ✅ (already imported)
- `../../room/domain/models.dart`          → `lib/features/room/domain/models.dart` ✅ (already imported via room_repository)
- `widgets/ownership_lock_feedback.dart`   → same directory
- `widgets/round_score_entry_sheet.dart`   → same directory

**From story 3.2 debug log (CRITICAL):** Import depth mismatch will cause `file not found` compile errors. Always count parent steps carefully.

### `canMutate` Function Signature (do NOT reimplement)

```dart
// From mobile/lib/features/game/domain/game_rules.dart (already implemented)
bool canMutate(String actorId, String roomCreatedBy, String targetPlayerId)
// Returns true if: actorId == targetPlayerId OR actorId == roomCreatedBy
// Returns false otherwise
```

### `_parseColor()` — Check Before Adding

Before adding a `_parseColor()` helper to `MatchScreen`, check if any existing widget in the project already defines this. The `score_grid_widget.dart` may already have a similar utility. If it does, extract it to a shared location or duplicate sparingly.

Typical implementation:
```dart
static Color _parseColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
```

### `PlayerModel.color` to `Color` Conversion

```dart
final player = players.firstWhere((p) => p.id == playerId);
final playerColor = _parseColor(player.color); // e.g. '#4FC3F7' → Color(0xFF4FC3F7)
final roundKey = round.toString();              // vpByRound key is String
final roundData = player.vpByRound[roundKey];   // Map<String, int>? — null if no data yet
final vpPrimBefore = roundData?['prim'];        // int? — null if first entry
final vpSecBefore  = roundData?['sec'];         // int? — null if first entry
```

### `submitScoreUpdate` Batch Pattern (CRITICAL)

The Firestore SDK does NOT support `.add()` inside a batch. Use `.doc()` (no arg → auto-ID) + `batch.set()`:

```dart
// ✅ CORRECT — auto-ID in a batch:
final eventRef = FirestorePaths.events(roomId).doc(); // generates new doc ID
batch.set(eventRef, eventData);

// ❌ WRONG — .add() cannot be batched:
// batch.add(FirestorePaths.events(roomId), eventData);  // does not exist
```

### Dot-Notation vpByRound Update

```dart
// ✅ CORRECT — Updates only round 2, preserves rounds 1,3,4,5:
batch.update(playerRef, {
  'vpByRound.2': {'prim': 7, 'sec': 3},
});

// ❌ WRONG — Overwrites entire vpByRound map, erasing all other rounds:
// batch.update(playerRef, {'vpByRound': {'2': {'prim': 7, 'sec': 3}}});
```

### `RoundScoreEntrySheet` — Keyboard Overlap Prevention

Since the bottom sheet contains `TextFormField`s that trigger the software keyboard, use `isScrollControlled: true` on `showModalBottomSheet` and wrap the sheet content with `Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))`. This resizes the sheet above the keyboard.

### SnackBar Context — Why Builder is Required

`MatchScreen.build()` returns a `Scaffold`, but the `StreamBuilder.builder` context is the same context as `MatchScreen.build(context)` — above the Scaffold. `ScaffoldMessenger.of(context)` works from any context below `MaterialApp` (which provides `ScaffoldMessenger`), so it works fine from the StreamBuilder builder context. However, `showModalBottomSheet` also needs a context with a `Navigator` ancestor. Using a `Builder` widget inside `Scaffold.body` provides a safe context that is:
1. Below `MaterialApp` (for `ScaffoldMessenger`)
2. Below `Navigator` (for `showModalBottomSheet`)
3. Below `Scaffold` (for potential `Scaffold.of(context)` if needed)

This is the canonical Flutter pattern for this scenario.

### `RoundScoreEntrySheet` — Parse VP Input Defensively

```dart
int _parseVp(String text) {
  if (text.isEmpty) return 0;
  return int.tryParse(text) ?? 0;  // non-numeric → 0, not a crash
}
```

### Theme Tokens Used in This Story

| Token | Value | Widget |
|-------|-------|--------|
| `surface-card` | `#161920` | Bottom sheet background |
| `border-subtle` | `#2A2F3E` | SnackBar background (OwnershipLockFeedback), sheet border-radius shape |
| `sync-error` | `#F44336` | Error message text in RoundScoreEntrySheet |
| Player 1 accent | `#4FC3F7` | Confirm button when P1 is the target |
| Player 2 accent | `#EF5350` | Confirm button when P2 is the target |

### Previous Story Learnings (Story 3.2 — CRITICAL)

From `3-2-score-grid-widget-round-score-cell.md` Dev Agent Record:

1. **Import depth bug**: `match_screen.dart` (at `presentation/`) needs `../../room/...` (2 levels up to `features/`). New imports to `game/domain/` need `../../domain/`. Widgets at `presentation/widgets/` need 3 levels: `../../../room/...`. Count directory levels explicitly before writing imports.

2. **Flutter Table + Stack incompatibility**: `SizedBox.expand()` inside `Table` cells causes layout issues because Table measures with unbounded height. Use `Row(MainAxisAlignment.end)` for overlays instead of `Stack(Positioned(...))`. **Relevant to this story**: any overlay or positioned element (like a lock icon or loading spinner) inside a Table cell should use `Row`/`Align` rather than `Stack(Positioned(...))`.

3. **`google_fonts: ^6.2.1`**: Already in `pubspec.yaml` — use `GoogleFonts.robotoCondensed(...)` for sheet title (no new dependency needed).

4. **Test pattern**: `flutter_test` only — no Mockito needed for widget-only tests. Use plain `onConfirm: (a, b) async {}` callbacks. Pump `await tester.pumpAndSettle()` to let async animations complete.

5. **21/21 existing tests**: `test/features/game/widgets/` has 21 passing tests. Task 6 MUST verify they still pass after MatchScreen changes.

6. **`firestore_paths.dart`** already has `FirestorePaths.player(roomId, uid)` and `FirestorePaths.events(roomId)` — both needed for `submitScoreUpdate`. No new paths required.

### Event Payload Schema

```dart
// score_update event structure (consistent with EventModel.fromMap in game_state.dart)
{
  'type': 'score_update',
  'actorId': String,           // currentUserId (who triggered the action)
  'targetPlayerId': String,    // whose score is being updated
  'before': {
    'round': int,              // round number (1–5)
    'vpPrim': int?,            // null if first entry for this round
    'vpSec': int?,             // null if first entry for this round
  },
  'after': {
    'round': int,
    'vpPrim': int,             // always present on write
    'vpSec': int,
  },
  'timestamp': FieldValue.serverTimestamp(), // Timestamp on read
  'undone': false,
}
```

### Firestore Security Rules Coverage

Story 3.3 writes to:
- `rooms/{roomId}/events/` — covered by existing rule: "authenticated user can append new document to events subcollection"
- `rooms/{roomId}/players/{targetPlayerId}` — the batch writes to another player's document when the owner submits. Verify `firestore.rules` allows this. From story 1.3 ACs: "an authenticated user can read and write to their own `/rooms/{roomId}/players/{uid}` document". If the security rule restricts player writes to `request.auth.uid == uid`, the owner batch-updating another player's VP will be **rejected by Firestore Security Rules**.

**RESOLUTION**: The security rules must allow owner to update any player's document. Check `firestore.rules` — if the rule only allows `request.auth.uid == playerId`, the owner override won't work. The rule should be:
```
allow write: if request.auth.uid == playerId || request.auth.uid == get(/databases/$(database)/documents/rooms/$(roomId)).data.createdBy;
```
If the current rules are too restrictive, this story requires an update to `firestore.rules` AND a Firebase deploy. **Check `mobile/firestore.rules` before testing** and raise the discrepancy if blocking.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.3]
- [Source: _bmad-output/planning-artifacts/epics.md#UX Design Requirements UX-DR4, UX-DR10, UX-DR12, UX-DR19, UX-DR20]
- [Source: _bmad-output/planning-artifacts/architecture.md#Architectural Boundaries]
- [Source: _bmad-output/planning-artifacts/architecture.md#Data Flow]
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns]
- [Source: _bmad-output/implementation-artifacts/3-2-score-grid-widget-round-score-cell.md — Dev Agent Record (import depth, Table+Stack bug, test pattern)]
- [Source: _bmad-output/implementation-artifacts/3-1-game-domain-models-pure-business-rules.md — event_repository.dart interface]
- [Source: mobile/lib/features/game/data/event_repository.dart — appendEvent, GameException]
- [Source: mobile/lib/features/game/domain/game_rules.dart — canMutate()]
- [Source: mobile/lib/features/game/presentation/match_screen.dart — current state, RoomRepository usage]
- [Source: mobile/lib/features/game/presentation/widgets/round_score_cell.dart — RoundCellState, interface]
- [Source: mobile/lib/features/game/presentation/widgets/score_grid_widget.dart — onCellTap signature]
- [Source: mobile/lib/features/room/domain/models.dart — PlayerModel.vpByRound, PlayerModel.color]
- [Source: mobile/lib/core/firebase/firestore_paths.dart — FirestorePaths.events(), FirestorePaths.player()]
- [Source: mobile/firestore.rules — verify owner-override write permission on players/{playerId}]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6 (GitHub Copilot)

### Debug Log References

- Task 5 — spinner test replaced `Future.delayed(10s)` with `Completer<void>` to avoid pending-timer assertion in `flutter_test`.
- `_parseColor` already exists as `_colorFromHex` in `ScoreGridWidget` (private static); duplicated as `_parseColor` in `MatchScreen` (same logic, normalized hex with length check).

### Completion Notes List

- Task 1: `OwnershipLockFeedback` (`abstract final class`) créé avec `HapticFeedback.selectionClick()` + SnackBar flottant.
- Task 2: `RoundScoreEntrySheet` (`StatefulWidget`) créé avec factory `show()`, deux `TextFormField` numériques, `_handleConfirm()` avec try/catch, spinner de chargement.
- Task 3: `submitScoreUpdate()` ajouté à `EventRepository` via `WriteBatch` — atomic event append + dot-notation `vpByRound.$round` update.
- Task 4: `MatchScreen` câblé — imports ajoutés, `_handleCellTap` + `_parseColor` implémentés, `ScoreGridWidget` enveloppé dans `Builder`, placeholder `debugPrint` supprimé.
- Task 5: 3 suites de tests créées (13 tests nouveaux) — `round_score_entry_sheet_test.dart`, `match_screen_cell_tap_test.dart`; ownership_lock_feedback_test omis (optionnel selon story).
- Task 6: `flutter analyze` → `No issues found!`, `flutter test test/features/game/` → 42/42 ✅.

### File List

- `mobile/lib/features/game/presentation/widgets/ownership_lock_feedback.dart` — CREATE
- `mobile/lib/features/game/presentation/widgets/round_score_entry_sheet.dart` — CREATE
- `mobile/lib/features/game/data/event_repository.dart` — MODIFY (added `submitScoreUpdate`)
- `mobile/lib/features/game/presentation/match_screen.dart` — MODIFY (imports, `_handleCellTap`, `_parseColor`, Builder wrap)
- `mobile/test/features/game/widgets/round_score_entry_sheet_test.dart` — CREATE
- `mobile/test/features/game/presentation/match_screen_cell_tap_test.dart` — CREATE
