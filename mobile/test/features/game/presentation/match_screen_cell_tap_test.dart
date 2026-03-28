import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/game/domain/game_rules.dart';
import 'package:mobile/features/game/presentation/widgets/ownership_lock_feedback.dart';
import 'package:mobile/features/game/presentation/widgets/round_score_entry_sheet.dart';
import 'package:mobile/features/room/domain/models.dart';

// ---------------------------------------------------------------------------
// Test harness — mimics _handleCellTap logic from MatchScreen without Firestore
// ---------------------------------------------------------------------------

class _CellTapHarness extends StatelessWidget {
  final String currentUserId;
  final String roomCreatedBy;
  final String playerId;
  final PlayerModel player;

  const _CellTapHarness({
    required this.currentUserId,
    required this.roomCreatedBy,
    required this.playerId,
    required this.player,
  });

  void _handleTap(BuildContext context) {
    if (!canMutate(currentUserId, roomCreatedBy, playerId)) {
      OwnershipLockFeedback.trigger(context);
      return;
    }

    final roundData = player.vpByRound['1'];

    RoundScoreEntrySheet.show(
      context,
      roundNumber: 1,
      playerName: player.name,
      playerColor: const Color(0xFF4FC3F7),
      vpPrimInitial: roundData?['prim'],
      vpSecInitial: roundData?['sec'],
      onConfirm: (_, __) async {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _handleTap(context),
      child: const Text('tap'),
    );
  }
}

PlayerModel _makePlayer({required String id, required String name}) {
  return PlayerModel(
    id: id,
    name: name,
    role: RoleEnum.player,
    cp: 0,
    vpByRound: {},
    connected: true,
    color: '#4FC3F7',
  );
}

void main() {
  const ownerUid = 'uid-owner';
  const playerUid = 'uid-player';

  Widget buildHarness({
    required String currentUserId,
    required String roomCreatedBy,
    required String playerId,
  }) {
    final player = _makePlayer(id: playerId, name: 'Alpha');
    return MaterialApp(
      home: Scaffold(
        body: _CellTapHarness(
          currentUserId: currentUserId,
          roomCreatedBy: roomCreatedBy,
          playerId: playerId,
          player: player,
        ),
      ),
    );
  }

  group('_handleCellTap — ownership guard', () {
    testWidgets(
      'shows snackbar and does NOT open sheet when non-owner taps another player cell',
      (tester) async {
        await tester.pumpWidget(
          buildHarness(
            currentUserId: playerUid,
            roomCreatedBy: ownerUid,
            playerId: 'uid-other-player',
          ),
        );

        await tester.tap(find.text('tap'));
        await tester.pumpAndSettle();

        // SnackBar should appear
        expect(
          find.text('Vous ne pouvez pas modifier cette cellule'),
          findsOneWidget,
        );

        // Bottom sheet should NOT appear
        expect(find.byType(RoundScoreEntrySheet), findsNothing);
      },
    );

    testWidgets('opens RoundScoreEntrySheet when currentUser taps own cell', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          currentUserId: playerUid,
          roomCreatedBy: ownerUid,
          playerId: playerUid,
        ),
      );

      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();

      // Sheet should be visible
      expect(find.byType(RoundScoreEntrySheet), findsOneWidget);

      // No snackbar
      expect(
        find.text('Vous ne pouvez pas modifier cette cellule'),
        findsNothing,
      );
    });

    testWidgets('opens RoundScoreEntrySheet when owner taps any player cell', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          currentUserId: ownerUid,
          roomCreatedBy: ownerUid,
          playerId: playerUid,
        ),
      );

      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();

      expect(find.byType(RoundScoreEntrySheet), findsOneWidget);
    });
  });
}
