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
