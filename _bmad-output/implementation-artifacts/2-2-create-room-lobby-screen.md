# Story 2.2: Create Room & Lobby Screen

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a match owner,
I want to create a new room and see its shareable code in a lobby screen,
so that I can invite other players to join before starting the match.

## Acceptance Criteria

1. **Given** the app is open on the home/lobby screen  
   **When** the owner taps "Créer une room" and enters their name  
   **Then** a new room document is created in Firestore with `status: 'waiting'`, `createdBy: uid`, and a unique readable room code  
   **And** the lobby screen displays the room code prominently (large, copyable)  
   **And** the owner's `PlayerModel` is created in `rooms/{id}/players/{uid}` with `role: 'owner'` and `color: '#4FC3F7'`

2. **Given** the lobby screen is visible  
   **When** a second player joins (via Story 2.3)  
   **Then** the owner sees the new player appear in the participant list in real time via Firestore stream  
   **And** each player entry shows `PlayerPresenceBadge` with their assigned color and online status (UX-DR7)

3. **Given** the lobby screen  
   **When** fewer than 2 players are connected  
   **Then** the "Lancer le match" button is disabled (opacity 0.38, non-tappable)

## Tasks / Subtasks

- [x] Task 1 — Create `PlayerPresenceBadge` widget (AC: #2)
  - [x] Create `mobile/lib/features/room/presentation/widgets/player_presence_badge.dart`
  - [x] Widget accepts: `playerName` (String), `playerColor` (Color), `isOnline` (bool), `isOwner` (bool)
  - [x] Show a circular avatar filled with `playerColor` (diameter 40dp) with the player's initials in white
  - [x] Show player name in `Roboto 14sp` `text-primary` (`#E8EAF0`) to the right of the avatar
  - [x] Show an online/offline dot: 10dp circle, `#4CAF50` when `isOnline: true`, `#5C6478` when `isOnline: false`
  - [x] If `isOwner: true`, show a small "OWNER" label in `Roboto Condensed 11sp` uppercase next to the name in `text-muted` (`#5C6478`)
  - [x] Minimum touch area: 48×48dp (wrap with `Semantics` with descriptive label)
  - [x] Color is never the sole indicator: the dot is supplemented by its position (dot is always present, differentiated only by hue)

- [x] Task 2 — Create `LobbyScreen` (two-phase home + lobby) (AC: #1, #2, #3)
  - [x] Create `mobile/lib/features/room/presentation/lobby_screen.dart`
  - [x] Use `StatefulWidget`; state fields: `String? _roomId` (null = home phase), `bool _isLoading` (creation in progress), `String? _errorMessage`, `final _nameController = TextEditingController()`
  - [x] **Home phase** (`_roomId == null`): render a centered column with:
    - App title "WH40K Match Companion" in `Roboto Condensed 20sp` uppercase, color `text-muted` (`#5C6478`)
    - `TextFormField` for owner name (label: "Votre nom"), min height 56dp, keyboard type text, border color `#2A2F3E`
    - `FilledButton` "Créer une room" full-width 48dp tall, color `#4FC3F7` on dark background
    - If `_isLoading`, show a `CircularProgressIndicator` instead of the button
    - If `_errorMessage != null`, show inline error text in `#F44336` below the button (no dialog)
  - [x] **On "Créer une room" tap**: validate name is not empty → call `RoomRepository().createRoom(name)` → on success, call `setState(() => _roomId = <returned_id>)` → on `RoomException`, set `_errorMessage` inline
  - [x] **Lobby phase** (`_roomId != null`): render a `Column` with two `StreamBuilder`s (room + players) wrapping the content:
    - Outer `StreamBuilder<RoomModel?>(stream: _repo.streamRoom(_roomId!))`: handle null (room deleted) and error states gracefully
    - Inner `StreamBuilder<List<PlayerModel>>(stream: _repo.streamPlayers(_roomId!))`: display player list
    - **Room code display**: show `room.code` in `Roboto Mono 40sp Bold`, color `#4FC3F7`, with a copy `IconButton` (`Icons.copy`) beside it; on tap copy to clipboard via `Clipboard.setData` and show a brief `SnackBar` "Code copié !"
    - **Player list**: `ListView` of `PlayerPresenceBadge` widgets; parse hex color string to `Color` with `_hexToColor()` helper (see below); show player as online if `player.connected == true`; isOwner if `player.role == RoleEnum.owner`
    - **"Lancer le match" button**: `FilledButton` "Lancer le match", disabled (`onPressed: null`) when `players.where((p) => p.connected).length < 2`; when disabled apply `Opacity(opacity: 0.38)`; when enabled (Story 2.4 scope) button remains disabled in this story — always `onPressed: null` for now with TODO comment
    - Show player count label: "N joueur(s) connecté(s)" in `Roboto 14sp` above the button
  - [x] **`_hexToColor()` helper** (private, static in the State): `Color _hexToColor(String hex) { final value = hex.replaceFirst('#', ''); return Color(int.parse('FF$value', radix: 16)); }`
  - [x] **dispose**: call `_nameController.dispose()` in `dispose()`
  - [x] **Background color**: scaffold `backgroundColor: const Color(0xFF0D0F14)`
  - [x] **Padding**: horizontal 24dp, vertical 32dp for home phase; horizontal 16dp for lobby phase

- [x] Task 3 — Update `app.dart` to use `LobbyScreen` as home (AC: #1)
  - [x] In `mobile/lib/app/app.dart`: add import `import 'package:mobile/features/room/presentation/lobby_screen.dart';`
  - [x] Change `home: const _AppShell()` → `home: const LobbyScreen()`
  - [x] The `_AppShell` class remains in `app.dart` — it will be the navigation target after a match starts (Story 2.4). Do NOT remove it.

- [x] Task 4 — Verify `flutter analyze` reports zero errors (AC: all)
  - [x] Run `flutter analyze` from `mobile/` directory
  - [x] Confirm 0 issues: no `avoid_print`, no unused imports, no missing const

## Dev Notes

### Starting Point — State of Repository at Story 2.2 Start

The following files are CONFIRMED present and describe the current project state:

| File | Status | Notes |
|------|--------|-------|
| `mobile/lib/app/app.dart` | ✅ Complete | `_AppShell` with bottom nav 4 tabs (Match/Historique/Joueurs/Room), home shows placeholder text, `backgroundColor: Color(0xFF0D0F14)` already applied |
| `mobile/lib/main.dart` | ✅ Complete | Firebase init + anon auth + `PersistenceSettings(cacheSizeBytes: CACHE_SIZE_UNLIMITED)` |
| `mobile/lib/core/firebase/firestore_paths.dart` | ✅ Complete | `rooms()`, `room(id)`, `players(id)`, `player(id, uid)`, `events(id)`, `event(id, eid)` |
| `mobile/lib/features/room/domain/models.dart` | ✅ Complete | `RoomStatus`, `RoomModel`, `RoleEnum`, `PlayerModel` — all with `fromMap/toMap/copyWith` |
| `mobile/lib/features/room/data/room_repository.dart` | ✅ Complete | `createRoom()`, `joinRoom()`, `streamRoom()`, `streamPlayers()`, `RoomException` |
| `mobile/lib/features/room/presentation/` | ✅ Directory exists | Contains only `.gitkeep` |
| `mobile/pubspec.yaml` | ✅ Complete | `cloud_firestore: ^5.6.7`, `firebase_auth: ^5.5.2`, `firebase_core: ^3.13.1`, no additional packages |
| `mobile/analysis_options.yaml` | ✅ Active | `avoid_print: true` enforced |

**Files to CREATE in this story:**
- `mobile/lib/features/room/presentation/lobby_screen.dart`
- `mobile/lib/features/room/presentation/widgets/player_presence_badge.dart`

**Files to MODIFY in this story:**
- `mobile/lib/app/app.dart` — change `home` from `_AppShell` to `LobbyScreen`

**No repository or model changes. No Firestore schema changes. Pure UI layer.**

### Architecture Constraints

- **Feature boundary**: `lobby_screen.dart` may only import from `features/room/` — NEVER from `features/game/`.
- **Firestore paths**: `RoomRepository` already abstracts all Firestore operations — `lobby_screen.dart` only calls repository methods and `StreamBuilder` streams. Never import `FirestorePaths` directly in screen files.
- **State management**: `StreamBuilder` native on Firestore streams — no external state management (no Riverpod, no Provider, no BLoC).
- **Logging**: `debugPrint()` is permitted. `print()` is FORBIDDEN (`avoid_print` lint is active).
- **No navigation to match screen in this story**: The "Lancer le match" button must be rendered but always `onPressed: null`. Story 2.4 will wire the navigation. Add a `// TODO(story-2.4): wire navigation to match screen` comment on the `onPressed:` line.

### Color Helper Pattern

```dart
// Private helper — never import Color parsing from another feature
Color _hexToColor(String hex) {
  final value = hex.replaceFirst('#', '');
  return Color(int.parse('FF$value', radix: 16));
}
```

### Design Token Reference

Use these exact values in the UI (no magic numbers elsewhere):

| Token | Value | Usage in this story |
|-------|-------|---------------------|
| `surface-bg` | `Color(0xFF0D0F14)` | Scaffold background |
| `surface-card` | `Color(0xFF161920)` | Player list container, code box |
| `border-subtle` | `Color(0xFF2A2F3E)` | Input field border, separators |
| `text-primary` | `Color(0xFFE8EAF0)` | Player names, body text |
| `text-muted` | `Color(0xFF5C6478)` | Secondary labels, section titles |
| Player 1 accent | `Color(0xFF4FC3F7)` | Room code display, button color |
| `sync-ok` | `Color(0xFF4CAF50)` | Online presence dot |
| `sync-error` | `Color(0xFFF44336)` | Error messages |

### RoomRepository API (from Story 2.1)

```dart
// Available methods on RoomRepository():
Future<String> createRoom(String ownerName)
    → creates Firestore room + player doc, returns roomId
    → throws RoomException on failure — catch and display inline

Stream<RoomModel?> streamRoom(String roomId)
    → emits RoomModel or null (if doc deleted); no try/catch on stream itself

Stream<List<PlayerModel>> streamPlayers(String roomId)
    → emits List<PlayerModel> in real time; may be empty list, never null
```

### PlayerModel fields available (from Story 2.1)

```dart
class PlayerModel {
  String id;         // Firestore doc ID (= uid)
  String name;       // Display name
  RoleEnum role;     // RoleEnum.owner | RoleEnum.player
  int cp;            // Command Points (not used in this story)
  Map<String, Map<String, int>> vpByRound; // VP scores (not used in this story)
  bool connected;    // true = online
  String color;      // Hex string, e.g. '#4FC3F7' — parse with _hexToColor()
}
```

### StreamBuilder Pattern (as established in project)

```dart
StreamBuilder<List<PlayerModel>>(
  stream: _repo.streamPlayers(_roomId!),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text('Erreur', style: TextStyle(color: Color(0xFFF44336))));
    }
    final players = snapshot.data ?? [];
    // render players
  },
)
```

### LobbyScreen Phase Design

```
──────────────────────────────────────────────────────────────
 HOME PHASE (before createRoom)       LOBBY PHASE (after createRoom)
──────────────────────────────────────────────────────────────

 ┌─────────────────────────┐          ┌─────────────────────────┐
 │ WH40K MATCH COMPANION   │          │    CODE DE ROOM          │
 │ (Roboto Condensed 20sp) │          │                          │
 │                         │          │    ┌───────────────┐    │
 │  ┌──────────────────┐   │          │    │  AB3K7M       │    │
 │  │ Votre nom...     │   │          │    │ (Mono 40sp)   │  📋│
 │  └──────────────────┘   │          │    └───────────────┘    │
 │                         │          │                          │
 │  [CRÉER UNE ROOM →]     │          │  JOUEURS (2)             │
 │  (blue 48dp)            │          │  ┌──────────────────┐   │
 │                         │          │  │ 🔵 Alice  OWNER  │   │
 │  Error message here     │          │  │ 🔴 Bob           │   │
 └─────────────────────────┘          │  └──────────────────┘   │
                                      │                          │
                                      │  2 joueur(s) connecté(s) │
                                      │                          │
                                      │  [LANCER LE MATCH]       │
                                      │  (disabled opacity 0.38) │
                                      └─────────────────────────┘
```

### Widget File Layout

```
mobile/lib/features/room/presentation/
├── lobby_screen.dart              ← new
└── widgets/
    └── player_presence_badge.dart ← new
```

**Important:** The `widgets/` subdirectory does not yet exist. Create it (the `.gitkeep` in `presentation/` should remain untouched, just add the new files alongside it).

### Typography Implementation

Use `TextStyle` directly (no `google_fonts` package — not in pubspec.yaml):
```dart
// Roboto Mono for code display:
const TextStyle(fontFamily: 'RobotoMono', ...)
// Fallback: Flutter default monospace. If RobotoMono not available, use:
const TextStyle(fontFamily: 'monospace', ...)
// For Roboto Condensed section labels:
const TextStyle(fontFamily: 'RobotoCondensed', fontWeight: FontWeight.bold,
    letterSpacing: 1.5, fontSize: 11, color: Color(0xFF5C6478))
// Note: Roboto Condensed may fall back to system default — acceptable for MVP.
```

### Clipboard Pattern

```dart
import 'package:flutter/services.dart'; // for Clipboard

// Copy room code on icon tap:
await Clipboard.setData(ClipboardData(text: room.code));
if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Code copié !')),
  );
}
```

### Error Handling in UI

- `RoomException` is the only exception type thrown by `RoomRepository` — catch it inline:
```dart
try {
  final id = await _repo.createRoom(_nameController.text.trim());
  setState(() { _roomId = id; _isLoading = false; });
} on RoomException catch (e) {
  setState(() { _errorMessage = e.message; _isLoading = false; });
}
```
- Never show `showDialog` for creation errors — always inline below the button.
- `StreamBuilder` errors in the lobby phase: show a centered error `Text` with `Color(0xFFF44336)`.

### Context Continuity from Story 2.1

From the Dev Agent completion notes on Story 2.1:
- `fromMap` + `fromFirestore` pattern established — models are fully serializable
- 21 unit tests passing; `flutter analyze` 0 issues
- `dart:async` explicit import was problematic — **do NOT explicitly import `dart:async`**; Stream types are available via flutter/material.dart transitively
- `RoomException` is defined in `room_repository.dart` — import it from there

### Git Context (recent commits at story start)

- `65ae57d` — resolve dette tech (Color fix in app.dart, now uses `const Color(0xFF0D0F14)`)
- `b336e66` — implement story 2.1 (full models + repo + 21 tests)
- `1683633` — build story 2.1

### Project Structure Notes

**Feature-first compliance:**
- `lobby_screen.dart` lives in `features/room/presentation/` — correct location
- `player_presence_badge.dart` lives in `features/room/presentation/widgets/` — correct location
- No cross-feature imports: never import `features/game/` from `features/room/`

**app.dart navigation context:**
- `_AppShell` (4-tab navigation) stays intact in `app.dart` and will be used as the navigation target in Story 2.4 (start match)
- Story 2.2 only changes `home: const _AppShell()` → `home: const LobbyScreen()`
- The `MaterialApp` theme, color scheme, and `_AppShell` class remain unchanged

### Scope Boundary — What NOT to Do in This Story

| ❌ Don't | ✅ Reason |
|----------|-----------|
| Implement "Rejoindre une room" / join by code form | Scope of Story 2.3 |
| Wire "Lancer le match" to navigate to match screen | Scope of Story 2.4 |
| Implement match screen or any in-match tab content | Scope of Epic 3+ |
| Add any packages to pubspec.yaml | No new packages needed |
| Add `SyncStatusIndicator` widget | Scope of Epic 5 (Story 5.1) |
| Implement `PlayerPresenceBadge` for skeleton shimmer | Skeleton shimmer (UX-DR17) deferred to later stories |
| Modify `room_repository.dart` or `models.dart` | All domain logic is complete from Story 2.1 |
| Remove `_AppShell` from `app.dart` | It will be navigated to in Story 2.4 |
| Fix JDK / Gradle configuration | Pre-configured from Epic 1; no Gradle changes involved |
| Add `print()` calls | `avoid_print` lint is active — use `debugPrint()` only |
| Build or test APK | UI test via `flutter analyze` is sufficient for this story |

### References

- Story AC source: [epics.md — Epic 2, Story 2.2](_bmad-output/planning-artifacts/epics.md)
- PlayerPresenceBadge spec: [ux-design-specification.md — Component Strategy](_bmad-output/planning-artifacts/ux-design-specification.md#component-strategy)
- Design tokens: [ux-design-specification.md — Color Palette](_bmad-output/planning-artifacts/ux-design-specification.md#color-palette)
- User Journey 1 (create & start room): [ux-design-specification.md — Journey 1](_bmad-output/planning-artifacts/ux-design-specification.md#journey-1)
- UX-DR7 (PlayerPresenceBadge), UX-DR11 (dark theme), UX-DR12 (typography), UX-DR15 (lobby screen): [epics.md — UX Design Requirements](_bmad-output/planning-artifacts/epics.md#ux-design-requirements)
- Feature-first boundaries: [architecture.md — Structure Patterns](_bmad-output/planning-artifacts/architecture.md#structure-patterns)
- RoomRepository implementation: [room_repository.dart](../../mobile/lib/features/room/data/room_repository.dart)
- RoomModel / PlayerModel: [models.dart](../../mobile/lib/features/room/domain/models.dart)
- Previous story learnings: [2-1-room-domain-models-repository.md](./2-1-room-domain-models-repository.md)

---

## Dev Agent Record

### Completion Notes

Implemented Story 2.2 in full. Two new files created:
- `PlayerPresenceBadge` widget: circular avatar with initials, online/offline dot, optional OWNER label, `Semantics` wrapper for accessibility, minimum 48×48dp touch target.
- `LobbyScreen`: two-phase `StatefulWidget`. Home phase has name input + "Créer une room" button with loading/error states. Lobby phase uses nested `StreamBuilder`s for room + players. Room code displayed in `RobotoMono 40sp` with clipboard copy + SnackBar. Player list uses `PlayerPresenceBadge`. "Lancer le match" button always `onPressed: null` with `TODO(story-2.4)` comment; `Opacity(0.38)` applied when fewer than 2 players connected.

`app.dart` updated: `home` changed from `const _AppShell()` to `const LobbyScreen()`. `_AppShell` class left intact for Story 2.4.

`flutter analyze` → **No issues found** (ran in 1.7s).

### Debug Log

| Date | Issue | Resolution |
|------|-------|------------|
| 2026-03-27 | None | Implementation completed without issues |

---

## File List

### To Create
- `mobile/lib/features/room/presentation/lobby_screen.dart`
- `mobile/lib/features/room/presentation/widgets/player_presence_badge.dart`

### To Modify
- `mobile/lib/app/app.dart` — change `home: const _AppShell()` to `home: const LobbyScreen()`

### Unchanged
- `mobile/lib/core/firebase/firestore_paths.dart`
- `mobile/lib/main.dart`
- `mobile/lib/features/room/domain/models.dart`
- `mobile/lib/features/room/data/room_repository.dart`
- `mobile/pubspec.yaml`
- `mobile/analysis_options.yaml`
