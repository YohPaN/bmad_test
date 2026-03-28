# Story 3.2: Score Grid Widget & Round Score Cell

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player,
I want to see the full 5-round score grid for both players side by side,
So that the complete match scoring state is visible at a glance without any navigation.

## Acceptance Criteria

1. **Given** the match screen with an active room  
   **When** `ScoreGridWidget` is rendered  
   **Then** a grid with 5 round rows and columns for Player 1 (VP Prim, VP Sec) and Player 2 (VP Prim, VP Sec) plus a total column is displayed  
   **And** the grid fits within the screen width without horizontal scroll on devices ≥ 360dp (UX-DR2)

2. **Given** `RoundScoreCell` for a past round with data  
   **When** rendered  
   **Then** it displays VP Prim and VP Sec on two lines with total below in `Roboto Mono 20sp` (state: `filled`)

3. **Given** `RoundScoreCell` for the current active round  
   **When** rendered  
   **Then** it shows a colored outline in the owning player's color (state: `active`)

4. **Given** `RoundScoreCell` for a future round  
   **When** rendered  
   **Then** it is grayed out with `text-muted` color (`#5C6478`) and non-interactive (state: `future`)

5. **Given** a cell owned by another player and the current user is not the room owner  
   **When** rendered  
   **Then** a lock icon (12px, 0.3 opacity) is shown in the top-right corner (state: `locked`, UX-DR16)

## Tasks / Subtasks

- [x] Task 1 — Define `RoundCellState` enum (AC: #2, #3, #4, #5)
  - [x] Create `mobile/lib/features/game/presentation/widgets/round_score_cell.dart`
  - [x] Define `enum RoundCellState { empty, active, filled, locked, future }`
  - [x] Implement `RoundScoreCell` stateless widget accepting: `state` (RoundCellState), `roundNumber` (int), `vpPrim` (int?), `vpSec` (int?), `playerColor` (Color), `onTap` (VoidCallback?)
  - [x] **`empty` state**: transparent background, `—` placeholder in `text-muted` (#5C6478), tappable if it's the current user's active cell
  - [x] **`active` state**: 1px border in `playerColor`, subtle surface-card background (#161920); tappable
  - [x] **`filled` state**: display `Prim: X` + `Sec: X` on two lines + `Tot: X` below; all in Roboto Mono 20sp / 14sp; not interactable (already filled — tapping re-opens entry in story 3.3)
  - [x] **`locked` state**: show lock icon `Icons.lock` at 12px size, opacity 0.3 in the top-right corner (UX-DR16); tap calls `onTap` (which triggers `OwnershipLockFeedback` — placeholder in this story, connected in 3.3)
  - [x] **`future` state**: entire cell grayed out — text labels in `#5C6478`; `onTap` is null / no-op
  - [x] All touch targets: minimum 48×48dp (UX-DR19)
  - [x] Border radius 4dp on cell containers (UX-DR20)

- [x] Task 2 — Implement `ScoreGridWidget` (AC: #1)
  - [x] Create `mobile/lib/features/game/presentation/widgets/score_grid_widget.dart`
  - [x] Widget accepts: `players` (List<PlayerModel>, exactly 2), `activeRound` (int, 1–5), `currentUserId` (String), `isOwner` (bool), `onCellTap` (void Function(String playerId, int round)?)
  - [x] Layout: header row (Round | P1 Prim | P1 Sec | P2 Prim | P2 Sec | P1 Total | P2 Total) + 5 data rows
  - [x] Must use `IntrinsicHeight` or fixed column widths to fit on ≥360dp screen without `SingleChildScrollView` horizontal scroll (UX-DR2)
  - [x] Use `Table` widget or `Row`/`Column` structure with `Flexible`/`Expanded` assignments — test that total width ≤ 360dp
  - [x] For each player × round combination: derive `RoundCellState`:
    - `round < activeRound` → `filled` if data exists, `empty` if no data
    - `round == activeRound` → `active` if currentUserId == player.id OR isOwner; `locked` if currentUserId != player.id AND NOT isOwner
    - `round > activeRound` → `future`
  - [x] Background: `surface-card` (#161920) for grid container, `border-subtle` (#2A2F3E) hairline 1px separators
  - [x] Section header labels in Roboto Condensed 11sp uppercase, letter-spacing +1.5 (UX-DR12)
  - [x] Total column: derives VP total via per-round prim+sec computation from `vpByRound` — NEVER store VP as scalar

- [x] Task 3 — Create `MatchScreen` scaffold (AC: #1)
  - [x] Create `mobile/lib/features/game/presentation/match_screen.dart`
  - [x] Widget accepts: `roomId` (String), `currentUserId` (String)
  - [x] Uses `StreamBuilder` on `RoomRepository().streamRoom(roomId)` and `RoomRepository().streamPlayers(roomId)`
  - [x] When both streams have data: display `ScoreGridWidget` with correct `activeRound`, `currentUserId`, `isOwner` (derived from `room.createdBy == currentUserId`)
  - [x] While loading: `CircularProgressIndicator` (skeleton shimmer deferred to story 3.4 per UX-DR17)
  - [x] `onCellTap` callback: placeholder (connected to bottom sheet in story 3.3) — for now `debugPrint('Cell tapped: $playerId round $round')`
  - [x] Background color: `#0D0F14` (surface-bg)
  - [x] No `print()` calls — only `debugPrint()`

- [x] Task 4 — Wire `MatchScreen` into `AppShell` tab 0 (AC: #1)
  - [x] Modify `mobile/lib/app/app.dart`
  - [x] Add import for `MatchScreen` (do NOT import from `features/room` inside `features/game` — cross-feature via `app.dart` only)
  - [x] In `_buildBody()` case 0: replace `Center(child: Text('Match — coming soon'))` with `MatchScreen(roomId: widget.roomId, currentUserId: currentUserId)` where `currentUserId` is obtained from `FirebaseAuth.instance.currentUser?.uid ?? ''`
  - [x] Add `firebase_auth` import to `app.dart`

- [x] Task 5 — Write widget tests (AC: #1–#5)
  - [x] Create `mobile/test/features/game/widgets/round_score_cell_test.dart`
  - [x] Test `empty` state: renders `—` placeholder, no lock icon
  - [x] Test `active` state: Container has border with `playerColor`, no lock icon, tappable
  - [x] Test `filled` state: displays VP Prim, VP Sec, and total values
  - [x] Test `locked` state: `Icons.lock` icon present with opacity 0.3
  - [x] Test `future` state: text in `#5C6478`, `onTap` is null (tap does nothing)
  - [x] Create `mobile/test/features/game/widgets/score_grid_widget_test.dart`
  - [x] Test grid renders 5 rows (for rounds 1–5)
  - [x] Test `isOwner=false, currentUserId != playerId` → `locked` state for opponent's active cell
  - [x] Test `isOwner=true` → `active` state for any player's current round cell
  - [x] Test total column uses `vpTotal()` derived value (no stored scalar)

- [x] Task 6 — Verify `flutter analyze` + all tests pass (AC: all)
  - [x] Run `flutter analyze` from `mobile/` — must report `No issues found!`
  - [x] Run `flutter test test/features/game/widgets/` — all tests pass

## Dev Notes

### Architecture Compliance — CRITICAL RULES

| Rule | Detail | Source |
|------|--------|--------|
| Feature isolation | `features/game` must NOT import from `features/room` directly — `RoomRepository` used only in `MatchScreen` which is wired via `app.dart` | [Source: architecture.md#Architectural Boundaries] |
| No `print()` | Use `debugPrint()` only | [Source: analysis_options.yaml] |
| `firestore_paths.dart` only | No hardcoded Firestore path strings — `RoomRepository` already handles this | [Source: architecture.md#Structure Patterns] |
| VP total = derived | Always `game_rules.vpTotal(player.vpByRound)` — never a stored scalar VP field | [Source: architecture.md#Data Architecture] |
| StreamBuilder pattern | No external state management — native `StreamBuilder` on Firestore streams | [Source: architecture.md#State Management] |
| Test mirror structure | Widget tests go in `mobile/test/features/game/widgets/` | [Source: architecture.md] |
| No horizontal scroll | `ScoreGridWidget` must fit in ≤360dp width — use fixed column widths, not scrollable | [Source: UX-DR2] |
| 2-step confirmation | NOT needed for score entry (1 tap) — only for undo (story 4.x) | [Source: architecture.md#Process Patterns] |

### Project Structure — Files for This Story

```
mobile/
├── lib/
│   ├── app/
│   │   └── app.dart                              ← MODIFY: wire MatchScreen into tab 0
│   └── features/
│       └── game/
│           └── presentation/
│               ├── match_screen.dart              ← CREATE (Task 3)
│               └── widgets/
│                   ├── round_score_cell.dart      ← CREATE (Task 1)
│                   └── score_grid_widget.dart     ← CREATE (Task 2)
└── test/
    └── features/
        └── game/
            └── widgets/                           ← CREATE directory
                ├── round_score_cell_test.dart     ← CREATE (Task 5)
                └── score_grid_widget_test.dart    ← CREATE (Task 5)
```

**Already exists — do NOT recreate:**
- `mobile/lib/features/game/presentation/.gitkeep` → delete the `.gitkeep` when creating `match_screen.dart`
- `mobile/lib/features/game/presentation/widgets/.gitkeep` → delete when creating widget files

**Do NOT touch these files:**
- `mobile/lib/features/game/domain/game_rules.dart`
- `mobile/lib/features/game/domain/game_state.dart`
- `mobile/lib/features/game/data/event_repository.dart`
- `mobile/lib/features/room/domain/models.dart`
- `mobile/lib/features/room/data/room_repository.dart`

### Theme Tokens — Exact Values

| Token | Value | Usage in this story |
|-------|-------|---------------------|
| `surface-bg` | `#0D0F14` | `MatchScreen` scaffold background |
| `surface-card` | `#161920` | `ScoreGridWidget` container |
| `border-subtle` | `#2A2F3E` | Grid cell separators (1px) |
| `text-muted` | `#5C6478` | `future` state cell text, header labels |
| `text-primary` | `#E8EAF0` | `filled` state values |
| Player 1 color | `#4FC3F7` | Imperial Blue — active border, filled text accent |
| Player 2 color | `#EF5350` | Crimson — active border, filled text accent |

### `RoundCellState` Derivation Logic

```dart
RoundCellState _cellState({
  required int round,
  required int activeRound,
  required String playerId,
  required String currentUserId,
  required bool isOwner,
  required bool hasData,
}) {
  if (round > activeRound) return RoundCellState.future;
  if (round < activeRound) return hasData ? RoundCellState.filled : RoundCellState.empty;
  // round == activeRound:
  if (currentUserId == playerId || isOwner) return RoundCellState.active;
  return RoundCellState.locked;
}
```

### `RoundScoreCell` — Interface Signature

```dart
enum RoundCellState { empty, active, filled, locked, future }

class RoundScoreCell extends StatelessWidget {
  final RoundCellState state;
  final int roundNumber;
  final int? vpPrim;     // null if no data yet
  final int? vpSec;      // null if no data yet
  final Color playerColor;
  final VoidCallback? onTap; // null for future/locked-non-interactive states; called by ScoreGridWidget

  const RoundScoreCell({
    super.key,
    required this.state,
    required this.roundNumber,
    required this.playerColor,
    this.vpPrim,
    this.vpSec,
    this.onTap,
  });
}
```

### `ScoreGridWidget` — Interface Signature

```dart
class ScoreGridWidget extends StatelessWidget {
  final List<PlayerModel> players;   // exactly 2 players expected
  final int activeRound;             // 1–5; from RoomModel.currentRound
  final String currentUserId;        // FirebaseAuth.instance.currentUser?.uid
  final bool isOwner;                // room.createdBy == currentUserId
  final void Function(String playerId, int round)? onCellTap;

  const ScoreGridWidget({
    super.key,
    required this.players,
    required this.activeRound,
    required this.currentUserId,
    required this.isOwner,
    this.onCellTap,
  });
}
```

### `MatchScreen` — Interface Signature

```dart
class MatchScreen extends StatelessWidget {
  final String roomId;
  final String currentUserId;

  const MatchScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
  });
}
```

### ScoreGridWidget Layout Guidance (fit ≤360dp)

At 360dp screen width, the grid has:  
- 1 round label column (~40dp)  
- 2 VP columns per player × 2 players = 4 VP columns (~50dp each = 200dp)  
- 2 total columns, one per player (~55dp each = 110dp)  
Total: 40 + 200 + 110 = 350dp ≈ fits on 360dp  

Use `Table` with `columnWidths`:
```dart
columnWidths: const {
  0: FixedColumnWidth(36),   // Round label
  1: FlexColumnWidth(1),     // P1 Prim
  2: FlexColumnWidth(1),     // P1 Sec
  3: FlexColumnWidth(1),     // P2 Prim
  4: FlexColumnWidth(1),     // P2 Sec
  5: FixedColumnWidth(50),   // P1 Total
  6: FixedColumnWidth(50),   // P2 Total
}
```
Or use `Flex`/`FractionallySizedBox`. **Key constraint**: DO NOT wrap in `SingleChildScrollView` with horizontal scrolling per UX-DR2.

### Typography in `ScoreGridWidget` and `RoundScoreCell`

```dart
// Cell VP values (filled state)
TextStyle(fontFamily: 'RobotoMono', fontSize: 14, fontWeight: FontWeight.w500)

// Cell total (filled state, smaller)
TextStyle(fontFamily: 'RobotoMono', fontSize: 12, color: textPrimaryColor)

// Grid header labels
TextStyle(
  fontFamily: 'RobotoCondensed',
  fontSize: 11,
  fontWeight: FontWeight.bold,
  letterSpacing: 1.5,
  color: textMutedColor,
)
```

Note: `RobotoMono` and `RobotoCondensed` are NOT bundled in Flutter by default. Use `google_fonts` package OR declare them in `pubspec.yaml` assets. **Check `pubspec.yaml` first** — if `google_fonts` is not already present, add it. The architecture's 56sp hero scores (Story 3.4) also need Roboto Mono.

### `app.dart` Change — `_buildBody()` case 0

```dart
// BEFORE:
case 0:
  return const Center(child: Text('Match — coming soon'));

// AFTER (app.dart already imports firebase_auth — add import if missing):
case 0:
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return MatchScreen(roomId: widget.roomId, currentUserId: uid);
```

Import to add to `app.dart`:
```dart
import 'package:firebase_auth/firebase_auth.dart';
import '../features/game/presentation/match_screen.dart';
```

### Previous Story Intelligence (Story 3.1 learnings)

From Story 3.1 implementation:
- **Repository exception classes**: `GameException` in `event_repository.dart` mirrors `RoomException` in `room_repository.dart`. Widget stories do NOT need new exception classes.
- **`game_rules.vpTotal()`** is confirmed working (`mobile/lib/features/game/domain/game_rules.dart`). Use it directly — do NOT reimplement VP summing logic in widgets.
- **`GameState.fromStreams()`** takes `RoomModel`, `List<PlayerModel>`, `List<EventModel>` — `MatchScreen` may use it OR stream room+players separately (simpler for this story since events are not yet displayed on match screen).
- **Test pattern**: `flutter_test` only — no Mockito needed for widget-only tests; use plain constructors with mock data.
- Stream pattern: `StreamBuilder<List<PlayerModel>>` via `RoomRepository().streamPlayers(roomId)`.

### `PlayerModel` Reference (from `models.dart`, do NOT modify)

```dart
class PlayerModel {
  final String id;           // Firebase UID
  final String name;
  final RoleEnum role;       // owner / player
  final int cp;
  final Map<String, Map<String, int>> vpByRound; // {'1': {'prim': 3, 'sec': 7}, ...}
  final bool connected;
  final String color;        // hex string e.g. '#4FC3F7'
}
```

To derive cell VP data for round N:
```dart
final roundData = player.vpByRound[roundNumber.toString()];
final vpPrim = roundData?['prim'];
final vpSec  = roundData?['sec'];
final hasData = roundData != null;
```

Total VP via pure function (NEVER stored scalar):
```dart
import '../../../domain/game_rules.dart';
final total = vpTotal(player.vpByRound);
```

### UX-DR16 — Lock Icon Implementation

```dart
// In RoundScoreCell for state == RoundCellState.locked:
Stack(
  children: [
    // cell content (grayed out or empty)
    Positioned(
      top: 4,
      right: 4,
      child: Opacity(
        opacity: 0.3,
        child: Icon(Icons.lock, size: 12, color: Colors.white),
      ),
    ),
  ],
)
```

Tap on locked cell calls `onTap` (which will trigger `OwnershipLockFeedback` in story 3.3). In this story, `onTap` for locked cells is a placeholder: `debugPrint('Locked cell tapped')`.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.2]
- [Source: _bmad-output/planning-artifacts/epics.md#UX Design Requirements UX-DR2, UX-DR3, UX-DR16, UX-DR18, UX-DR19, UX-DR20]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Defining Core Interaction]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Visual Foundation]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Component Strategy — ScoreGridWidget, RoundScoreCell]
- [Source: _bmad-output/planning-artifacts/architecture.md#Project Structure & Boundaries]
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns]
- [Source: mobile/lib/features/room/domain/models.dart — PlayerModel, RoomModel]
- [Source: mobile/lib/features/game/domain/game_rules.dart — vpTotal()]
- [Source: mobile/lib/features/room/data/room_repository.dart — streamRoom(), streamPlayers()]
- [Source: mobile/lib/app/app.dart — AppShell, _buildBody() tab 0]
- [Source: _bmad-output/implementation-artifacts/3-1-game-domain-models-pure-business-rules.md — Dev Notes]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6 (GitHub Copilot)

### Debug Log References

- Replaced `SizedBox.expand()` (inside Table cells) with `SizedBox.shrink()` for the `active` state and restructured `locked` state from `Stack(Positioned)` to `Row(MainAxisAlignment.end)` — Flutter's `Table` measures cells with unbounded height, causing Stack with only Positioned children to attempt infinite height.
- Fixed import path depth: `match_screen.dart` (at `presentation/`) needs `../../room/...` (2 levels up to `features/`), while `score_grid_widget.dart` (at `presentation/widgets/`) correctly uses `../../../room/...` (3 levels up).

### Completion Notes List

- ✅ `RoundCellState` enum + `RoundScoreCell` widget created with all 5 states, 48×48dp min touch targets, 4dp border radius.
- ✅ `ScoreGridWidget` implemented with `Table` and fixed column widths (fits ≤360dp, no horizontal scroll). Header uses Roboto Condensed 11sp uppercase. Total column derives prim+sec per round from `vpByRound` (no stored scalar).
- ✅ `MatchScreen` created with nested `StreamBuilder` on room + players. Placeholder `onCellTap` with `debugPrint`.
- ✅ `AppShell` tab 0 wired to `MatchScreen` with `FirebaseAuth.instance.currentUser?.uid`.
- ✅ `google_fonts: ^6.2.1` added to `pubspec.yaml` for Roboto Mono / Roboto Condensed.
- ✅ `flutter analyze`: No issues found. `flutter test test/features/game/widgets/`: 21/21 tests pass.

### File List

- `mobile/pubspec.yaml` (modified — added google_fonts dependency)
- `mobile/lib/app/app.dart` (modified — wired MatchScreen into tab 0)
- `mobile/lib/features/game/presentation/match_screen.dart` (created)
- `mobile/lib/features/game/presentation/widgets/round_score_cell.dart` (created)
- `mobile/lib/features/game/presentation/widgets/score_grid_widget.dart` (created)
- `mobile/test/features/game/widgets/round_score_cell_test.dart` (created)
- `mobile/test/features/game/widgets/score_grid_widget_test.dart` (created)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — story status updated)

## Change Log

- 2026-03-28: Story implemented — RoundScoreCell (5 states), ScoreGridWidget (7-col Table layout), MatchScreen (StreamBuilder scaffold), AppShell Tab 0 wired. Added google_fonts dependency. 21/21 tests pass, flutter analyze clean. Status → review.
