import 'package:flutter/material.dart';
import '../constants/field_constants.dart';
import '../theme/magnetic_theme.dart';
import '../utils/decoration_utils.dart';
import '../models/field_config.dart';
import '../models/form_field.dart';

/// Utility class for creating test fields with consistent styling and configuration.
/// 
/// Provides pre-built form fields that demonstrate the magnetic form builder's
/// capabilities. These fields use consistent styling, theming, and behavior
/// patterns that can serve as examples for creating custom fields.
/// 
/// ## Usage
/// 
/// ```dart
/// // Create test fields for demonstration
/// final fields = TestFieldBuilder.createTestFields();
/// final configs = TestFieldBuilder.createDefaultConfigs();
/// 
/// MagneticFormBuilder(
///   availableFields: fields,
///   defaultFieldConfigs: configs,
/// )
/// ```
/// 
/// ## Custom Field Creation
/// 
/// Use [buildStandardTestField] as a template for creating your own fields:
/// 
/// ```dart
/// MagneticFormField(
///   id: 'custom_field',
///   label: 'Custom Field',
///   icon: Icons.custom,
///   builder: (context, isCustomizationMode) => 
///     TestFieldBuilder.buildStandardTestField(
///       fieldId: 'custom_field',
///       label: 'Custom Field',
///       context: context,
///       isCustomizationMode: isCustomizationMode,
///     ),
/// )
/// ```
class TestFieldBuilder {
  // Private constructor to prevent instantiation
  TestFieldBuilder._();

  /// Builds a standard test field widget with consistent styling and theming.
  /// 
  /// Creates a field widget that follows the magnetic form builder's design
  /// patterns, including proper theming, decoration, and customization mode
  /// handling. The field automatically adapts to the current theme colors.
  /// 
  /// Parameters:
  /// - [fieldId]: Unique identifier for the field (affects colors)
  /// - [label]: Display label for the field
  /// - [context]: Build context for accessing theme data
  /// - [isCustomizationMode]: Whether the form is in customization mode
  /// 
  /// Returns a styled container widget representing the field.
  /// 
  /// Example:
  /// ```dart
  /// Widget myField = TestFieldBuilder.buildStandardTestField(
  ///   fieldId: 'email',
  ///   label: 'Email Address',
  ///   context: context,
  ///   isCustomizationMode: false,
  /// );
  /// ```
  static Widget buildStandardTestField({
    required String fieldId,
    required String label,
    required BuildContext context,
    required bool isCustomizationMode,
  }) {
    return Container(
      height: FieldConstants.fieldHeight,
      padding: FieldConstants.fieldPadding,
      decoration: DecorationUtils.createFieldDecoration(
        context: context,
        state: FieldDecorationState.normal,
        customColor: MagneticTheme.getFieldColor(context, fieldId),
        customBorderColor: MagneticTheme.getFieldBorderColor(context, fieldId),
      ),
      child: Center(
        child: Text(
          '$fieldId - $label Field',
          style: const TextStyle(fontWeight: FieldConstants.fieldTextWeight),
        ),
      ),
    );
  }

  /// Creates a complete list of test fields for demonstration purposes.
  /// 
  /// Generates [MagneticFormField] instances using the centralized test field
  /// configuration data. Each field uses the [buildStandardTestField] method
  /// for consistent styling and behavior.
  /// 
  /// The created fields include various types (text, email, phone, etc.) with
  /// appropriate icons and labels. All fields follow the same styling patterns
  /// but receive different colors based on their field IDs.
  /// 
  /// Returns a list of ready-to-use [MagneticFormField] objects.
  /// 
  /// Example:
  /// ```dart
  /// final testFields = TestFieldBuilder.createTestFields();
  /// // Returns fields: field1, field2, field3, field4, field5
  /// 
  /// MagneticFormBuilder(
  ///   availableFields: testFields,
  ///   defaultFieldConfigs: TestFieldBuilder.createDefaultConfigs(),
  /// )
  /// ```
  static List<MagneticFormField> createTestFields() {
    return TestFieldData.testFields
        .map(
          (config) => MagneticFormField(
            id: config.id,
            label: config.label,
            icon: config.icon,
            builder: (context, isCustomizationMode) => buildStandardTestField(
              fieldId: config.id,
              label: config.label,
              context: context,
              isCustomizationMode: isCustomizationMode,
            ),
          ),
        )
        .toList();
  }

  /// Creates default field configurations for the test fields.
  /// 
  /// Generates [FieldConfig] objects that define the initial positions and
  /// sizes for all test fields on the magnetic grid. The configurations are
  /// based on centralized test data to ensure consistency.
  /// 
  /// The default layout typically includes:
  /// - Full-width fields at the top
  /// - Half-width fields side by side
  /// - Various field sizes demonstrating grid flexibility
  /// 
  /// Returns a map where keys are field IDs and values are [FieldConfig] objects.
  /// 
  /// Example:
  /// ```dart
  /// final configs = TestFieldBuilder.createDefaultConfigs();
  /// // Returns configurations for field1, field2, field3, field4, field5
  /// 
  /// MagneticFormBuilder(
  ///   availableFields: TestFieldBuilder.createTestFields(),
  ///   defaultFieldConfigs: configs,
  /// )
  /// ```
  static Map<String, FieldConfig> createDefaultConfigs() {
    final configs = <String, FieldConfig>{};
    
    for (final entry in TestFieldData.defaultPositions.entries) {
      final fieldId = entry.key;
      final position = entry.value;
      
      configs[fieldId] = FieldConfig(
        id: fieldId,
        position: Offset(position.x, position.y),
        width: position.width,
      );
    }
    
    return configs;
  }
}