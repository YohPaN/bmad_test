# Story 2.6: Players Screen — Connected Participants View

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a participant,
I want to see all connected players and their presence status on the Players tab,
So that I can identify who is in the room at any time during the match.

## Acceptance Criteria

1. **Given** the Players tab (tab 2, `players_screen.dart`) is active  
   **When** the screen renders  
   **Then** a list of all room participants is displayed, one row per player  
   **And** each row shows a `PlayerPresenceBadge` with the player's name, assigned color, and online/offline status (UX-DR7)  
   **And** the list is visible to all participants (not owner-only)

2. **Given** a player connects or disconnects while the Players screen is open  
   **When** the Firestore `streamPlayers(roomId)` updates  
   **Then** the affected player's presence indicator updates in real time without requiring navigation or refresh

3. **Given** the Players screen is open during an active match  
   **When** the current user is a non-owner participant  
   **Then** no ownership management controls are visible (those are in the Room tab, tab 3)

## Tasks / Subtasks

- [x] Task 1 — Create `players_screen.dart` (AC: #1, #2, #3)
  - [x] `StatefulWidget` `PlayersScreen` with `roomId` constructor param
  - [x] `StreamBuilder<List<PlayerModel>>` on `_repo.streamPlayers(widget.roomId)`
  - [x] Render one `PlayerPresenceBadge` per player with `playerName`, `playerColor`, `isOnline`, `isOwner`
  - [x] Skeleton shimmer loading state when stream has no data yet (UX-DR17)
  - [x] Error state with descriptive text (no crash)
  - [x] Empty state with "Aucun joueur connecté." label
  - [x] Include private `_hexToColor()` helper (same pattern as `room_management_screen.dart`)
  - [x] Zero ownership management UI (no transfer/close/leave buttons)

- [x] Task 2 — Wire tab 2 in `AppShell._buildBody()` (AC: #1, #2)
  - [x] Replace `const Center(child: Text('Joueurs — coming soon'))` with `PlayersScreen(roomId: widget.roomId)`
  - [x] Add `import '../features/room/presentation/players_screen.dart';` to `app.dart`

- [x] Task 3 — Write unit tests (AC: all)
  - [x] Create `mobile/test/features/room/players_screen_test.dart`
  - [x] Test: renders `PlayerPresenceBadge` for each player in the stream
  - [x] Test: online/offline status correctly reflected per `PlayerModel.connected`
  - [x] Test: owner badge shown for player with `role == RoleEnum.owner`
  - [x] Test: no ownership management button rendered at all

- [x] Task 4 — Verify `flutter analyze` reports zero errors (AC: all)
  - [x] Run `flutter analyze` from `mobile/` — must report `No issues found!`

## Dev Notes

### Starting Point — Confirmed State at Story 2.6 Start

These files are **CONFIRMED present and fully implemented** (all of Stories 2.1–2.5 are `done`):

| File | Status | Notes |
|------|--------|-------|
| `mobile/lib/app/app.dart` | ✅ Complete | `AppShell` has `roomId` param. Tab 2 body is currently `const Center(child: Text('Joueurs — coming soon'))`. **Must be updated in this story.** |
| `mobile/lib/features/room/data/room_repository.dart` | ✅ Complete | Exposes `streamPlayers(String roomId)` → `Stream<List<PlayerModel>>`. Also has `currentUserId`. **No new methods needed.** |
| `mobile/lib/features/room/domain/models.dart` | ✅ Complete | `PlayerModel`: `id`, `name`, `role` (`RoleEnum.owner`/`player`), `cp`, `vpByRound`, `connected` (bool), `color` (hex String). **No changes needed.** |
| `mobile/lib/features/room/presentation/widgets/player_presence_badge.dart` | ✅ Complete | Constructor: `playerName` (String), `playerColor` (Color), `isOnline` (bool), `isOwner` (bool). Already has `Semantics` label. **Reuse as-is.** |
| `mobile/lib/features/room/presentation/room_management_screen.dart` | ✅ Complete | Contains `_hexToColor()` private static helper — **copy the exact same pattern** into `players_screen.dart`. |
| `mobile/lib/core/firebase/firestore_paths.dart` | ✅ Complete | `players(roomId)` returns the correct collection ref. Used internally by `RoomRepository`. **Do not call directly from UI.** |
| `mobile/pubspec.yaml` | ✅ Complete | `cloud_firestore: ^5.6.7`, `firebase_auth: ^5.5.2`, `firebase_core: ^3.13.1`. **No new packages needed.** No shimmer package exists — implement skeleton with Flutter primitives only. |
| `mobile/analysis_options.yaml` | ✅ Active | `avoid_print: true` enforced — use `debugPrint()`, never `print()`. |

**Files to CREATE in this story:**
- `mobile/lib/features/room/presentation/players_screen.dart` — new Players tab screen
- `mobile/test/features/room/players_screen_test.dart` — unit tests

**Files to MODIFY in this story:**
- `mobile/lib/app/app.dart` — wire tab 2 body to `PlayersScreen`

**Files NOT to touch (zero changes):**
- `mobile/lib/features/room/data/room_repository.dart`
- `mobile/lib/features/room/domain/models.dart`
- `mobile/lib/features/room/presentation/widgets/player_presence_badge.dart`
- `mobile/lib/core/firebase/firestore_paths.dart`
- `mobile/firestore.rules` — existing rules cover all read operations already
- `mobile/pubspec.yaml`
- `mobile/lib/main.dart`

---

### Design Token Colors (from UX-DR11)

| Token | Value | Use |
|-------|-------|-----|
| `background` | `#0D0F14` | Screen background |
| `surface-card` | `#161920` | List tile background |
| `surface-elevated` | `#1E2330` | Elevated elements |
| `border` | `#2A2F3E` | Dividers, skeleton placeholders |
| text-primary | `#E8EAF0` | Player name text |
| text-muted | `#8A9BB8` | Empty state text |
| P1 accent | `#4FC3F7` | Player 1 color |
| P2 accent | `#EF5350` | Player 2 color |
| online | `#4CAF50` | Online dot in `PlayerPresenceBadge` |
| offline | `#5C6478` | Offline dot in `PlayerPresenceBadge` |

---

### UX Constraints

- **UX-DR7:** `PlayerPresenceBadge` is the required widget per player — do not create a custom row widget.
- **UX-DR17:** Skeleton shimmer while stream is loading — **no** `CircularProgressIndicator` or `LinearProgressIndicator`. Use a pulsing opacity animation (see implementation below).
- **UX-DR18:** `PlayerPresenceBadge` already wraps everything in a `Semantics` widget — no additional wrapping needed.
- **UX-DR19:** Minimum 48×48dp touch targets — `PlayerPresenceBadge` already has `ConstrainedBox(constraints: BoxConstraints(minWidth: 48, minHeight: 48))`. Add `EdgeInsets.symmetric(vertical: 8)` padding around each row for UX-DR19 compliance.
- **UX-DR20:** 1px hairline `Divider(color: Color(0xFF2A2F3E), height: 1)` between rows.
- **No owner-only controls** — AC3 enforced by simply not adding any ownership-related widgets.

---

### Task 1 — Full `players_screen.dart` Implementation

Create new file `mobile/lib/features/room/presentation/players_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../data/room_repository.dart';
import '../domain/models.dart';
import 'widgets/player_presence_badge.dart';

class PlayersScreen extends StatefulWidget {
  final String roomId;
  const PlayersScreen({super.key, required this.roomId});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _repo = RoomRepository();

  static Color _hexToColor(String hex) {
    try {
      final value = hex.replaceFirst('#', '');
      return Color(int.parse('FF$value', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PlayerModel>>(
      stream: _repo.streamPlayers(widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Erreur de chargement des joueurs.',
              style: TextStyle(color: Color(0xFFE8EAF0)),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const _SkeletonPlayerList();
        }

        final players = snapshot.data!;

        if (players.isEmpty) {
          return const Center(
            child: Text(
              'Aucun joueur connecté.',
              style: TextStyle(color: Color(0xFF8A9BB8)),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: players.length,
          separatorBuilder: (_, __) => const Divider(
            color: Color(0xFF2A2F3E),
            height: 1,
          ),
          itemBuilder: (context, index) {
            final player = players[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: PlayerPresenceBadge(
                playerName: player.name,
                playerColor: _hexToColor(player.color),
                isOnline: player.connected,
                isOwner: player.role == RoleEnum.owner,
              ),
            );
          },
        );
      },
    );
  }
}

// ── Skeleton shimmer (UX-DR17: no blocking spinners) ─────────────────────────

class _SkeletonPlayerList extends StatefulWidget {
  const _SkeletonPlayerList();

  @override
  State<_SkeletonPlayerList> createState() => _SkeletonPlayerListState();
}

class _SkeletonPlayerListState extends State<_SkeletonPlayerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.25, end: 0.55).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: 3,
          separatorBuilder: (_, __) => const Divider(
            color: Color(0xFF2A2F3E),
            height: 1,
          ),
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Opacity(
              opacity: _opacity.value,
              child: Row(
                children: [
                  // Avatar placeholder
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF2A2F3E),
                  ),
                  const SizedBox(width: 12),
                  // Name placeholder
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2F3E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
```

> **Why `StatefulWidget` and not `StatelessWidget`?** The `RoomRepository()` instance is stored in state so it is not recreated on every widget rebuild — same pattern as `RoomManagementScreen` in Story 2.5. This avoids unnecessary Firestore listener churn.

> **Why `_SkeletonPlayerList` is a separate `StatefulWidget`?** The `AnimationController` requires a `TickerProvider` mixin. Extracting it to a separate stateful widget keeps `_PlayersScreenState.build()` clean and avoids mixing concerns. The controller is properly disposed in `dispose()` to prevent memory leaks.

> **Why no `currentUserId` call here?** AC3 ("no ownership management controls") is satisfied structurally — the screen never renders any ownership-related widget, regardless of the current user's role. There is no need to check who the current user is; ownership controls simply do not exist in this widget.

---

### Task 2 — `AppShell._buildBody()` Update in `app.dart`

**In `mobile/lib/app/app.dart`, update the import section:**

```dart
// ADD this import (after existing imports):
import '../features/room/presentation/players_screen.dart';
```

**In `_buildBody()`, replace case 2:**

```dart
// BEFORE:
case 2:
  return const Center(child: Text('Joueurs — coming soon'));

// AFTER:
case 2:
  return PlayersScreen(roomId: widget.roomId);
```

Only these two changes are needed in `app.dart`. All other lines remain untouched.

---

### Task 3 — Unit Tests

Create `mobile/test/features/room/players_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Note: Since RoomRepository relies on Firebase, unit-test PlayersScreen
// by injecting a fake stream via a thin wrapper or by testing the widget
// rendering in isolation using a mock. Use testWidgets with a pumped widget
// tree providing the MaterialApp wrapper and a mock stream.
//
// The test approach:
// 1. Build a minimal MaterialApp wrapping a StreamBuilder<List<PlayerModel>>
//    that directly provides the data (bypassing RoomRepository).
// 2. Verify that PlayerPresenceBadge is rendered per player.
// 3. Verify no ownership management controls appear.
//
// IMPORTANT: Since PlayersScreen uses RoomRepository internally (which requires
// Firebase), prefer testing the rendering logic directly by constructing
// PlayerPresenceBadge instances inline, or by wrapping in a widget that
// replaces the StreamBuilder stream with a known test stream.

void main() {
  // Test the _hexToColor logic indirectly via color output validation.
  group('PlayersScreen rendering', () {
    testWidgets('renders PlayerPresenceBadge for each player', (tester) async {
      final players = [
        _fakePlayer(id: 'u1', name: 'Alice', color: '#4FC3F7', connected: true, role: 'owner'),
        _fakePlayer(id: 'u2', name: 'Bob', color: '#EF5350', connected: false, role: 'player'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _PlayersListView(players: players),
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows owner badge for owner player', (tester) async {
      final players = [
        _fakePlayer(id: 'u1', name: 'Alice', color: '#4FC3F7', connected: true, role: 'owner'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _PlayersListView(players: players),
          ),
        ),
      );

      // PlayerPresenceBadge uses Semantics label that includes "propriétaire"
      expect(find.bySemanticsLabel(RegExp('propriétaire')), findsOneWidget);
    });

    testWidgets('shows no ownership management controls', (tester) async {
      final players = [
        _fakePlayer(id: 'u1', name: 'Alice', color: '#4FC3F7', connected: true, role: 'owner'),
        _fakePlayer(id: 'u2', name: 'Bob', color: '#EF5350', connected: false, role: 'player'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _PlayersListView(players: players),
          ),
        ),
      );

      // No transfer, close, or leave controls
      expect(find.text('Transférer'), findsNothing);
      expect(find.text('Terminer le match'), findsNothing);
      expect(find.text('Quitter la room'), findsNothing);
    });

    testWidgets('shows empty state when player list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _PlayersListView(players: []),
          ),
        ),
      );

      expect(find.text('Aucun joueur connecté.'), findsOneWidget);
    });
  });
}

// ── Test helpers ──────────────────────────────────────────────────────────────

PlayerModel _fakePlayer({
  required String id,
  required String name,
  required String color,
  required bool connected,
  required String role,
}) {
  return PlayerModel.fromMap(id, {
    'name': name,
    'role': role,
    'cp': 0,
    'vpByRound': <String, dynamic>{},
    'connected': connected,
    'color': color,
  });
}

/// Testable rendering layer that mirrors PlayersScreen's list-rendering logic
/// without requiring Firebase initialization.
class _PlayersListView extends StatelessWidget {
  final List<PlayerModel> players;
  const _PlayersListView({required this.players});

  static Color _hexToColor(String hex) {
    try {
      final value = hex.replaceFirst('#', '');
      return Color(int.parse('FF$value', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return const Center(
        child: Text(
          'Aucun joueur connecté.',
          style: TextStyle(color: Color(0xFF8A9BB8)),
        ),
      );
    }
    return ListView.separated(
      itemCount: players.length,
      separatorBuilder: (_, __) => const Divider(color: Color(0xFF2A2F3E), height: 1),
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: PlayerPresenceBadge(
          playerName: players[i].name,
          playerColor: _hexToColor(players[i].color),
          isOnline: players[i].connected,
          isOwner: players[i].role == RoleEnum.owner,
        ),
      ),
    );
  }
}
```

> **Why `_PlayersListView` test helper instead of testing `PlayersScreen` directly?** `PlayersScreen` depends on `RoomRepository`, which requires Firebase initialization. Rather than setting up the full Firebase emulator for unit tests, the rendering logic is extracted into a testable helper that mirrors the real implementation. This is consistent with how Story 2.1 tests `RoomModel.fromFirestore` logic — isolate from Firebase for unit tests, save integration tests for `mobile/integration_test/`.

---

### Firestore Security Rules — NO CHANGES NEEDED ✅

The `streamPlayers(roomId)` is a **read** operation on `rooms/{roomId}/players/`. The existing `firestore.rules` already allows any authenticated user to read player documents within a room they have access to. No rule amendment required.

---

### Previous Story Intelligence (from Story 2.5)

| Pattern | What 2.5 established | Apply in 2.6 |
|---------|---------------------|--------------|
| `_hexToColor()` | Private static helper in `RoomManagementScreen` | **Copy exact same implementation** into `PlayersScreen` |
| `StatefulWidget` + `RoomRepository()` in state | Prevents listener churn on rebuilds | **Same pattern** in `PlayersScreen` |
| `StreamBuilder<List<PlayerModel>>` | Wraps player list stream | **Same pattern** in `PlayersScreen` |
| `PlayerPresenceBadge` | Renders player name, color, online/offline | **Same widget**, same props mapping |
| `_navigationTriggered` guard | Room closure navigation — owned by `AppShell` | **Not needed** in `PlayersScreen` (no navigation logic here) |
| `debugPrint()` over `print()` | Analysis option enforcement | **Apply** in any error logging |

---

### Architecture Compliance Checklist

- [ ] No hardcoded Firestore path strings — all paths via `RoomRepository` → `FirestorePaths`
- [ ] No feature-to-feature imports — `players_screen.dart` only imports from `features/room/` and `core/`
- [ ] No external state management packages — `StreamBuilder` only
- [ ] `debugPrint()` used, never `print()`
- [ ] Test file at `mobile/test/features/room/players_screen_test.dart` (mirrors lib structure)
- [ ] `flutter analyze` reports zero errors after implementation

### References

- Epic requirements: [_bmad-output/planning-artifacts/epics.md — Story 2.6](../../_bmad-output/planning-artifacts/epics.md)
- UX-DR7 (PlayerPresenceBadge), UX-DR17 (skeleton shimmer), UX-DR18-20: [_bmad-output/planning-artifacts/ux-design-specification.md](../../_bmad-output/planning-artifacts/ux-design-specification.md)
- `PlayerPresenceBadge` widget API: [mobile/lib/features/room/presentation/widgets/player_presence_badge.dart](../../mobile/lib/features/room/presentation/widgets/player_presence_badge.dart)
- `RoomRepository.streamPlayers`: [mobile/lib/features/room/data/room_repository.dart#L110](../../mobile/lib/features/room/data/room_repository.dart)
- `AppShell._buildBody()` tab 2 placeholder: [mobile/lib/app/app.dart](../../mobile/lib/app/app.dart)
- Design token colors and typography: [_bmad-output/planning-artifacts/ux-design-specification.md — UX-DR11, UX-DR12](../../_bmad-output/planning-artifacts/ux-design-specification.md)
- Previous story patterns (2.5): [_bmad-output/implementation-artifacts/2-5-player-presence-room-management-screen.md](2-5-player-presence-room-management-screen.md)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6

### Debug Log References

No blockers encountered.

### Completion Notes List

- Task 1: Created `mobile/lib/features/room/presentation/players_screen.dart` — `StatefulWidget` with `StreamBuilder<List<PlayerModel>>`, `_hexToColor()` helper copied from `RoomManagementScreen`, `_SkeletonPlayerList` extracted to its own `StatefulWidget` to cleanly isolate the `AnimationController` with `SingleTickerProviderStateMixin`, all three states (loading/empty/list) implemented. Zero ownership controls per AC3.
- Task 2: Updated `mobile/lib/app/app.dart` — added import and replaced `case 2` placeholder with `PlayersScreen(roomId: widget.roomId)`. Only two lines changed, all other code untouched.
- Task 3: Created `mobile/test/features/room/players_screen_test.dart` — 5 tests using `_PlayersListView` helper to bypass Firebase dependency. Tests cover: multi-player render, online/offline semantics, owner badge, no ownership controls, empty state.
- Task 4: `flutter analyze` → `No issues found!`. All 5 unit tests pass.

### File List

- `mobile/lib/features/room/presentation/players_screen.dart` — CREATED
- `mobile/lib/app/app.dart` — MODIFIED (import + case 2)
- `mobile/test/features/room/players_screen_test.dart` — CREATED
