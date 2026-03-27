import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/room/domain/models.dart';
import 'package:mobile/features/room/presentation/players_screen.dart';
import 'package:mobile/features/room/presentation/widgets/player_presence_badge.dart';

void main() {
  group('PlayersScreen rendering', () {
    testWidgets('shows skeleton while stream has no data', (tester) async {
      final controller = StreamController<List<PlayerModel>>();
      addTearDown(controller.close);

      await tester.pumpWidget(_buildSubject(controller.stream));

      // No data emitted yet: no error text, no player names
      expect(find.text('Erreur de chargement des joueurs.'), findsNothing);
      expect(find.text('Aucun joueur connecté.'), findsNothing);
      // Skeleton renders 3 placeholder circle avatars
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CircleAvatar && w.backgroundColor == const Color(0xFF2A2F3E),
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('shows error state on stream error', (tester) async {
      final controller = StreamController<List<PlayerModel>>();
      addTearDown(controller.close);

      await tester.pumpWidget(_buildSubject(controller.stream));
      controller.addError(Exception('Firestore error'));
      await tester.pump();

      expect(find.text('Erreur de chargement des joueurs.'), findsOneWidget);
    });

    testWidgets('renders PlayerPresenceBadge for each player', (tester) async {
      final controller = StreamController<List<PlayerModel>>();
      addTearDown(controller.close);
      final players = [
        _fakePlayer(
          id: 'u1',
          name: 'Alice',
          color: '#4FC3F7',
          connected: true,
          role: 'owner',
        ),
        _fakePlayer(
          id: 'u2',
          name: 'Bob',
          color: '#EF5350',
          connected: false,
          role: 'player',
        ),
      ];

      await tester.pumpWidget(_buildSubject(controller.stream));
      controller.add(players);
      await tester.pump();

      expect(find.byType(PlayerPresenceBadge), findsNWidgets(2));
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets(
      'online/offline status correctly reflected per connected field',
      (tester) async {
        final controller = StreamController<List<PlayerModel>>();
        addTearDown(controller.close);
        final players = [
          _fakePlayer(
            id: 'u1',
            name: 'Alice',
            color: '#4FC3F7',
            connected: true,
            role: 'owner',
          ),
          _fakePlayer(
            id: 'u2',
            name: 'Bob',
            color: '#EF5350',
            connected: false,
            role: 'player',
          ),
        ];

        await tester.pumpWidget(_buildSubject(controller.stream));
        controller.add(players);
        await tester.pump();

        // Alice is online
        expect(
          find.bySemanticsLabel(
            RegExp('Alice.*en ligne', caseSensitive: false),
          ),
          findsOneWidget,
        );
        // Bob is offline
        expect(
          find.bySemanticsLabel(
            RegExp('Bob.*hors ligne', caseSensitive: false),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('owner badge shown for player with role == owner', (
      tester,
    ) async {
      final controller = StreamController<List<PlayerModel>>();
      addTearDown(controller.close);
      final players = [
        _fakePlayer(
          id: 'u1',
          name: 'Alice',
          color: '#4FC3F7',
          connected: true,
          role: 'owner',
        ),
      ];

      await tester.pumpWidget(_buildSubject(controller.stream));
      controller.add(players);
      await tester.pump();

      // PlayerPresenceBadge Semantics label includes 'propriétaire' for owner
      expect(
        find.bySemanticsLabel(RegExp('propriétaire', caseSensitive: false)),
        findsOneWidget,
      );
    });

    testWidgets('no ownership management button rendered at all', (
      tester,
    ) async {
      final controller = StreamController<List<PlayerModel>>();
      addTearDown(controller.close);
      final players = [
        _fakePlayer(
          id: 'u1',
          name: 'Alice',
          color: '#4FC3F7',
          connected: true,
          role: 'owner',
        ),
        _fakePlayer(
          id: 'u2',
          name: 'Bob',
          color: '#EF5350',
          connected: false,
          role: 'player',
        ),
      ];

      await tester.pumpWidget(_buildSubject(controller.stream));
      controller.add(players);
      await tester.pump();

      expect(find.text('Transférer'), findsNothing);
      expect(find.text('Terminer le match'), findsNothing);
      expect(find.text('Quitter la room'), findsNothing);
    });

    testWidgets('shows empty state when player list is empty', (tester) async {
      final controller = StreamController<List<PlayerModel>>();
      addTearDown(controller.close);

      await tester.pumpWidget(_buildSubject(controller.stream));
      controller.add([]);
      await tester.pump();

      expect(find.text('Aucun joueur connecté.'), findsOneWidget);
    });
  });
}

// ── Test helpers ──────────────────────────────────────────────────────────────

Widget _buildSubject(Stream<List<PlayerModel>> stream) => MaterialApp(
  home: Scaffold(body: PlayersScreen(roomId: 'r1', playersStream: stream)),
);

PlayerModel _fakePlayer({
  required String id,
  required String name,
  required String color,
  required bool connected,
  required String role,
}) {
  return PlayerModel.fromMap(id, {
    'name': name,
    'role': role,
    'cp': 0,
    'vpByRound': <String, dynamic>{},
    'connected': connected,
    'color': color,
  });
}
