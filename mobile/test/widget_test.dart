import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';

void main() {
  testWidgets('App renders bottom navigation with 4 tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    expect(find.text('Match'), findsOneWidget);
    expect(find.text('Historique'), findsOneWidget);
    expect(find.text('Joueurs'), findsOneWidget);
    expect(find.text('Room'), findsOneWidget);
  });
}
