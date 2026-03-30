# Story 3.4: Score Hero Bar & Real-Time Score Broadcast

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player,
I want to see both players' cumulative VP totals prominently at the top of the match screen,
So that the current match standing is readable at a glance from across the table.

## Acceptance Criteria

1. **Given** the active match screen
   **When** `ScoreHeroBar` is rendered
   **Then** two large score totals are shown side by side in `Roboto Mono 56sp Bold`, each in the player's assigned color (UX-DR1)
   **And** scores are derived via `game_rules.vpTotal(vpByRound)` — never stored as a scalar aggregate
   **And** `ScoreHeroBar` is always visible at the top of the match screen without any navigation

2. **Given** a player on Client B updates their score via Story 3.3's `RoundScoreEntrySheet`
   **When** the Firestore batch write is confirmed
   **Then** Client A's `ScoreHeroBar` updates its total within the near-instant latency target (NFR4) via the existing `StreamBuilder<List<PlayerModel>>`
   **And** Client A's `ScoreGridWidget` also updates simultaneously (same stream — no additional wiring required)
   **And** the updated `RoundScoreCell` on **all** connected clients shows a 200ms opacity flash in the scoring player's color (UX-DR13)

## Tasks / Subtasks

- [x] Task 1 — Create `ScoreHeroBar` widget (AC: #1)
  - [x] Create `mobile/lib/features/game/presentation/widgets/score_hero_bar.dart`
  - [x] Declare `class ScoreHeroBar extends StatelessWidget`
  - [x] Constructor parameters:
    ```dart
    final PlayerModel player1;
    final PlayerModel player2;
    ```
  - [x] Import `package:flutter/material.dart`
  - [x] Import `package:google_fonts/google_fonts.dart`
  - [x] Import `../../../../core/utils/color_utils.dart` for `colorFromHex()`
  - [x] Import `../../../room/domain/models.dart` for `PlayerModel`
  - [x] Import `../../domain/game_rules.dart` for `vpTotal()`
  - [x] `build()` returns an `IntrinsicHeight` `Row` with:
    - `Expanded` child for Player 1 score panel
    - A 1px vertical divider using `_borderSubtle` color
    - `Expanded` child for Player 2 score panel
  - [x] Each score panel is a `Container` with:
    - Background color: `Color(0xFF161920)` (surface-card token)
    - Padding: `EdgeInsets.symmetric(vertical: 12, horizontal: 8)`
    - A `Column` (or `Center`) with:
      - **Score text**: `Text('${vpTotal(player.vpByRound)}')` styled with `GoogleFonts.robotoMono(fontSize: 56, fontWeight: FontWeight.bold, color: colorFromHex(player.color))`
      - **Player name**: `Text(player.name)` styled with `GoogleFonts.robotoCondensed(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFF5C6478))` (muted, uppercase)
    - `CrossAxisAlignment.center` alignment on the column
  - [x] Define private constants:
    ```dart
    static const Color _borderSubtle = Color(0xFF2A2F3E);
    ```
  - [x] No `print()` — use `debugPrint()` if needed
  - [x] Accessibility: Wrap the score `Text` in `Semantics(label: '${player.name}: ${vpTotal(player.vpByRound)} points')` (UX-DR18)

- [x] Task 2 — Add 200ms opacity flash animation to `RoundScoreCell` (AC: #2, UX-DR13)
  - [x] Modify `mobile/lib/features/game/presentation/widgets/round_score_cell.dart`
  - [x] Convert `RoundScoreCell` from `StatelessWidget` to `StatefulWidget` + `State<RoundScoreCell> with SingleTickerProviderStateMixin`
  - [x] Add constructor parameter `final bool flashOnUpdate` (default `false`) — only `filled` cells need animation
  - [x] In `_RoundScoreCellState`, declare:
    ```dart
    late final AnimationController _flashController;
    late final Animation<double> _flashOpacity;
    ```
  - [x] In `initState()`:
    ```dart
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _flashOpacity = Tween<double>(begin: 0.0, end: 0.4).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
    ```
  - [x] In `dispose()`: `_flashController.dispose();`
  - [x] Override `didUpdateWidget(RoundScoreCell oldWidget)`:
    ```dart
    @override
    void didUpdateWidget(RoundScoreCell oldWidget) {
      super.didUpdateWidget(oldWidget);
      // Trigger flash when vpPrim or vpSec changes while in filled state
      if (widget.flashOnUpdate &&
          widget.state == RoundCellState.filled &&
          (widget.vpPrim != oldWidget.vpPrim || widget.vpSec != oldWidget.vpSec)) {
        _flashController.forward(from: 0.0).then((_) => _flashController.reverse());
      }
    }
    ```
  - [x] In `build()`, wrap the existing `GestureDetector` in an `AnimatedBuilder`:
    ```dart
    @override
    Widget build(BuildContext context) {
      return AnimatedBuilder(
        animation: _flashOpacity,
        builder: (context, child) {
          return Stack(
            children: [
              child!,
              if (_flashController.isAnimating || _flashController.value > 0)
                Positioned.fill(
                  child: ColoredBox(
                    color: widget.playerColor.withValues(alpha: _flashOpacity.value),
                  ),
                ),
            ],
          );
        },
        child: GestureDetector(
          onTap: _isInteractive ? widget.onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _minTouchSize,
              minHeight: _minTouchSize,
            ),
            child: _buildCell(),
          ),
        ),
      );
    }
    ```
  - [x] **CRITICAL**: All references to `state`, `vpPrim`, `vpSec`, `playerColor`, `onTap` inside `_state` and `_buildCell()` MUST be changed from `this.state/vpPrim/...` to `widget.state`, `widget.vpPrim`, `widget.vpSec`, `widget.playerColor`, `widget.onTap` since the class is now a State
  - [x] **CRITICAL**: `_isInteractive` must reference `widget.state`:
    ```dart
    bool get _isInteractive =>
        widget.state == RoundCellState.empty ||
        widget.state == RoundCellState.active ||
        widget.state == RoundCellState.locked;
    ```
  - [x] **CRITICAL**: `_buildCell()` must switch on `widget.state` and use `widget.vpPrim`, `widget.vpSec`, `widget.playerColor`
  - [x] Leave all existing styling constants unchanged (`_textMuted`, `_textPrimary`, `_surfaceCard`, `_minTouchSize`, `_borderRadius`)
  - [x] No new imports needed (AnimationController is from `flutter/material.dart`)
  - [x] EXISTING TESTS in `mobile/test/features/game/widgets/round_score_cell_test.dart` MUST still pass after conversion — the public API (constructor, `RoundCellState` enum) is unchanged

- [x] Task 3 — Wire `ScoreHeroBar` into `MatchScreen` and pass `flashOnUpdate` to cells (AC: #1, #2)
  - [x] Modify `mobile/lib/features/game/presentation/match_screen.dart`
  - [x] Add import:
    ```dart
    import 'widgets/score_hero_bar.dart';
    ```
  - [x] In the `Scaffold` body, add `ScoreHeroBar` above the `ScoreGridWidget`. Replace the current `SafeArea` body structure with:
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
        ],
      ),
    ),
    ```
  - [x] **`ScoreGridWidget` does NOT need changes for real-time updates**: the existing `StreamBuilder<List<PlayerModel>>` in `MatchScreen` already rebuilds the full widget tree (including `ScoreHeroBar` and `ScoreGridWidget`) on every Firestore player update. Real-time sync is already wired — just render correctly (NFR4 is satisfied by the existing stream architecture).
  - [x] **For flash animation**: `ScoreGridWidget` passes `flashOnUpdate: true` to `RoundScoreCell` for `filled` cells. Check `score_grid_widget.dart`'s `_buildDataRow` method and pass `flashOnUpdate: true` when calling `RoundScoreCell` — see Task 4.

- [x] Task 4 — Pass `flashOnUpdate: true` to filled `RoundScoreCell` in `ScoreGridWidget` (AC: #2, UX-DR13)
  - [x] Modify `mobile/lib/features/game/presentation/widgets/score_grid_widget.dart`
  - [x] Locate where `RoundScoreCell` is instantiated (inside `_buildDataRow`)
  - [x] Add `flashOnUpdate: state == RoundCellState.filled` to each `RoundScoreCell` constructor call
  - [x] Example:
    ```dart
    RoundScoreCell(
      state: state,
      roundNumber: round,
      playerColor: playerColor,
      vpPrim: vpPrim,
      vpSec: vpSec,
      flashOnUpdate: state == RoundCellState.filled,     // ← ADD THIS
      onTap: onCellTap != null ? () => onCellTap!(playerId, round) : null,
    )
    ```
  - [x] Since `ScoreGridWidget` is a `StatelessWidget` and rebuilds fully on stream change, `didUpdateWidget` in `RoundScoreCell` will be called with the updated VP values, triggering the flash automatically.
  - [x] EXISTING TESTS in `mobile/test/features/game/widgets/score_grid_widget_test.dart` MUST still pass.

- [x] Task 5 — Write widget tests for `ScoreHeroBar` (AC: #1)
  - [x] Create `mobile/test/features/game/widgets/score_hero_bar_test.dart`
  - [x] Setup: use `WidgetTester`, wrap in `MaterialApp` with dark theme
  - [x] Test: `ScoreHeroBar` renders Player 1's name and VP total in their color
  - [x] Test: `ScoreHeroBar` renders Player 2's name and VP total in their color
  - [x] Test: VP total is 0 when `vpByRound` is empty (`{}`)
  - [x] Test: VP total correctly sums across multiple rounds (e.g. `{'1': {'prim': 3, 'sec': 7}, '2': {'prim': 5, 'sec': 2}}` → 17)
  - [x] Test: score text font is 56sp (check `TextStyle` on the widget via finder and style inspection)
  - [x] **Helper to build mock `PlayerModel`**:
    ```dart
    PlayerModel _makePlayer({
      String id = 'uid1',
      String name = 'Alice',
      String color = '#4FC3F7',
      Map<String, Map<String, int>> vpByRound = const {},
    }) => PlayerModel(
      id: id, name: name, role: RoleEnum.player,
      cp: 0, vpByRound: vpByRound, connected: true, color: color,
    );
    ```

- [x] Task 6 — Write widget tests for `RoundScoreCell` flash animation (AC: #2)
  - [x] Modify (or extend) `mobile/test/features/game/widgets/round_score_cell_test.dart`
  - [x] Test: `flashOnUpdate: false` — `didUpdateWidget` with changed VP does NOT trigger animation
  - [x] Test: `flashOnUpdate: true` + state `filled` + VP change → animation controller triggers (verify via `pump` + `pumpAndSettle`)
  - [x] Test: `flashOnUpdate: true` + state NOT `filled` → animation does NOT trigger even if widget updates
  - [x] **CRITICAL**: All 21 existing tests from story 3.2 MUST still pass after the `StatelessWidget` → `StatefulWidget` conversion — the public constructor API is identical.

- [x] Task 7 — Verify `flutter analyze` + all tests pass (AC: all)
  - [x] Run `flutter analyze` from `mobile/` — must report `No issues found!`
  - [x] Run `flutter test test/features/game/widgets/` — all tests pass (including 21 existing round_score_cell tests and existing score_grid tests)
  - [x] Run `flutter test test/features/game/` — all tests pass

## Dev Notes

### Architecture Compliance — CRITICAL RULES

| Rule | Detail | Source |
|------|--------|--------|
| VP total is always derived | `vpTotal()` from `game_rules.dart` — NEVER store or pass a scalar VP aggregate | [Source: architecture.md#Data Architecture] |
| Feature isolation | `score_hero_bar.dart` imports `models.dart` from `features/room/domain/` — this is permitted because it lives in `features/game` which depends on `features/room`. No import in the reverse direction. | [Source: architecture.md#Architectural Boundaries] |
| `colorFromHex()` is the shared utility | DO NOT add another hex→Color conversion function. Use `colorFromHex()` from `core/utils/color_utils.dart` exclusively. | [Source: 3-3 dev notes — `_parseColor()` duplication warning] |
| StreamBuilder native | Real-time updates come for free from `MatchScreen`'s existing `StreamBuilder<List<PlayerModel>>`. No extra stream wiring needed for `ScoreHeroBar`. | [Source: architecture.md#State Management] |
| No `print()` | `debugPrint()` only — `analysis_options.yaml` enforces `avoid_print: true` | [Source: analysis_options.yaml] |
| Test mirror structure | Tests in `mobile/test/` must mirror `mobile/lib/` exactly. New test: `test/features/game/widgets/score_hero_bar_test.dart` | [Source: architecture.md] |
| `RoundScoreCell` conversion safety | After `StatelessWidget` → `StatefulWidget` conversion, the **public constructor** is unchanged. All existing tests that build `RoundScoreCell(...)` continue to work. Only the internal class body changes. | Internal |

### Project Structure — Files to Create / Modify

```
mobile/
├── lib/
│   └── features/
│       └── game/
│           └── presentation/
│               ├── match_screen.dart                        ← MODIFY: add ScoreHeroBar, restructure body Column
│               └── widgets/
│                   ├── score_hero_bar.dart                  ← CREATE (Task 1)
│                   ├── round_score_cell.dart                ← MODIFY: StatelessWidget → StatefulWidget + flash (Task 2)
│                   └── score_grid_widget.dart               ← MODIFY: pass flashOnUpdate to RoundScoreCell (Task 4)
└── test/
    └── features/
        └── game/
            └── widgets/
                ├── score_hero_bar_test.dart                 ← CREATE (Task 5)
                ├── round_score_cell_test.dart               ← MODIFY: add flash animation tests (Task 6)
                └── score_grid_widget_test.dart              ← DO NOT MODIFY (tests must still pass)
```

**Already exists — do NOT recreate or break:**
- `mobile/lib/features/game/domain/game_rules.dart` — `vpTotal()` already implemented, do NOT modify
- `mobile/lib/core/utils/color_utils.dart` — `colorFromHex()` already implemented, do NOT add another
- `mobile/lib/features/game/data/event_repository.dart` — no changes needed in this story
- `mobile/lib/features/room/domain/models.dart` — `PlayerModel` with `vpByRound`, `color`, `name` already defined

### Import Paths — Critical Depth Reference

**`score_hero_bar.dart`** is at `mobile/lib/features/game/presentation/widgets/`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/color_utils.dart';       // → lib/core/utils/color_utils.dart
import '../../../room/domain/models.dart';              // → lib/features/room/domain/models.dart
import '../../domain/game_rules.dart';                  // → lib/features/game/domain/game_rules.dart
```

**`match_screen.dart`** is at `mobile/lib/features/game/presentation/`:
```dart
import 'widgets/score_hero_bar.dart';                   // ← ADD (same dir widgets/)
// Already present:
import '../../../core/utils/color_utils.dart';
import '../../room/data/room_repository.dart';
import '../../room/domain/models.dart';
import '../data/event_repository.dart';
import '../domain/game_rules.dart';
import 'widgets/ownership_lock_feedback.dart';
import 'widgets/round_score_entry_sheet.dart';
import 'widgets/score_grid_widget.dart';
```

**`round_score_cell.dart`** is at `mobile/lib/features/game/presentation/widgets/` — no import changes needed (AnimationController is from `flutter/material.dart`, already imported).

### `vpTotal()` — Function Signature (do NOT re-implement)

```dart
// From mobile/lib/features/game/domain/game_rules.dart (already implemented)
int vpTotal(Map<String, Map<String, int>> vpByRound)
// Sums all prim + sec values across all rounds. Returns 0 for empty map.
// Example: {'1': {'prim': 3, 'sec': 7}, '2': {'prim': 5, 'sec': 2}} → 17
```

### `colorFromHex()` — Already in `core/utils/color_utils.dart`

```dart
// DO NOT CREATE A NEW HELPER — use this:
Color colorFromHex(String hex)
// '#4FC3F7' → Color(0xFF4FC3F7)
// '4FC3F7'  → Color(0xFF4FC3F7)  (handles both with and without #)
```

### Why Real-Time Updates Are Already Wired

The `MatchScreen` uses `StreamBuilder<List<PlayerModel>>` which listens to `RoomRepository.streamPlayers(roomId)` — a Firestore real-time stream. When **any** player's `vpByRound` is updated via `EventRepository.submitScoreUpdate()` (Story 3.3), the stream emits a new snapshot, `MatchScreen` rebuilds, and **both** `ScoreHeroBar` and `ScoreGridWidget` receive the new player data automatically.

**No additional Firestore subscriptions or state lifting is required for story 3.4.**

The 200ms flash in `RoundScoreCell` is triggered by `didUpdateWidget` when Flutter's widget reconciliation detects that the cell has new `vpPrim`/`vpSec` values during a rebuild — which happens precisely when the Firestore stream delivers updated data.

### `PlayerModel` Fields Reference (relevant to this story)

```dart
// From mobile/lib/features/room/domain/models.dart
class PlayerModel {
  final String id;
  final String name;
  final RoleEnum role;
  final int cp;
  final Map<String, Map<String, int>> vpByRound;  // e.g. {'1': {'prim': 3, 'sec': 7}}
  final bool connected;
  final String color;  // hex string, e.g. '#4FC3F7' (P1) or '#EF5350' (P2)
  // ... fromFirestore(), toMap(), copyWith()
}
```

### `withValues(alpha: ...)` vs `withOpacity(...)`

Flutter 3.27+ deprecates `Color.withOpacity()` in favor of `Color.withValues(alpha: ...)`. Use `withValues(alpha: value)` to avoid lint warnings:
```dart
widget.playerColor.withValues(alpha: _flashOpacity.value)
```

### Design Tokens Used in This Story

| Token | Value | Usage |
|-------|-------|-------|
| `surface-card` | `Color(0xFF161920)` | `ScoreHeroBar` panel background |
| `border-subtle` | `Color(0xFF2A2F3E)` | Vertical divider between scores |
| Player 1 color | `#4FC3F7` | Score text color for P1 |
| Player 2 color | `#EF5350` | Score text color for P2 |
| Text muted | `Color(0xFF5C6478)` | Player name label under score |

### `ScoreGridWidget._buildDataRow` — Where to Add `flashOnUpdate`

Look for the method that creates a `TableRow` per round. It calls `RoundScoreCell(...)` for each player/type combination. The `state` variable is already computed per cell — just add `flashOnUpdate: state == RoundCellState.filled` to the constructor positional/named args.

### Regression Safety Checklist

Before completing, verify:
- [ ] `flutter analyze` → `No issues found!`
- [ ] All 21 existing `round_score_cell_test.dart` tests pass (from story 3.2)
- [ ] All existing `score_grid_widget_test.dart` tests pass (from story 3.2)
- [ ] All existing `match_screen_cell_tap_test.dart` tests pass (from story 3.3)
- [ ] `round_score_entry_sheet_test.dart` tests pass (from story 3.3)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (GitHub Copilot)

### Debug Log References

No blockers encountered. All tasks implemented cleanly.

### Completion Notes List

- **Task 1**: Created `score_hero_bar.dart` as a `StatelessWidget`. Uses `IntrinsicHeight` + `Row` for side-by-side panels separated by a 1px `_borderSubtle` divider. VP total derived via `vpTotal()` from `game_rules.dart`. Semantics label wraps each score Text for accessibility (UX-DR18). No extra `colorFromHex()` added — reused from `core/utils/color_utils.dart`.
- **Task 2**: Converted `RoundScoreCell` from `StatelessWidget` to `StatefulWidget` with `SingleTickerProviderStateMixin`. Added `flashOnUpdate` parameter (default `false`). `didUpdateWidget` triggers a 200ms easeOut opacity flash when `vpPrim`/`vpSec` changes on a `filled` cell. Used `withValues(alpha: ...)` per Flutter 3.27+ deprecation of `withOpacity()`. All existing tests continue to pass — public constructor API unchanged.
- **Task 3**: Added `import 'widgets/score_hero_bar.dart'` to `match_screen.dart`. Restructured `SafeArea` body to a `Column` with `ScoreHeroBar` above the `Expanded` `ScoreGridWidget`. No extra Firestore wiring needed — existing `StreamBuilder<List<PlayerModel>>` already drives rebuilds.
- **Task 4**: Added `flashOnUpdate: state == RoundCellState.filled` to `RoundScoreCell` constructor in `ScoreGridWidget._buildPlayerCell`. Existing `score_grid_widget_test.dart` passes without modification.
- **Tasks 5 & 6**: Created `score_hero_bar_test.dart` (5 tests) and added a `flash animation` group to `round_score_cell_test.dart` (3 tests). All 50 game feature tests pass.
- **Task 7**: `flutter analyze` → `No issues found!`. `flutter test test/features/game/` → 50 tests, all passed.

### File List

- `mobile/lib/features/game/presentation/widgets/score_hero_bar.dart` — CREATED
- `mobile/lib/features/game/presentation/widgets/round_score_cell.dart` — MODIFIED (StatelessWidget → StatefulWidget, flash animation)
- `mobile/lib/features/game/presentation/match_screen.dart` — MODIFIED (ScoreHeroBar wired, body restructured)
- `mobile/lib/features/game/presentation/widgets/score_grid_widget.dart` — MODIFIED (flashOnUpdate added)
- `mobile/test/features/game/widgets/score_hero_bar_test.dart` — CREATED
- `mobile/test/features/game/widgets/round_score_cell_test.dart` — MODIFIED (3 flash animation tests added)
