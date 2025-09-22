import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnetic_form_builder_example/main.dart';

void main() {
  testWidgets('Example app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Verify that the app loads without throwing errors
    await tester.pumpAndSettle();
  });
}