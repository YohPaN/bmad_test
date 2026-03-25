---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
lastStep: 8
status: 'complete'
completedAt: '2026-03-24'
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/tech-spec-warhammer-40k-match-companion-mvp.md
  - _bmad-output/brainstorming/brainstorming-session-2026-03-21-185615.md
workflowType: 'architecture'
project_name: 'cursor_project'
user_name: 'Vartus'
date: '2026-03-24'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Starter Template Evaluation

### Primary Technology Domain

Mobile application (Flutter + Firebase) — Android-first, cross-platform codebase.

### Selected Starter: flutter create (Flutter CLI officiel)

**Rationale:** Clean slate volontaire. Architecture feature-first custom incompatible avec tout boilerplate tiers. Le starter Flutter officiel fournit la fondation minimale correcte, la structure feature-first étant construite manuellement.

**Initialization Command:**

```bash
flutter create \
  --org com.vartus \
  --template=app \
  --platforms=android \
  --description="Warhammer 40K Match Companion" \
  mobile
```

**Architectural Decisions Provided by Starter:**

- **Language & Runtime:** Dart 3, null-safety enforced
- **Build Tooling:** Gradle (Android), Flutter stable toolchain
- **Testing Framework:** flutter_test (unit/widget) + integration_test
- **Linting:** analysis_options.yaml, Flutter recommended ruleset
- **Project Structure:** lib/main.dart bootstrapped → restructured to feature-first manually
- **Development Experience:** Hot reload, Flutter DevTools, Android emulator support

**Post-Init Firebase Packages (pubspec.yaml):**
firebase_core, firebase_auth, cloud_firestore — added as first implementation task.

**Note:** Project initialization using this command should be the first implementation story.

## Core Architectural Decisions

### Decision Priority Analysis

**Already Decided (from tech spec & PRD):**
- Stack: Flutter (Dart 3) + Firebase (Firestore + Anonymous Auth)
- Architecture: feature-first (`features/room`, `features/game`, `core/firebase`)
- Data model: event sourcing léger — append-only events subcollection
- Platform: Android-first, cross-platform Flutter codebase

**Decisions Made in This Step:**

### Data Architecture

**Firestore Schema (confirmed):**
- `rooms/{roomId}` — `status`, `currentRound`, `createdBy`, `createdAt`
- `rooms/{roomId}/players/{playerId}` — `name`, `role`, `cp`, `vpByRound`, `connected`, `color`
  - `vpByRound` : `Map<String, Map<String, int>>` — ex. `{'1': {'prim': 3, 'sec': 7}, '2': {'prim': 5, 'sec': 2}}`
  - `color` : String hex — assigné à la création de room (`#4FC3F7` joueur 1, `#EF5350` joueur 2, extensible post-MVP)
  - Note : champ `vp` scalaire supprimé — le total VP est **dérivé** de `vpByRound` par `game_rules.dart` (pure function)
- `rooms/{roomId}/events/{eventId}` — `type`, `actorId`, `targetPlayerId`, `before`, `after`, `timestamp`, `undone`
  - Pour `score_update` : `before`/`after` contiennent `{round, type: 'prim'|'sec', value}`

**Offline Queue Strategy:** Firestore native offline persistence (`enablePersistence()` / `PersistenceSettings`) — leverages the SDK cache automatically for MVP. Avoids custom queue complexity.

**Undo Scope:** Latest event only. Undo = set `undone: true` on the document. Never hard delete events.

### Authentication & Security

**Authentication:** Firebase Anonymous Auth — no persistent accounts at MVP.

**Firestore Security Rules (to implement):**
- Players can only write to their own `/players/{uid}` document
- Events can be appended by any authenticated room member
- Undo (`undone: true`) restricted to event author OR room host (`createdBy`)
- Room `status` field writable only by host (`request.auth.uid == resource.data.createdBy`)

### State Management (Flutter)

**Choice:** `StreamBuilder` natif Flutter on Firestore streams — zero external dependency for MVP, directly maps Firestore realtime listeners to UI. Game state derived as a pure function from room snapshot + event stream.

**Rationale:** Simplest approach for solo builder MVP; Riverpod can be introduced post-MVP if complexity grows.

### Infrastructure & Deployment

**Distribution:** APK internal testing (no public store for MVP).
**CI/CD:** Manual local builds for MVP — no CI pipeline overhead at this stage.

### Decision Impact Analysis

**Implementation Sequence:**
1. Flutter project bootstrap + Firebase wiring
2. Firestore Security Rules implementation
3. Room feature (create/join/lobby)
4. Game feature (state, events, rules, UI)
5. Offline persistence validation + reconnect flow
6. Integration tests (multi-client sync)

**Cross-Component Dependencies:**
- `core/firebase` must be initialized before `room` or `game` features
- Game state derivation depends on both `room` snapshot and `events` stream
- Ownership guards shared between security rules (Firestore) and business rules (game_rules.dart)

## Implementation Patterns & Consistency Rules

### Naming Patterns

**Code (Dart) Naming Conventions:**

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Classes / Models / Widgets | `PascalCase` | `RoomModel`, `TwoStepConfirmButton` |
| Fichiers | `snake_case.dart` | `room_repository.dart`, `game_state.dart` |
| Variables / fonctions | `camelCase` | `currentRound`, `joinRoom()` |
| Constantes | `SCREAMING_SNAKE_CASE` | `MAX_PLAYERS` |

**Firestore Naming Conventions:**

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Collections | `camelCase` | `rooms`, `players`, `events` |
| Champs documents | `camelCase` | `createdAt`, `actorId`, `targetPlayerId` |
| Event type values | `snake_case` string | `'score_update'`, `'cp_adjust'`, `'turn_advance'` |
| IDs | Firebase auto-ID (`doc()`) | Pas de format custom |

### Structure Patterns

**Feature-first layout (règle absolue) :**
- Chaque feature est auto-contenue : `data/`, `domain/`, `presentation/`
- Aucune dépendance directe entre `features/room` et `features/game` — communication via modèles de domaine partagés uniquement
- `core/firebase/firestore_paths.dart` est le seul fichier autorisé à contenir des chaînes de chemins Firestore

**Tests — organisation miroir :**
- `mobile/test/` reproduit la structure de `mobile/lib/` (ex. `test/features/game/game_rules_test.dart`)
- Tests d'intégration multi-clients dans `mobile/integration_test/` uniquement

### Format Patterns

**Sérialisation Firestore :**
- Timestamps : `Timestamp` Firestore natif — jamais de String ISO en base
- Booléens : `true/false` Dart natif — jamais `0/1` ni `null` pour les flags
- Undo flag : champ `bool undone` obligatoire sur chaque event document

**Game Event types (valeurs canoniques) :**
```
score_update | cp_adjust | vp_adjust | turn_advance | player_join | player_disconnect | undo
```

### Process Patterns

**Règle d'ownership universelle :**
> Toute action mutatrice vérifie `actorId == currentUser.uid OR room.createdBy == currentUser.uid` AVANT écriture Firestore — tant dans `game_rules.dart` (couche métier) que dans les Firestore Security Rules.

**Undo pattern (immuabilité des events) :**
```dart
// TOUJOURS soft-delete via flag — JAMAIS de delete Firestore
eventRef.update({'undone': true});
```

**Two-step confirmation (règle UI) :**
> Seules les **actions destructives** (undo d'un événement) passent par `TwoStepConfirmButton`. Les saisies courantes (VP Prim, VP Sec par round, CP adjust) sont confirmées en **1 tap** via bottom sheet — ce sont des saisies, pas des destructions. Aucun `showDialog` ad-hoc pour l'undo.

**Error handling :**
- Erreurs Firestore : catchées au niveau repository uniquement, jamais propagées raw vers l'UI
- `debugPrint()` autorisé en développement — `print()` interdit

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
The system must support a real-time multi-player room model where a host creates a room with a shareable code and players join anonymously. Core in-match operations cover resource tracking (VP, CP, scores), ownership-aware mutations (player self-edits + host override), two-step confirmation for sensitive actions, append-only event logging with actor/action/before/after, single-event undo (mark undone, never delete), auto +1 CP on round advance, and offline queue reconciliation on reconnect.

**Non-Functional Requirements:**
- Real-time sync latency: perceived instant during active play (Firestore listeners)
- In-match action completion: < 30 seconds
- Room onboarding: < 5 minutes (1 min target for repeat users)
- Initial app load: < 10 seconds
- Disconnection resilience: full state recovery on reconnect with deterministic ordering
- Distribution: internal/private (APK/internal testing) for MVP

**Scale & Complexity:**
- Primary domain: Mobile real-time collaborative app (Flutter + Firebase)
- Complexity level: Medium
- Players per room: small N (2–6 typically), no multi-tenancy at scale
- Estimated architectural components: 4 (room, game, core/firebase, offline queue)

### Technical Constraints & Dependencies

- Flutter SDK (stable) — Android-first, cross-platform codebase
- Firebase Anonymous Auth — no persistent accounts at MVP
- Cloud Firestore — real-time listeners as primary consistency mechanism
- No push notifications, no server-side functions (MVP scope)
- No public store distribution (IP/legal review deferred)
- Microphone permission declared for future voice readiness only

### Cross-Cutting Concerns Identified

1. **Ownership & Authorization** — enforced at business rule layer + Firestore Security Rules
2. **Event Integrity** — append-only events collection; undo = soft mark, never hard delete
3. **Offline Resilience** — local queue with deterministic reconciliation on reconnect
4. **State Derivation** — game state derived from room snapshot + event stream (reducer model); VP total derived from `vpByRound` map (pure function, no stored aggregate)
5. **Testability** — pure functions for game rules, mock Firestore for repository tests
6. **UI Safety** — two-step confirmation wrapper (`TwoStepConfirmButton`) für undo uniquement — actions de saisie en 1 tap
7. **Connectivity Awareness** — `SyncStatusIndicator` global toujours visible (synced/pending/offline); UI bloque les actions destructives en état offline

## Project Structure & Boundaries

### Complete Project Directory Structure

```
cursor_project/
└── mobile/
    ├── pubspec.yaml                                    ← firebase_core, firebase_auth, cloud_firestore
    ├── analysis_options.yaml                           ← Flutter recommended linting rules
    ├── android/
    │   └── app/google-services.json                   ← Firebase Android config (FlutterFire generated)
    ├── integration_test/
    │   └── multiplayer_sync_test.dart                 ← 2-client realtime sync + undo cross-client
    ├── test/
    │   └── features/
    │       └── game/
    │           ├── game_rules_test.dart               ← ownership, host override, +1CP, transitions
    │           ├── event_repository_test.dart         ← append + undo semantics, mock Firestore
    │           └── two_step_confirm_button_test.dart  ← arm/execute/timeout/cancel contract
    └── lib/
        ├── main.dart                                  ← Flutter bindings + Firebase init + anon auth
        ├── app/
        │   └── app.dart                               ← MaterialApp, Warhammer theme, bottom nav 4 onglets (Match/Historique/Joueurs/Room), routing lobby↔match
        ├── core/
        │   └── firebase/
        │       ├── firebase_options.dart              ← FlutterFire generated, Android-first
        │       └── firestore_paths.dart               ← ALL Firestore path strings centralized here
        └── features/
            ├── room/
            │   ├── data/
            │   │   └── room_repository.dart           ← create, join by code, stream room/players
            │   ├── domain/
            │   │   └── models.dart                    ← RoomModel, PlayerModel (incl. color + vpByRound), RoleEnum
            │   └── presentation/
            │       ├── lobby_screen.dart              ← create/join form, code room affiché, attente joueurs
            │       └── room_management_screen.dart   ← gestion post-lobby: joueurs connectés, owner controls (bottom nav tab 3)
            └── game/
                ├── data/
                │   └── event_repository.dart          ← append event, undo last (auth check)
                ├── domain/
                │   ├── game_state.dart                ← GameState derived from room + events streams; VP total derived from vpByRound
                │   └── game_rules.dart                ← pure functions: ownership, host override, +1CP, vpTotal()
                └── presentation/
                    ├── match_screen.dart              ← écran principal match (bottom nav tab 0): ScoreHeroBar + ScoreGrid + CP strip
                    ├── history_screen.dart            ← historique événements + undo (bottom nav tab 1)
                    ├── players_screen.dart            ← liste joueurs connectés + présence (bottom nav tab 2)
                    └── widgets/
                        ├── score_hero_bar.dart        ← 2 grands scores totaux côte à côte (Roboto Mono 56sp, couleur joueur)
                        ├── score_grid_widget.dart     ← tableau 5 rounds × 2 types VP × 2 joueurs
                        ├── round_score_cell.dart      ← cellule ScoreGrid (états: empty/active/filled/locked/future)
                        ├── resource_counter.dart      ← compteur CP +/− avec feedback haptique
                        ├── sync_status_indicator.dart ← point pulsé état Firestore (synced/pending/offline)
                        ├── player_presence_badge.dart ← avatar couleur joueur + indicateur online/offline
                        ├── ownership_lock_feedback.dart ← micro-vibration + message inline si tap verrouillé
                        ├── two_step_confirm_button.dart  ← 2-tap confirm wrapper (undo uniquement)
                        └── event_timeline.dart           ← compact actor/action/before/after log
```

### Architectural Boundaries

**Feature Boundaries:**
- `features/room` owns the room lifecycle: creation, join, lobby (`lobby_screen`), and post-match room management (`room_management_screen`)
- `features/game` owns match state, business rules, and in-match UI: match screen, history screen, players screen, and all game widgets
- No direct imports between `features/room` and `features/game` — cross-feature navigation via `app.dart` only
- `core/firebase` is the only layer allowed to contain Firestore path strings or Firebase initialization logic

**Data Boundaries:**
- `firestore_paths.dart` = single source of truth for all Firestore collection/document paths
- `room_repository.dart` and `event_repository.dart` are the only files that read/write Firestore
- `game_rules.dart` = pure functions only, zero Firestore access, fully testable without mocks

**Data Flow:**
1. `main.dart` → Firebase init + anonymous auth → uid available via `FirebaseAuth.instance.currentUser`
2. Repository streams → `StreamBuilder` widgets in `lobby_screen`, `match_screen`, `history_screen`, `players_screen`, `room_management_screen`
3. `game_state.dart` merges room stream + events stream → single derived `GameState` for UI; `game_rules.vpTotal()` computes VP total from `vpByRound` map
4. Mutation path: UI widget → `game_rules.dart` guard → `event_repository.dart` Firestore write
5. `sync_status_indicator.dart` observes Firestore connection state → blocks destructive actions when offline

**Integration Points:**
- Firebase Anonymous Auth: initialized once in `main.dart`
- Firestore Security Rules: enforced server-side, mirroring ownership logic in `game_rules.dart`
- Firestore offline persistence: enabled at Firebase init via `PersistenceSettings(cacheSizeBytes: CACHE_SIZE_UNLIMITED)`

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**
All technology choices are compatible: Flutter (Dart 3) + Firestore is a well-established production pairing. Anonymous Auth integrates natively with Firestore Security Rules via `request.auth.uid`. Native `StreamBuilder` aligns directly with Firestore's realtime stream model. No version conflicts identified.

**Pattern Consistency:**
Naming conventions (camelCase Firestore fields, snake_case Dart files, PascalCase classes) are internally consistent and match Flutter/Dart community standards. The append-only event model supports both the audit timeline requirement and the undo-as-soft-mark pattern without conflict.

**Structure Alignment:**
Feature-first structure cleanly separates room and game concerns. The `core/firebase` layer correctly isolates infrastructure from business logic. Test mirror structure ensures every domain file has a corresponding test file.

### Requirements Coverage Validation ✅

**Functional Requirements Coverage:**
- ✅ Room creation/join by code → `room_repository` + `lobby_screen`
- ✅ Realtime sync → Firestore streams + `StreamBuilder`
- ✅ Ownership-aware mutations → `game_rules.dart` (pure guards)
- ✅ Two-step confirmation → `TwoStepConfirmButton` widget (undo uniquement)
- ✅ Event timeline → `history_screen` + `event_timeline.dart` + append-only events collection
- ✅ Undo last event → `event_repository.undo()` with `undone: true` flag
- ✅ Auto +1 CP on round advance → `game_rules.turnAdvance()` pure function
- ✅ VP par round (Prim + Sec) → `vpByRound` map in `PlayerModel`; `ScoreGridWidget` + `RoundScoreCell`
- ✅ Score héros en grand → `ScoreHeroBar` (Roboto Mono 56sp, couleur joueur)
- ✅ CP toujours visibles → `ResourceCounter` dans le bandeau match_screen
- ✅ Sync indicator global → `SyncStatusIndicator` (synced/pending/offline)
- ✅ Appartenance visuelle par joueur → champ `color` dans `PlayerModel`, `PlayerPresenceBadge`
- ✅ Offline queue → Firestore native persistence (`PersistenceSettings`)
- ✅ Reconnect restore → Firestore re-subscription on reconnect (SDK-managed)
- ✅ Offline queue → Firestore native persistence (`PersistenceSettings`)
- ✅ Reconnect restore → Firestore re-subscription on reconnect (SDK-managed)

**Non-Functional Requirements Coverage:**
- ✅ Realtime sync latency → Firestore realtime listeners (sub-second typical)
- ✅ Offline resilience → Firestore SDK cache with `CACHE_SIZE_UNLIMITED`
- ✅ Security → Firestore Security Rules + ownership guards in `game_rules.dart`
- ✅ Testability → Pure functions in `game_rules.dart`, mock-friendly repositories
- ✅ Android-first → `--platforms=android` flutter create flag

### Implementation Readiness Validation ✅

**Decision Completeness:** All critical decisions documented with rationale. Firestore schema fully specified. Security rule patterns defined. State management approach clear.

**Structure Completeness:** Every file from the tech spec is mapped to a concrete path in the directory structure. No orphaned requirements.

**Pattern Completeness:** Naming, structure, format, and process patterns all defined. Potential AI agent conflict points (Firestore path strings, ownership logic duplication, ad-hoc dialogs) are explicitly addressed with rules.

### Gap Analysis

**No critical gaps identified.**

**Minor items for post-MVP:**
- Riverpod migration path if state complexity grows
- Firestore Security Rules file (`firestore.rules`) not yet in project structure — add in bootstrap story
- `firebase.json` and `.firebaserc` for Firebase CLI deployment — add in bootstrap story

### Architecture Completeness Checklist

- [x] Project context analyzed and cross-cutting concerns mapped
- [x] Starter template selected with exact init command
- [x] Core architectural decisions documented (data, auth, state, deployment)
- [x] Implementation patterns & consistency rules defined
- [x] Complete project directory structure with all target files
- [x] Architectural boundaries and data flow documented
- [x] All functional requirements architecturally covered
- [x] All NFRs addressed

### Architecture Readiness Assessment

**Overall Status: READY FOR IMPLEMENTATION**

**First Implementation Steps:**
1. Run `flutter create` command (see Starter Template section)
2. Add Firebase packages to `pubspec.yaml`
3. Configure `firebase_options.dart` via FlutterFire CLI
4. Implement Firestore Security Rules (`firestore.rules`)
5. Bootstrap feature structure per directory tree above

**AI Agent Guideline:** All implementation agents must refer to this document for architecture decisions, naming conventions, file placement, and ownership logic. The `game_rules.dart` ownership pattern and `firestore_paths.dart` centralization rule are non-negotiable.
