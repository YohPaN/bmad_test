import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/game/domain/game_rules.dart';
import 'package:mobile/features/game/presentation/widgets/round_score_cell.dart';
import 'package:mobile/features/game/presentation/widgets/score_grid_widget.dart';
import 'package:mobile/features/room/domain/models.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PlayerModel _makePlayer({
  required String id,
  required String name,
  required String color,
  Map<String, Map<String, int>>? vpByRound,
}) {
  return PlayerModel(
    id: id,
    name: name,
    role: RoleEnum.player,
    cp: 0,
    vpByRound: vpByRound ?? {},
    connected: true,
    color: color,
  );
}

Widget _buildGrid(ScoreGridWidget widget) {
  return MaterialApp(home: Scaffold(body: SizedBox(width: 400, child: widget)));
}

void main() {
  final p1 = _makePlayer(
    id: 'uid-p1',
    name: 'Alpha',
    color: '#4FC3F7',
    vpByRound: {
      '1': {'prim': 3, 'sec': 5},
      '2': {'prim': 7, 'sec': 2},
    },
  );
  final p2 = _makePlayer(id: 'uid-p2', name: 'Beta', color: '#EF5350');

  group('ScoreGridWidget — structure', () {
    testWidgets('renders exactly 5 data rows plus header', (tester) async {
      await tester.pumpWidget(
        _buildGrid(
          ScoreGridWidget(
            players: [p1, p2],
            activeRound: 3,
            currentUserId: 'uid-p1',
            isOwner: false,
          ),
        ),
      );

      // The Table has 6 rows: 1 header + 5 data rows
      final table = tester.widget<Table>(find.byType(Table));
      expect(table.children.length, equals(6));
    });

    testWidgets('renders a cell for every round 1–5', (tester) async {
      await tester.pumpWidget(
        _buildGrid(
          ScoreGridWidget(
            players: [p1, p2],
            activeRound: 3,
            currentUserId: 'uid-p1',
            isOwner: false,
          ),
        ),
      );

      // 5 data rows each containing cells
      for (int r = 1; r <= 5; r++) {
        expect(find.text('$r'), findsAtLeastNWidgets(1));
      }
    });
  });

  group('ScoreGridWidget — cell state derivation', () {
    testWidgets(
      'isOwner=false, currentUserId != p2.id → locked state for p2 active cell',
      (tester) async {
        await tester.pumpWidget(
          _buildGrid(
            ScoreGridWidget(
              players: [p1, p2],
              activeRound: 3,
              currentUserId: 'uid-p1',
              isOwner: false,
            ),
          ),
        );

        // p2's active round (3) cells should contain a lock icon
        // (p2 has no data for round 3 → locked state)
        expect(find.byIcon(Icons.lock), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'isOwner=true → active state for any player\'s current round cell',
      (tester) async {
        await tester.pumpWidget(
          _buildGrid(
            ScoreGridWidget(
              players: [p1, p2],
              activeRound: 3,
              currentUserId: 'uid-p1',
              isOwner: true,
            ),
          ),
        );

        // No lock icons when isOwner=true — all active cells are accessible
        expect(find.byIcon(Icons.lock), findsNothing);
      },
    );

    testWidgets('rounds before activeRound with data → filled state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildGrid(
          ScoreGridWidget(
            players: [p1, p2],
            activeRound: 3,
            currentUserId: 'uid-p1',
            isOwner: false,
          ),
        ),
      );

      // p1 has data for round 1: prim=3, sec=5
      expect(find.text('P:3'), findsOneWidget);
      expect(find.text('S:5'), findsOneWidget);
    });

    testWidgets('rounds after activeRound → future state (grayed out)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildGrid(
          ScoreGridWidget(
            players: [p1, p2],
            activeRound: 3,
            currentUserId: 'uid-p1',
            isOwner: false,
          ),
        ),
      );

      // All RoundScoreCell widgets with future state should be grayed out
      final futureCells =
          tester
              .widgetList<RoundScoreCell>(find.byType(RoundScoreCell))
              .where((c) => c.state == RoundCellState.future)
              .toList();

      // Rounds 4 and 5 are future for 2 players × 2 VP columns = 4 cells each round
      // Round 4 and 5 × 4 cells = 8 future cells for Prim/Sec columns
      expect(futureCells.length, greaterThanOrEqualTo(4));
    });
  });

  group('ScoreGridWidget — total column (derived, no stored scalar)', () {
    testWidgets(
      'total column shows per-round derived totals, not stored scalar',
      (tester) async {
        // vpByRound for p1 round 1: prim=3, sec=5 → total 8
        // Verify vpTotal is consistent: vpTotal({'1': {'prim':3,'sec':5}}) = 8
        expect(
          vpTotal({
            '1': {'prim': 3, 'sec': 5},
          }),
          equals(8),
        );

        await tester.pumpWidget(
          _buildGrid(
            ScoreGridWidget(
              players: [p1, p2],
              activeRound: 3,
              currentUserId: 'uid-p1',
              isOwner: false,
            ),
          ),
        );

        // Total for round 1 (p1): 3+5 = 8 — derived from vpByRound
        expect(find.text('8'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('total shows 0 for player with no vpByRound data', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildGrid(
          ScoreGridWidget(
            players: [p1, p2],
            activeRound: 3,
            currentUserId: 'uid-p1',
            isOwner: false,
          ),
        ),
      );

      // p2 has no rounds data → all round totals are 0
      // vpTotal({}) == 0 per game_rules.dart
      expect(vpTotal(p2.vpByRound), equals(0));
      expect(find.text('0'), findsAtLeastNWidgets(1));
    });
  });

  group('ScoreGridWidget — onCellTap callback', () {
    testWidgets('onCellTap fires with correct playerId and round', (
      tester,
    ) async {
      String? tappedPlayer;
      int? tappedRound;

      await tester.pumpWidget(
        _buildGrid(
          ScoreGridWidget(
            players: [p1, p2],
            activeRound: 3,
            currentUserId: 'uid-p1',
            isOwner: false,
            onCellTap: (pid, r) {
              tappedPlayer = pid;
              tappedRound = r;
            },
          ),
        ),
      );

      // Tap first RoundScoreCell with active state (p1, round 3)
      final activeCells =
          tester
              .widgetList<RoundScoreCell>(find.byType(RoundScoreCell))
              .where((c) => c.state == RoundCellState.active)
              .toList();

      expect(activeCells, isNotEmpty);

      // Tap the first active cell
      final activeCell = find.byWidget(activeCells.first);
      await tester.tap(activeCell);

      expect(tappedPlayer, equals('uid-p1'));
      expect(tappedRound, equals(3));
    });
  });
}
