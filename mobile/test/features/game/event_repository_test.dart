import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/game/data/event_repository.dart';

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────

/// Seeds a minimal room document and two player documents so batch.update()
/// targets existing docs (FakeFirestore requires docs to exist for update).
Future<void> _seedRoom(
  FakeFirebaseFirestore fakeFs, {
  required String roomId,
  required int currentRound,
  required List<String> playerIds,
}) async {
  await fakeFs.collection('rooms').doc(roomId).set({
    'currentRound': currentRound,
  });
  for (final uid in playerIds) {
    await fakeFs
        .collection('rooms')
        .doc(roomId)
        .collection('players')
        .doc(uid)
        .set({'cp': 3});
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Tests
// ────────────────────────────────────────────────────────────────────────────

void main() {
  const roomId = 'room-abc';
  const actorId = 'uid-actor';
  const targetId = 'uid-target';

  // ---------------------------------------------------------------------------
  // submitCpAdjust
  // ---------------------------------------------------------------------------

  group('EventRepository.submitCpAdjust', () {
    late FakeFirebaseFirestore fakeFs;
    late EventRepository repo;

    setUp(() async {
      fakeFs = FakeFirebaseFirestore();
      repo = EventRepository.withFirestore(fakeFs);
      await _seedRoom(
        fakeFs,
        roomId: roomId,
        currentRound: 1,
        playerIds: [targetId],
      );
    });

    test('writes a cp_adjust event with correct fields', () async {
      await repo.submitCpAdjust(
        roomId: roomId,
        actorId: actorId,
        targetPlayerId: targetId,
        beforeCp: 3,
        afterCp: 4,
      );

      final events =
          await fakeFs
              .collection('rooms')
              .doc(roomId)
              .collection('events')
              .get();

      expect(events.docs.length, 1);
      final data = events.docs.first.data();
      expect(data['type'], 'cp_adjust');
      expect(data['actorId'], actorId);
      expect(data['targetPlayerId'], targetId);
      expect((data['before'] as Map)['cp'], 3);
      expect((data['after'] as Map)['cp'], 4);
      expect(data['undone'], false);
    });

    test('updates player document with afterCp', () async {
      await repo.submitCpAdjust(
        roomId: roomId,
        actorId: actorId,
        targetPlayerId: targetId,
        beforeCp: 3,
        afterCp: 4,
      );

      final playerDoc =
          await fakeFs
              .collection('rooms')
              .doc(roomId)
              .collection('players')
              .doc(targetId)
              .get();

      expect(playerDoc.data()?['cp'], 4);
    });
  });

  // ---------------------------------------------------------------------------
  // submitTurnAdvance
  // ---------------------------------------------------------------------------

  group('EventRepository.submitTurnAdvance', () {
    const player1Id = 'uid-p1';
    const player2Id = 'uid-p2';

    late FakeFirebaseFirestore fakeFs;
    late EventRepository repo;

    setUp(() async {
      fakeFs = FakeFirebaseFirestore();
      repo = EventRepository.withFirestore(fakeFs);
      await _seedRoom(
        fakeFs,
        roomId: roomId,
        currentRound: 2,
        playerIds: [player1Id, player2Id],
      );
    });

    test('increments room currentRound by 1', () async {
      await repo.submitTurnAdvance(
        roomId: roomId,
        currentRound: 2,
        actorId: actorId,
        cpChanges: [
          (playerId: player1Id, beforeCp: 3, afterCp: 4),
          (playerId: player2Id, beforeCp: 2, afterCp: 3),
        ],
      );

      final roomDoc = await fakeFs.collection('rooms').doc(roomId).get();
      expect(roomDoc.data()?['currentRound'], 3);
    });

    test('updates each player cp to afterCp', () async {
      await repo.submitTurnAdvance(
        roomId: roomId,
        currentRound: 2,
        actorId: actorId,
        cpChanges: [
          (playerId: player1Id, beforeCp: 3, afterCp: 4),
          (playerId: player2Id, beforeCp: 2, afterCp: 3),
        ],
      );

      final p1 =
          await fakeFs
              .collection('rooms')
              .doc(roomId)
              .collection('players')
              .doc(player1Id)
              .get();
      final p2 =
          await fakeFs
              .collection('rooms')
              .doc(roomId)
              .collection('players')
              .doc(player2Id)
              .get();

      expect(p1.data()?['cp'], 4);
      expect(p2.data()?['cp'], 3);
    });

    test('writes a turn_advance event with correct round values', () async {
      await repo.submitTurnAdvance(
        roomId: roomId,
        currentRound: 2,
        actorId: actorId,
        cpChanges: [(playerId: player1Id, beforeCp: 3, afterCp: 4)],
      );

      final events =
          await fakeFs
              .collection('rooms')
              .doc(roomId)
              .collection('events')
              .get();

      expect(events.docs.length, 1);
      final data = events.docs.first.data();
      expect(data['type'], 'turn_advance');
      expect(data['actorId'], actorId);
      expect(data['targetPlayerId'], isNull);
      expect((data['before'] as Map)['round'], 2);
      expect((data['after'] as Map)['round'], 3);
      expect(data['undone'], false);
    });
  });
}
