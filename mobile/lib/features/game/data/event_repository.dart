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
