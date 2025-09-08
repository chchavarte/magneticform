import 'package:flutter/material.dart';
import 'field_theme_extension.dart';

/// Theme system for the magnetic form builder package.
/// 
/// Provides default light and dark themes with field-specific styling extensions.
/// Supports custom theme integration while maintaining consistent field appearance.
class MagneticTheme {
  // Private constructor to prevent instantiation
  MagneticTheme._();

  /// Primary seed color used for default themes
  static const Color _seedColor = Colors.deepPurple;
  
  /// Common app bar theme configuration
  static const AppBarTheme _appBarTheme = AppBarTheme(
    centerTitle: true,
    elevation: 0.5,
  );

  /// Default light theme for the magnetic form builder
  static ThemeData get lightTheme => _createTheme(Brightness.light);

  /// Default dark theme for the magnetic form builder
  static ThemeData get darkTheme => _createTheme(Brightness.dark);

  /// Create theme with specified brightness
  static ThemeData _createTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
      ),
      useMaterial3: true,
      appBarTheme: _appBarTheme,
    );
  }

  /// Gets a theme with field extensions, using custom or default theme data
  static ThemeData getTheme({ThemeData? customTheme, bool isDark = false}) {
    final baseTheme = customTheme ?? (isDark ? darkTheme : lightTheme);
    return withFieldExtensions(baseTheme);
  }

  /// Field color mapping for consistent theming
  static const Map<String, int> _fieldColorMap = {
    'field1': 0, // primaryContainer
    'field2': 1, // secondaryContainer
    'field3': 2, // tertiaryContainer
    'field4': 3, // errorContainer
    'field5': 4, // surfaceContainerHighest
  };

  /// Gets the background color for a field based on its ID and current theme
  static Color getFieldColor(BuildContext context, String fieldId) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorIndex = _fieldColorMap[fieldId] ?? -1;
    
    return switch (colorIndex) {
      0 => colorScheme.primaryContainer,
      1 => colorScheme.secondaryContainer,
      2 => colorScheme.tertiaryContainer,
      3 => colorScheme.errorContainer,
      4 => colorScheme.surfaceContainerHighest,
      _ => colorScheme.surfaceContainer,
    };
  }

  /// Gets the border color for a field based on its ID and current theme
  static Color getFieldBorderColor(BuildContext context, String fieldId) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorIndex = _fieldColorMap[fieldId] ?? -1;
    
    return switch (colorIndex) {
      0 => colorScheme.primary,
      1 => colorScheme.secondary,
      2 => colorScheme.tertiary,
      3 => colorScheme.error,
      4 => colorScheme.outline,
      _ => colorScheme.outline,
    };
  }

  /// Transparent color used for invisible resize handles and overlays
  static Color get transparentColor => Colors.transparent;

  /// Enhances a theme with field-specific styling extensions
  static ThemeData withFieldExtensions(ThemeData baseTheme) {
    return baseTheme.copyWith(
      extensions: [_createFieldExtension(baseTheme.colorScheme)],
    );
  }

  /// Create field theme extension from color scheme
  static FieldThemeExtension _createFieldExtension(ColorScheme colorScheme) {
    return FieldThemeExtension(
      draggedFieldBorderColor: colorScheme.primary,
      selectedFieldBorderColor: colorScheme.secondary,
      previewFieldBackgroundColor: colorScheme.secondary.withValues(alpha: 0.1),
      snapGuideColor: colorScheme.onSurface.withValues(alpha: 0.08),
      snapGuideBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.02),
    );
  }
}