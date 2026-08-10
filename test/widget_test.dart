// This is a basic Flutter widget test.
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll gestures.

import 'package:flutter_test/flutter_test.dart';
import 'package:convertix/app/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ConvertixApp());

    // Verify that the app loads with the title
    expect(find.text('Convertix'), findsOneWidget);
  });
}