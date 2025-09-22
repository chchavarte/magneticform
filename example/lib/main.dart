import 'package:flutter/material.dart';
import 'package:magnetic_form_builder/magnetic_form_builder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magnetic Form Builder Example',
      theme: MagneticTheme.withFieldExtensions(MagneticTheme.lightTheme),
      darkTheme: MagneticTheme.withFieldExtensions(MagneticTheme.darkTheme),
      themeMode: ThemeMode.system, // Automatically switch based on system preference
      home: const ExampleHomeScreen(),
    );
  }
}

class ExampleHomeScreen extends StatelessWidget {
  const ExampleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Magnetic Form Builder Examples'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose an example to see different theme configurations:',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DefaultThemeFormScreen(),
                  ),
                );
              },
              child: const Text('Default Theme Example'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomThemeFormScreen(),
                  ),
                );
              },
              child: const Text('Custom Theme Example'),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Usage:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Default Theme: Uses MagneticTheme.lightTheme/darkTheme'),
                    Text('• Custom Theme: Provide your own ThemeData to the theme parameter'),
                    Text('• When no theme is provided, it automatically matches the original app appearance'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example showing default theme usage
/// 
/// This demonstrates how the MagneticFormBuilder works when no custom theme
/// is provided. It automatically uses the original theme system from the
/// source application, ensuring identical appearance and behavior.
class DefaultThemeFormScreen extends StatelessWidget {
  const DefaultThemeFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Create test fields using the centralized builder - EXACT copy from original
    final List<MagneticFormField> testFields = TestFieldBuilder.createTestFields();

    // Create default field configurations using centralized data - EXACT copy from original
    final Map<String, FieldConfig> defaultConfigs = TestFieldBuilder.createDefaultConfigs();

    return MagneticFormBuilder(
      availableFields: testFields,
      defaultFieldConfigs: defaultConfigs,
      appBarTitle: 'Default Theme Example',
      storageKey: 'magnetic_form_default_theme_storage',
      // NO theme parameter provided - uses MagneticTheme.lightTheme automatically
      // This ensures the UI looks identical to the original app
    );
  }
}

/// Example showing custom theme usage
/// 
/// This demonstrates how to provide a custom ThemeData to the MagneticFormBuilder.
/// The custom theme is processed through MagneticTheme.withFieldExtensions() to
/// ensure all field-specific styling is properly applied.
class CustomThemeFormScreen extends StatelessWidget {
  const CustomThemeFormScreen({super.key});

  // Custom theme with teal color scheme - different from the original purple theme
  static final ThemeData _customTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal, // Different from original Colors.deepPurple
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0.5,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Create test fields using the centralized builder - EXACT copy from original
    final List<MagneticFormField> testFields = TestFieldBuilder.createTestFields();

    // Create default field configurations using centralized data - EXACT copy from original
    final Map<String, FieldConfig> defaultConfigs = TestFieldBuilder.createDefaultConfigs();

    return MagneticFormBuilder(
      availableFields: testFields,
      defaultFieldConfigs: defaultConfigs,
      appBarTitle: 'Custom Theme Example',
      storageKey: 'magnetic_form_custom_theme_storage',
      // Custom theme provided - uses teal color scheme instead of default purple
      theme: MagneticTheme.withFieldExtensions(_customTheme),
    );
  }
}