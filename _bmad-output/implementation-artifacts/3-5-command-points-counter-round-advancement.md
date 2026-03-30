# Story 3.5: Command Points Counter & Round Advancement

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player,
I want to increment or decrement my Command Points from the main match screen and advance the round,
So that CP management never interrupts the flow of play.

## Acceptance Criteria

1. **Given** the active match screen
   **When** `ResourceCounter` is rendered for each player's CP
   **Then** the counter displays the current CP value with `+` and `−` buttons (min 40dp wide × 48dp tall, UX-DR5)
   **And** the CP strip is always visible without any navigation

2. **Given** a player taps `+` or `−` on their own CP counter
   **When** the tap is registered
   **Then** a `cp_adjust` event is appended to `rooms/{id}/events/` with `before` and `after` values
   **And** `PlayerModel.cp` is updated in Firestore
   **And** `HapticFeedback.lightImpact()` is triggered
   **And** all clients see the updated CP value in real time

3. **Given** a non-owner attempts to tap another player's CP counter
   **When** the tap is registered
   **Then** `OwnershipLockFeedback` triggers and no Firestore write occurs

4. **Given** the owner taps "Avancer le round" (round advancement control)
   **When** the action is confirmed
   **Then** `rooms/{id}.currentRound` is incremented by 1
   **And** `game_rules.autoIncrementCp()` is applied to all players: each player's CP is increased by +1
   **And** a `turn_advance` event is appended to `rooms/{id}/events/`
   **And** all clients receive the round update and the ScoreGrid highlights the new active round cells

## Tasks / Subtasks

- [x] Task 1 — Create `ResourceCounter` widget (AC: #1, #2, #3, UX-DR5)
  - [x] Create `mobile/lib/features/game/presentation/widgets/resource_counter.dart`
  - [x] Declare `class ResourceCounter extends StatelessWidget`
  - [x] Constructor parameters:
    ```dart
    final String label;       // e.g. 'CP'
    final int value;
    final Color playerColor;
    final VoidCallback? onIncrement;  // null → locked state (non-owner)
    final VoidCallback? onDecrement;  // null → locked state (non-owner)
    ```
  - [ ] Imports:
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter/services.dart';
    ```
  - [ ] `build()` returns a `Row` with:
    - `_CounterButton` for `−`: `onTap: onDecrement`, icon `Icons.remove`
    - `SizedBox(width: 8)`
    - `Column` with:
      - `Text(label)` styled with `GoogleFonts.robotoCondensed(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF5C6478))`
      - `Text('$value')` styled with `GoogleFonts.robotoMono(fontSize: 28, fontWeight: FontWeight.bold, color: playerColor)`
    - `SizedBox(width: 8)`
    - `_CounterButton` for `+`: `onTap: onIncrement`, icon `Icons.add`
  - [ ] Define private `_CounterButton` widget (StatelessWidget):
    ```dart
    class _CounterButton extends StatelessWidget {
      final IconData icon;
      final VoidCallback? onTap;
      const _CounterButton({required this.icon, required this.onTap});

      @override
      Widget build(BuildContext context) {
        return GestureDetector(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
            child: ColoredBox(
              color: const Color(0xFF161920),
              child: Icon(
                icon,
                color: onTap != null ? Colors.white : const Color(0xFF5C6478),
                size: 20,
              ),
            ),
          ),
        );
      }
    }
    ```
  - [ ] `HapticFeedback.lightImpact()` is called from the **callback site** in `MatchScreen` (not inside `ResourceCounter`), so the widget stays pure/testable
  - [ ] Accessibility: wrap each `_CounterButton` inner content in `Semantics(label: onTap != null ? (icon == Icons.add ? '${label} + 1' : '${label} - 1') : '${label} bouton verrouillé')`
  - [ ] No `print()` — `debugPrint()` only

- [ ] Task 2 — Add `submitCpAdjust` to `EventRepository` (AC: #2)
  - [ ] Modify `mobile/lib/features/game/data/event_repository.dart`
  - [ ] Add method:
    ```dart
    /// Appends a cp_adjust event and updates the player's cp atomically.
    ///
    /// Uses a [WriteBatch] to ensure the event write and the cp update
    /// succeed or fail together.
    Future<void> submitCpAdjust({
      required String roomId,
      required String actorId,
      required String targetPlayerId,
      required int beforeCp,
      required int afterCp,
    }) async {
      try {
        final batch = FirebaseFirestore.instance.batch();

        final eventRef = FirestorePaths.events(roomId).doc();
        batch.set(eventRef, {
          'type': 'cp_adjust',
          'actorId': actorId,
          'targetPlayerId': targetPlayerId,
          'before': {'cp': beforeCp},
          'after': {'cp': afterCp},
          'timestamp': FieldValue.serverTimestamp(),
          'undone': false,
        });

        final playerRef = FirestorePaths.player(roomId, targetPlayerId);
        batch.update(playerRef, {'cp': afterCp});

        await batch.commit();
      } on FirebaseException catch (e) {
        throw GameException('Failed to submit CP adjust: ${e.message}');
      } catch (e) {
        throw GameException('Failed to submit CP adjust: $e');
      }
    }
    ```
  - [ ] No new imports needed (FirebaseFirestore, FieldValue, FirestorePaths, GameException are already imported)

- [ ] Task 3 — Add `submitTurnAdvance` to `EventRepository` (AC: #4)
  - [ ] Modify `mobile/lib/features/game/data/event_repository.dart`
  - [ ] Add method:
    ```dart
    /// Increments room.currentRound, applies +1 CP to all players, and appends
    /// a turn_advance event — all in a single [WriteBatch].
    Future<void> submitTurnAdvance({
      required String roomId,
      required int currentRound,
      required String actorId,
      required List<({String playerId, int beforeCp, int afterCp})> cpChanges,
    }) async {
      try {
        final batch = FirebaseFirestore.instance.batch();

        // 1. Increment round
        final roomRef = FirestorePaths.room(roomId);
        batch.update(roomRef, {'currentRound': currentRound + 1});

        // 2. Update each player's CP
        for (final change in cpChanges) {
          batch.update(
            FirestorePaths.player(roomId, change.playerId),
            {'cp': change.afterCp},
          );
        }

        // 3. Append turn_advance event
        final eventRef = FirestorePaths.events(roomId).doc();
        batch.set(eventRef, {
          'type': 'turn_advance',
          'actorId': actorId,
          'targetPlayerId': null,
          'before': {'round': currentRound},
          'after': {'round': currentRound + 1},
          'timestamp': FieldValue.serverTimestamp(),
          'undone': false,
        });

        await batch.commit();
      } on FirebaseException catch (e) {
        throw GameException('Failed to submit turn advance: ${e.message}');
      } catch (e) {
        throw GameException('Failed to submit turn advance: $e');
      }
    }
    ```
  - [ ] No new imports needed

- [ ] Task 4 — Wire `ResourceCounter` into `MatchScreen` and add "Avancer le round" button (AC: #1, #2, #3, #4)
  - [ ] Modify `mobile/lib/features/game/presentation/match_screen.dart`
  - [ ] Add import:
    ```dart
    import 'package:flutter/services.dart';
    import 'widgets/resource_counter.dart';
    ```
  - [ ] Add private methods to `MatchScreen`:
    ```dart
    void _handleCpAdjust({
      required BuildContext context,
      required RoomModel room,
      required PlayerModel player,
      required int delta,          // +1 or -1
    }) {
      if (!canMutate(currentUserId, room.createdBy, player.id)) {
        OwnershipLockFeedback.trigger(context);
        return;
      }
      HapticFeedback.lightImpact();
      EventRepository().submitCpAdjust(
        roomId: room.id,
        actorId: currentUserId,
        targetPlayerId: player.id,
        beforeCp: player.cp,
        afterCp: player.cp + delta,
      );
    }

    void _handleTurnAdvance({
      required BuildContext context,
      required RoomModel room,
      required List<PlayerModel> players,
    }) {
      if (room.createdBy != currentUserId) {
        OwnershipLockFeedback.trigger(context);
        return;
      }
      final cpChanges = players
          .map(
            (p) => (
              playerId: p.id,
              beforeCp: p.cp,
              afterCp: autoIncrementCp(p).cp,
            ),
          )
          .toList();
      EventRepository().submitTurnAdvance(
        roomId: room.id,
        currentRound: room.currentRound,
        actorId: currentUserId,
        cpChanges: cpChanges,
      );
    }
    ```
  - [ ] In `build()`, replace the existing `Scaffold` body with a layout that includes the CP strips and round advancement button **below** the `ScoreGridWidget`. The new `Column` inside `SafeArea` becomes:
    ```dart
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScoreHeroBar(player1: players[0], player2: players[1]),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
          const SizedBox(height: 12),
          // CP strip — always visible
          Builder(
            builder: (innerContext) => _CpStrip(
              players: players,
              currentUserId: currentUserId,
              isOwner: isOwner,
              onIncrement: (player) => _handleCpAdjust(
                context: innerContext,
                room: room,
                player: player,
                delta: 1,
              ),
              onDecrement: (player) => _handleCpAdjust(
                context: innerContext,
                room: room,
                player: player,
                delta: -1,
              ),
            ),
          ),
          if (isOwner) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (innerContext) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: () => _handleTurnAdvance(
                    context: innerContext,
                    room: room,
                    players: players,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2330),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                  child: Text('Avancer le round (${room.currentRound})'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    ),
    ```
  - [ ] Add private `_CpStrip` widget class **at the bottom of `match_screen.dart`** (file-private, not exported):
    ```dart
    class _CpStrip extends StatelessWidget {
      final List<PlayerModel> players;
      final String currentUserId;
      final bool isOwner;
      final void Function(PlayerModel) onIncrement;
      final void Function(PlayerModel) onDecrement;

      const _CpStrip({
        required this.players,
        required this.currentUserId,
        required this.isOwner,
        required this.onIncrement,
        required this.onDecrement,
      });

      @override
      Widget build(BuildContext context) {
        return Container(
          color: const Color(0xFF161920),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: players.map((player) {
              final canEdit = isOwner || player.id == currentUserId;
              return ResourceCounter(
                label: 'CP',
                value: player.cp,
                playerColor: colorFromHex(player.color),
                onIncrement: canEdit ? () => onIncrement(player) : null,
                onDecrement: canEdit ? () => onDecrement(player) : null,
              );
            }).toList(),
          ),
        );
      }
    }
    ```
  - [ ] **CRITICAL**: `autoIncrementCp` is already imported via `game_rules.dart` — do NOT re-implement

- [ ] Task 5 — Write unit tests for `submitCpAdjust` and `submitTurnAdvance` (AC: #2, #4)
  - [ ] Create or extend `mobile/test/features/game/event_repository_test.dart`
  - [ ] Test `submitCpAdjust`:
    - Batch writes correct `cp_adjust` event fields (type, actorId, targetPlayerId, before.cp, after.cp, undone: false)
    - Batch updates player document with `cp: afterCp`
  - [ ] Test `submitTurnAdvance`:
    - Room document `currentRound` incremented by 1
    - Each player document `cp` set to `afterCp`
    - `turn_advance` event contains `before.round` and `after.round`
    - Event `undone: false`
  - [ ] Follow the existing mock pattern in the file (fake Firestore / `FakeFirebaseFirestore`)
  - [ ] Tests mirror path: `test/features/game/event_repository_test.dart`

- [ ] Task 6 — Write widget tests for `ResourceCounter` (AC: #1, #3)
  - [ ] Create `mobile/test/features/game/widgets/resource_counter_test.dart`
  - [ ] Setup: wrap in `MaterialApp` + dark theme
  - [ ] Test: displays CP value as string using Roboto Mono
  - [ ] Test: `+` button has minimum touch size ≥ 40dp wide × 48dp tall (UX-DR5)
  - [ ] Test: `−` button has minimum touch size ≥ 40dp wide × 48dp tall
  - [ ] Test: tapping `+` when `onIncrement` is `null` does not throw (locked state)
  - [ ] Test: tapping `+` when `onIncrement` is provided calls the callback
  - [ ] Test: tapping `−` when `onDecrement` is provided calls the callback
  - [ ] Test: widget renders with value `0`, `5`, and negative value without overflow

- [ ] Task 7 — Verify `flutter analyze` + all tests pass (AC: all)
  - [ ] Run `flutter analyze` from `mobile/` — must report `No issues found!`
  - [ ] Run `flutter test test/features/game/widgets/resource_counter_test.dart`
  - [ ] Run `flutter test test/features/game/event_repository_test.dart`
  - [ ] Run `flutter test test/features/game/` — all existing tests must still pass (including game_rules_test, score_hero_bar, score_grid, round_score_cell)

## Dev Notes

### Architecture Compliance — CRITICAL RULES

| Rule | Detail | Source |
|------|--------|--------|
| `autoIncrementCp()` is already implemented | Pure function in `game_rules.dart` — do NOT re-implement or duplicate. Call it from `_handleTurnAdvance` to derive `afterCp` for each player. | [Source: game_rules.dart] |
| `canMutate()` guard | Always call `canMutate(currentUserId, room.createdBy, player.id)` before any CP write. Already used in `_handleCellTap` — follow same pattern. | [Source: game_rules.dart, architecture.md#Ownership rule] |
| `firestore_paths.dart` exclusivity | `FirestorePaths.room(roomId)`, `FirestorePaths.player(roomId, uid)`, `FirestorePaths.events(roomId)` — all paths come from there. No hardcoded strings. | [Source: architecture.md#Data Boundaries] |
| Batch writes mandatory | CP adjust and turn advance both touch 2+ documents atomically — `WriteBatch` is required, as established in `submitScoreUpdate`. | [Source: event_repository.dart#submitScoreUpdate] |
| `google_fonts` for typography | `ResourceCounter` must use `GoogleFonts.robotoMono()` for the numeric value and `GoogleFonts.robotoCondensed()` for the label to match `ScoreHeroBar` conventions. | [Source: 3-4 dev notes, UX-DR12] |
| `colorFromHex()` only | Use `colorFromHex()` from `core/utils/color_utils.dart` for hex → Color conversion in `_CpStrip`. Do NOT add another converter. | [Source: 3-3 & 3-4 dev notes] |
| `HapticFeedback.lightImpact()` in `MatchScreen` | Haptic is fired in `_handleCpAdjust`, not inside `ResourceCounter`, so the widget remains a pure stateless widget testable without platform channels. | [Source: UX-DR5] |
| No `print()` | `debugPrint()` only — `analysis_options.yaml` enforces `avoid_print: true` | [Source: analysis_options.yaml] |
| StreamBuilder native | Real-time CP updates arrive automatically via the existing `StreamBuilder<List<PlayerModel>>` in `MatchScreen`. No additional stream wiring needed. | [Source: architecture.md#State Management] |
| `_CpStrip` and `_handleTurnAdvance` are file-private | They live in `match_screen.dart` and are not exported. Only `MatchScreen` is the public API. | [Source: architecture patterns] |
| Round advance is owner-only | Only the room owner can call "Avancer le round". The button is hidden for non-owners (`if (isOwner)`). `_handleTurnAdvance` also guards via `room.createdBy != currentUserId`. | [Source: epics.md#3.5 AC, FR12] |
| Turn advance max round guard | Epic defines 5 rounds max — guard against advancing past round 5: do not call `submitTurnAdvance` if `room.currentRound >= 5`. Disable or hide the button when `currentRound >= 5`. | [Source: UX-DR2 "5 rounds", game domain] |

### Project Structure — Files to Create / Modify

```
mobile/
├── lib/
│   └── features/
│       └── game/
│           ├── data/
│           │   └── event_repository.dart             ← MODIFY: add submitCpAdjust, submitTurnAdvance
│           └── presentation/
│               ├── match_screen.dart                 ← MODIFY: add CP strip, round advancement, _CpStrip
│               └── widgets/
│                   └── resource_counter.dart         ← CREATE (Task 1)
└── test/
    └── features/
        └── game/
            ├── event_repository_test.dart            ← MODIFY: add cp_adjust + turn_advance tests
            └── widgets/
                └── resource_counter_test.dart        ← CREATE (Task 6)
```

**Already exists — do NOT recreate or break:**
- `mobile/lib/features/game/domain/game_rules.dart` — `autoIncrementCp()`, `canMutate()`, `vpTotal()` implemented
- `mobile/lib/core/utils/color_utils.dart` — `colorFromHex()` implemented
- `mobile/lib/features/game/presentation/widgets/score_hero_bar.dart` — do not modify
- `mobile/lib/features/game/presentation/widgets/score_grid_widget.dart` — do not modify
- `mobile/lib/features/game/presentation/widgets/round_score_cell.dart` — do not modify
- `mobile/lib/features/game/presentation/widgets/ownership_lock_feedback.dart` — reuse as-is
- `mobile/lib/features/game/data/event_repository.dart` — existing `submitScoreUpdate`, `appendEvent`, `streamEvents` must NOT be modified, only new methods added

### Import Paths — Critical Depth Reference

**`resource_counter.dart`** is at `mobile/lib/features/game/presentation/widgets/`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
```
(no cross-feature imports needed — ResourceCounter receives all data via constructor)

**`match_screen.dart`** is at `mobile/lib/features/game/presentation/`:
```dart
// Already present:
import 'package:flutter/material.dart';
import '../../../core/utils/color_utils.dart';
import '../../room/data/room_repository.dart';
import '../../room/domain/models.dart';
import '../data/event_repository.dart';
import '../domain/game_rules.dart';
import 'widgets/ownership_lock_feedback.dart';
import 'widgets/round_score_entry_sheet.dart';
import 'widgets/score_grid_widget.dart';
import 'widgets/score_hero_bar.dart';

// ADD:
import 'package:flutter/services.dart';
import 'widgets/resource_counter.dart';
```

**`event_repository.dart`** is at `mobile/lib/features/game/data/`:
```dart
// Already present — no new imports needed:
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase/firestore_paths.dart';
import '../domain/game_state.dart';   // contains GameException
```

### `autoIncrementCp()` — Function Signature (do NOT re-implement)

```dart
// Already in mobile/lib/features/game/domain/game_rules.dart
PlayerModel autoIncrementCp(PlayerModel player)
// Returns a new PlayerModel with cp incremented by +1.
// Pure function — no side effects.
```

**Usage in `_handleTurnAdvance`:**
```dart
final cpChanges = players
    .map((p) => (
          playerId: p.id,
          beforeCp: p.cp,
          afterCp: autoIncrementCp(p).cp,   // ← ALWAYS use this, never p.cp + 1 directly
        ))
    .toList();
```

### Event Schema — `cp_adjust` and `turn_advance`

```
// cp_adjust event (canonical per architecture.md)
{
  type: 'cp_adjust',
  actorId: <uid>,
  targetPlayerId: <uid>,
  before: { cp: <int> },
  after:  { cp: <int> },
  timestamp: <ServerTimestamp>,
  undone: false
}

// turn_advance event (canonical per architecture.md)
{
  type: 'turn_advance',
  actorId: <uid>,
  targetPlayerId: null,
  before: { round: <int> },
  after:  { round: <int+1> },
  timestamp: <ServerTimestamp>,
  undone: false
}
```

### UX Notes

- **CP strip placement**: below `ScoreGridWidget`, always visible without scrolling (UX-DR5 "always visible on match screen without navigation")
- **`+`/`−` buttons**: `ConstrainedBox(minWidth: 40, minHeight: 48)` — touch target compliance (UX-DR19)
- **"Avancer le round" button**: `ElevatedButton` with `minimumSize: Size.fromHeight(48)`. Shows current round number in label for context. **Hidden for non-owners** (`if (isOwner) ...`). Disabled or hidden when `currentRound >= 5`.
- **Color token reference**: `surface-card: #161920`, `surface-elevated: #1E2330`, `border: #2A2F3E`, `text-muted: #5C6478`
- **Typography tokens**: CP label → Roboto Condensed 11sp uppercase +1.5 letter-spacing; CP value → Roboto Mono 28sp bold in player color

### Previous Story Learnings (from 3-3 & 3-4)

- **`_parseColor()` duplication trap**: story 3-3 accidentally created a duplicate color parser. Always use `colorFromHex()` from `core/utils/color_utils.dart` — never add another hex→Color helper.
- **`widget.` prefix after StatefulWidget conversion**: story 3-4 had critical subtasks ensuring all state fields referenced via `widget.` prefix. `ResourceCounter` is `StatelessWidget` so this is not applicable here, but keep in mind if ever promoted.
- **`WriteBatch` pattern**: story 3-3 established the pattern — always use `WriteBatch` when writing multiple Firestore documents from a single user action. `submitCpAdjust` and `submitTurnAdvance` must follow this.
- **`OwnershipLockFeedback.trigger(context)` usage**: called with a `Builder`-scoped context to ensure `ScaffoldMessenger` is reachable. Use `Builder` wrapper around the CP strip as done for `ScoreGridWidget` in story 3-4.

### Referenced FR/NFR/UX-DR Coverage

| Item | Satisfied By |
|------|-------------|
| FR10 — Player updates own tracked resources | CP adjust via `submitCpAdjust` |
| FR11 — Owner updates any player's resources | `canMutate` guard allows owner override |
| FR12 — Round/turn progression | `submitTurnAdvance` increments `currentRound` |
| FR13 — Auto +1 CP on round advance | `autoIncrementCp()` applied to all players in `submitTurnAdvance` |
| FR14 — View current round context | Round number displayed in "Avancer le round" button label |
| NFR2 — In-match action < 30s | Batch write to Firestore, confirmed by existing latency targets |
| NFR4 — Near-instant realtime propagation | StreamBuilder on `streamPlayers` already wired in MatchScreen |
| NFR17 — Clear legible controls | 40×48dp minimum buttons, distinguishable `+`/`−` icons |
| UX-DR5 — ResourceCounter widget | `resource_counter.dart` with +/- buttons, haptic, always visible |

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-5

### Debug Log References

### Completion Notes List

- Story context created by bmad-create-story workflow on 2026-03-30

### File List
