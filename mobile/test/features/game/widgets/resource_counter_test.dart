import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mobile/features/game/presentation/widgets/resource_counter.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget buildCounter({
    String label = 'CP',
    int value = 3,
    Color playerColor = const Color(0xFF4FC3F7),
    VoidCallback? onIncrement,
    VoidCallback? onDecrement,
  }) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: ResourceCounter(
            label: label,
            value: value,
            playerColor: playerColor,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
        ),
      ),
    );
  }

  group('ResourceCounter', () {
    testWidgets('displays the CP value as text', (tester) async {
      await tester.pumpWidget(buildCounter(value: 5));
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('displays the label as text', (tester) async {
      await tester.pumpWidget(buildCounter(label: 'CP', value: 0));
      expect(find.text('CP'), findsOneWidget);
    });

    testWidgets('renders with value 0 without overflow', (tester) async {
      await tester.pumpWidget(buildCounter(value: 0));
      expect(tester.takeException(), isNull);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders with value 5 without overflow', (tester) async {
      await tester.pumpWidget(buildCounter(value: 5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with negative value without overflow', (tester) async {
      await tester.pumpWidget(buildCounter(value: -1));
      expect(tester.takeException(), isNull);
      expect(find.text('-1'), findsOneWidget);
    });

    testWidgets('+ button touch target is at least 40dp wide x 48dp tall', (
      tester,
    ) async {
      await tester.pumpWidget(buildCounter(value: 3, onIncrement: () {}));

      // Find the ConstrainedBox wrapping the + button icon
      final addIcons = find.byIcon(Icons.add);
      expect(addIcons, findsOneWidget);

      // Walk up to find the ConstrainedBox
      final constrainedBoxes = find.ancestor(
        of: addIcons,
        matching: find.byType(ConstrainedBox),
      );
      expect(constrainedBoxes, findsWidgets);

      // Verify the rendered size meets minimum requirements
      final renderBox = tester.renderObject<RenderBox>(addIcons);
      expect(renderBox, isNotNull);

      // Check via the ConstrainedBox constraints
      final cb = tester.widget<ConstrainedBox>(constrainedBoxes.first);
      expect(cb.constraints.minWidth, greaterThanOrEqualTo(40));
      expect(cb.constraints.minHeight, greaterThanOrEqualTo(48));
    });

    testWidgets('- button touch target is at least 40dp wide x 48dp tall', (
      tester,
    ) async {
      await tester.pumpWidget(buildCounter(value: 3, onDecrement: () {}));

      final removeIcons = find.byIcon(Icons.remove);
      expect(removeIcons, findsOneWidget);

      final constrainedBoxes = find.ancestor(
        of: removeIcons,
        matching: find.byType(ConstrainedBox),
      );
      expect(constrainedBoxes, findsWidgets);

      final cb = tester.widget<ConstrainedBox>(constrainedBoxes.first);
      expect(cb.constraints.minWidth, greaterThanOrEqualTo(40));
      expect(cb.constraints.minHeight, greaterThanOrEqualTo(48));
    });

    testWidgets('tapping + when onIncrement is null does not throw', (
      tester,
    ) async {
      await tester.pumpWidget(buildCounter(value: 3, onIncrement: null));
      await tester.tap(find.byIcon(Icons.add), warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping + calls onIncrement callback', (tester) async {
      var called = false;
      await tester.pumpWidget(
        buildCounter(value: 3, onIncrement: () => called = true),
      );
      await tester.tap(find.byIcon(Icons.add));
      expect(called, isTrue);
    });

    testWidgets('tapping - calls onDecrement callback', (tester) async {
      var called = false;
      await tester.pumpWidget(
        buildCounter(value: 3, onDecrement: () => called = true),
      );
      await tester.tap(find.byIcon(Icons.remove));
      expect(called, isTrue);
    });
  });
}
