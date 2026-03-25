---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/ux-design-specification.md
---

# cursor_project - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for cursor_project (Warhammer 40K Match Companion), decomposing the requirements from the PRD, UX Design, and Architecture into implementable stories.

---

## Requirements Inventory

### Functional Requirements

FR1: A match owner can create a new match room.
FR2: A player can join an existing room using a room code.
FR3: The system can associate each participant with a unique player identity within a room.
FR4: A room owner can start an active match session once participants are present.
FR5: A room owner can end or close a match session.
FR6: A participant can view current room membership and player presence state.
FR7: A room owner can transfer or reassign ownership within a room.
FR8: A participant can leave a room without breaking other participants' active session.
FR9: A player can view current shared match state for all participants in the room.
FR10: A player can update their own tracked match resources.
FR11: A room owner can update any player's tracked match resources when needed.
FR12: The system can apply turn/round progression updates to match state.
FR13: The system can apply configured automatic resource increments tied to turn/round progression.
FR14: A participant can view the current turn/round context of the match.
FR15: A participant can view current score-related values for all players.
FR16: The system can require explicit confirmation before committing sensitive match actions.
FR17: A participant can cancel a pending sensitive action before it is committed.
FR18: The system can enforce player-ownership rules for restricted actions.
FR19: The system can enforce owner-override permissions for authorized corrections.
FR20: The system can preserve a chronological event record of committed match actions.
FR21: A participant can view actor and state-change context for recorded events.
FR22: An authorized participant can undo the latest eligible event.
FR23: The system can recalculate current match state after an undo action.
FR24: The system can synchronize committed state updates across all connected participants in the same room.
FR25: A reconnecting participant can recover the latest valid room and match state.
FR26: The system can preserve pending local actions during temporary offline periods.
FR27: The system can reconcile queued offline actions after connectivity returns.
FR28: A participant can view whether their actions are pending synchronization or confirmed.
FR29: The system can prevent duplicated state mutations during reconnect reconciliation.
FR30: A participant can inspect the event timeline to resolve "who changed what" questions.
FR31: A room owner can use historical event context to resolve player disputes.
FR32: The system can provide sufficient action traceability to support trusted final match outcomes.
FR33: A participant can identify the latest authoritative state after conflict resolution actions.
FR34: A room owner can enable or disable owner-device voice control mode for a room.
FR35: The system can accept owner-device voice commands for an approved command subset.
FR36: The system can require confirmation for sensitive actions initiated via voice.
FR37: The system can execute supported voice commands as standard room events.
FR38: The system can provide fallback manual execution for all voice-supported actions.
FR39: The system can restrict voice command authority to the room owner profile in the initial voice model.
FR40: The product can be distributed through internal/private channels for MVP validation.
FR41: A tester can install and run MVP builds without public store publication.
FR42: The product can support small-group and local-store pilot usage patterns.

### NonFunctional Requirements

NFR1: The system shall allow users to create or join a room and reach match-ready state within 5 minutes for first-time sessions, with a 1-minute target for repeat users.
NFR2: Core in-match user actions (resource/score updates, turn progression, undo requests) shall complete user-visible processing within 30 seconds.
NFR3: Initial application startup shall complete within 10 seconds on supported Android devices under normal network conditions.
NFR4: Realtime state updates shall propagate to connected room participants with near-instant perceived latency during active play.
NFR5: All data in transit between client and backend services shall be encrypted using industry-standard transport security.
NFR6: Match data at rest shall be protected using managed backend encryption controls.
NFR7: Access control shall enforce player-level ownership boundaries and owner-level override permissions.
NFR8: Sensitive actions (including high-impact state mutations) shall require explicit confirmation before commit.
NFR9: MVP public exposure risk shall be limited by using private/internal distribution channels only.
NFR10: The system shall preserve match continuity through temporary client disconnects and reconnections without requiring manual full-state rebuild by users.
NFR11: The system shall maintain an auditable event history sufficient to reconstruct authoritative match state after disputes or recovery flows.
NFR12: The system shall prevent duplicated mutations during reconnect and queued-action reconciliation flows.
NFR13: Undo and recovery behaviors shall keep state consistent across all connected participants after resolution actions.
NFR14: The MVP architecture shall support growth from a small core user group to local community/store pilot usage without redesign of core domain model.
NFR15: The system shall maintain stable match operations for small multiplayer rooms typical of tabletop sessions.
NFR16: The product shall support phased capability expansion (notifications, voice features, wider distribution) without breaking core match workflows.
NFR17: Core gameplay interactions shall remain usable with clear, legible controls and tap targets suitable for fast in-match operation.
NFR18: Critical state information (scores/resources/turn context) shall be presented in a way that minimizes ambiguity and cognitive load during active play.
NFR19: Confirmation and error/recovery messaging shall be explicit enough to prevent accidental irreversible actions.
NFR20: The product shall integrate with anonymous authentication and realtime data services required for room-based multiplayer operation.
NFR21: Integration behaviors shall support deterministic event ordering and state reconstruction requirements.
NFR22: External distribution or ecosystem integrations beyond MVP shall remain optional and decoupled from core match functionality.

### Additional Requirements

- **Starter Template:** Architecture mandates `flutter create --org com.vartus --template=app --platforms=android --description="Warhammer 40K Match Companion" mobile` as the first implementation action (Epic 1, Story 1).
- Firebase packages to add to pubspec.yaml immediately after init: `firebase_core`, `firebase_auth`, `cloud_firestore`.
- `firebase_options.dart` must be generated via FlutterFire CLI and placed at `mobile/lib/core/firebase/firebase_options.dart`.
- Firestore Security Rules (`firestore.rules`) must be implemented as a distinct story after Firebase wiring — not bundled with the domain logic.
- `firebase.json` and `.firebaserc` needed for Firebase CLI deployment — add in bootstrap story alongside `firestore.rules`.
- Feature-first directory layout is mandatory: `features/room/`, `features/game/`, `core/firebase/` — no feature may import from another feature directly.
- `firestore_paths.dart` is the sole permitted location for all Firestore path strings — all repositories must import from it.
- `game_rules.dart` must be pure functions only (zero Firestore access), fully testable without mocks.
- Ownership rule: every mutating action checks `actorId == currentUser.uid OR room.createdBy == currentUser.uid` in both `game_rules.dart` and Firestore Security Rules.
- Undo is always a soft-delete via `undone: true` flag on the event document — hard Firestore delete is forbidden.
- `debugPrint()` is permitted in development; `print()` is forbidden throughout the codebase.
- State management: `StreamBuilder` native on Firestore streams — no external state management package for MVP.
- Firestore offline persistence: enabled at Firebase init via `PersistenceSettings(cacheSizeBytes: CACHE_SIZE_UNLIMITED)`.
- Test mirror structure: `mobile/test/` reproduces `mobile/lib/` structure exactly.
- Integration tests for multi-client sync in `mobile/integration_test/` only.
- APK internal distribution only — no public store for MVP.

### UX Design Requirements

UX-DR1: Implement `ScoreHeroBar` widget — 2 large cumulative score totals side by side, Roboto Mono 56sp Bold, each in the assigned player color, always visible at the top of the match screen.
UX-DR2: Implement `ScoreGridWidget` — 5 rounds × 2 VP types (Prim + Sec) × 2 players, with derived total column; must fit without horizontal scroll on screens ≥ 360dp width.
UX-DR3: Implement `RoundScoreCell` with 5 distinct visual states: `empty` (default), `active` (current round, colored outline), `filled` (round complete, VP values displayed), `locked` (opponent's cell for non-owner), `future` (grayed out).
UX-DR4: Round score entry via bottom sheet (ModalBottomSheet): 2 numeric fields (VP Prim / VP Sec), minimum field height 56dp, numeric keyboard, single full-width confirmation button in the player's accent color — tap once (not destructive, no 2-step confirmation).
UX-DR5: Implement `ResourceCounter` widget — CP counter with +/- buttons (40dp wide × 48dp tall min), `HapticFeedback.lightImpact()` on confirmation, always visible on match screen without navigation.
UX-DR6: Implement `SyncStatusIndicator` — pulsing dot globally visible at all times: green (synced), orange (pending/reconnecting), red (offline). Offline state blocks all destructive actions in the UI.
UX-DR7: Implement `PlayerPresenceBadge` — player avatar with assigned color and live online/offline presence indicator.
UX-DR8: Implement `EventTimelineItem` — compact audit trail row with actor, action type, before value, after value, and timestamp.
UX-DR9: Implement `TwoStepConfirmButton` — two-tap confirmation wrapper used exclusively for undo action; no `showDialog` ad-hoc allowed for undo elsewhere.
UX-DR10: Implement `OwnershipLockFeedback` — micro-vibration + discrete inline message when a non-owner taps a locked cell.
UX-DR11: Configure Material Design 3 dark theme with custom color tokens: background `#0D0F14`, surface-card `#161920`, surface-elevated `#1E2330`, border `#2A2F3E`; player accents `#4FC3F7` (P1) and `#EF5350` (P2); sync feedback colors `#4CAF50`/`#FF9800`/`#F44336`.
UX-DR12: Configure typography system: Roboto Mono for all numeric/score displays, Roboto Condensed for section labels (11sp uppercase, +1.5 letter-spacing), Roboto for body/actions; respect system `textScaleFactor`.
UX-DR13: Implement 200ms opacity flash animation in player color on any Firestore-updated cell — visible simultaneously on all connected clients.
UX-DR14: Implement bottom navigation bar with 4 tabs in order: Match (tab 0) / Historique (tab 1) / Joueurs (tab 2) / Room (tab 3).
UX-DR15: Implement lobby screen — room creation form + join-by-code form; room code prominently displayed for sharing; "Launch match" button disabled until minimum players joined.
UX-DR16: Ownership gate pattern: lock icon (12px, 0.3 opacity) in the top-right corner of cells owned by another player; tap on locked cell triggers `OwnershipLockFeedback` instead of action.
UX-DR17: Skeleton shimmer loading states for all screens/lists — no blocking spinners.
UX-DR18: Accessibility implementation: minimum contrast ratio 4.5:1 for all text/UI elements; `Semantics` widgets with descriptive labels on all `RoundScoreCell` instances; `ExcludeSemantics` on purely decorative elements; color is never the sole status indicator.
UX-DR19: Touch target compliance: minimum 48×48dp for all interactive elements; minimum 8dp spacing between adjacent tappables.
UX-DR20: Border radius 4dp throughout (bevel effect) — no Material-style large rounded corners; 1px hairline separators using `border-subtle` token.

### FR Coverage Map

FR1: Epic 2 — Création de room
FR2: Epic 2 — Jointure par code room
FR3: Epic 2 — Identité unique par participant
FR4: Epic 2 — Démarrage de session
FR5: Epic 2 — Clôture de session
FR6: Epic 2 — Présence des joueurs
FR7: Epic 2 — Transfert d'ownership
FR8: Epic 2 — Départ d'un participant
FR9: Epic 3 — Vue état partagé tous joueurs
FR10: Epic 3 — Mise à jour ressources propres
FR11: Epic 3 — Override owner sur ressources
FR12: Epic 3 — Progression round/turn
FR13: Epic 3 — Auto +1 CP sur avancement de round
FR14: Epic 3 — Vue round/turn actif
FR15: Epic 3 — Vue scores VP tous joueurs
FR16: Epic 4 — Confirmation avant action sensible
FR17: Epic 4 — Annulation action en attente
FR18: Epic 4 — Enforcement ownership restrictions
FR19: Epic 4 — Override permissions owner
FR20: Epic 4 — Enregistrement chronologique événements
FR21: Epic 4 — Vue acteur + contexte changement d'état
FR22: Epic 4 — Undo dernier événement
FR23: Epic 4 — Recalcul état après undo
FR24: Epic 5 — Synchronisation état tous participants
FR25: Epic 5 — Récupération état après reconnexion
FR26: Epic 5 — Préservation actions pendant offline
FR27: Epic 5 — Réconciliation queue offline
FR28: Epic 5 — Vue état sync (pending/confirmé)
FR29: Epic 5 — Prévention mutations dupliquées
FR30: Epic 4 — Inspection timeline pour disputes
FR31: Epic 4 — Owner utilise historique pour résoudre disputes
FR32: Epic 4 — Traçabilité pour résultat final de confiance
FR33: Epic 4 — État autoritaire après résolution
FR34: Epic 6 — Activation mode voix par owner
FR35: Epic 6 — Acceptation commandes vocales
FR36: Epic 6 — Confirmation actions sensibles via voix
FR37: Epic 6 — Exécution commandes vocales comme events standard
FR38: Epic 6 — Fallback manuel pour toutes actions vocales
FR39: Epic 6 — Restriction autorité voix au room owner
FR40: Epic 1 — Distribution canal interne/privé
FR41: Epic 1 — Installation APK sans store public
FR42: Epic 5 — Support small-group et local store pilot

---

## Epic List

### Epic 1: Project Foundation & Infrastructure Bootstrap
Un développeur peut initialiser le projet Flutter avec la commande exacte définie en Architecture, connecter Firebase (auth anonyme + Firestore), appliquer les Security Rules, configurer la structure feature-first, et déployer un APK de test sur Android — établissant l'ensemble de l'infrastructure sur laquelle tous les epics suivants reposent.
**FRs couverts :** FR40, FR41
**NFRs couverts :** NFR5, NFR6, NFR9, NFR14, NFR20

### Epic 2: Match Room Lifecycle
Un joueur peut créer une room avec un code partageable, rejoindre une room existante via son code, voir les participants connectés en temps réel, et le room owner peut démarrer, gérer la propriété et clôturer la session — permettant à tout groupe de commencer un match collaboratif en moins de 5 minutes.
**FRs couverts :** FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR8
**NFRs couverts :** NFR1, NFR7
**UX-DRs couverts :** UX-DR7, UX-DR11, UX-DR12, UX-DR14, UX-DR15, UX-DR20
**Stories :** 2.1, 2.2, 2.3, 2.4, 2.5, 2.6

### Epic 3: Live Match Score & Resource Tracking
Les joueurs peuvent saisir les VP Primaires et VP Secondaires par round dans un ScoreGrid 5 rounds côte à côte, voir les scores héros cumulés de tous les joueurs en temps réel, et gérer les Command Points depuis l'écran principal sans navigation — transformant l'app en source de vérité partagée pour tout le match.
**FRs couverts :** FR9, FR10, FR11, FR12, FR13, FR14, FR15
**NFRs couverts :** NFR2, NFR4, NFR17, NFR18, NFR19
**UX-DRs couverts :** UX-DR1, UX-DR2, UX-DR3, UX-DR4, UX-DR5, UX-DR13, UX-DR16, UX-DR17, UX-DR18, UX-DR19

### Epic 4: Action Safety & Dispute Resolution
Les joueurs peuvent compter sur l'app pour protéger toutes les mutations sensibles via confirmations explicites, accéder à une timeline d'événements complète avec attribution acteur/action/avant/après, et résoudre les disputes avec un undo contrôlé — garantissant la confiance dans le résultat final de chaque match.
**FRs couverts :** FR16, FR17, FR18, FR19, FR20, FR21, FR22, FR23, FR30, FR31, FR32, FR33
**NFRs couverts :** NFR7, NFR8, NFR11, NFR13
**UX-DRs couverts :** UX-DR8, UX-DR9, UX-DR10

### Epic 5: Realtime Sync & Offline Resilience
Tous les joueurs voient le même état de match simultanément avec une latence perçue quasi-nulle, et un joueur qui se déconnecte en cours de partie peut rejoindre transparairement sans perte de données ni reconstruction manuelle — garantissant la continuité du match dans toutes les conditions réseau réalistes.
**FRs couverts :** FR24, FR25, FR26, FR27, FR28, FR29, FR42
**NFRs couverts :** NFR3, NFR4, NFR10, NFR12, NFR15, NFR21
**UX-DRs couverts :** UX-DR6

### Epic 6: Voice Command Interaction (Post-MVP)
Le room owner peut contrôler les opérations de match en mode mains-libres via des commandes vocales sur son propre appareil, avec confirmation pour les actions sensibles et fallback manuel toujours disponible — préservant le flow de jeu dans les moments critiques sans dépendance obligatoire à la voix.
**FRs couverts :** FR34, FR35, FR36, FR37, FR38, FR39
**NFRs couverts :** NFR16
---

## Epic 1: Project Foundation & Infrastructure Bootstrap

Un développeur peut initialiser le projet Flutter, connecter Firebase, appliquer les Security Rules, structurer le projet feature-first, et livrer un APK interne fonctionnel — établissant l'ensemble de l'infrastructure sur laquelle tous les epics suivants reposent.

### Story 1.1: Initialize Flutter Android Project

As a developer,
I want to initialize the Flutter project using the exact architecture-specified command,
So that the codebase starts from a clean, correctly configured Android-first foundation.

**Acceptance Criteria:**

**Given** a machine with Flutter stable SDK installed
**When** the following command is executed: `flutter create --org com.vartus --template=app --platforms=android --description="Warhammer 40K Match Companion" mobile`
**Then** a `mobile/` directory is created at the project root with a valid Flutter project structure
**And** `mobile/android/` exists and builds a runnable APK via `flutter run`
**And** `mobile/analysis_options.yaml` is configured with the Flutter recommended linting ruleset
**And** `mobile/pubspec.yaml` contains the correct `description` and `name` fields

**Given** the initialized project
**When** `flutter analyze` is run
**Then** zero lint errors are reported

### Story 1.2: Firebase Integration & Anonymous Authentication

As a developer,
I want to wire Firebase into the Flutter app with anonymous authentication,
So that every app session has a unique, authenticated user identity required for Firestore ownership rules.

**Acceptance Criteria:**

**Given** the initialized Flutter project from Story 1.1
**When** `firebase_core`, `firebase_auth`, and `cloud_firestore` are added to `pubspec.yaml` and FlutterFire CLI generates `firebase_options.dart`
**Then** `mobile/lib/core/firebase/firebase_options.dart` exists with valid Android configuration
**And** `mobile/android/app/google-services.json` is present

**Given** the app launches on an Android device or emulator
**When** `main.dart` calls `Firebase.initializeApp()` and `FirebaseAuth.instance.signInAnonymously()`
**Then** a non-null `uid` is available via `FirebaseAuth.instance.currentUser`
**And** the same `uid` persists across hot-restarts within the same session
**And** no authentication error is thrown under normal network conditions

**Given** the app launches with no network connection
**When** Firebase initialization runs
**Then** the app does not crash and displays a graceful error state

### Story 1.3: Firestore Security Rules & Firebase CLI Configuration

As a developer,
I want Firestore Security Rules deployed and Firebase CLI config in place,
So that data access is enforced server-side and matches the ownership model from the architecture before any data is written.

**Acceptance Criteria:**

**Given** a `firestore.rules` file at the project root
**When** the rules are deployed via Firebase CLI
**Then** an authenticated user can read and write to their own `/rooms/{roomId}/players/{uid}` document
**And** an authenticated user can append a new document to `/rooms/{roomId}/events/`
**And** an unauthenticated request to any room path is rejected with `PERMISSION_DENIED`

**Given** a room document where `createdBy == uid_A`
**When** `uid_B` (not the owner) attempts to update `rooms/{roomId}.status`
**Then** the write is rejected with `PERMISSION_DENIED`

**Given** an event document where `actorId == uid_A`
**When** `uid_B` attempts to set `undone: true` on that event and `uid_B` is not the room owner
**Then** the write is rejected with `PERMISSION_DENIED`

**Given** the project root
**When** `firebase.json` and `.firebaserc` are present
**Then** `firebase deploy --only firestore:rules` completes without error

### Story 1.4: Feature-First Project Structure & Core Utilities

As a developer,
I want the complete feature-first directory structure and core utilities scaffolded,
So that all future stories have a consistent, architecture-compliant file organization from the start.

**Acceptance Criteria:**

**Given** the Firebase-wired project from Story 1.2
**When** the feature-first structure is created manually
**Then** the following directories exist: `mobile/lib/app/`, `mobile/lib/core/firebase/`, `mobile/lib/features/room/data/`, `mobile/lib/features/room/domain/`, `mobile/lib/features/room/presentation/`, `mobile/lib/features/game/data/`, `mobile/lib/features/game/domain/`, `mobile/lib/features/game/presentation/`, `mobile/lib/features/game/presentation/widgets/`

**Given** the structure above
**When** `mobile/lib/core/firebase/firestore_paths.dart` is created
**Then** it contains typed path helpers/constants for `rooms`, `rooms/{id}/players`, and `rooms/{id}/events` collections
**And** no other Dart file in the project contains hardcoded Firestore path strings

**Given** `mobile/lib/app/app.dart` is created
**When** the app runs
**Then** `MaterialApp` is initialized with a dark-theme seed based on the design token `#0D0F14`
**And** the bottom navigation bar with 4 placeholder tabs (Match / Historique / Joueurs / Room) is visible

**Given** the test directory
**When** the mirror structure is verified
**Then** `mobile/test/features/game/` and `mobile/test/features/room/` directories exist
**And** `mobile/integration_test/` directory exists

**Given** `flutter analyze` is run on the full project
**Then** zero lint errors are reported
**And** `print()` calls are flagged as lint warnings (analysis_options configured accordingly)

### Story 1.5: Internal APK Build & Distribution Setup

As a developer,
I want a reproducible internal APK build pipeline,
So that testers can install and validate the app on Android devices without public store publication.

**Acceptance Criteria:**

**Given** the complete scaffold from Stories 1.1–1.4
**When** `flutter build apk --release` is run
**Then** a valid `.apk` file is produced at `mobile/build/app/outputs/flutter-apk/app-release.apk`
**And** the APK installs successfully on a physical Android device via `adb install`

**Given** the installed APK on an Android device
**When** the app is launched
**Then** the app starts within 10 seconds (NFR3)
**And** anonymous Firebase authentication completes silently
**And** the bottom navigation with 4 tabs is displayed
**And** no crash or unhandled exception occurs on cold start

---

## Epic 2: Match Room Lifecycle

Un joueur peut créer une room avec un code partageable, rejoindre une room existante via son code, voir les participants connectés en temps réel, et le room owner peut démarrer, gérer la propriété et clôturer la session — permettant à tout groupe de commencer un match collaboratif en moins de 5 minutes.

### Story 2.1: Room Domain Models & Repository

As a developer,
I want the `RoomModel`, `PlayerModel`, and `room_repository.dart` implemented,
So that all room-related data operations have a typed, testable foundation before any UI is built.

**Acceptance Criteria:**

**Given** `mobile/lib/features/room/domain/models.dart`
**When** it is created
**Then** `RoomModel` contains: `id`, `status` (enum: waiting/active/closed), `currentRound`, `createdBy`, `createdAt`
**And** `PlayerModel` contains: `id`, `name`, `role` (RoleEnum: owner/player), `cp`, `vpByRound` (Map<String, Map<String, int>>), `connected`, `color` (hex String)
**And** `RoleEnum` has values `owner` and `player`
**And** both models have `fromFirestore()` and `toMap()` methods

**Given** `mobile/lib/features/room/data/room_repository.dart`
**When** it is created
**Then** it exposes: `createRoom(String ownerName)`, `joinRoom(String code, String playerName)`, `streamRoom(String roomId)`, `streamPlayers(String roomId)`
**And** all Firestore paths are imported from `firestore_paths.dart` — no hardcoded strings
**And** Firestore errors are caught at repository level and never propagated raw to the UI

### Story 2.2: Create Room & Lobby Screen

As a match owner,
I want to create a new room and see its shareable code in a lobby screen,
So that I can invite other players to join before starting the match.

**Acceptance Criteria:**

**Given** the app is open on the home/lobby screen
**When** the owner taps "Créer une room" and enters their name
**Then** a new room document is created in Firestore with `status: waiting`, `createdBy: uid`, and a unique readable room code
**And** the lobby screen displays the room code prominently (large, copyable)
**And** the owner's `PlayerModel` is created in `rooms/{id}/players/{uid}` with `role: owner` and color `#4FC3F7`

**Given** the lobby screen is visible
**When** a second player joins (via Story 2.3)
**Then** the owner sees the new player appear in the participant list in real time via Firestore stream
**And** each player entry shows `PlayerPresenceBadge` with their assigned color and online status (UX-DR7)

**Given** the lobby screen
**When** fewer than 2 players are connected
**Then** the "Lancer le match" button is disabled (opacity 0.38, non-tappable)

### Story 2.3: Join Room by Code

As a player,
I want to join an existing room by entering its code,
So that I can participate in a match session created by another player.

**Acceptance Criteria:**

**Given** the home screen
**When** a player enters a valid room code and their name and taps "Rejoindre"
**Then** a `PlayerModel` is created for that player in `rooms/{id}/players/{uid}` with `role: player` and color `#EF5350` (or next available color)
**And** the player is navigated to the lobby screen showing existing participants

**Given** a player attempts to join with an invalid or non-existent room code
**When** the join action is submitted
**Then** an inline error message is shown (no blocking dialog)
**And** the player remains on the join screen

**Given** a player joins while the room `status` is `active` or `closed`
**When** the join action is submitted
**Then** an appropriate inline error is shown ("Match déjà en cours" / "Room fermée")

### Story 2.4: Start Match Session

As a room owner,
I want to start the match session from the lobby,
So that all connected players are moved to the active match screen simultaneously.

**Acceptance Criteria:**

**Given** the lobby screen with at least 2 connected players
**When** the owner taps "Lancer le match"
**Then** the room document's `status` is updated to `active` and `currentRound` is set to `1`
**And** all connected clients detect the status change via Firestore stream and navigate to the match screen
**And** the transition happens within the NFR1 performance target (overall onboarding <5 minutes)

**Given** a non-owner player in the lobby
**When** they view the "Lancer le match" button
**Then** the button is not visible or is rendered as disabled with no action bound

### Story 2.5: Player Presence & Room Management Screen

As a room owner,
I want to see who is currently connected during the match and manage the room,
So that I can monitor participation and handle edge cases like ownership transfer or closing the room.

**Acceptance Criteria:**

**Given** the Room tab (tab 3, `room_management_screen.dart`)
**When** a player disconnects or reconnects
**Then** their `PlayerPresenceBadge` updates to reflect the new online/offline status in real time

**Given** the Room tab
**When** the owner views the screen
**Then** each player entry shows name, color badge, and online/offline presence indicator
**And** an ownership transfer control is visible only to the current owner

**Given** the owner triggers ownership transfer to another player
**When** the transfer is confirmed
**Then** `rooms/{id}.createdBy` is updated to the new owner's `uid`
**And** the new owner's `PlayerModel.role` is updated to `owner`
**And** the previous owner's role is updated to `player`

**Given** the owner taps "Terminer le match"
**When** the action is confirmed
**Then** `rooms/{id}.status` is updated to `closed`
**And** all clients receive the status change and are navigated back to the home screen

**Given** any participant (non-owner)
**When** they tap "Quitter la room"
**Then** their `PlayerModel.connected` is set to `false`
**And** other participants' presence views update accordingly
**And** the remaining session is unaffected

### Story 2.6: Players Screen — Connected Participants View

As a participant,
I want to see all connected players and their presence status on the Players tab,
So that I can identify who is in the room at any time during the match.

**Acceptance Criteria:**

**Given** the Players tab (tab 2, `players_screen.dart`) is active
**When** the screen renders
**Then** a list of all room participants is displayed, one row per player
**And** each row shows a `PlayerPresenceBadge` with the player's name, assigned color, and online/offline status (UX-DR7)
**And** the list is visible to all participants (not owner-only)

**Given** a player connects or disconnects while the Players screen is open
**When** the Firestore `streamPlayers(roomId)` updates
**Then** the affected player's presence indicator updates in real time without requiring navigation or refresh

**Given** the Players screen is open during an active match
**When** the current user is a non-owner participant
**Then** no ownership management controls are visible (those are in the Room tab, tab 3)

---

## Epic 3: Live Match Score & Resource Tracking

Les joueurs peuvent saisir les VP Primaires et VP Secondaires par round dans un ScoreGrid 5 rounds côte à côte, voir les scores héros cumulés de tous les joueurs en temps réel, et gérer les Command Points depuis l'écran principal sans navigation — transformant l'app en source de vérité partagée pour tout le match.

### Story 3.1: Game Domain Models & Pure Business Rules

As a developer,
I want `GameState`, `game_rules.dart` pure functions, and `event_repository.dart` scaffolded,
So that all match logic is testable in isolation before any UI is built.

**Acceptance Criteria:**

**Given** `mobile/lib/features/game/domain/game_rules.dart`
**When** it is created
**Then** it contains pure functions: `canMutate(actorId, roomCreatedBy, targetPlayerId)` → bool, `vpTotal(Map<String, Map<String, int>> vpByRound)` → int, `autoIncrementCp(PlayerModel)` → PlayerModel (adds +1 CP)
**And** zero Firestore imports exist in this file
**And** unit tests in `mobile/test/features/game/game_rules_test.dart` cover: ownership enforcement, host override, vpTotal derivation from vpByRound, +1 CP on round advance

**Given** `mobile/lib/features/game/domain/game_state.dart`
**When** it is created
**Then** it exposes a `GameState` class derived from a `RoomModel` snapshot + list of events
**And** `GameState` exposes: `currentRound`, `players` (with derived VP totals), `activeRound`

**Given** `mobile/lib/features/game/data/event_repository.dart`
**When** it is created
**Then** it exposes: `appendEvent(roomId, eventData)` and `streamEvents(roomId)`
**And** `appendEvent` writes to `rooms/{roomId}/events/` via `firestore_paths.dart`
**And** Firestore errors are caught at repository level

### Story 3.2: Score Grid Widget & Round Score Cell

As a player,
I want to see the full 5-round score grid for both players side by side,
So that the complete match scoring state is visible at a glance without any navigation.

**Acceptance Criteria:**

**Given** the match screen with an active room
**When** `ScoreGridWidget` is rendered
**Then** a grid with 5 round rows and columns for Player 1 (VP Prim, VP Sec) and Player 2 (VP Prim, VP Sec) plus a total column is displayed
**And** the grid fits within the screen width without horizontal scroll on devices ≥ 360dp (UX-DR2)

**Given** `RoundScoreCell` for a past round with data
**When** rendered
**Then** it displays VP Prim and VP Sec on two lines with total below in `Roboto Mono 20sp` (state: `filled`)

**Given** `RoundScoreCell` for the current active round
**When** rendered
**Then** it shows a colored outline in the owning player's color (state: `active`)

**Given** `RoundScoreCell` for a future round
**When** rendered
**Then** it is grayed out with `text-muted` color and non-interactive (state: `future`)

**Given** a cell owned by another player and current user is not owner
**When** rendered
**Then** a lock icon (12px, 0.3 opacity) is shown in the top-right corner (state: `locked`, UX-DR16)

### Story 3.3: Round Score Entry Bottom Sheet

As a player,
I want to tap my active round cell and enter VP Primaires and VP Secondaires in a bottom sheet,
So that I can declare my round score in under 3 gestures.

**Acceptance Criteria:**

**Given** the match screen with `currentRound = N`
**When** a player taps their own active `RoundScoreCell`
**Then** a `ModalBottomSheet` opens with two numeric input fields: "VP Primaires" and "VP Secondaires"
**And** the numeric keyboard is shown automatically (`keyboardType: numeric`)
**And** each field has a minimum height of 56dp with 12dp padding
**And** a single full-width confirmation button "Confirmer Round N" is shown in the player's accent color

**Given** the bottom sheet is open and valid values are entered
**When** the player taps the confirmation button
**Then** a `score_update` event is appended to `rooms/{id}/events/` with `type: 'score_update'`, `actorId`, `targetPlayerId`, `before`, `after` containing `{round, type: 'prim'|'sec', value}`
**And** `PlayerModel.vpByRound` is updated in Firestore for that round
**And** the bottom sheet closes
**And** the `RoundScoreCell` transitions to `filled` state

**Given** a non-owner player taps a cell belonging to another player
**When** the tap is registered
**Then** `OwnershipLockFeedback` triggers: micro-vibration + discrete inline message (UX-DR10)
**And** the bottom sheet does NOT open

**Given** the room owner taps any player's active `RoundScoreCell`
**When** the tap is registered
**Then** the bottom sheet opens normally for that player's data

### Story 3.4: Score Hero Bar & Real-Time Score Broadcast

As a player,
I want to see both players' cumulative VP totals prominently at the top of the match screen,
So that the current match standing is readable at a glance from across the table.

**Acceptance Criteria:**

**Given** the active match screen
**When** `ScoreHeroBar` is rendered
**Then** two large score totals are shown side by side in `Roboto Mono 56sp Bold`, each in the player's assigned color (UX-DR1)
**And** scores are derived via `game_rules.vpTotal(vpByRound)` — never stored as a scalar aggregate

**Given** a player on Client B updates their score via Story 3.3
**When** the Firestore write is confirmed
**Then** Client A's `ScoreHeroBar` and `ScoreGridWidget` update within the near-instant latency target (NFR4)
**And** the updated `RoundScoreCell` on all clients shows a 200ms opacity flash in the scoring player's color (UX-DR13)

### Story 3.5: Command Points Counter & Round Advancement

As a player,
I want to increment or decrement my Command Points from the main match screen and advance the round,
So that CP management never interrupts the flow of play.

**Acceptance Criteria:**

**Given** the active match screen
**When** `ResourceCounter` is rendered for each player's CP
**Then** the counter displays the current CP value with `+` and `−` buttons (min 40dp wide × 48dp tall, UX-DR5)
**And** the CP strip is always visible without any navigation

**Given** a player taps `+` or `−` on their own CP counter
**When** the tap is registered
**Then** a `cp_adjust` event is appended to `rooms/{id}/events/` with `before` and `after` values
**And** `PlayerModel.cp` is updated in Firestore
**And** `HapticFeedback.lightImpact()` is triggered
**And** all clients see the updated CP value in real time

**Given** a non-owner attempts to tap another player's CP counter
**When** the tap is registered
**Then** `OwnershipLockFeedback` triggers and no Firestore write occurs

**Given** the owner taps "Avancer le round" (round advancement control)
**When** the action is confirmed
**Then** `rooms/{id}.currentRound` is incremented by 1
**And** `game_rules.autoIncrementCp()` is applied to all players: each player's CP is increased by +1
**And** a `turn_advance` event is appended to `rooms/{id}/events/`
**And** all clients receive the round update and the ScoreGrid highlights the new active round cells

---

## Epic 4: Action Safety & Dispute Resolution

Les joueurs peuvent compter sur l'app pour protéger toutes les mutations sensibles via confirmations explicites, accéder à une timeline d'événements complète avec attribution acteur/action/avant/après, et résoudre les disputes avec un undo contrôlé — garantissant la confiance dans le résultat final de chaque match.

### Story 4.1: Append-Only Event Log & History Screen

As a player,
I want to see a chronological list of all match actions with actor, action type, before and after values,
So that I can verify what happened at any point during the match without relying on memory.

**Acceptance Criteria:**

**Given** the Historique tab (tab 1, `history_screen.dart`)
**When** the screen is opened
**Then** a scrollable list of `EventTimelineItem` widgets is displayed, one per committed event
**And** each item shows: actor name (with player color), action type label, before value, after value, and timestamp (UX-DR8)
**And** events are ordered chronologically, most recent at the top
**And** events with `undone: true` are visually distinguished (e.g. strikethrough or muted style)

**Given** a new event is committed by any player
**When** the Firestore events stream updates
**Then** the new item appears at the top of the history list in real time on all connected clients
**And** the update occurs without requiring any navigation or manual refresh

**Given** the history screen
**When** any participant (not only the owner) views it
**Then** all events are visible regardless of which player performed them (FR21, FR30)

### Story 4.2: Two-Step Undo with State Recalculation

As a room owner,
I want to undo the latest eligible event using a two-step confirmation,
So that accidental or erroneous actions can be safely corrected without risk of mis-tap.

**Acceptance Criteria:**

**Given** the Historique screen with at least one undoable event (not already `undone: true`)
**When** the owner taps the "Undo dernier événement" button
**Then** `TwoStepConfirmButton` renders: first tap arms the button (visual change + label update to "Confirmer l'annulation"), second tap within timeout executes the undo (UX-DR9)
**And** if no second tap occurs within the timeout, the button resets to its initial state

**Given** the two-step confirmation is completed by the owner
**When** the undo is executed
**Then** `event_repository` calls `eventRef.update({'undone': true})` — no hard Firestore delete is performed
**And** `rooms/{id}/players/{id}` state is recalculated to reflect the pre-event values (FR23)
**And** a new `undo` event is appended to the events collection recording the rollback

**Given** a non-owner player views the Historique screen
**When** the screen renders
**Then** the undo button is not visible or is disabled — undo is owner-only

**Given** the undo is executed on a `cp_adjust` event
**When** recalculation occurs
**Then** the affected player's `cp` is restored to the `before` value
**And** all connected clients see the updated CP via Firestore stream

**Given** the undo is executed on a `score_update` event
**When** recalculation occurs
**Then** the affected player's `vpByRound` entry for the relevant round is restored to the `before` value
**And** `ScoreHeroBar` and `ScoreGridWidget` update on all clients in real time

**Given** `mobile/test/features/game/event_repository_test.dart`
**When** tests are run
**Then** append + undo semantics are covered: append creates event with `undone: false`, undo sets `undone: true` without deleting, double-undo on same event is rejected

### Story 4.3: Ownership Enforcement & Owner Override

As a player,
I want all match mutations to enforce ownership rules consistently,
So that only authorized players can modify any given resource, preventing accidental or unauthorized changes.

**Acceptance Criteria:**

**Given** any mutating action (score update, CP adjust, turn advance)
**When** the action is initiated
**Then** `game_rules.canMutate(actorId, roomCreatedBy, targetPlayerId)` is called before any Firestore write
**And** if `canMutate` returns `false`, no write occurs and `OwnershipLockFeedback` is triggered (UX-DR10)
**And** if `canMutate` returns `true`, the write proceeds normally

**Given** a room owner performing an action on any player's resources
**When** `canMutate` is evaluated
**Then** it returns `true` regardless of `targetPlayerId` (owner override, FR19)

**Given** a non-owner player performing an action on another player's resources
**When** `canMutate` is evaluated
**Then** it returns `false` (FR18)

**Given** Firestore Security Rules (implemented in Story 1.3)
**When** a client attempts a write that violates ownership server-side
**Then** the write is rejected with `PERMISSION_DENIED`
**And** the rejection is caught by the repository and surfaced as a non-blocking inline error — no raw exception propagates to the UI

**Given** `mobile/test/features/game/game_rules_test.dart`
**When** ownership tests run
**Then** all combinations are covered: self-edit ✅, owner-on-any ✅, non-owner-on-other ❌

---

## Epic 5: Realtime Sync & Offline Resilience

Tous les joueurs voient le même état de match simultanément avec une latence perçue quasi-nulle, et un joueur qui se déconnecte en cours de partie peut rejoindre transparairement sans perte de données ni reconstruction manuelle — garantissant la continuité du match dans toutes les conditions réseau réalistes.

### Story 5.1: Firestore Offline Persistence & Sync Status Indicator

As a player,
I want my pending match actions to be preserved locally when I lose connectivity,
So that a temporary disconnect doesn't cause data loss or require me to redo my actions.

**Acceptance Criteria:**

**Given** Firebase is initialized in `main.dart`
**When** `FirebaseFirestore.instance.settings` is configured
**Then** `PersistenceSettings(cacheSizeBytes: CACHE_SIZE_UNLIMITED)` is applied
**And** Firestore offline persistence is active for all collections

**Given** `SyncStatusIndicator` widget is rendered globally in the app shell (UX-DR6)
**When** the device is fully connected and all writes are confirmed
**Then** the indicator shows a green pulsing dot with label "Synchronisé"

**Given** one or more Firestore writes are pending (queued locally)
**When** the sync indicator observes the pending state
**Then** the indicator shows an orange dot with label "En attente..."

**Given** the device has no network connectivity
**When** the sync indicator detects offline state
**Then** the indicator shows a red dot with label "Hors ligne"
**And** all destructive actions (undo) in the UI are disabled while offline

### Story 5.2: Transparent Reconnect & State Recovery

As a player,
I want to automatically recover the full match state when I reconnect after a disconnect,
So that I can rejoin a match mid-session without any manual intervention or data loss.

**Acceptance Criteria:**

**Given** a player who has disconnected mid-match (network loss)
**When** network connectivity is restored
**Then** Firestore SDK re-establishes the stream subscription automatically — no user action required (FR25)
**And** the `SyncStatusIndicator` transitions from red → orange → green
**And** the match screen reflects the latest authoritative Firestore state within the near-instant latency target (NFR4)

**Given** actions were taken locally while offline (queued in Firestore cache)
**When** connectivity is restored and the queue is reconciled
**Then** queued writes are applied to Firestore in deterministic order (FR27)
**And** no duplicate mutations occur (FR29, NFR12)
**And** the event log reflects the reconciled sequence without gaps or duplicates

**Given** a player reconnects and their `PlayerModel.connected` was set to `false` during disconnect
**When** reconnection is detected
**Then** `PlayerModel.connected` is updated to `true` in Firestore
**And** other participants' `PlayerPresenceBadge` for that player updates to online in real time

### Story 5.3: Multi-Client Sync Integration Test

As a developer,
I want an automated integration test that validates realtime sync and undo across two simulated clients,
So that the core synchronization contract is regression-protected before any public usage.

**Acceptance Criteria:**

**Given** `mobile/integration_test/multiplayer_sync_test.dart`
**When** the test runs with two Firestore client instances in the same room
**Then** a score update written by Client A is received by Client B within the near-instant latency window
**And** an undo executed by Client A (owner) is reflected on Client B's event list with `undone: true`
**And** no duplicate events appear after reconciliation

**Given** Client B simulates an offline period then reconnects
**When** the test runs the reconnect scenario
**Then** Client B's state matches Client A's authoritative state after reconnection
**And** any locally queued actions from Client B are applied once without duplication

---

## Epic 6: Voice Command Interaction (Post-MVP)

Le room owner peut contrôler les opérations de match en mode mains-libres via des commandes vocales sur son propre appareil, avec confirmation pour les actions sensibles et fallback manuel toujours disponible — préservant le flow de jeu dans les moments critiques sans dépendance obligatoire à la voix.

### Story 6.1: Microphone Permission & Voice Mode Foundation

As a room owner,
I want the app to declare microphone permission and provide a toggleable voice mode,
So that the voice command infrastructure is in place and can be activated without affecting players who don't use it.

**Acceptance Criteria:**

**Given** `mobile/android/app/src/main/AndroidManifest.xml`
**When** the app is built
**Then** `RECORD_AUDIO` permission is declared
**And** the permission prompt is only shown when the owner explicitly attempts to enable voice mode (contextual, non-disruptive)

**Given** the Room management screen (tab 3)
**When** the owner views it
**Then** a "Activer le mode voix" toggle is visible only to the owner
**And** toggling it on requests microphone permission if not yet granted
**And** toggling it off disables voice mode immediately with no Firestore write

**Given** the voice mode toggle is enabled
**When** `rooms/{id}` is observed
**Then** a `voiceEnabled: true` field is written to the room document
**And** all clients can read this flag (for future UI indicators)

**Given** voice mode is disabled or microphone permission is denied
**When** any voice action would normally trigger
**Then** no voice processing occurs and manual controls remain fully functional (FR38)

### Story 6.2: Owner-Device Voice Command Processing

As a room owner,
I want to issue voice commands from my device to perform match actions hands-free,
So that I can update match state during a turn without interrupting the physical play flow.

**Acceptance Criteria:**

**Given** voice mode is active on the owner's device
**When** the owner issues a supported voice command (e.g. "avancer le round", "+1 PC joueur 1", "undo")
**Then** the command is recognized and mapped to the corresponding match action
**And** the recognized action is displayed on screen for owner review before execution (FR36)

**Given** the recognized voice command is a non-destructive action (e.g. "+1 CP")
**When** the owner confirms
**Then** the corresponding event is appended to `rooms/{id}/events/` as a standard room event (FR37)
**And** all clients reflect the update in real time

**Given** the recognized voice command is a destructive action (e.g. "undo")
**When** the action is presented for confirmation
**Then** explicit owner confirmation is required before execution (FR36)
**And** the two-step confirmation flow from Story 4.2 is reused

**Given** voice command recognition fails or produces an unsupported command
**When** the failure occurs
**Then** an inline non-blocking message is shown ("Commande non reconnue")
**And** no Firestore write occurs
**And** manual controls remain immediately accessible (FR38)

**Given** voice command authority
**When** any voice action is evaluated
**Then** `game_rules.canMutate` is applied as for manual actions — voice does not bypass ownership rules (FR39)

### Story 6.3: Voice Command Fallback & Manual Parity

As a room owner,
I want every voice-supported action to have an equivalent manual control,
So that voice mode failure or unavailability never blocks match progress.

**Acceptance Criteria:**

**Given** voice mode is active
**When** any voice-supported action exists (turn advance, CP adjust, undo)
**Then** the corresponding manual control in the match UI is still visible and fully functional

**Given** voice mode is toggled off mid-match
**When** the toggle is disabled
**Then** no in-progress voice commands are executed
**And** all manual controls remain unaffected
**And** the match state is not altered by the toggle action itself

**Given** the microphone hardware is unavailable or permission is revoked
**When** voice mode is attempted
**Then** the app degrades gracefully to manual-only mode
**And** an inline non-blocking message informs the owner of the fallback state