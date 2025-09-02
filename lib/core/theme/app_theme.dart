import 'package:flutter/material.dart';
import 'field_theme_extension.dart';

/// Custom theme system for the field collision test app
class AppTheme {
  // Private constructor
  AppTheme._();

  /// Primary seed color - can be customized
  static const Color _seedColor = Colors.deepPurple;

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0.5,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0.5,
      ),
    );
  }

  /// Get field background color based on field ID and theme
  static Color getFieldColor(BuildContext context, String fieldId) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (fieldId) {
      case 'field1':
        return colorScheme.primaryContainer;
      case 'field2':
        return colorScheme.secondaryContainer;
      case 'field3':
        return colorScheme.tertiaryContainer;
      case 'field4':
        return colorScheme.errorContainer;
      case 'field5':
        return colorScheme.surfaceContainerHighest;
      default:
        return colorScheme.surfaceContainer;
    }
  }

  /// Get field border color based on field ID and theme
  static Color getFieldBorderColor(BuildContext context, String fieldId) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (fieldId) {
      case 'field1':
        return colorScheme.primary;
      case 'field2':
        return colorScheme.secondary;
      case 'field3':
        return colorScheme.tertiary;
      case 'field4':
        return colorScheme.error;
      case 'field5':
        return colorScheme.outline;
      default:
        return colorScheme.outline;
    }
  }

  /// Transparent color for resize handles
  static Color get transparentColor => Colors.transparent;

  /// Custom theme extension for field-specific styling
  static ThemeData withFieldExtensions(ThemeData baseTheme) {
    return baseTheme.copyWith(
      extensions: [
        FieldThemeExtension(
          draggedFieldBorderColor: baseTheme.colorScheme.primary,
          selectedFieldBorderColor: baseTheme.colorScheme.secondary,
          previewFieldBackgroundColor: baseTheme.colorScheme.secondary.withValues(alpha: 0.1),
          snapGuideColor: baseTheme.colorScheme.onSurface.withValues(alpha: 0.08),
          snapGuideBackgroundColor: baseTheme.colorScheme.onSurface.withValues(alpha: 0.02),
        ),
      ],
    );
  }
}