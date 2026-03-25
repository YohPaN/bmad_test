---
stepsCompleted:
  - step-01-init
  - step-02-discovery
  - step-02b-vision
  - step-02c-executive-summary
  - step-03-success
  - step-04-journeys
  - step-05-domain
  - step-06-innovation
  - step-07-project-type
  - step-08-scoping
  - step-09-functional
  - step-10-nonfunctional
inputDocuments:
  - _bmad-output/brainstorming/brainstorming-session-2026-03-21-185615.md
  - _bmad-output/tech-spec-warhammer-40k-match-companion-mvp.md
documentCounts:
  briefCount: 0
  researchCount: 0
  brainstormingCount: 1
  projectDocsCount: 0
workflowType: 'prd'
projectName: 'cursor_project'
author: 'Vartus'
date: '2026-03-21'
classification:
  projectType: mobile_app
  domain: general
  complexity: medium
  projectContext: greenfield
---

# Product Requirements Document - cursor_project

**Author:** Vartus  
**Date:** 2026-03-21

## Executive Summary

Warhammer Match Companion is an Android-first mobile utility for tabletop Warhammer 40K matches, built to provide a shared, real-time source of truth for scores, command points, and key match resources. It targets local multiplayer sessions where players need fast, low-friction state updates without interrupting gameplay flow.  
The product solves a deeper trust-and-rhythm problem: manual tracking methods create disputes, context switching, and cognitive overhead during turns. The MVP focuses on reliable room-based synchronization, ownership-aware actions, event history, and controlled undo so players can keep momentum while maintaining confidence in match state.

### What Makes This Special

The differentiator is "flow-preserving reliability": the app is designed for in-match use, not post-match recordkeeping. Sensitive actions use explicit two-step confirmation to reduce accidental mutations, while an event timeline and undo-last-event model preserve transparency and recoverability across players.  
A key insight is that perceived fairness matters as much as numerical correctness in competitive and casual tabletop play. A future voice-command layer (hands-free updates during occupied moments) strengthens this advantage by minimizing physical interaction cost while preserving synchronized trust.

## Project Classification

- **Project Type:** Mobile app  
- **Domain:** General (tabletop match companion utility)  
- **Complexity:** Medium  
- **Project Context:** Greenfield

## Success Criteria

### User Success

- Players can create or join a room and start tracking a match in **under 5 minutes**, with a stretch target of **under 1 minute** for recurring users.
- Core in-match updates (resources, score, command points, undo) complete in **under 30 seconds** per action.
- The "aha" moment is when players can run a full match without paper tracking and finish with a **clear, trusted final result**.

### Business Success

- **3-month success:** stable usage by the initial core group (you + friends), with regular match tracking sessions and no workflow blockers.
- **12-month success:** expand usage to a small local community (including potential use in your local game store), while preserving simplicity and reliability.
- Primary success signal is **continued repeat usage** by real tables rather than broad acquisition at this stage.

### Technical Success

- State synchronization across participants should feel **instant** during active play.
- System must minimize data loss risk, especially in reconnect scenarios (e.g., player disconnects mid-match and state remains recoverable).
- Initial app load should complete in **under 10 seconds**.

### Measurable Outcomes

- Room creation/join/start completed within target time for most sessions.
- In-match actions consistently completed within the 30-second target.
- Reconnect scenarios recover usable match state without manual reconstruction.
- Repeated real-world sessions from your core group over time.

## Product Scope

### MVP - Minimum Viable Product

- Real-time game rooms for multiplayer tabletop sessions.
- Player resource/state management (score/VP/CP and relevant match resources).
- Undo/rollback of latest actions.
- Visual identity with a **futuristic Warhammer-inspired design direction**.

### Growth Features (Post-MVP)

- Additional convenience and polish features beyond core tracking/reliability.
- Broader sharing/onboarding improvements if local store adoption begins.
- Expanded gameplay-support capabilities after core loop is validated.

### Vision (Future)

- Voice command mode using a **single listening device** (room owner's phone) as first implementation.
- Later expansion to broader voice interaction models once reliability and UX are validated in real sessions.

## User Journeys

### Journey 1 - Primary User (Success Path): Match Owner Runs a Clean Game

**Opening scene:** Vartus arrives for a friendly in-store match. Usually, everyone tracks numbers differently, and disagreements appear quickly.  
**Rising action:** He creates a room, shares the code, and players join in under 5 minutes. During the match, key updates are captured in the app with instant synchronization for all participants.  
**Climax:** A critical score moment happens late in a round; every player sees the same value at the same time, with no dispute.  
**Resolution:** The match ends with a clear, trusted result. The owner keeps game flow without constantly arbitrating score disagreements.

### Journey 2 - Primary User (Edge Case): Disconnect During a Critical Turn

**Opening scene:** Mid-turn, a player disconnects right after a sensitive action attempt.  
**Rising action:** The player reconnects; room state resynchronizes, and the event timeline shows what was actually applied.  
**Climax:** A perceived inconsistency is identified and quickly resolved using the event history and, when authorized, undo of the latest event.  
**Resolution:** The table resumes with confidence. Players feel control and trust instead of stress.

### Journey 3 - Admin/Operations User: Room Owner Maintains Match Integrity

**Opening scene:** The room owner must keep play fast while preserving fairness.  
**Rising action:** The owner monitors connected players, uses two-step confirmation for sensitive actions, and can correct obvious mistakes via latest-event rollback.  
**Climax:** During a disagreement, the owner resolves it quickly using a clear timeline (actor, action, before/after).  
**Resolution:** Critical decisions are made quickly and transparently, and gameplay continues without major interruption.

### Journey 4 - Support/Troubleshooting Context: Friends or Local Store Resolution

**Opening scene:** A nearby table stalls on a "who changed what?" dispute.  
**Rising action:** A reference player or owner opens the room timeline, verifies event order, and isolates the issue.  
**Climax:** The group applies the fastest safe correction (often undo latest event, then re-apply correctly).  
**Resolution:** The issue is resolved in minutes without restarting tracking or prolonging debate.

### Journey Requirements Summary

- Fast onboarding flow to create/join/start a room in under 5 minutes (target 1 minute for repeat users)
- Reliable real-time synchronization so all players see the same state during active play
- Operational auditability through readable event timeline with actor/action/before/after
- Recovery resilience through reconnect restoration and controlled undo of latest event
- Lightweight room governance so owner can resolve disputes quickly without heavy admin workflows
- Flow-first UX with short interactions and minimal cognitive overhead during match play

## Domain-Specific Requirements

### Compliance & Regulatory

- No formal regulated-industry compliance is required for MVP (not healthcare/fintech/govtech).
- Community safety baseline still applies: avoid abusive room names/content where feasible.
- If local store rollout happens, prepare clear usage terms and lightweight moderation guidance.

### Technical Constraints

- Realtime consistency is critical during active play; updates should propagate near-instantly.
- Offline/disconnect resilience is mandatory to prevent match-state loss and trust breakdown.
- Access control must enforce player ownership with explicit room-owner override paths.
- Sensitive actions require confirmation and auditable event history.

### Integration Requirements

- Core integration: Firebase Auth (anonymous) + Cloud Firestore for room/player/event data.
- Optional post-MVP integrations: store tournament workflow tools, export/share mechanisms.

### Risk Mitigations

- **Risk:** Score/resource disputes due to conflicting actions  
  **Mitigation:** append-only event timeline + before/after audit + latest-event undo.
- **Risk:** Disconnect during critical moments  
  **Mitigation:** reconnect restore flow with deterministic state rebuild.
- **Risk:** Mis-taps in high-tempo play  
  **Mitigation:** two-step confirmation for sensitive mutations.
- **Risk:** UX friction harms adoption  
  **Mitigation:** keep MVP interaction model minimal and fast; prioritize core loop reliability.

## Innovation & Novel Patterns

### Detected Innovation Areas

- **Flow-preserving match operations:** the product is optimized for in-match continuity, not just score storage.
- **Trust-centered state model:** append-only event history + before/after trace + controlled latest-event undo for dispute resolution.
- **Single-device voice control concept:** first implementation uses only the room owner's phone as the listening endpoint, reducing multi-device complexity while delivering hands-free utility.

### Market Context & Competitive Landscape

- Typical alternatives (paper notes, generic counters, shared sheets) are either not synchronized or not designed for low-friction tabletop conflict resolution.
- Existing tools often optimize either convenience or transparency, but rarely both under active match pressure.
- The proposed owner-centric voice interaction could differentiate by minimizing interaction cost without introducing immediate cross-device voice complexity.

### Validation Approach

- Run real-table pilots with your core group and compare against baseline sessions (without app).
- Validate three hypotheses:
  1. room sync reduces disputes,
  2. timeline + undo shortens conflict resolution time,
  3. owner-only voice commands reduce interaction overhead in critical turns.
- Start with a narrow voice command set (e.g., turn advance, +1 PC, undo latest) and measure practical reliability before expansion.

### Risk Mitigation

- **Risk:** voice false positives in noisy environments  
  **Mitigation:** push-to-talk or explicit wake interaction, confirmation for sensitive commands.
- **Risk:** over-promising innovation before core stability  
  **Mitigation:** keep voice as staged rollout after core realtime loop proves reliable.
- **Risk:** perceived complexity from advanced features  
  **Mitigation:** preserve simple default UX; expose advanced controls progressively.
- **Risk:** owner-device dependency  
  **Mitigation:** fallback manual controls always available; no hard lock to voice path.

## Mobile App Specific Requirements

### Project-Type Overview

The product will be built as a cross-platform mobile app using Flutter, with Android-first execution for MVP speed and future expansion readiness. The app is designed for live tabletop match operations where reliability, synchronization, and low-friction input matter more than broad feature breadth at launch.

### Technical Architecture Considerations

- **Platform strategy:** Flutter cross-platform architecture retained; Android is the primary target for MVP validation.
- **Offline strategy:** local mutation queue is required (`offline mode B`) so players can continue key actions during temporary disconnects; queued actions synchronize when connectivity returns.
- **Realtime model:** Firestore-backed near-instant room synchronization remains the primary consistency mechanism.
- **Notification strategy:** push notifications are out of MVP scope and deferred to post-MVP.
- **Device capability scope:** microphone capability is included as a forward-compatible foundation for owner-device voice command workflows.

### Platform Requirements

- Android-first packaging and runtime validation.
- Cross-platform codebase conventions maintained to avoid major iOS rework later.
- Deployment profile optimized for internal testing and rapid iteration.

### Device Permissions & Features

- **MVP permission target:** microphone access (future voice-control readiness, even if full voice UX is phased).
- No additional sensor-heavy dependencies required for MVP.
- Permission prompts must be contextual and minimally disruptive to gameplay flow.

### Offline Mode Requirements

- Queue local match events while offline/disconnected.
- Reconcile queued updates safely on reconnect with deterministic ordering.
- Provide user-visible sync status so players understand when actions are pending vs confirmed.
- Preserve audit trail integrity during offline-to-online reconciliation.

### Store & Distribution Considerations

- **MVP distribution:** private/internal channel (APK/internal testing), not public store launch.
- Public shop distribution is a future option and should be evaluated later against platform policies and IP/legal considerations (including potential Games Workshop-related constraints before any commercial/public listing).

### Implementation Considerations

- Keep MVP architecture modular by feature (`room`, `game`, shared `core`) to support staged rollout of voice and notifications.
- Prioritize robustness in reconnect/replay/undo paths before adding growth UX.
- Treat voice as a controlled expansion path (owner device first) after core reliability metrics are met.

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** problem-solving MVP focused on trusted realtime match tracking for small local groups.  
**Resource Requirements:** solo builder (you) with optional occasional tester support from friends; no dedicated ops requirement at MVP stage.

### MVP Feature Set (Phase 1)

**Core User Journeys Supported:**

- Host creates room, players join quickly, and match starts with shared state.
- Players update resources and score with near-instant synchronization.
- Table resolves mistakes quickly via event history and latest-event undo.
- Reconnect restores usable state after temporary disconnect.

**Must-Have Capabilities:**

- Room creation and join flow.
- Realtime shared state for core match resources.
- Ownership-aware action model with host override path.
- Event timeline with actor/action/before/after.
- Latest-event undo (controlled).
- Offline queue with reconnect reconciliation.
- Fast, flow-friendly UI for in-match usage.
- Internal/private distribution workflow (APK/internal testing).

### Post-MVP Features

**Phase 2 (Post-MVP):**

- UX polish and faster onboarding improvements.
- Push notifications (invites/rejoin reminders).
- Better sharing and export options.
- Wider local community adoption support (e.g., store usage patterns).

**Phase 3 (Expansion):**

- Voice command workflow (owner-device listening first).
- Broader voice interaction model and command set.
- Potential store/public distribution, pending policy and IP/legal review.
- Additional advanced gameplay assistance and scaling capabilities.

### Risk Mitigation Strategy

**Technical Risks:** realtime consistency and offline queue reconciliation complexity.  
**Mitigation:** keep event model deterministic, narrow command/action surface in MVP, prioritize reconnect/undo reliability testing.

**Market Risks:** product may solve only a small user circle initially.  
**Mitigation:** validate through repeated sessions in your group, then run a small local-store pilot before broader release.

**Resource Risks:** solo development bandwidth limits scope and polish speed.  
**Mitigation:** enforce strict must-have boundaries, defer non-core features, and release iterative internal builds.

## Functional Requirements

### Room Lifecycle & Session Management

- FR1: A match owner can create a new match room.
- FR2: A player can join an existing room using a room code.
- FR3: The system can associate each participant with a unique player identity within a room.
- FR4: A room owner can start an active match session once participants are present.
- FR5: A room owner can end or close a match session.
- FR6: A participant can view current room membership and player presence state.
- FR7: A room owner can transfer or reassign ownership within a room.
- FR8: A participant can leave a room without breaking other participants' active session.

### Match State & Resource Tracking

- FR9: A player can view current shared match state for all participants in the room.
- FR10: A player can update their own tracked match resources.
- FR11: A room owner can update any player's tracked match resources when needed.
- FR12: The system can apply turn/round progression updates to match state.
- FR13: The system can apply configured automatic resource increments tied to turn/round progression.
- FR14: A participant can view the current turn/round context of the match.
- FR15: A participant can view current score-related values for all players.

### Action Governance, Safety & Recovery

- FR16: The system can require explicit confirmation before committing sensitive match actions.
- FR17: A participant can cancel a pending sensitive action before it is committed.
- FR18: The system can enforce player-ownership rules for restricted actions.
- FR19: The system can enforce owner-override permissions for authorized corrections.
- FR20: The system can preserve a chronological event record of committed match actions.
- FR21: A participant can view actor and state-change context for recorded events.
- FR22: An authorized participant can undo the latest eligible event.
- FR23: The system can recalculate current match state after an undo action.

### Realtime Consistency & Reconnect Continuity

- FR24: The system can synchronize committed state updates across all connected participants in the same room.
- FR25: A reconnecting participant can recover the latest valid room and match state.
- FR26: The system can preserve pending local actions during temporary offline periods.
- FR27: The system can reconcile queued offline actions after connectivity returns.
- FR28: A participant can view whether their actions are pending synchronization or confirmed.
- FR29: The system can prevent duplicated state mutations during reconnect reconciliation.

### Visibility, Trust & Dispute Resolution

- FR30: A participant can inspect the event timeline to resolve "who changed what" questions.
- FR31: A room owner can use historical event context to resolve player disputes.
- FR32: The system can provide sufficient action traceability to support trusted final match outcomes.
- FR33: A participant can identify the latest authoritative state after conflict resolution actions.

### Voice Interaction Expansion Path

- FR34: A room owner can enable or disable owner-device voice control mode for a room.
- FR35: The system can accept owner-device voice commands for an approved command subset.
- FR36: The system can require confirmation for sensitive actions initiated via voice.
- FR37: The system can execute supported voice commands as standard room events.
- FR38: The system can provide fallback manual execution for all voice-supported actions.
- FR39: The system can restrict voice command authority to the room owner profile in the initial voice model.

### Distribution & Operational Use

- FR40: The product can be distributed through internal/private channels for MVP validation.
- FR41: A tester can install and run MVP builds without public store publication.
- FR42: The product can support small-group and local-store pilot usage patterns.

## Non-Functional Requirements

### Performance

- NFR1: The system shall allow users to create or join a room and reach match-ready state within 5 minutes for first-time sessions, with a 1-minute target for repeat users.
- NFR2: Core in-match user actions (resource/score updates, turn progression, undo requests) shall complete user-visible processing within 30 seconds.
- NFR3: Initial application startup shall complete within 10 seconds on supported Android devices under normal network conditions.
- NFR4: Realtime state updates shall propagate to connected room participants with near-instant perceived latency during active play.

### Security

- NFR5: All data in transit between client and backend services shall be encrypted using industry-standard transport security.
- NFR6: Match data at rest shall be protected using managed backend encryption controls.
- NFR7: Access control shall enforce player-level ownership boundaries and owner-level override permissions.
- NFR8: Sensitive actions (including high-impact state mutations) shall require explicit confirmation before commit.
- NFR9: MVP public exposure risk shall be limited by using private/internal distribution channels only.

### Reliability

- NFR10: The system shall preserve match continuity through temporary client disconnects and reconnections without requiring manual full-state rebuild by users.
- NFR11: The system shall maintain an auditable event history sufficient to reconstruct authoritative match state after disputes or recovery flows.
- NFR12: The system shall prevent duplicated mutations during reconnect and queued-action reconciliation flows.
- NFR13: Undo and recovery behaviors shall keep state consistent across all connected participants after resolution actions.

### Scalability

- NFR14: The MVP architecture shall support growth from a small core user group to local community/store pilot usage without redesign of core domain model.
- NFR15: The system shall maintain stable match operations for small multiplayer rooms typical of tabletop sessions.
- NFR16: The product shall support phased capability expansion (notifications, voice features, wider distribution) without breaking core match workflows.

### Accessibility

- NFR17: Core gameplay interactions shall remain usable with clear, legible controls and tap targets suitable for fast in-match operation.
- NFR18: Critical state information (scores/resources/turn context) shall be presented in a way that minimizes ambiguity and cognitive load during active play.
- NFR19: Confirmation and error/recovery messaging shall be explicit enough to prevent accidental irreversible actions.

### Integration

- NFR20: The product shall integrate with anonymous authentication and realtime data services required for room-based multiplayer operation.
- NFR21: Integration behaviors shall support deterministic event ordering and state reconstruction requirements.
- NFR22: External distribution or ecosystem integrations beyond MVP shall remain optional and decoupled from core match functionality.

