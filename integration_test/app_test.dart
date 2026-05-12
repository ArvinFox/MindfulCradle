import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:mamamind/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App smoke tests', () {
    testWidgets('app launches without crashing', (tester) async {
      // Start the real app (including Firebase initialisation).
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The app should render at least one widget.
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('splash / onboarding or login screen appears on first launch', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
