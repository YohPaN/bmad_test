import 'package:cloud_firestore/cloud_firestore.dart';

import '../../room/domain/models.dart';
import 'game_rules.dart';

// ────────────────────────────────────────────────────────────────────────────
// EventModel
// ────────────────────────────────────────────────────────────────────────────

class EventModel {
  final String id;
  final String type;
  final String actorId;
  final String? targetPlayerId;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final Timestamp timestamp;
  final bool undone;

  const EventModel({
    required this.id,
    required this.type,
    required this.actorId,
    this.targetPlayerId,
    this.before,
    this.after,
    required this.timestamp,
    required this.undone,
  });

  factory EventModel.fromMap(String id, Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final actorId = data['actorId'] as String?;
    final timestamp = data['timestamp'];
    if (type == null || actorId == null || timestamp == null) {
      throw FormatException(
        'Event $id is missing required fields (type, actorId, or timestamp)',
      );
    }
    return EventModel(
      id: id,
      type: type,
      actorId: actorId,
      targetPlayerId: data['targetPlayerId'] as String?,
      before: data['before'] as Map<String, dynamic>?,
      after: data['after'] as Map<String, dynamic>?,
      timestamp: timestamp as Timestamp,
      undone: (data['undone'] as bool?) ?? false,
    );
  }

  factory EventModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Event document ${doc.id} does not exist');
    }
    return EventModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'actorId': actorId,
      if (targetPlayerId != null) 'targetPlayerId': targetPlayerId,
      if (before != null) 'before': before,
      if (after != null) 'after': after,
      'timestamp': timestamp,
      'undone': undone,
    };
  }
}

// ────────────────────────────────────────────────────────────────────────────
// GameState
// ────────────────────────────────────────────────────────────────────────────

class GameState {
  final RoomModel room;
  final List<PlayerModel> players;
  final List<EventModel> events;

  const GameState({
    required this.room,
    required this.players,
    required this.events,
  });

  int get currentRound => room.currentRound;

  int get activeRound => room.currentRound;

  /// Pre-computed VP total per player, keyed by [PlayerModel.id].
  Map<String, int> get playerVpTotals => {
    for (final p in players) p.id: vpTotal(p.vpByRound),
  };

  factory GameState.fromStreams(
    RoomModel room,
    List<PlayerModel> players,
    List<EventModel> events,
  ) {
    return GameState(
      room: room,
      players: List.unmodifiable(players),
      events: List.unmodifiable(events),
    );
  }
}
