# Story 2.5: Player Presence & Room Management Screen

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a room owner,
I want to see who is currently connected during the match and manage the room,
So that I can monitor participation and handle edge cases like ownership transfer or closing the room.

## Acceptance Criteria

1. **Given** the Room tab (tab 3, `room_management_screen.dart`)  
   **When** a player disconnects or reconnects  
   **Then** their `PlayerPresenceBadge` updates to reflect the new online/offline status in real time

2. **Given** the Room tab  
   **When** the owner views the screen  
   **Then** each player entry shows name, color badge, and online/offline presence indicator  
   **And** an ownership transfer control is visible only to the current owner

3. **Given** the owner triggers ownership transfer to another player  
   **When** the transfer is confirmed via the confirmation dialog  
   **Then** `rooms/{id}.createdBy` is updated to the new owner's `uid`  
   **And** the new owner's `PlayerModel.role` is updated to `owner`  
   **And** the previous owner's role is updated to `player`

4. **Given** the owner taps "Terminer le match"  
   **When** the action is confirmed via the confirmation dialog  
   **Then** `rooms/{id}.status` is updated to `closed`  
   **And** all clients receive the status change via `AppShell`'s `streamRoom` listener and are navigated back to the home screen (`LobbyScreen`)

5. **Given** any participant (non-owner)  
   **When** they tap "Quitter la room" and confirm  
   **Then** their `PlayerModel.connected` is set to `false`  
   **And** other participants' presence views update accordingly  
   **And** the quitting player is navigated back to the home screen (`LobbyScreen`)  
   **And** the remaining session is unaffected

## Tasks / Subtasks

- [x] Task 1 — Add 3 new methods to `RoomRepository` (AC: #3, #4, #5)
  - [x] Add `transferOwnership(String roomId, String newOwnerUid)` — batch: update `rooms/{id}.createdBy`, set old owner role → `player`, set new owner role → `owner`
  - [x] Add `closeRoom(String roomId)` — update `rooms/{id}.status` → `'closed'`
  - [x] Add `leaveRoom(String roomId)` — update current player's `connected` → `false`

- [x] Task 2 — Update `AppShell` in `app.dart` (AC: #4)
  - [x] Add `roomId` constructor parameter: `final String roomId;`
  - [x] Add `final _repo = RoomRepository();` to `_AppShellState`
  - [x] Wrap `Scaffold` in `StreamBuilder<RoomModel?>` on `_repo.streamRoom(widget.roomId)`
  - [x] On `room.status == RoomStatus.closed` → `WidgetsBinding.instance.addPostFrameCallback` → `Navigator.pushAndRemoveUntil` to `LobbyScreen`
  - [x] Wire tab 3 body to `RoomManagementScreen(roomId: widget.roomId)` in `_buildBody()` helper
  - [x] Add required imports: `room_repository.dart`, `models.dart`, `room_management_screen.dart`

- [x] Task 3 — Update `lobby_screen.dart` navigation (AC: #4)
  - [x] Change `const AppShell()` → `AppShell(roomId: _roomId!)` in the auto-navigation post-frame callback

- [x] Task 4 — Create `room_management_screen.dart` (AC: #1, #2, #3, #4, #5)
  - [x] `StatefulWidget` `RoomManagementScreen` with `roomId` constructor param
  - [x] `StreamBuilder<RoomModel?>` outer + `StreamBuilder<List<PlayerModel>>` inner
  - [x] Render player list: `PlayerPresenceBadge` per player, name, color, online/offline
  - [x] Owner-only: transfer button per non-owner player → confirmation `AlertDialog` → `_repo.transferOwnership()`
  - [x] Owner-only: "Terminer le match" button → confirmation `AlertDialog` → `_repo.closeRoom()`
  - [x] Non-owner: "Quitter la room" button → confirmation `AlertDialog` → `_repo.leaveRoom()` → `Navigator.pushAndRemoveUntil` to `LobbyScreen`
  - [x] Add `_hexToColor()` private static helper

- [x] Task 5 — Verify `flutter analyze` reports zero errors (AC: all)
  - [x] Run `flutter analyze` from `mobile/` — must report `No issues found!`

## Dev Notes

### Starting Point — State of Repository at Story 2.5 Start

These files are **CONFIRMED present and fully implemented** (from Stories 2.1–2.4):

| File | Status | Notes |
|------|--------|-------|
| `mobile/lib/app/app.dart` | ✅ Complete | `AppShell` is **public** (renamed in 2.4). Has 4 tabs as skeleton. NO `roomId` param yet — added in this story. |
| `mobile/lib/features/room/data/room_repository.dart` | ✅ Complete | Has `createRoom`, `joinRoom`, `streamRoom`, `streamPlayers`, `currentUserId`, `startMatch`. Needs `transferOwnership`, `closeRoom`, `leaveRoom`. |
| `mobile/lib/features/room/domain/models.dart` | ✅ Complete | `RoomModel` (id, code, status, currentRound, createdBy, createdAt), `PlayerModel` (id, name, role, cp, vpByRound, connected, color), `RoleEnum` (owner/player). No changes needed. |
| `mobile/lib/features/room/presentation/lobby_screen.dart` | ✅ Complete | Navigates to `const AppShell()` on status active — must be updated to `AppShell(roomId: _roomId!)`. Uses `_navigationTriggered` guard to prevent duplicate navigation. |
| `mobile/lib/features/room/presentation/widgets/player_presence_badge.dart` | ✅ Complete | Accepts `playerName`, `playerColor` (Color), `isOnline`, `isOwner`. Already has Semantics label. Reuse as-is. |
| `mobile/lib/core/firebase/firestore_paths.dart` | ✅ Complete | `rooms()`, `room(roomId)`, `players(roomId)`, `player(roomId, uid)`, `events(roomId)`, `event(roomId, eventId)`. No changes needed. |
| `mobile/pubspec.yaml` | ✅ Complete | `cloud_firestore: ^5.6.7`, `firebase_auth: ^5.5.2`, `firebase_core: ^3.13.1` — **no new packages needed** |
| `mobile/analysis_options.yaml` | ✅ Active | `avoid_print: true` enforced |

**Files to MODIFY in this story:**
- `mobile/lib/features/room/data/room_repository.dart` — add 3 new methods
- `mobile/lib/app/app.dart` — add `roomId` param, closed-room stream, wire tab 3
- `mobile/lib/features/room/presentation/lobby_screen.dart` — update `AppShell` navigation to pass `roomId`

**Files to CREATE in this story:**
- `mobile/lib/features/room/presentation/room_management_screen.dart` — new Room tab screen

**Files NOT to touch (zero changes):**
- `mobile/lib/features/room/domain/models.dart`
- `mobile/lib/features/room/presentation/widgets/player_presence_badge.dart`
- `mobile/lib/core/firebase/firestore_paths.dart`
- `mobile/firestore.rules` — existing rules already cover all new operations (see note below)
- `mobile/pubspec.yaml`
- `mobile/lib/main.dart`

---

### Firestore Security Rules — NO CHANGES NEEDED ✅

The existing `firestore.rules` already covers all Story 2.5 write operations:

| Operation | Firestore path | Rule that covers it |
|-----------|----------------|---------------------|
| `closeRoom()` — update `status: closed` | `rooms/{roomId}` | `allow update: if isRoomOwner(roomId)` ✅ |
| `transferOwnership()` — update `createdBy` | `rooms/{roomId}` | `allow update: if isRoomOwner(roomId)` ✅ |
| `transferOwnership()` — update old owner's `role` | `players/{oldOwnerUid}` | `allow update: if isAuthenticated() && (request.auth.uid == uid || isRoomOwner(roomId))` ✅ |
| `transferOwnership()` — update new owner's `role` | `players/{newOwnerUid}` | `allow update: if isAuthenticated() && (request.auth.uid == uid || isRoomOwner(roomId))` ✅ |
| `leaveRoom()` — update own `connected: false` | `players/{uid}` | `allow update: if isAuthenticated() && request.auth.uid == uid` ✅ |

The existing rule `allow update: if isRoomOwner(roomId)` covers ALL fields on the room document — not just `status`. No amendment required.

---

### Task 1 — Exact Code for `RoomRepository` (3 new methods)

Add after the `startMatch()` method:

```dart
// ── Ownership transfer ────────────────────────────────────────────────────

/// Transfers ownership from the current user to [newOwnerUid].
/// Atomically updates room.createdBy, old owner's role → player,
/// new owner's role → owner, in a single Firestore batch.
/// Throws [RoomException] if the update fails.
Future<void> transferOwnership(String roomId, String newOwnerUid) async {
  final uid = _auth.currentUser!.uid;
  try {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(FirestorePaths.room(roomId), {'createdBy': newOwnerUid});
    batch.update(FirestorePaths.player(roomId, uid), {'role': 'player'});
    batch.update(FirestorePaths.player(roomId, newOwnerUid), {'role': 'owner'});
    await batch.commit();
  } on RoomException {
    rethrow;
  } catch (e) {
    throw RoomException('Failed to transfer ownership: $e');
  }
}

// ── Room closure ──────────────────────────────────────────────────────────

/// Closes the room by setting its status to 'closed'.
/// Firestore Security Rules enforce that only the room owner can do this.
/// Throws [RoomException] if the update fails.
Future<void> closeRoom(String roomId) async {
  try {
    await FirestorePaths.room(roomId).update({'status': 'closed'});
  } on RoomException {
    rethrow;
  } catch (e) {
    throw RoomException('Failed to close room: $e');
  }
}

// ── Room departure ───────────────────────────────────────────────────────

/// Marks the current player as disconnected without closing the room.
/// Safe to call by non-owners to leave a session gracefully.
/// Throws [RoomException] if the update fails.
Future<void> leaveRoom(String roomId) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;
  try {
    await FirestorePaths.player(roomId, uid).update({'connected': false});
  } on RoomException {
    rethrow;
  } catch (e) {
    throw RoomException('Failed to leave room: $e');
  }
}
```

> **Why a batch for `transferOwnership`?** The three writes (room.createdBy, old owner role, new owner role) must be atomic. A partial write (e.g., createdBy updated but roles not yet swapped) would briefly create an inconsistent owner state. Firestore `WriteBatch` commits all three writes in a single round-trip. The batch is already available via `FirebaseFirestore.instance` — no new imports needed since `cloud_firestore` is already imported.

---

### Task 2 — Updated `AppShell` in `app.dart`

**Full replacement of `AppShell` and `_AppShellState`:**

```dart
class AppShell extends StatefulWidget {
  final String roomId;
  const AppShell({super.key, required this.roomId});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _repo = RoomRepository();
  int _currentIndex = 0;
  bool _navigationTriggered = false;

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
    return StreamBuilder<RoomModel?>(
      stream: _repo.streamRoom(widget.roomId),
      builder: (context, snapshot) {
        final room = snapshot.data;

        // ── Navigate ALL clients back to home when room is closed ──────────
        if (room != null && room.status == RoomStatus.closed) {
          if (!_navigationTriggered) {
            _navigationTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LobbyScreen()),
                  (route) => false,
                );
              }
            });
          }
          return const SizedBox.shrink();
        }
        // ──────────────────────────────────────────────────────────────────

        return Scaffold(
          body: _buildBody(),
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
      },
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const Center(child: Text('Match — coming soon'));
      case 1:
        return const Center(child: Text('Historique — coming soon'));
      case 2:
        return const Center(child: Text('Joueurs — coming soon'));
      case 3:
        return RoomManagementScreen(roomId: widget.roomId);
      default:
        return const SizedBox.shrink();
    }
  }
}
```

**Imports to add at the top of `app.dart`:**

```dart
import '../features/room/data/room_repository.dart';
import '../features/room/domain/models.dart';
import '../features/room/presentation/room_management_screen.dart';
```

> **Why `_navigationTriggered` guard?** The `StreamBuilder` builder may be called multiple times after `status == closed` is detected (e.g., layout rebuilds). Without the guard, `addPostFrameCallback` would fire multiple times, stacking navigation calls. The bool guard ensures exactly one navigation is triggered — same pattern used in `lobby_screen.dart`.

> **Why `pushAndRemoveUntil` instead of `pushReplacement`?** `AppShell` is already a full-screen replacement of `LobbyScreen`. Using `pushAndRemoveUntil` with `(route) => false` clears the entire navigation stack before placing LobbyScreen. This prevents a "back" gesture from returning to the closed match.

---

### Task 3 — Lobby Screen Navigation Update

**In `lobby_screen.dart`, find and replace the auto-navigate block:**

```dart
// BEFORE:
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => const AppShell()),
);

// AFTER:
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => AppShell(roomId: _roomId!)),
);
```

The `_navigationTriggered` guard already present in lobby_screen.dart prevents duplicate navigation. No other changes needed in lobby_screen.dart.

---

### Task 4 — Full `room_management_screen.dart` Implementation

Create new file `mobile/lib/features/room/presentation/room_management_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../data/room_repository.dart';
import '../domain/models.dart';
import 'lobby_screen.dart';
import 'widgets/player_presence_badge.dart';

class RoomManagementScreen extends StatefulWidget {
  final String roomId;
  const RoomManagementScreen({super.key, required this.roomId});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final _repo = RoomRepository();

  static Color _hexToColor(String hex) {
    try {
      final value = hex.replaceFirst('#', '');
      return Color(int.parse('FF$value', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  // ── Owner: Transfer Ownership ─────────────────────────────────────────────

  Future<void> _confirmTransferOwnership(
    String newOwnerUid,
    String newOwnerName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2330),
        title: const Text(
          'Transférer la propriété',
          style: TextStyle(color: Color(0xFFE8EAF0)),
        ),
        content: Text(
          'Transférer la propriété à $newOwnerName ?',
          style: const TextStyle(color: Color(0xFFE8EAF0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4FC3F7),
              foregroundColor: const Color(0xFF0D0F14),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.transferOwnership(widget.roomId, newOwnerUid);
    } on RoomException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('transferOwnership unexpected error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de transférer la propriété.'),
        ),
      );
    }
  }

  // ── Owner: Close Room ─────────────────────────────────────────────────────

  Future<void> _confirmCloseRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2330),
        title: const Text(
          'Terminer le match',
          style: TextStyle(color: Color(0xFFE8EAF0)),
        ),
        content: const Text(
          'Confirmer la fin du match ?\nTous les joueurs seront renvoyés à l\'accueil.',
          style: TextStyle(color: Color(0xFFE8EAF0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
            ),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.closeRoom(widget.roomId);
      // AppShell's streamRoom listener handles navigation for ALL clients.
      // No local Navigator call needed here.
    } on RoomException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('closeRoom unexpected error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de terminer le match.')),
      );
    }
  }

  // ── Non-owner: Leave Room ────────────────────────────────────────────────

  Future<void> _confirmLeaveRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2330),
        title: const Text(
          'Quitter la room',
          style: TextStyle(color: Color(0xFFE8EAF0)),
        ),
        content: const Text(
          'Quitter la room ?\nLes autres joueurs continueront le match.',
          style: TextStyle(color: Color(0xFFE8EAF0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.leaveRoom(widget.roomId);
      if (!mounted) return;
      // Only this client navigates — others are unaffected (room not closed).
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LobbyScreen()),
        (route) => false,
      );
    } on RoomException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('leaveRoom unexpected error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de quitter la room.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RoomModel?>(
      stream: _repo.streamRoom(widget.roomId),
      builder: (context, roomSnapshot) {
        if (roomSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (roomSnapshot.hasError) {
          debugPrint('RoomManagement streamRoom error: ${roomSnapshot.error}');
          return const Center(
            child: Text(
              'Erreur de connexion à la room.',
              style: TextStyle(color: Color(0xFFF44336)),
            ),
          );
        }
        final room = roomSnapshot.data;
        if (room == null) {
          return const Center(
            child: Text(
              'La room a été supprimée.',
              style: TextStyle(color: Color(0xFFE8EAF0)),
            ),
          );
        }

        final isOwner = room.createdBy == _repo.currentUserId;

        return StreamBuilder<List<PlayerModel>>(
          stream: _repo.streamPlayers(widget.roomId),
          builder: (context, playersSnapshot) {
            final players = playersSnapshot.data ?? [];

            return Scaffold(
              backgroundColor: const Color(0xFF0D0F14),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Section header ────────────────────────────────
                      const Text(
                        'GESTION DE ROOM',
                        style: TextStyle(
                          fontFamily: 'RobotoCondensed',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Color(0xFF5C6478),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Player list ───────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF161920),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF2A2F3E)),
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'JOUEURS CONNECTÉS',
                                  style: TextStyle(
                                    fontFamily: 'RobotoCondensed',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: Color(0xFF5C6478),
                                  ),
                                ),
                              ),
                            ),
                            const Divider(
                              color: Color(0xFF2A2F3E),
                              height: 1,
                            ),
                            // Player rows
                            if (players.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Aucun joueur.',
                                  style: TextStyle(color: Color(0xFF5C6478)),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: players.length,
                                separatorBuilder: (_, __) => const Divider(
                                  color: Color(0xFF2A2F3E),
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final player = players[index];
                                  final isThisPlayerOwner =
                                      player.id == room.createdBy;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        // Badge
                                        PlayerPresenceBadge(
                                          playerName: player.name,
                                          playerColor:
                                              _hexToColor(player.color),
                                          isOnline: player.connected,
                                          isOwner: isThisPlayerOwner,
                                        ),
                                        const Spacer(),
                                        // Transfer button — owner only, for non-owner players
                                        if (isOwner && !isThisPlayerOwner)
                                          Semantics(
                                            label:
                                                'Transférer la propriété à ${player.name}',
                                            child: TextButton(
                                              onPressed: () =>
                                                  _confirmTransferOwnership(
                                                player.id,
                                                player.name,
                                              ),
                                              child: const Text(
                                                'TRANSFÉRER',
                                                style: TextStyle(
                                                  fontFamily: 'RobotoCondensed',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                  color: Color(0xFF5C6478),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Owner action ─────────────────────────── ──────
                      if (isOwner) ...[
                        const Text(
                          'ACTIONS OWNER',
                          style: TextStyle(
                            fontFamily: 'RobotoCondensed',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Color(0xFF5C6478),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _confirmCloseRoom,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF44336),
                              side: const BorderSide(
                                color: Color(0xFFF44336),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text('Terminer le match'),
                          ),
                        ),
                      ],

                      // ── Non-owner action ──────────────────────────────
                      if (!isOwner) ...[
                        const Text(
                          'ACTIONS',
                          style: TextStyle(
                            fontFamily: 'RobotoCondensed',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Color(0xFF5C6478),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _confirmLeaveRoom,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5C6478),
                              side: const BorderSide(
                                color: Color(0xFF5C6478),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text('Quitter la room'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
```

---

### Architecture Constraints

- **No direct Firebase imports in screen files** — use `_repo.currentUserId`, not `FirebaseAuth.instance.currentUser?.uid`
- **Feature boundary**: `room_management_screen.dart` is in `features/room/` — it may import `lobby_screen.dart` (same feature) for navigation. It must NOT import anything from `features/game/`.
- **`app.dart` imports**: `app/app.dart` may import from `features/room/` — this is the app shell layer above features. Already established in 1.4 (`lobby_screen.dart` imported there).
- **State management**: `StreamBuilder` native on Firestore streams — no external state management
- **Logging**: `debugPrint()` is permitted. `print()` is FORBIDDEN (`avoid_print` lint is active)
- **No new packages**: All needed APIs already in the project
- **`_hexToColor()` is a private helper**: Intentionally re-declared in `_RoomManagementScreenState` (no shared utils allowed between screens). Same pattern as lobby_screen.dart.
- **`Scaffold` inside tab body**: `RoomManagementScreen` has its own `Scaffold` with background color. This is correct — `AppShell`'s Scaffold body wraps the current tab's widget. The inner Scaffold provides the background color and SafeArea independently.

### Navigation Architecture for Room Closure

Two distinct navigation paths when leaving the match:

| Actor | Trigger | Mechanism | Result |
|-------|---------|-----------|--------|
| **Owner** closes room | `closeRoom()` sets `status = closed` | `AppShell` `StreamBuilder` → `addPostFrameCallback` → `pushAndRemoveUntil(LobbyScreen)` | ALL connected clients navigate home |
| **Non-owner** leaves room | `leaveRoom()` sets `connected = false` | `_confirmLeaveRoom()` → direct `pushAndRemoveUntil(LobbyScreen)` | Only the leaving participant navigates home |

> **Why doesn't `closeRoom()` in `_RoomManagementScreenState` navigate directly?** The owner's `AppShell` will detect `status == closed` from the stream and navigate via the same path used by all other clients. Adding an extra `Navigator` call in `_confirmCloseRoom()` would cause a double-navigation race condition. The `AppShell` stream is the single source of truth for closed-room navigation.

### Scope Boundary — What NOT to Do in This Story

| ❌ Don't | ✅ Reason |
|----------|-----------|
| Implement Players tab (tab 2) content | Scope of Story 2.6 |
| Implement Match/History tabs content | Scope of Epic 3 |
| Pass `roomId` to Match, History, Players tabs in `_buildBody()` | Not needed until those tabs are implemented |
| Add `SyncStatusIndicator` | Scope of Epic 5 (Story 5.1) |
| Hard-delete room document or player documents | Architecture: hard delete forbidden at MVP |
| Pass `RoomModel` or `List<PlayerModel>` from AppShell into `RoomManagementScreen` | Screens own their own streams — no prop-drilling at this scope |
| Add ownership transfer confirmation with TwoStepConfirmButton | `TwoStepConfirmButton` is exclusively for undo actions. Ownership transfer uses `AlertDialog`. |
| Check ownership in Dart before `closeRoom()` / `transferOwnership()` | Firestore Security Rules are the authoritative gate |

### Learnings from Stories 2.1–2.4

- `!mounted` guard is **MANDATORY** after every `await` in async methods within `StatefulWidget`
- `debugPrint()` for unexpected errors, NEVER `print()` — `avoid_print` lint will catch violations
- `flutter analyze` must report "No issues found!" before marking story done
- `WidgetsBinding.instance.addPostFrameCallback` for navigation triggered from `StreamBuilder` builder — never call `Navigator` directly inside `build()` or a `builder` callback
- `_navigationTriggered` bool guard prevents duplicate navigation when builder fires multiple times with the same status
- `FilledButton` with `onPressed: null` to disable; `Opacity(opacity: 0.38)` wrapping for visual disabled state
- `const` constructors reduce rebuild cost — use `const` on all stateless child widgets
- `pushAndRemoveUntil` with `(route) => false` for full stack clear (not `pushReplacement`)
- `StreamBuilder`: always handle `connectionState.waiting` and `hasError` cases gracefully

### Design Token Reference

| Token | Value | Usage in this story |
|-------|-------|---------------------|
| `surface-bg` | `Color(0xFF0D0F14)` | Scaffold background |
| `surface-card` | `Color(0xFF161920)` | Player list container |
| `surface-elevated` | `Color(0xFF1E2330)` | AlertDialog background |
| `border-subtle` | `Color(0xFF2A2F3E)` | Container borders, dividers |
| `accent-p1` | `Color(0xFF4FC3F7)` | Transfer confirm button |
| `sync-error` | `Color(0xFFF44336)` | "Terminer le match" button + confirm button |
| `text-primary` | `Color(0xFFE8EAF0)` | Main text, dialog text |
| `text-muted` | `Color(0xFF5C6478)` | Section labels, "TRANSFÉRER" button text, "Quitter" button |

### Git Context (recent commits at story start)

| Commit | Description |
|--------|-------------|
| `implement 2.4` | Added `startMatch()`, owner-gated "Lancer le match" button, auto-navigation to `AppShell` on `status == active` |
| `implement story 2.3` | Added join room by code, `_UpperCaseTextFormatter`, join section UI |
| `implement story 2.2` | Create room lobby UI, `PlayerPresenceBadge` widget, lobby phase with real-time player list |
| `implement story 2.1` | `RoomModel`, `PlayerModel`, `RoleEnum`, `RoomRepository` foundation |

### References

- Story AC source: [epics.md — Epic 2, Story 2.5](_bmad-output/planning-artifacts/epics.md)
- App shell to modify: [app.dart](../../mobile/lib/app/app.dart)
- Repository to extend: [room_repository.dart](../../mobile/lib/features/room/data/room_repository.dart)
- Lobby screen (navigation update): [lobby_screen.dart](../../mobile/lib/features/room/presentation/lobby_screen.dart)
- Player presence widget (reuse): [player_presence_badge.dart](../../mobile/lib/features/room/presentation/widgets/player_presence_badge.dart)
- Domain models (no change): [models.dart](../../mobile/lib/features/room/domain/models.dart)
- Firestore paths (no change): [firestore_paths.dart](../../mobile/lib/core/firebase/firestore_paths.dart)
- Firestore rules (no change needed): [firestore.rules](../../mobile/firestore.rules)
- Architecture reference: [architecture.md](_bmad-output/planning-artifacts/architecture.md)
- UX spec: [ux-design-specification.md](_bmad-output/planning-artifacts/ux-design-specification.md)
- Previous story dev notes: [2-4-start-match-session.md](./2-4-start-match-session.md)

---

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6 (GitHub Copilot)

### Debug Log References

(none)

### Completion Notes List

- ✅ Task 1: Added `transferOwnership`, `closeRoom`, `leaveRoom` methods to `RoomRepository` with Firestore batch for atomic ownership transfer.
- ✅ Task 2: `AppShell` now accepts `roomId` param, wraps Scaffold in `StreamBuilder<RoomModel?>`, navigates all clients back to `LobbyScreen` on `status == closed` via `_navigationTriggered` guard.
- ✅ Task 3: `lobby_screen.dart` navigation updated from `const AppShell()` to `AppShell(roomId: _roomId!)`.
- ✅ Task 4: Created `room_management_screen.dart` with dual `StreamBuilder`, `PlayerPresenceBadge` list, owner/non-owner conditional actions, all three confirmation dialogs, and `_hexToColor()` helper.
- ✅ Task 5: `flutter analyze` — No issues found!

### File List

- `mobile/lib/features/room/data/room_repository.dart` (modified)
- `mobile/lib/app/app.dart` (modified)
- `mobile/lib/features/room/presentation/lobby_screen.dart` (modified)
- `mobile/lib/features/room/presentation/room_management_screen.dart` (created)

### Change Log

- Added `transferOwnership`, `closeRoom`, `leaveRoom` to `RoomRepository` (Date: 2026-03-27)
- `AppShell` now requires `roomId`, streams room status, navigates all clients home on close (Date: 2026-03-27)
- `lobby_screen.dart` passes `roomId` to `AppShell` on match start navigation (Date: 2026-03-27)
- Created `room_management_screen.dart`: player presence list, ownership transfer, close room, leave room flows (Date: 2026-03-27)
