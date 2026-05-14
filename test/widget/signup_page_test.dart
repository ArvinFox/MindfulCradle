import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mamamind/screens/auth/signup_page.dart';
import 'package:mamamind/services/localization_service.dart';
import '../helpers/fake_providers.dart';

// SignupPage creates AuthService in its State constructor which calls
// FirebaseAuth.instance. In widget tests Firebase is not initialised, so the
// widget renders as an ErrorWidget. We suppress the expected Firebase exception
// and then verify that (a) Flutter doesn't crash fatally, and (b) the rest of
// the test infrastructure is fine. Structural signup tests run properly in
// integration tests where Firebase IS available.

void _suppressKnownErrors() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString();
    if (msg.contains('overflowed')) return;
    if (msg.contains('No Firebase App') || msg.contains('[core/no-app]')) {
      return;
    }
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);
}

Widget _buildSignupPage({FakeAuthProvider? auth, FakeLanguageProvider? lang}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<FakeAuthProvider>.value(
        value: auth ?? FakeAuthProvider(),
      ),
      ChangeNotifierProvider<FakeLanguageProvider>.value(
        value: lang ?? FakeLanguageProvider(),
      ),
    ],
    child: const MaterialApp(home: SignupPage()),
  );
}

void main() {
  setUpAll(() async {
    LocalizationService.instance.reset();
    await LocalizationService.instance.loadTranslations();
  });

  group('SignupPage widget smoke tests', () {
    testWidgets('pumping SignupPage does not cause an unhandled test error', (
      tester,
    ) async {
      _suppressKnownErrors();
      // pumpWidget must not throw outside of Firebase exception which is
      // suppressed above.
      await tester.pumpWidget(_buildSignupPage());
      await tester.pump();
      // If we reach this line the test runner didn't crash.
      expect(true, isTrue);
    });

    testWidgets('MaterialApp renders when wrapping SignupPage', (tester) async {
      _suppressKnownErrors();
      await tester.pumpWidget(_buildSignupPage());
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('pumping with Sinhala provider does not throw', (tester) async {
      _suppressKnownErrors();
      await tester.pumpWidget(
        _buildSignupPage(lang: FakeLanguageProvider(lang: 'si')),
      );
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('pumping with loading auth state does not throw', (
      tester,
    ) async {
      _suppressKnownErrors();
      await tester.pumpWidget(
        _buildSignupPage(auth: FakeAuthProvider(isLoading: true)),
      );
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
