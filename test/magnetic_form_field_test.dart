import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:magnetic_form_builder/src/models/field_models.dart';

void main() {
  group('MagneticFormField', () {
    test('should create MagneticFormField with required parameters', () {
      final field = MagneticFormField(
        id: 'test_field',
        label: 'Test Field',
        icon: Icons.text_fields,
        builder: (context, isCustomizationMode) => const TextField(),
      );
      
      expect(field.id, 'test_field');
      expect(field.label, 'Test Field');
      expect(field.icon, Icons.text_fields);
      expect(field.isMandatory, false); // Default value
      expect(field.defaultValue, null); // Default value
    });

    test('should create MagneticFormField with all parameters', () {
      final field = MagneticFormField(
        id: 'full_field',
        label: 'Full Field',
        icon: Icons.email,
        builder: (context, isCustomizationMode) => const TextField(),
        isMandatory: true,
        defaultValue: 'default@example.com',
      );
      
      expect(field.id, 'full_field');
      expect(field.label, 'Full Field');
      expect(field.icon, Icons.email);
      expect(field.isMandatory, true);
      expect(field.defaultValue, 'default@example.com');
    });

    test('should create different field types with different builders', () {
      final textField = MagneticFormField(
        id: 'text_field',
        label: 'Text Input',
        icon: Icons.text_fields,
        builder: (context, isCustomizationMode) => const TextField(
          decoration: InputDecoration(labelText: 'Text Input'),
        ),
      );

      final dropdownField = MagneticFormField(
        id: 'dropdown_field',
        label: 'Dropdown',
        icon: Icons.arrow_drop_down,
        builder: (context, isCustomizationMode) => DropdownButtonFormField<String>(
          items: const [
            DropdownMenuItem(value: 'option1', child: Text('Option 1')),
            DropdownMenuItem(value: 'option2', child: Text('Option 2')),
          ],
          onChanged: (value) {},
        ),
      );

      final checkboxField = MagneticFormField(
        id: 'checkbox_field',
        label: 'Checkbox',
        icon: Icons.check_box,
        builder: (context, isCustomizationMode) => CheckboxListTile(
          title: const Text('Checkbox'),
          value: false,
          onChanged: (value) {},
        ),
      );

      expect(textField.id, 'text_field');
      expect(textField.label, 'Text Input');
      expect(textField.icon, Icons.text_fields);

      expect(dropdownField.id, 'dropdown_field');
      expect(dropdownField.label, 'Dropdown');
      expect(dropdownField.icon, Icons.arrow_drop_down);

      expect(checkboxField.id, 'checkbox_field');
      expect(checkboxField.label, 'Checkbox');
      expect(checkboxField.icon, Icons.check_box);
    });

    test('should handle builder function correctly', () {
      final field = MagneticFormField(
        id: 'builder_test',
        label: 'Builder Test',
        icon: Icons.build,
        builder: (context, isCustomizationMode) {
          return const Text('Built Widget');
        },
      );

      // Test builder function exists
      expect(field.builder, isNotNull);
    });

    testWidgets('should execute builder function correctly', (WidgetTester tester) async {
      bool builderCalled = false;
      BuildContext? capturedContext;
      bool? capturedCustomizationMode;

      final field = MagneticFormField(
        id: 'builder_test',
        label: 'Builder Test',
        icon: Icons.build,
        builder: (context, isCustomizationMode) {
          builderCalled = true;
          capturedContext = context;
          capturedCustomizationMode = isCustomizationMode;
          return const Text('Built Widget');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return field.builder(context, true);
              },
            ),
          ),
        ),
      );

      expect(builderCalled, true);
      expect(capturedContext, isNotNull);
      expect(capturedCustomizationMode, true);
      expect(find.text('Built Widget'), findsOneWidget);
    });

    test('should handle mandatory field properties', () {
      final mandatoryField = MagneticFormField(
        id: 'mandatory_field',
        label: 'Required Field',
        icon: Icons.star,
        builder: (context, isCustomizationMode) => const TextField(),
        isMandatory: true,
      );

      final optionalField = MagneticFormField(
        id: 'optional_field',
        label: 'Optional Field',
        icon: Icons.star_border,
        builder: (context, isCustomizationMode) => const TextField(),
        isMandatory: false,
      );

      expect(mandatoryField.isMandatory, true);
      expect(optionalField.isMandatory, false);
    });

    test('should handle default values correctly', () {
      final fieldWithDefault = MagneticFormField(
        id: 'default_field',
        label: 'Field with Default',
        icon: Icons.text_fields,
        builder: (context, isCustomizationMode) => const TextField(),
        defaultValue: 'Initial Value',
      );

      final fieldWithoutDefault = MagneticFormField(
        id: 'no_default_field',
        label: 'Field without Default',
        icon: Icons.text_fields,
        builder: (context, isCustomizationMode) => const TextField(),
      );

      expect(fieldWithDefault.defaultValue, 'Initial Value');
      expect(fieldWithoutDefault.defaultValue, null);
    });

    test('should create fields with different icon types', () {
      final fields = [
        MagneticFormField(
          id: 'text_field',
          label: 'Text',
          icon: Icons.text_fields,
          builder: (context, isCustomizationMode) => const TextField(),
        ),
        MagneticFormField(
          id: 'email_field',
          label: 'Email',
          icon: Icons.email,
          builder: (context, isCustomizationMode) => const TextField(),
        ),
        MagneticFormField(
          id: 'phone_field',
          label: 'Phone',
          icon: Icons.phone,
          builder: (context, isCustomizationMode) => const TextField(),
        ),
        MagneticFormField(
          id: 'date_field',
          label: 'Date',
          icon: Icons.calendar_today,
          builder: (context, isCustomizationMode) => const TextField(),
        ),
      ];

      expect(fields[0].icon, Icons.text_fields);
      expect(fields[1].icon, Icons.email);
      expect(fields[2].icon, Icons.phone);
      expect(fields[3].icon, Icons.calendar_today);
    });

    test('should maintain field properties immutability', () {
      final field = MagneticFormField(
        id: 'immutable_field',
        label: 'Immutable Field',
        icon: Icons.lock,
        builder: (context, isCustomizationMode) => const TextField(),
        isMandatory: true,
        defaultValue: 'locked_value',
      );

      // Properties should be final and immutable
      expect(field.id, 'immutable_field');
      expect(field.label, 'Immutable Field');
      expect(field.icon, Icons.lock);
      expect(field.isMandatory, true);
      expect(field.defaultValue, 'locked_value');

      // Verify const constructor works
      const constField = MagneticFormField(
        id: 'const_field',
        label: 'Const Field',
        icon: Icons.text_fields,
        builder: _staticBuilder,
      );

      expect(constField.id, 'const_field');
      expect(constField.label, 'Const Field');
      expect(constField.icon, Icons.text_fields);
    });
  });
}

// Static builder function for const constructor test
Widget _staticBuilder(BuildContext context, bool isCustomizationMode) {
  return const TextField();
}