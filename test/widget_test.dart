// Basic sanity test that does NOT require Firebase.
// Full widget and unit tests are in test/unit/ and test/widget/.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamamind/models/user_model.dart';

void main() {
  test('UserModel.newUser() returns a valid instance', () {
    final user = UserModel.newUser(
      id: 'uid-sanity',
      fullName: 'Test User',
      email: 'test@example.com',
    );
    expect(user.email, contains('@'));
    expect(user.isUserRegistrationComplete, isFalse);
  });

  testWidgets('MaterialApp renders without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Mindful Cradle'))),
      ),
    );
    expect(find.text('Mindful Cradle'), findsOneWidget);
  });
}
