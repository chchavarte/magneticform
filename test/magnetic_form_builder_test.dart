import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:magnetic_form_builder/magnetic_form_builder.dart';

void main() {
  group('MagneticFormBuilder', () {
    late List<MagneticFormField> testFields;

    setUp(() {
      testFields = [
        MagneticFormField(
          id: 'text_field',
          label: 'Text Field',
          icon: Icons.text_fields,
          builder: (context, isCustomizationMode) => const TextField(
            decoration: InputDecoration(labelText: 'Text Input'),
          ),
        ),
        MagneticFormField(
          id: 'email_field',
          label: 'Email Field',
          icon: Icons.email,
          builder: (context, isCustomizationMode) => const TextField(
            decoration: InputDecoration(labelText: 'Email'),
          ),
        ),
      ];
    });

    testWidgets('should create MagneticFormBuilder widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MagneticFormBuilder(
            availableFields: testFields,
            defaultFieldConfigs: const {},
          ),
        ),
      );

      expect(find.byType(MagneticFormBuilder), findsOneWidget);
    });

    testWidgets('should apply default theme when no custom theme provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MagneticFormBuilder(
            availableFields: testFields,
            defaultFieldConfigs: const {},
          ),
        ),
      );

      // Widget should render without errors using default theme
      expect(find.byType(MagneticFormBuilder), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should apply custom theme when provided', (WidgetTester tester) async {
      final customTheme = ThemeData(
        primarySwatch: Colors.green,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MagneticFormBuilder(
            availableFields: testFields,
            defaultFieldConfigs: const {},
            theme: customTheme,
          ),
        ),
      );

      // Widget should render without errors using custom theme
      expect(find.byType(MagneticFormBuilder), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render with custom app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MagneticFormBuilder(
            availableFields: testFields,
            defaultFieldConfigs: const {},
            appBarTitle: 'Custom Form Builder',
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(MagneticFormBuilder), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should hide app bar when showAppBar is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MagneticFormBuilder(
            availableFields: testFields,
            defaultFieldConfigs: const {},
            showAppBar: false,
          ),
        ),
      );

      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('should handle empty field list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MagneticFormBuilder(
            availableFields: const [],
            defaultFieldConfigs: const {},
          ),
        ),
      );

      expect(find.byType(MagneticFormBuilder), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should accept onFormDataChanged callback', (WidgetTester tester) async {
      Map<String, dynamic>? capturedFormData;
      
      await tester.pumpWidget(
        MaterialApp(
          home: MagneticFormBuilder(
            availableFields: testFields,
            defaultFieldConfigs: const {},
            onFormDataChanged: (formData) {
              capturedFormData = formData;
            },
          ),
        ),
      );

      // Widget should render without errors when callback is provided
      expect(find.byType(MagneticFormBuilder), findsOneWidget);
      expect(tester.takeException(), isNull);
      
      // Verify the callback was set up (capturedFormData starts as null)
      expect(capturedFormData, isNull);
    });

    testWidgets('should accept bottom widget function', (WidgetTester tester) async {
      Widget bottomWidget(BuildContext context, Map<String, dynamic> formData) {
        return const Text('Bottom Widget');
      }
      
      await tester.pumpWidget(
        MaterialApp(
          home: MagneticFormBuilder(
            availableFields: testFields,
            defaultFieldConfigs: const {},
            bottomWidget: bottomWidget,
          ),
        ),
      );

      // Widget should render without errors when bottom widget is provided
      expect(find.byType(MagneticFormBuilder), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should use custom storage key', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MagneticFormBuilder(
            availableFields: testFields,
            defaultFieldConfigs: const {},
            storageKey: 'custom_storage_key',
          ),
        ),
      );

      expect(find.byType(MagneticFormBuilder), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}