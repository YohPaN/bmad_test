import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/game_state.dart';

// ────────────────────────────────────────────────────────────────────────────
// GameException
// ────────────────────────────────────────────────────────────────────────────

class GameException implements Exception {
  final String message;
  const GameException(this.message);

  @override
  String toString() => 'GameException: $message';
}

// ────────────────────────────────────────────────────────────────────────────
// EventRepository
// ────────────────────────────────────────────────────────────────────────────

class EventRepository {
  final FirebaseFirestore _firestore;

  EventRepository() : _firestore = FirebaseFirestore.instance;

  /// Named constructor for testing — accepts a [FirebaseFirestore] instance
  /// (e.g., [FakeFirebaseFirestore]) to avoid live Firestore calls.
  EventRepository.withFirestore(this._firestore);

  /// Appends a new event document to `rooms/{roomId}/events/`.
  ///
  /// Throws [GameException] on Firestore errors.
  Future<void> appendEvent(
    String roomId,
    Map<String, dynamic> eventData,
  ) async {
    try {
      await FirestorePaths.events(roomId).add(eventData);
    } on FirebaseException catch (e) {
      throw GameException('Failed to append event: ${e.message}');
    } catch (e) {
      throw GameException('Failed to append event: $e');
    }
  }

  /// Appends a score_update event and updates the player's vpByRound atomically.
  ///
  /// Uses a [WriteBatch] to ensure the event write and the vpByRound update
  /// succeed or fail together.
  ///
  /// Throws [GameException] on Firestore errors.
  Future<void> submitScoreUpdate({
    required String roomId,
    required String actorId,
    required String targetPlayerId,
    required int round,
    required Map<String, int>? beforeVp,
    required int vpPrimAfter,
    required int vpSecAfter,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Auto-ID event document — .add() is not batchable, so use .doc() + batch.set()
      final eventRef = FirestorePaths.events(roomId).doc();
      batch.set(eventRef, {
        'type': 'score_update',
        'actorId': actorId,
        'targetPlayerId': targetPlayerId,
        'before': {
          'round': round,
          'vpPrim': beforeVp?['prim'],
          'vpSec': beforeVp?['sec'],
        },
        'after': {'round': round, 'vpPrim': vpPrimAfter, 'vpSec': vpSecAfter},
        'timestamp': FieldValue.serverTimestamp(),
        'undone': false,
      });

      // 2. Dot-notation preserves other rounds' data
      final playerRef = FirestorePaths.player(roomId, targetPlayerId);
      batch.update(playerRef, {
        'vpByRound.$round': {'prim': vpPrimAfter, 'sec': vpSecAfter},
      });

      await batch.commit();
    } on FirebaseException catch (e) {
      throw GameException('Failed to submit score update: ${e.message}');
    } catch (e) {
      throw GameException('Failed to submit score update: $e');
    }
  }

  /// Appends a cp_adjust event and updates the player's cp atomically.
  ///
  /// Uses a [WriteBatch] to ensure the event write and the cp update
  /// succeed or fail together.
  // Private path helpers that delegate to FirestorePaths injectable overloads
  // so tests can substitute a FakeFirebaseFirestore without relying on the global singleton.
  DocumentReference<Map<String, dynamic>> _roomRef(String roomId) =>
      FirestorePaths.roomWith(_firestore, roomId);

  DocumentReference<Map<String, dynamic>> _playerRef(
    String roomId,
    String uid,
  ) => FirestorePaths.playerWith(_firestore, roomId, uid);

  CollectionReference<Map<String, dynamic>> _eventsRef(String roomId) =>
      FirestorePaths.eventsWith(_firestore, roomId);

  Future<void> submitCpAdjust({
    required String roomId,
    required String actorId,
    required String targetPlayerId,
    required int beforeCp,
    required int afterCp,
  }) async {
    try {
      final batch = _firestore.batch();

      final eventRef = _eventsRef(roomId).doc();
      batch.set(eventRef, {
        'type': 'cp_adjust',
        'actorId': actorId,
        'targetPlayerId': targetPlayerId,
        'before': {'cp': beforeCp},
        'after': {'cp': afterCp},
        'timestamp': FieldValue.serverTimestamp(),
        'undone': false,
      });

      final playerRef = _playerRef(roomId, targetPlayerId);
      batch.update(playerRef, {'cp': afterCp});

      await batch.commit();
    } on FirebaseException catch (e) {
      throw GameException('Failed to submit CP adjust: ${e.message}');
    } catch (e) {
      throw GameException('Failed to submit CP adjust: $e');
    }
  }

  /// Increments room.currentRound, applies +1 CP to all players, and appends
  /// a turn_advance event — all in a single [WriteBatch].
  Future<void> submitTurnAdvance({
    required String roomId,
    required int currentRound,
    required String actorId,
    required List<({String playerId, int beforeCp, int afterCp})> cpChanges,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Increment round
      batch.update(_roomRef(roomId), {'currentRound': currentRound + 1});

      // 2. Update each player's CP
      for (final change in cpChanges) {
        batch.update(_playerRef(roomId, change.playerId), {
          'cp': change.afterCp,
        });
      }

      // 3. Append turn_advance event
      final eventRef = _eventsRef(roomId).doc();
      batch.set(eventRef, {
        'type': 'turn_advance',
        'actorId': actorId,
        'targetPlayerId': null,
        'before': {'round': currentRound},
        'after': {'round': currentRound + 1},
        'timestamp': FieldValue.serverTimestamp(),
        'undone': false,
      });

      await batch.commit();
    } on FirebaseException catch (e) {
      throw GameException('Failed to submit turn advance: ${e.message}');
    } catch (e) {
      throw GameException('Failed to submit turn advance: $e');
    }
  }

  /// Streams the ordered list of events for [roomId].
  ///
  /// Events are ordered by `timestamp` ascending.
  Stream<List<EventModel>> streamEvents(String roomId) {
    return FirestorePaths.events(roomId)
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map(EventModel.fromFirestore).toList())
        .handleError(
          (Object e) =>
              throw GameException(
                'Stream error: ${e is FirebaseException ? e.message : e}',
              ),
        );
  }
}
