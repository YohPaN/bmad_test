import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/game/domain/game_rules.dart';
import 'package:mobile/features/room/domain/models.dart';

void main() {
  // ── canMutate ─────────────────────────────────────────────────────────────

  group('canMutate', () {
    const owner = 'uid-owner';
    const player1 = 'uid-player1';
    const player2 = 'uid-player2';

    test('returns true when actorId == targetPlayerId (self-mutation)', () {
      expect(canMutate(player1, owner, player1), isTrue);
    });

    test('returns true when actorId == roomCreatedBy (owner override)', () {
      // Owner mutating a different player's data
      expect(canMutate(owner, owner, player1), isTrue);
    });

    test('returns false when actor is neither target nor owner', () {
      expect(canMutate(player2, owner, player1), isFalse);
    });
  });

  // ── vpTotal ───────────────────────────────────────────────────────────────

  group('vpTotal', () {
    test('returns 0 for an empty map', () {
      expect(vpTotal({}), 0);
    });

    test('correctly sums prim + sec values across multiple rounds', () {
      final vpByRound = {
        '1': {'prim': 3, 'sec': 7},
        '2': {'prim': 5, 'sec': 2},
      };
      // 3 + 7 + 5 + 2 = 17
      expect(vpTotal(vpByRound), 17);
    });

    test('handles rounds with only prim key (no sec)', () {
      final vpByRound = {
        '1': {'prim': 4},
        '2': {'prim': 6, 'sec': 1},
      };
      // 4 + 6 + 1 = 11
      expect(vpTotal(vpByRound), 11);
    });
  });

  // ── autoIncrementCp ───────────────────────────────────────────────────────

  group('autoIncrementCp', () {
    const basePlayer = PlayerModel(
      id: 'uid-p1',
      name: 'Alice',
      role: RoleEnum.player,
      cp: 3,
      vpByRound: {},
      connected: true,
      color: '#4FC3F7',
    );

    test('returns a new PlayerModel with cp incremented by 1', () {
      final result = autoIncrementCp(basePlayer);
      expect(result.cp, 4);
    });

    test('original PlayerModel is unchanged (pure function)', () {
      autoIncrementCp(basePlayer);
      expect(basePlayer.cp, 3);
    });
  });
}
