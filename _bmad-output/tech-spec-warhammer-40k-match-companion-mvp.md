---

## title: 'Warhammer 40K Match Companion MVP'
slug: 'warhammer-40k-match-companion-mvp'
created: '2026-03-21'
status: 'ready-for-dev'
stepsCompleted: [1, 2, 3, 4]
tech_stack: ['Dart 3', 'Flutter', 'Firebase Auth (Anonymous)', 'Cloud Firestore', 'Flutter test', 'Integration test']
files_to_modify: ['mobile/pubspec.yaml', 'mobile/lib/main.dart', 'mobile/lib/app/app.dart', 'mobile/lib/features/room/data/room_repository.dart', 'mobile/lib/features/room/domain/models.dart', 'mobile/lib/features/room/presentation/room_screen.dart', 'mobile/lib/features/game/data/event_repository.dart', 'mobile/lib/features/game/domain/game_state.dart', 'mobile/lib/features/game/domain/game_rules.dart', 'mobile/lib/features/game/presentation/game_screen.dart', 'mobile/lib/features/game/presentation/widgets/two_step_confirm_button.dart', 'mobile/lib/features/game/presentation/widgets/event_timeline.dart', 'mobile/lib/core/firebase/firebase_options.dart', 'mobile/lib/core/firebase/firestore_paths.dart', 'mobile/test/features/game/game_rules_test.dart', 'mobile/test/features/game/event_repository_test.dart', 'mobile/test/features/game/two_step_confirm_button_test.dart', 'mobile/integration_test/multiplayer_sync_test.dart']
code_patterns: ['Confirmed clean slate: create modular feature-first Flutter structure', 'Event sourcing light: append-only events collection + derived game state', 'Ownership and role guards: player-only self edits, host override', 'Two-step confirmation wrapper for sensitive actions', 'Optimistic UI with Firestore realtime listeners and rollback support']
test_patterns: ['Given/When/Then acceptance format', 'Unit tests for game rules and event application', 'Widget tests for two-step confirmation UX', 'Integration test for multi-client realtime synchronization']

# Tech-Spec: Warhammer 40K Match Companion MVP

**Created:** 2026-03-21

## Overview

### Problem Statement

Pendant une partie de Warhammer 40K, le suivi des points et ressources est souvent manuel et sujet aux erreurs. Les joueurs ont besoin d'une source de verite partagee, en temps reel, simple a utiliser en pleine partie.

### Solution

Construire une application mobile Flutter Android-first avec synchronisation temps reel via Firestore. Le MVP inclut room de partie, ownership par joueur, automatisation simple (+1 PC), actions sensibles en 2 taps et rollback du dernier evenement avec historique.

### Scope

**In Scope:**

- Creation de room et invitation par code
- Rejoindre une room en anonyme
- Suivi temps reel des scores/PV/PC/ressources
- Attribution auto de +1 PC au debut de tour/round selon regle configuree
- Actions sensibles avec confirmation en 2 taps
- Undo du dernier evenement et historique minimal des actions

**Out of Scope:**

- Comptes utilisateurs persistants (email/social)
- Personnalisation avancee des profils
- Historique global multi-parties par utilisateur
- Regles avancees par faction/detachement et mode tournoi complet
- Anti-cheat avance et moderation competitive

## Context for Development

### Codebase Patterns

**Confirmed Clean Slate:** aucun code applicatif mobile existant detecte dans ce workspace.  
Le feature set MVP doit donc definir un bootstrap complet avec structure projet Flutter feature-first.

Patterns a appliquer:

- Architecture `feature-first` (`features/room`, `features/game`, `core/firebase`)
- Repositories minces pour Firestore + modeles de domaine explicites
- Flux evenementiel (`events` append-only) pour audit et undo dernier event
- Derivation de l'etat de partie depuis snapshot room + dernieres mutations
- Garde-fous metier: ownership joueur, host override, confirmations sensibles en 2 taps

### Files to Reference


| File                                                                    | Purpose                                                     |
| ----------------------------------------------------------------------- | ----------------------------------------------------------- |
| `_bmad-output/brainstorming/brainstorming-session-2026-03-21-185615.md` | Decisions produit issues de la session brainstorming        |
| `_bmad-output/tech-spec-wip.md`                                         | Source de verite du spec technique en cours                 |
| `mobile/lib/features/room/...`                                          | Creation/rejoindre room, gestion participants, code de room |
| `mobile/lib/features/game/...`                                          | Ecran de partie, score/PC, workflow 2 taps, historique/undo |
| `mobile/lib/core/firebase/...`                                          | Initialisation Firebase, chemins Firestore centralises      |
| `mobile/test/...`                                                       | Tests unitaires + widget sur regles et UX sensible          |
| `mobile/integration_test/...`                                           | Validation sync multi-joueurs en temps reel                 |


### Technical Decisions

- Stack: Flutter + Firebase (Firestore + Auth anonyme)
- Plateforme cible initiale: Android first
- Portabilite: architecture Flutter preparee pour extension iOS sans rework majeur
- Auth: anonyme au MVP, comptes persistants en phase suivante
- Mode de securite UX: confirmation 2 taps pour actions sensibles + rollback dernier event
- Firestore model:
  - `rooms/{roomId}`: metadonnees partie (`status`, `currentRound`, `createdBy`, `createdAt`)
  - `rooms/{roomId}/players/{playerId}`: etat joueur (`name`, `role`, `cp`, `vp`, `connected`)
  - `rooms/{roomId}/events/{eventId}`: journal (`type`, `actorId`, `targetPlayerId`, `before`, `after`, `timestamp`, `undone`)
- Undo scope MVP: dernier evenement uniquement, auteur ou host autorise
- Auto `+1 PC`: declenche a l'avance de round/tour via action metier explicite (pas cron backend MVP)

## Implementation Plan

### Tasks

- Task 1: Bootstrap Flutter project structure and Firebase dependencies
  - File: `mobile/pubspec.yaml`
  - Action: Add required packages for Firebase Core/Auth/Firestore, state management, and test tooling.
  - Notes: Keep dependency set minimal for MVP; avoid adding analytics/crash tooling now.
- Task 2: Initialize app entrypoint and Firebase boot sequence
  - File: `mobile/lib/main.dart`
  - Action: Initialize Flutter bindings, Firebase, anonymous auth handshake, and mount root app.
  - Notes: Fail fast with explicit startup error surface if Firebase init fails.
- Task 3: Create application shell and route flow
  - File: `mobile/lib/app/app.dart`
  - Action: Implement root MaterialApp, theme baseline, and navigation between room setup and game screen.
  - Notes: Keep route model simple (named routes or direct Navigator); optimize for MVP speed.
- Task 4: Define Firestore path helpers and shared Firebase config access
  - File: `mobile/lib/core/firebase/firestore_paths.dart`
  - Action: Centralize all collection/document path builders for rooms, players, and events.
  - Notes: Avoid hardcoded strings in feature repositories.
- Task 5: Add generated Firebase options and environment wiring
  - File: `mobile/lib/core/firebase/firebase_options.dart`
  - Action: Add platform Firebase options scaffold for Android-first target.
  - Notes: Keep structure compatible with future iOS onboarding.
- Task 6: Implement room domain models
  - File: `mobile/lib/features/room/domain/models.dart`
  - Action: Create typed models for Room, Player, and role/connection states with Firestore serialization.
  - Notes: Include fields needed by ownership and host-override logic.
- Task 7: Implement room repository for create/join/listen flows
  - File: `mobile/lib/features/room/data/room_repository.dart`
  - Action: Add methods to create room, join by code, subscribe to room/player state, and update connectivity.
  - Notes: Enforce anonymous user presence and idempotent join behavior.
- Task 8: Build room UI flow (create/join + lobby state)
  - File: `mobile/lib/features/room/presentation/room_screen.dart`
  - Action: Implement screen to create room, join with code, display participants, and start match.
  - Notes: Ensure Android-first ergonomic layout with large tap targets.
- Task 9: Implement game state and event application logic
  - File: `mobile/lib/features/game/domain/game_state.dart`
  - Action: Define current game view model derived from room snapshot + event stream.
  - Notes: Keep deterministic reducer-like event application to support undo consistency.
- Task 10: Implement game business rules (ownership, +1PC, sensitive actions)
  - File: `mobile/lib/features/game/domain/game_rules.dart`
  - Action: Encode guards for player self-edit, host override, auto +1PC turn advance, and valid event transitions.
  - Notes: Design pure functions so rule tests stay fast and isolated.
- Task 11: Implement event repository (append event + undo last event)
  - File: `mobile/lib/features/game/data/event_repository.dart`
  - Action: Add append-only writes to events subcollection and undo-last-event flow with authorization checks.
  - Notes: Undo MVP scope = latest event only; mark undone instead of delete.
- Task 12: Build reusable two-step confirmation component
  - File: `mobile/lib/features/game/presentation/widgets/two_step_confirm_button.dart`
  - Action: Implement generic 2-tap confirmation control used by sensitive game actions.
  - Notes: Include cancel timeout/reset behavior to reduce accidental confirms.
- Task 13: Build event timeline widget
  - File: `mobile/lib/features/game/presentation/widgets/event_timeline.dart`
  - Action: Render compact chronological event log with actor, action, before/after values, and undo badge.
  - Notes: Optimize readability during active gameplay.
- Task 14: Build game screen (scores, PC, turn controls, sensitive actions)
  - File: `mobile/lib/features/game/presentation/game_screen.dart`
  - Action: Integrate realtime game state, action controls, 2-step confirmations, auto-turn progression, and undo trigger.
  - Notes: Keep interactions low-friction; prioritize clarity over dense feature set.
- Task 15: Add rule-level unit tests
  - File: `mobile/test/features/game/game_rules_test.dart`
  - Action: Test ownership guards, host override, auto +1PC logic, and invalid transition rejection.
  - Notes: Cover happy path and edge cases for unauthorized actions.
- Task 16: Add repository unit tests for event write/undo behavior
  - File: `mobile/test/features/game/event_repository_test.dart`
  - Action: Validate append-only event persistence and single-step undo semantics.
  - Notes: Mock Firestore interactions for deterministic tests.
- Task 17: Add widget tests for two-step confirmation UX
  - File: `mobile/test/features/game/two_step_confirm_button_test.dart`
  - Action: Verify first tap arms confirmation, second tap executes action, and timeout reset behavior.
  - Notes: Ensure accidental single taps do not commit sensitive actions.
- Task 18: Add multiplayer realtime integration test
  - File: `mobile/integration_test/multiplayer_sync_test.dart`
  - Action: Simulate two anonymous clients in same room and assert synchronized score/PC state propagation.
  - Notes: Include one undo scenario to validate cross-client reconciliation.

### Acceptance Criteria

- AC 1: Given a user opens the app without account, when startup completes, then anonymous auth is created and user can create or join a room.
- AC 2: Given a host creates a room, when a second player joins with the room code, then both clients see the same participant list in realtime.
- AC 3: Given a player attempts to edit another player's private resource, when action is submitted, then the action is rejected by business rules.
- AC 4: Given the host performs an override on a player's resource, when confirmed, then the event is accepted and visible to all clients.
- AC 5: Given turn advance is triggered, when rule conditions are met, then +1 PC is automatically applied and logged as an event.
- AC 6: Given a sensitive action (mission validation, PC adjust, VP adjust), when user taps once, then no mutation occurs until second confirmation tap.
- AC 7: Given a sensitive action is armed for confirmation, when timeout/cancel occurs before second tap, then action is discarded without state mutation.
- AC 8: Given an event is committed, when timeline is displayed, then actor, action type, before/after values, and timestamp are visible.
- AC 9: Given the latest event was created by current player or host, when undo is requested, then latest event is marked undone and state is recalculated on all clients.
- AC 10: Given a user without permission attempts undo, when action is triggered, then undo is denied and no state change occurs.
- AC 11: Given one client updates score/PC, when Firestore listener receives update on second client, then both clients display identical state within realtime sync latency.
- AC 12: Given network reconnect happens mid-match, when client re-subscribes, then room, players, and event timeline restore to latest consistent state.

## Additional Context

### Dependencies

- Flutter SDK stable
- Firebase project (Firestore + Anonymous Auth)
- Dart SDK compatible with selected Flutter stable channel
- Android emulator/device setup for local validation
- Firebase CLI / FlutterFire configuration tooling for `firebase_options.dart`

### Testing Strategy

- Unit tests:
  - Validate pure game rules (ownership, host override, auto +1PC)
  - Validate event reducer consistency with undo marker behavior
- Widget tests:
  - Validate 2-step confirmation interaction contract
  - Validate timeline rendering for normal and undone events
- Integration tests:
  - Two-client room synchronization scenario
  - Undo propagation and state reconciliation across clients
- Manual verification:
  - Android device flow: create room -> join room -> run turn -> sensitive action confirm -> undo
  - Disconnect/reconnect smoke test during active room

### Notes

- High-risk items:
  - Firestore security rules must match ownership/host override semantics
  - Realtime conflict handling when near-simultaneous actions occur
- Known MVP limitations:
  - Undo limited to latest event only
  - No persistent user profile/history yet (anonymous session model)
- Future considerations:
  - Account system and cross-match history
  - Rule packs for mission/faction variants
  - iOS release hardening once Android MVP usage validated

