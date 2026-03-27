import 'package:cloud_firestore/cloud_firestore.dart';

// ────────────────────────────────────────────────────────────────────────────
// RoomStatus
// ────────────────────────────────────────────────────────────────────────────

enum RoomStatus {
  waiting,
  active,
  closed;

  static RoomStatus fromString(String value) {
    switch (value) {
      case 'waiting':
        return RoomStatus.waiting;
      case 'active':
        return RoomStatus.active;
      case 'closed':
        return RoomStatus.closed;
      default:
        throw ArgumentError('Unknown RoomStatus: $value');
    }
  }

  String toValue() {
    switch (this) {
      case RoomStatus.waiting:
        return 'waiting';
      case RoomStatus.active:
        return 'active';
      case RoomStatus.closed:
        return 'closed';
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// RoomModel
// ────────────────────────────────────────────────────────────────────────────

class RoomModel {
  final String id;
  final String code;
  final RoomStatus status;
  final int currentRound;
  final String createdBy;
  final Timestamp createdAt;

  const RoomModel({
    required this.id,
    required this.code,
    required this.status,
    required this.currentRound,
    required this.createdBy,
    required this.createdAt,
  });

  factory RoomModel.fromMap(String id, Map<String, dynamic> data) {
    return RoomModel(
      id: id,
      code: data['code'] as String,
      status: RoomStatus.fromString(data['status'] as String),
      currentRound: (data['currentRound'] as num).toInt(),
      createdBy: data['createdBy'] as String,
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  factory RoomModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      RoomModel.fromMap(doc.id, doc.data()!);

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'status': status.toValue(),
      'currentRound': currentRound,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  RoomModel copyWith({
    String? id,
    String? code,
    RoomStatus? status,
    int? currentRound,
    String? createdBy,
    Timestamp? createdAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      code: code ?? this.code,
      status: status ?? this.status,
      currentRound: currentRound ?? this.currentRound,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// RoleEnum
// ────────────────────────────────────────────────────────────────────────────

enum RoleEnum {
  owner,
  player;

  static RoleEnum fromString(String value) {
    switch (value) {
      case 'owner':
        return RoleEnum.owner;
      case 'player':
        return RoleEnum.player;
      default:
        throw ArgumentError('Unknown RoleEnum: $value');
    }
  }

  String toValue() {
    switch (this) {
      case RoleEnum.owner:
        return 'owner';
      case RoleEnum.player:
        return 'player';
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PlayerModel
// ────────────────────────────────────────────────────────────────────────────

class PlayerModel {
  final String id;
  final String name;
  final RoleEnum role;
  final int cp;
  final Map<String, Map<String, int>> vpByRound;
  final bool connected;
  final String color;

  const PlayerModel({
    required this.id,
    required this.name,
    required this.role,
    required this.cp,
    required this.vpByRound,
    required this.connected,
    required this.color,
  });

  factory PlayerModel.fromMap(String id, Map<String, dynamic> data) {
    final raw = data['vpByRound'] as Map<String, dynamic>? ?? {};
    final vpByRound = raw.map(
      (round, value) => MapEntry(
        round,
        (value as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
      ),
    );

    return PlayerModel(
      id: id,
      name: data['name'] as String,
      role: RoleEnum.fromString(data['role'] as String),
      cp: (data['cp'] as num).toInt(),
      vpByRound: vpByRound,
      connected: data['connected'] as bool,
      color: data['color'] as String,
    );
  }

  factory PlayerModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => PlayerModel.fromMap(doc.id, doc.data()!);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role.toValue(),
      'cp': cp,
      'vpByRound': vpByRound.map(
        (round, innerMap) =>
            MapEntry(round, innerMap.map((k, v) => MapEntry(k, v))),
      ),
      'connected': connected,
      'color': color,
    };
  }

  PlayerModel copyWith({
    String? id,
    String? name,
    RoleEnum? role,
    int? cp,
    Map<String, Map<String, int>>? vpByRound,
    bool? connected,
    String? color,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      cp: cp ?? this.cp,
      vpByRound: vpByRound ?? this.vpByRound,
      connected: connected ?? this.connected,
      color: color ?? this.color,
    );
  }
}
