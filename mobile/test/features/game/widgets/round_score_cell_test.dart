import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/game/presentation/widgets/round_score_cell.dart';

void main() {
  const playerColor = Color(0xFF4FC3F7);
  const textMuted = Color(0xFF5C6478);

  Widget buildCell(RoundScoreCell cell) {
    return MaterialApp(home: Scaffold(body: Center(child: cell)));
  }

  group('RoundScoreCell — empty state', () {
    testWidgets('renders — placeholder in muted colour', (tester) async {
      await tester.pumpWidget(
        buildCell(
          const RoundScoreCell(
            state: RoundCellState.empty,
            roundNumber: 1,
            playerColor: playerColor,
          ),
        ),
      );

      expect(find.text('—'), findsOneWidget);
      final text = tester.widget<Text>(find.text('—'));
      expect(text.style?.color, equals(textMuted));
    });

    testWidgets('no lock icon in empty state', (tester) async {
      await tester.pumpWidget(
        buildCell(
          const RoundScoreCell(
            state: RoundCellState.empty,
            roundNumber: 1,
            playerColor: playerColor,
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsNothing);
    });

    testWidgets('is tappable when onTap provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildCell(
          RoundScoreCell(
            state: RoundCellState.empty,
            roundNumber: 1,
            playerColor: playerColor,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(RoundScoreCell));
      expect(tapped, isTrue);
    });
  });

  group('RoundScoreCell — active state', () {
    testWidgets('container has border with playerColor', (tester) async {
      await tester.pumpWidget(
        buildCell(
          const RoundScoreCell(
            state: RoundCellState.active,
            roundNumber: 2,
            playerColor: playerColor,
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(RoundScoreCell),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      final border = decoration.border as Border;
      expect(border.top.color, equals(playerColor));
    });

    testWidgets('no lock icon in active state', (tester) async {
      await tester.pumpWidget(
        buildCell(
          const RoundScoreCell(
            state: RoundCellState.active,
            roundNumber: 2,
            playerColor: playerColor,
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsNothing);
    });

    testWidgets('is tappable when onTap provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildCell(
          RoundScoreCell(
            state: RoundCellState.active,
            roundNumber: 2,
            playerColor: playerColor,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(RoundScoreCell));
      expect(tapped, isTrue);
    });
  });

  group('RoundScoreCell — filled state', () {
    testWidgets('displays VP Prim, VP Sec, and total values', (tester) async {
      await tester.pumpWidget(
        buildCell(
          const RoundScoreCell(
            state: RoundCellState.filled,
            roundNumber: 1,
            playerColor: playerColor,
            vpPrim: 8,
            vpSec: 5,
          ),
        ),
      );

      expect(find.text('P:8'), findsOneWidget);
      expect(find.text('S:5'), findsOneWidget);
      expect(find.text('T:13'), findsOneWidget);
    });

    testWidgets('shows zero total when vpPrim and vpSec are null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCell(
          const RoundScoreCell(
            state: RoundCellState.filled,
            roundNumber: 1,
            playerColor: playerColor,
          ),
        ),
      );

      expect(find.text('T:0'), findsOneWidget);
    });
  });

  group('RoundScoreCell — locked state', () {
    testWidgets('shows lock icon with opacity 0.3', (tester) async {
      await tester.pumpWidget(
        buildCell(
          const RoundScoreCell(
            state: RoundCellState.locked,
            roundNumber: 3,
            playerColor: playerColor,
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);

      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byIcon(Icons.lock),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, closeTo(0.3, 0.01));
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildCell(
          RoundScoreCell(
            state: RoundCellState.locked,
            roundNumber: 3,
            playerColor: playerColor,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(RoundScoreCell));
      expect(tapped, isTrue);
    });
  });

  group('RoundScoreCell — future state', () {
    testWidgets('text placeholder in muted colour', (tester) async {
      await tester.pumpWidget(
        buildCell(
          const RoundScoreCell(
            state: RoundCellState.future,
            roundNumber: 4,
            playerColor: playerColor,
          ),
        ),
      );

      expect(find.text('—'), findsOneWidget);
      final text = tester.widget<Text>(find.text('—'));
      expect(text.style?.color, equals(textMuted));
    });

    testWidgets('onTap is null — tap does nothing', (tester) async {
      await tester.pumpWidget(
        buildCell(
          const RoundScoreCell(
            state: RoundCellState.future,
            roundNumber: 4,
            playerColor: playerColor,
          ),
        ),
      );

      // Should not throw even when tapped
      await tester.tap(find.byType(RoundScoreCell), warnIfMissed: false);
    });
  });

  group('RoundScoreCell — flash animation', () {
    testWidgets('flashOnUpdate false — VP change does NOT trigger animation', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCell(
          const RoundScoreCell(
            state: RoundCellState.filled,
            roundNumber: 1,
            playerColor: playerColor,
            vpPrim: 3,
            vpSec: 4,
            flashOnUpdate: false,
          ),
        ),
      );

      // Rebuild with a different VP — no flash should occur
      await tester.pumpWidget(
        buildCell(
          const RoundScoreCell(
            state: RoundCellState.filled,
            roundNumber: 1,
            playerColor: playerColor,
            vpPrim: 5,
            vpSec: 6,
            flashOnUpdate: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1));

      // ColoredBox overlay should not be in the tree
      expect(find.byType(ColoredBox), findsNothing);
    });

    testWidgets(
      'flashOnUpdate true + filled + VP change → animation triggers',
      (tester) async {
        await tester.pumpWidget(
          buildCell(
            const RoundScoreCell(
              state: RoundCellState.filled,
              roundNumber: 1,
              playerColor: playerColor,
              vpPrim: 3,
              vpSec: 4,
              flashOnUpdate: true,
            ),
          ),
        );

        // Rebuild with updated VP to trigger didUpdateWidget
        await tester.pumpWidget(
          buildCell(
            const RoundScoreCell(
              state: RoundCellState.filled,
              roundNumber: 1,
              playerColor: playerColor,
              vpPrim: 5,
              vpSec: 6,
              flashOnUpdate: true,
            ),
          ),
        );

        // Advance animation one frame — overlay should be visible
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(ColoredBox), findsOneWidget);

        // Let animation complete
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'flashOnUpdate true + state NOT filled → animation does NOT trigger',
      (tester) async {
        await tester.pumpWidget(
          buildCell(
            const RoundScoreCell(
              state: RoundCellState.active,
              roundNumber: 1,
              playerColor: playerColor,
              vpPrim: 3,
              vpSec: 4,
              flashOnUpdate: true,
            ),
          ),
        );

        await tester.pumpWidget(
          buildCell(
            const RoundScoreCell(
              state: RoundCellState.active,
              roundNumber: 1,
              playerColor: playerColor,
              vpPrim: 5,
              vpSec: 6,
              flashOnUpdate: true,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // No ColoredBox overlay — wrong state
        expect(find.byType(ColoredBox), findsNothing);
      },
    );
  });
}
