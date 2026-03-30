import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mobile/features/game/presentation/widgets/score_hero_bar.dart';
import 'package:mobile/features/room/domain/models.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  PlayerModel makePlayer({
    String id = 'uid1',
    String name = 'Alice',
    String color = '#4FC3F7',
    Map<String, Map<String, int>> vpByRound = const {},
  }) => PlayerModel(
    id: id,
    name: name,
    role: RoleEnum.player,
    cp: 0,
    vpByRound: vpByRound,
    connected: true,
    color: color,
  );

  Widget buildBar(PlayerModel p1, PlayerModel p2) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: ScoreHeroBar(player1: p1, player2: p2)),
    );
  }

  group('ScoreHeroBar', () {
    testWidgets('renders Player 1 name and VP total', (tester) async {
      final p1 = makePlayer(
        id: 'uid1',
        name: 'Alice',
        color: '#4FC3F7',
        vpByRound: {
          '1': {'prim': 3, 'sec': 7},
        },
      );
      final p2 = makePlayer(id: 'uid2', name: 'Bob', color: '#EF5350');

      await tester.pumpWidget(buildBar(p1, p2));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('renders Player 2 name and VP total', (tester) async {
      final p1 = makePlayer(id: 'uid1', name: 'Alice', color: '#4FC3F7');
      final p2 = makePlayer(
        id: 'uid2',
        name: 'Bob',
        color: '#EF5350',
        vpByRound: {
          '1': {'prim': 2, 'sec': 4},
        },
      );

      await tester.pumpWidget(buildBar(p1, p2));

      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('VP total is 0 when vpByRound is empty', (tester) async {
      final p1 = makePlayer(id: 'uid1', name: 'Alice', color: '#4FC3F7');
      final p2 = makePlayer(id: 'uid2', name: 'Bob', color: '#EF5350');

      await tester.pumpWidget(buildBar(p1, p2));

      // Both players have 0 VP — there are two '0' texts
      expect(find.text('0'), findsNWidgets(2));
    });

    testWidgets('VP total sums correctly across multiple rounds', (
      tester,
    ) async {
      final p1 = makePlayer(
        id: 'uid1',
        name: 'Alice',
        color: '#4FC3F7',
        vpByRound: {
          '1': {'prim': 3, 'sec': 7},
          '2': {'prim': 5, 'sec': 2},
        },
      );
      final p2 = makePlayer(id: 'uid2', name: 'Bob', color: '#EF5350');

      await tester.pumpWidget(buildBar(p1, p2));

      // 3 + 7 + 5 + 2 = 17
      expect(find.text('17'), findsOneWidget);
    });

    testWidgets('score text is rendered at 56sp', (tester) async {
      final p1 = makePlayer(
        id: 'uid1',
        name: 'Alice',
        color: '#4FC3F7',
        vpByRound: {
          '1': {'prim': 5, 'sec': 2},
        },
      );
      final p2 = makePlayer(id: 'uid2', name: 'Bob', color: '#EF5350');

      await tester.pumpWidget(buildBar(p1, p2));

      // Find the Text widget showing P1's VP total ('7')
      final textWidget = tester.widget<Text>(find.text('7'));
      expect(textWidget.style?.fontSize, equals(56.0));
    });
  });
}
