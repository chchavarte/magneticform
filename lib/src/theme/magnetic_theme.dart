import 'package:flutter/material.dart';
import 'field_theme_extension.dart';

/// Theme system for the magnetic form builder package.
/// 
/// Provides default light and dark themes with field-specific styling extensions.
/// Supports custom theme integration while maintaining consistent field appearance.
/// 
/// ## Usage
/// 
/// ### Default Themes
/// ```dart
/// // Use default light theme
/// MaterialApp(
///   theme: MagneticTheme.withFieldExtensions(MagneticTheme.lightTheme),
///   home: MyFormScreen(),
/// )
/// 
/// // Use default dark theme
/// MaterialApp(
///   darkTheme: MagneticTheme.withFieldExtensions(MagneticTheme.darkTheme),
///   home: MyFormScreen(),
/// )
/// ```
/// 
/// ### Custom Themes
/// ```dart
/// final customTheme = ThemeData(
///   colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
/// );
/// 
/// MaterialApp(
///   theme: MagneticTheme.withFieldExtensions(customTheme),
///   home: MyFormScreen(),
/// )
/// ```
class MagneticTheme {
  // Private constructor to prevent instantiation
  MagneticTheme._();

  /// Primary seed color used for default themes.
  /// 
  /// This deep purple color provides the base for the default light and dark
  /// color schemes. When using custom themes, this color is not used.
  static const Color _seedColor = Colors.deepPurple;

  /// Default light theme for the magnetic form builder.
  /// 
  /// Uses Material 3 design with a deep purple color scheme. Includes
  /// optimized app bar styling for the form builder interface.
  /// 
  /// Example:
  /// ```dart
  /// MaterialApp(
  ///   theme: MagneticTheme.withFieldExtensions(MagneticTheme.lightTheme),
  ///   home: MyFormScreen(),
  /// )
  /// ```
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

  /// Default dark theme for the magnetic form builder.
  /// 
  /// Uses Material 3 design with a deep purple color scheme optimized for
  /// dark mode. Includes consistent app bar styling with the light theme.
  /// 
  /// Example:
  /// ```dart
  /// MaterialApp(
  ///   darkTheme: MagneticTheme.withFieldExtensions(MagneticTheme.darkTheme),
  ///   themeMode: ThemeMode.system,
  ///   home: MyFormScreen(),
  /// )
  /// ```
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

  /// Gets a theme with field extensions, using custom or default theme data.
  /// 
  /// If [customTheme] is provided, it will be enhanced with field-specific
  /// extensions. Otherwise, returns the default light or dark theme based
  /// on the [isDark] parameter.
  /// 
  /// Example:
  /// ```dart
  /// // Use custom theme
  /// final theme = MagneticTheme.getTheme(
  ///   customTheme: myCustomTheme,
  /// );
  /// 
  /// // Use default dark theme
  /// final darkTheme = MagneticTheme.getTheme(isDark: true);
  /// ```
  static ThemeData getTheme({ThemeData? customTheme, bool isDark = false}) {
    if (customTheme != null) {
      return withFieldExtensions(customTheme);
    }
    return withFieldExtensions(isDark ? darkTheme : lightTheme);
  }

  /// Gets the background color for a field based on its ID and current theme.
  /// 
  /// Different field IDs receive different colors to provide visual distinction
  /// in the form builder interface. Colors are derived from the current theme's
  /// color scheme to ensure consistency.
  /// 
  /// Parameters:
  /// - [context]: Build context for accessing the current theme
  /// - [fieldId]: Unique identifier of the field
  /// 
  /// Returns a color from the theme's color scheme containers.
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

  /// Gets the border color for a field based on its ID and current theme.
  /// 
  /// Provides consistent border colors that complement the field background
  /// colors. Used for field outlines, selection indicators, and drag previews.
  /// 
  /// Parameters:
  /// - [context]: Build context for accessing the current theme
  /// - [fieldId]: Unique identifier of the field
  /// 
  /// Returns a color from the theme's color scheme.
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

  /// Transparent color used for invisible resize handles and overlays.
  /// 
  /// Provides a consistent transparent color for UI elements that need to be
  /// invisible but still capture touch events, such as resize handles.
  static Color get transparentColor => Colors.transparent;

  /// Enhances a theme with field-specific styling extensions.
  /// 
  /// Adds [FieldThemeExtension] to the provided theme, which includes colors
  /// for drag operations, field selection, preview states, and grid guides.
  /// This ensures consistent field styling across different base themes.
  /// 
  /// **Always use this method** when applying themes to ensure proper field
  /// styling in the magnetic form builder.
  /// 
  /// Parameters:
  /// - [baseTheme]: The base theme to enhance with field extensions
  /// 
  /// Returns the enhanced theme with field-specific styling.
  /// 
  /// Example:
  /// ```dart
  /// // Enhance default theme
  /// final theme = MagneticTheme.withFieldExtensions(MagneticTheme.lightTheme);
  /// 
  /// // Enhance custom theme
  /// final customTheme = ThemeData(colorScheme: myColorScheme);
  /// final enhancedTheme = MagneticTheme.withFieldExtensions(customTheme);
  /// ```
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