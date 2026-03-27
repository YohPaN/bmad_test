# Story 1.3: Firestore Security Rules & Firebase CLI Configuration

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want Firestore Security Rules deployed and Firebase CLI config in place,
so that data access is enforced server-side and matches the ownership model from the architecture before any data is written.

## Acceptance Criteria

1. **Given** a `firestore.rules` file at `mobile/` (project Firebase root)  
   **When** the rules are deployed via Firebase CLI (`firebase deploy --only firestore:rules`)  
   **Then** an authenticated user can read and write to their own `/rooms/{roomId}/players/{uid}` document  
   **And** an authenticated user can create (append) a new document to `/rooms/{roomId}/events/`  
   **And** an unauthenticated request to any room path is rejected with `PERMISSION_DENIED`

2. **Given** a room document where `createdBy == uid_A`  
   **When** `uid_B` (not the owner) attempts to update `rooms/{roomId}.status`  
   **Then** the write is rejected with `PERMISSION_DENIED`

3. **Given** an event document where `actorId == uid_A`  
   **When** `uid_B` attempts to set `undone: true` on that event and `uid_B` is not the room owner  
   **Then** the write is rejected with `PERMISSION_DENIED`

4. **Given** `mobile/firebase.json` (with `"firestore"` section added) and `mobile/.firebaserc` are present  
   **When** `firebase deploy --only firestore:rules` is run from `mobile/`  
   **Then** the command completes without error

## Tasks / Subtasks

- [x] Task 1 — Create `mobile/firestore.rules` with complete security rules (AC: #1, #2, #3)
  - [x] Create `mobile/firestore.rules` with the following content (see Dev Notes for exact rules):
    - `isAuthenticated()` helper: `request.auth != null`
    - `isRoomOwner(roomId)` helper: fetches room doc and checks `createdBy == uid`
    - `/rooms/{roomId}`: any authenticated user can read; authenticated user can create; only owner can update `status` field
    - `/rooms/{roomId}/players/{uid}`: any authenticated user can read; only own `uid` can create; own `uid` OR room owner can update
    - `/rooms/{roomId}/events/{eventId}`: any authenticated user can read and create; update only allowed for setting `undone: true` — restricted to event `actorId` OR room owner; delete forbidden

- [x] Task 2 — Update `mobile/firebase.json` to add Firebase CLI firestore config (AC: #4)
  - [x] Open `mobile/firebase.json` (currently contains FlutterFire `"flutter"` section only)
  - [x] Add a `"firestore"` section alongside the existing `"flutter"` section:
    ```json
    {
      "firestore": {
        "rules": "firestore.rules",
        "indexes": "firestore.indexes.json"
      },
      "flutter": { ... existing content ... }
    }
    ```
  - [x] Preserve all existing `"flutter"` config untouched

- [x] Task 3 — Create `mobile/firestore.indexes.json` (AC: #4)
  - [x] Create `mobile/firestore.indexes.json` with empty indexes (required by Firebase CLI):
    ```json
    {
      "indexes": [],
      "fieldOverrides": []
    }
    ```

- [x] Task 4 — Create `mobile/.firebaserc` with project reference (AC: #4)
  - [x] Create `mobile/.firebaserc`:
    ```json
    {
      "projects": {
        "default": "whcompagnion"
      }
    }
    ```

- [x] Task 5 — Validate rules deployment (AC: #1, #2, #3, #4)
  - [x] From `mobile/`, run: `firebase deploy --only firestore:rules`
  - [x] Confirm command exits without error
  - [ ] (Optional) Using Firebase Console's Rules Playground, verify each security rule scenario from the acceptance criteria

## Dev Notes

### Starting Point — What Exists After Story 1.2

```
mobile/
├── pubspec.yaml                    ← firebase_core ^3.13.1, firebase_auth ^5.5.2, cloud_firestore ^5.6.7
├── analysis_options.yaml           ← flutter_lints + avoid_print: true
├── firebase.json                   ← FlutterFire CLI format only (no firestore section yet)
├── lib/
│   ├── main.dart                   ← Firebase.initializeApp + Firestore offline persistence + signInAnonymously
│   └── core/
│       └── firebase/
│           └── firebase_options.dart  ← FlutterFire generated (Android, project: whcompagnion)
├── android/
│   └── app/
│       ├── google-services.json    ← FlutterFire generated
│       └── ...
└── test/
    └── widget_test.dart
```

**Key environment notes from Story 1.2:**
- Firebase project ID: `whcompagnion`
- Application ID: `com.vartus.mobile`
- Firebase Tools: v15.11.0 (installed globally via npm)
- FlutterFire CLI: v1.3.1 (invoked via `dart pub global run flutterfire_cli:flutterfire`)
- JDK 20 configured via `org.gradle.java.home` in `android/gradle.properties` — do not alter

### `mobile/firestore.rules` — Complete File Content

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ─── Helper Functions ──────────────────────────────────────────────────
    function isAuthenticated() {
      return request.auth != null;
    }

    function isRoomOwner(roomId) {
      return isAuthenticated() &&
             request.auth.uid ==
               get(/databases/$(database)/documents/rooms/$(roomId)).data.createdBy;
    }

    // ─── Rooms ─────────────────────────────────────────────────────────────
    match /rooms/{roomId} {
      // Any authenticated user can read a room
      allow read: if isAuthenticated();

      // Any authenticated user can create a room
      allow create: if isAuthenticated();

      // Updates: only owner may change 'status' field (and any other field)
      // Non-owners may NOT update 'status' under any circumstance
      allow update: if isAuthenticated() && (
        !request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['status']) ||
        request.auth.uid == resource.data.createdBy
      );

      // Hard delete forbidden — rooms are never deleted at MVP
      allow delete: if false;

      // ─── Players Subcollection ──────────────────────────────────────────
      match /players/{uid} {
        // Any authenticated user can read player documents in the room
        allow read: if isAuthenticated();

        // A player can only create their own player document
        allow create: if isAuthenticated() && request.auth.uid == uid;

        // A player can update their own doc; room owner can override any player doc
        allow update: if isAuthenticated() &&
                         (request.auth.uid == uid || isRoomOwner(roomId));

        allow delete: if false;
      }

      // ─── Events Subcollection ───────────────────────────────────────────
      match /events/{eventId} {
        // Any authenticated user can read events
        allow read: if isAuthenticated();

        // Any authenticated user can append (create) an event
        allow create: if isAuthenticated();

        // Update ONLY to set 'undone: true' — restricted to event author OR room owner
        // Hard delete is FORBIDDEN — undo is always a soft-mark
        allow update: if isAuthenticated() &&
                         request.resource.data.diff(resource.data)
                           .affectedKeys().hasOnly(['undone']) &&
                         request.resource.data.undone == true &&
                         (request.auth.uid == resource.data.actorId ||
                          isRoomOwner(roomId));

        allow delete: if false;
      }
    }
  }
}
```

**Critical ownership note:** The `isRoomOwner()` function uses `get()` to fetch the parent room document — this counts as a Firestore Security Rules read operation. Ensure the requesting user is authenticated before calling this function (the `isAuthenticated()` check in `isRoomOwner()` prevents unauthenticated `get()` calls).

### `mobile/firebase.json` — Updated Content

The existing `firebase.json` contains only FlutterFire CLI metadata (`"flutter"` key). Merge the Firebase CLI `"firestore"` section into it. The resulting file should be:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "flutter": {
    "platforms": {
      "android": {
        "default": {
          "projectId": "whcompagnion",
          "appId": "1:376789122983:android:aa0725dc1462425ffc8082",
          "fileOutput": "android/app/google-services.json"
        }
      },
      "dart": {
        "lib/firebase_options.dart": {
          "projectId": "whcompagnion",
          "configurations": {
            "android": "1:376789122983:android:aa0725dc1462425ffc8082"
          }
        }
      }
    }
  }
}
```

> **Important:** The `"flutter"` section above reflects the exact content currently in `mobile/firebase.json`. Copy that existing content verbatim and add the `"firestore"` section.

### `mobile/.firebaserc` — Content

```json
{
  "projects": {
    "default": "whcompagnion"
  }
}
```

### Running Firebase CLI Deploy

Firebase CLI must be run from `mobile/` (where `firebase.json` lives):

```bash
cd mobile
firebase deploy --only firestore:rules
```

If Firebase CLI is not logged in, run `firebase login` first.

### Scope of This Story — What NOT to Do

| Deferred | Story |
|----------|-------|
| `firestore_paths.dart` — all Firestore path helpers | 1.4 |
| Feature-first directory structure (`features/room/`, `features/game/`) | 1.4 |
| `app/app.dart` — dark theme + bottom navigation | 1.4 |
| Any Flutter UI code changes | 1.4+ |
| Domain models (`RoomModel`, `PlayerModel`) | 2.1 |
| APK release pipeline | 1.5 |

**Do NOT** modify `lib/main.dart` or any Dart source file in this story. This story is exclusively Firebase CLI configuration and security rules.

### Architecture Guardrails

- Rules enforce the universal ownership pattern: `actorId == currentUser.uid OR room.createdBy == currentUser.uid`  
  [Source: architecture.md — Process Patterns]
- Undo is **always soft-delete via `undone: true` flag** — hard Firestore delete is forbidden at both app code and security rules level  
  [Source: architecture.md — Process Patterns]
- `request.auth.uid` is the anonymous Firebase UID established in Story 1.2 via `signInAnonymously()`

### NFRs Applicable to This Story

| NFR | Relevance |
|-----|-----------|
| NFR5 — Data in transit encrypted | Firebase SDK enforces TLS; rules do not affect transport |
| NFR6 — Data at rest protected | Firestore managed encryption at rest; default |
| NFR7 — Access control ownership boundaries | **Core deliverable** — rules enforce player-level and owner-level permissions |
| NFR8 — Sensitive actions require confirmation | Security rules are server-side gate; client-side confirmation is future story scope |
| NFR9 — Private distribution only | Rules apply regardless of distribution channel |

### FRs Covered by This Story

- **FR18** — System enforces player ownership restrictions (server-side via Security Rules)
- **FR19** — System enforces owner-override permissions (server-side)
- All future stories depend on these rules being deployed before any Firestore writes occur

### Previous Story Learnings (from Story 1.2)

- `firebase deploy` requires `firebase-tools` globally installed. Confirmed as v15.11.0 in Story 1.2.
- `dart pub global run flutterfire_cli:flutterfire` was used as PATH workaround for FlutterFire CLI; `firebase` CLI itself should be accessible directly on PATH (`npx firebase` as fallback).
- The `mobile/firebase.json` generated by `flutterfire configure` uses a minified single-line JSON format. When updating it, reformat as valid pretty-printed JSON to avoid hard-to-read diffs.

### References

- Story requirements: [_bmad-output/planning-artifacts/epics.md — Story 1.3](_bmad-output/planning-artifacts/epics.md)
- Ownership rule: [_bmad-output/planning-artifacts/architecture.md — Process Patterns](_bmad-output/planning-artifacts/architecture.md)
- Security Rules design: [_bmad-output/planning-artifacts/architecture.md — Authentication & Security](_bmad-output/planning-artifacts/architecture.md)
- Undo pattern: [_bmad-output/planning-artifacts/architecture.md — Process Patterns](_bmad-output/planning-artifacts/architecture.md)
- Firebase Security Rules reference: https://firebase.google.com/docs/firestore/security/get-started
- Firebase CLI deploy: https://firebase.google.com/docs/cli#deployment

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (GitHub Copilot)

### Implementation Notes

- Created `mobile/firestore.rules` with complete security rules covering rooms, players, and events subcollections. Implemented `isAuthenticated()` and `isRoomOwner()` helpers. All hard-deletes are explicitly forbidden per architecture requirements.
- Updated `mobile/firebase.json` from minified single-line FlutterFire format to pretty-printed JSON, adding `"firestore"` section with `rules` and `indexes` references. All existing `"flutter"` content preserved verbatim.
- Created `mobile/firestore.indexes.json` with empty indexes/fieldOverrides as required by Firebase CLI.
- Created `mobile/.firebaserc` referencing project `whcompagnion`.
- Ran `firebase deploy --only firestore:rules` from `mobile/`. Firebase automatically enabled `firestore.googleapis.com` API, created the default Firestore database, compiled rules successfully, and published them. Deploy exited with `+  Deploy complete!`.
- No Dart/Flutter source files were modified — scope strictly limited to Firebase CLI config and security rules.

### File List

- `mobile/firestore.rules` — Created (new)
- `mobile/firebase.json` — Modified (added `"firestore"` section; reformatted to pretty JSON)
- `mobile/firestore.indexes.json` — Created (new)
- `mobile/.firebaserc` — Created (new)

### Change Log

| Date | Change | Reason |
|------|--------|--------|
| 2026-03-27 | Created `firestore.rules` with complete ownership-based security rules | AC #1, #2, #3 — server-side enforcement of player and owner permissions |
| 2026-03-27 | Updated `firebase.json` to add `"firestore"` CLI section | AC #4 — enable `firebase deploy --only firestore:rules` |
| 2026-03-27 | Created `firestore.indexes.json` (empty) | AC #4 — required by Firebase CLI |
| 2026-03-27 | Created `.firebaserc` pointing to `whcompagnion` | AC #4 — Firebase project reference |
| 2026-03-27 | Ran `firebase deploy --only firestore:rules` — completed successfully | AC #4 — deployment verified |

### Debug Log References

### Completion Notes List

### File List
