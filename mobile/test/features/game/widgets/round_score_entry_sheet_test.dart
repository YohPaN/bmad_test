import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/game/data/event_repository.dart';
import 'package:mobile/features/game/presentation/widgets/round_score_entry_sheet.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildSheet({
  int roundNumber = 1,
  String playerName = 'Alpha',
  Color playerColor = const Color(0xFF4FC3F7),
  int? vpPrimInitial,
  int? vpSecInitial,
  Future<void> Function(int, int)? onConfirm,
}) {
  return MaterialApp(
    home: Scaffold(
      body: RoundScoreEntrySheet(
        roundNumber: roundNumber,
        playerName: playerName,
        playerColor: playerColor,
        vpPrimInitial: vpPrimInitial,
        vpSecInitial: vpSecInitial,
        onConfirm: onConfirm ?? (_, __) async {},
      ),
    ),
  );
}

void main() {
  group('RoundScoreEntrySheet — fields', () {
    testWidgets('renders VP Primaires and VP Secondaires fields', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSheet());

      expect(find.text('VP Primaires'), findsOneWidget);
      expect(find.text('VP Secondaires'), findsOneWidget);
    });

    testWidgets('renders confirmation button with round number', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSheet(roundNumber: 3));

      expect(find.text('Confirmer Round 3'), findsOneWidget);
    });

    testWidgets('confirmation button is full-width SizedBox', (tester) async {
      await tester.pumpWidget(_buildSheet());

      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(ElevatedButton),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.width, equals(double.infinity));
    });
  });

  group('RoundScoreEntrySheet — initial values', () {
    testWidgets('pre-populates VP Primaires from vpPrimInitial', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSheet(vpPrimInitial: 7));

      final primField = find.widgetWithText(TextFormField, 'VP Primaires');
      final controller =
          tester
              .widget<EditableText>(
                find.descendant(
                  of: primField,
                  matching: find.byType(EditableText),
                ),
              )
              .controller;
      expect(controller.text, equals('7'));
    });

    testWidgets('pre-populates VP Secondaires from vpSecInitial', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSheet(vpSecInitial: 4));

      final secField = find.widgetWithText(TextFormField, 'VP Secondaires');
      final controller =
          tester
              .widget<EditableText>(
                find.descendant(
                  of: secField,
                  matching: find.byType(EditableText),
                ),
              )
              .controller;
      expect(controller.text, equals('4'));
    });

    testWidgets('empty controllers when initials are null', (tester) async {
      await tester.pumpWidget(_buildSheet());

      final editableTexts =
          tester.widgetList<EditableText>(find.byType(EditableText)).toList();
      expect(editableTexts[0].controller.text, equals(''));
      expect(editableTexts[1].controller.text, equals(''));
    });
  });

  group('RoundScoreEntrySheet — confirm', () {
    testWidgets('calls onConfirm with parsed ints on confirm tap', (
      tester,
    ) async {
      int? capturedPrim;
      int? capturedSec;

      await tester.pumpWidget(
        _buildSheet(
          onConfirm: (prim, sec) async {
            capturedPrim = prim;
            capturedSec = sec;
          },
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'VP Primaires'),
        '10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'VP Secondaires'),
        '5',
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(capturedPrim, equals(10));
      expect(capturedSec, equals(5));
    });

    testWidgets('defaults to 0 for empty or non-numeric input', (tester) async {
      int? capturedPrim;
      int? capturedSec;

      await tester.pumpWidget(
        _buildSheet(
          onConfirm: (prim, sec) async {
            capturedPrim = prim;
            capturedSec = sec;
          },
        ),
      );

      // Leave fields empty
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(capturedPrim, equals(0));
      expect(capturedSec, equals(0));
    });

    testWidgets('shows loading spinner while onConfirm is in progress', (
      tester,
    ) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        _buildSheet(onConfirm: (_, __) => completer.future),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // single frame — loading starts

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete to avoid pending timer assertion
      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('shows error message on thrown GameException', (tester) async {
      await tester.pumpWidget(
        _buildSheet(
          onConfirm: (_, __) async {
            throw const GameException('network error');
          },
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('network error'), findsOneWidget);
    });
  });
}
