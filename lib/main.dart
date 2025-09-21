import 'package:flutter/material.dart';
import 'package:field_collision_test/core/core.dart';
import 'package:field_collision_test/features/customizable_form/customizable_form.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: AppTheme.withFieldExtensions(AppTheme.lightTheme),
      darkTheme: AppTheme.withFieldExtensions(AppTheme.darkTheme),
      themeMode:
          ThemeMode.system, // Automatically switch based on system preference
      home: const TestFormScreen(),
    );
  }
}

class TestFormScreen extends StatelessWidget {
  const TestFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Create test fields using the centralized builder
    final List<CustomFormField> testFields =
        TestFieldBuilder.createTestFields();

    // Create default field configurations using centralized data
    final Map<String, FieldConfig> defaultConfigs =
        TestFieldBuilder.createDefaultConfigs();

    return CustomizableFormScreen(
      availableFields: testFields,
      defaultFieldConfigs: defaultConfigs,
      appBarTitle: AppConstants.appTitle,
      storageKey: AppConstants.defaultStorageKey,
    );
  }
}
