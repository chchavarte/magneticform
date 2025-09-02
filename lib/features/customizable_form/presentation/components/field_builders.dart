import 'package:flutter/material.dart';
import 'package:field_collision_test/core/constants/field_constants.dart';
import 'package:field_collision_test/core/theme/app_theme.dart';
import 'package:field_collision_test/core/utils/decoration_utils.dart';
import '../../data/models/field_config.dart';
import '../../data/models/form_field.dart';

/// Utility class for building test fields with consistent styling
class TestFieldBuilder {
  // Private constructor to prevent instantiation
  TestFieldBuilder._();

  /// Build a standard test field with consistent styling
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
        customColor: AppTheme.getFieldColor(context, fieldId),
        customBorderColor: AppTheme.getFieldBorderColor(context, fieldId),
      ),
      child: Center(
        child: Text(
          '$fieldId - $label Field',
          style: const TextStyle(fontWeight: FieldConstants.fieldTextWeight),
        ),
      ),
    );
  }

  /// Create all test fields using the centralized configuration
  static List<CustomFormField> createTestFields() {
    return TestFieldData.testFields
        .map(
          (config) => CustomFormField(
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

  /// Create default field configurations using centralized data
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