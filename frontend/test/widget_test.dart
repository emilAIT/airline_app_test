// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zaku_app/app/zaku_app.dart';

void main() {
  testWidgets('MyApp boots and shows AuthScreen when logged out',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());

    // Allow async restoreSession() to complete.
    await tester.pumpAndSettle();

    expect(find.text('Вход'), findsOneWidget);
  });
}
