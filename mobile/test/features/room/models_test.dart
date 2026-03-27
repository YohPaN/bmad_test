import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/room/domain/models.dart';

void main() {
  // ── RoomStatus ─────────────────────────────────────────────────────────────

  group('RoomStatus.fromString', () {
    test('parses waiting', () {
      expect(RoomStatus.fromString('waiting'), RoomStatus.waiting);
    });

    test('parses active', () {
      expect(RoomStatus.fromString('active'), RoomStatus.active);
    });

    test('parses closed', () {
      expect(RoomStatus.fromString('closed'), RoomStatus.closed);
    });

    test('throws on unknown value', () {
      expect(() => RoomStatus.fromString('unknown'), throwsArgumentError);
    });
  });

  // ── RoomModel ──────────────────────────────────────────────────────────────

  group('RoomModel.fromMap', () {
    final ts = Timestamp.fromDate(DateTime(2026, 3, 25));

    final data = <String, dynamic>{
      'code': 'AB3K7M',
      'status': 'waiting',
      'currentRound': 1,
      'createdBy': 'uid-owner',
      'createdAt': ts,
    };

    test('maps all fields correctly', () {
      final model = RoomModel.fromMap('room-id-1', data);

      expect(model.id, 'room-id-1');
      expect(model.code, 'AB3K7M');
      expect(model.status, RoomStatus.waiting);
      expect(model.currentRound, 1);
      expect(model.createdBy, 'uid-owner');
      expect(model.createdAt, ts);
    });

    test('createdAt is Timestamp (not null)', () {
      final model = RoomModel.fromMap('room-id-2', data);
      expect(model.createdAt, isA<Timestamp>());
    });
  });

  group('RoomModel.toMap', () {
    final ts = Timestamp.fromDate(DateTime(2026, 3, 25));

    final model = RoomModel(
      id: 'room-id-1',
      code: 'AB3K7M',
      status: RoomStatus.active,
      currentRound: 2,
      createdBy: 'uid-owner',
      createdAt: ts,
    );

    test('roundtrip fidelity', () {
      final map = model.toMap();

      expect(map['code'], 'AB3K7M');
      expect(map['status'], 'active');
      expect(map['currentRound'], 2);
      expect(map['createdBy'], 'uid-owner');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('status serialized as String', () {
      final map = model.toMap();
      expect(map['status'], isA<String>());
    });

    test('createdAt serialized as Timestamp', () {
      final map = model.toMap();
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('fromMap roundtrip preserves all fields', () {
      final map = model.toMap();
      // inject id manually as fromMap takes id separately
      final restored = RoomModel.fromMap(model.id, map);

      expect(restored.id, model.id);
      expect(restored.code, model.code);
      expect(restored.status, model.status);
      expect(restored.currentRound, model.currentRound);
      expect(restored.createdBy, model.createdBy);
      expect(restored.createdAt, model.createdAt);
    });
  });

  // ── RoleEnum ───────────────────────────────────────────────────────────────

  group('RoleEnum.fromString', () {
    test('parses owner', () {
      expect(RoleEnum.fromString('owner'), RoleEnum.owner);
    });

    test('parses player', () {
      expect(RoleEnum.fromString('player'), RoleEnum.player);
    });

    test('throws on unknown value', () {
      expect(() => RoleEnum.fromString('admin'), throwsArgumentError);
    });
  });

  // ── PlayerModel ────────────────────────────────────────────────────────────

  group('PlayerModel.fromMap', () {
    final vpByRound = {
      '1': {'prim': 3, 'sec': 7},
      '2': {'prim': 5, 'sec': 2},
    };

    final data = <String, dynamic>{
      'name': 'Alice',
      'role': 'owner',
      'cp': 10,
      'vpByRound': vpByRound,
      'connected': true,
      'color': '#4FC3F7',
    };

    test('maps all fields correctly', () {
      final model = PlayerModel.fromMap('uid-alice', data);

      expect(model.id, 'uid-alice');
      expect(model.name, 'Alice');
      expect(model.role, RoleEnum.owner);
      expect(model.cp, 10);
      expect(model.connected, true);
      expect(model.color, '#4FC3F7');
    });

    test('vpByRound parsed as Map<String, Map<String, int>>', () {
      final model = PlayerModel.fromMap('uid-alice', data);

      expect(model.vpByRound, isA<Map<String, Map<String, int>>>());
      expect(model.vpByRound['1']!['prim'], 3);
      expect(model.vpByRound['1']!['sec'], 7);
      expect(model.vpByRound['2']!['prim'], 5);
      expect(model.vpByRound['2']!['sec'], 2);
    });

    test('connected is native bool', () {
      final model = PlayerModel.fromMap('uid-alice', data);
      expect(model.connected, isA<bool>());
    });

    test('empty vpByRound parses correctly', () {
      final emptyData = Map<String, dynamic>.from(data)
        ..['vpByRound'] = <String, dynamic>{};
      final model = PlayerModel.fromMap('uid-alice', emptyData);
      expect(model.vpByRound, isEmpty);
    });

    test('vpByRound with num (double) values coerced to int', () {
      // Firestore can return numeric fields as double — cast must handle this
      final numData = Map<String, dynamic>.from(data)
        ..['vpByRound'] = <String, dynamic>{
          '1': <String, dynamic>{'prim': 3.0, 'sec': 7.0},
        };
      final model = PlayerModel.fromMap('uid-alice', numData);
      expect(model.vpByRound['1']!['prim'], 3);
      expect(model.vpByRound['1']!['sec'], 7);
      expect(model.vpByRound['1']!['prim'], isA<int>());
    });
  });

  group('PlayerModel.toMap', () {
    final vpByRound = <String, Map<String, int>>{
      '1': {'prim': 3, 'sec': 7},
    };

    final model = PlayerModel(
      id: 'uid-bob',
      name: 'Bob',
      role: RoleEnum.player,
      cp: 5,
      vpByRound: vpByRound,
      connected: false,
      color: '#EF5350',
    );

    test('role serialized as String', () {
      final map = model.toMap();
      expect(map['role'], 'player');
      expect(map['role'], isA<String>());
    });

    test('connected serialized as bool', () {
      final map = model.toMap();
      expect(map['connected'], false);
      expect(map['connected'], isA<bool>());
    });

    test('vpByRound nested map preserved', () {
      final map = model.toMap();
      final vp = map['vpByRound'] as Map<String, dynamic>;
      final round1 = vp['1'] as Map<String, dynamic>;
      expect(round1['prim'], 3);
      expect(round1['sec'], 7);
    });

    test('fromMap roundtrip preserves all fields', () {
      final map = model.toMap();
      final restored = PlayerModel.fromMap(model.id, map);

      expect(restored.id, model.id);
      expect(restored.name, model.name);
      expect(restored.role, model.role);
      expect(restored.cp, model.cp);
      expect(restored.connected, model.connected);
      expect(restored.color, model.color);
      expect(restored.vpByRound['1']!['prim'], 3);
      expect(restored.vpByRound['1']!['sec'], 7);
    });
  });
}
