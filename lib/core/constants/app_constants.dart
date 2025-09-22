/// General application constants and configuration values
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // Application Information
  static const String appTitle = 'Field Collision Test';
  static const String defaultStorageKey = 'collision_test_configs';



  // UI Configuration
  static const bool enableSystemThemeMode = true;
  static const bool enableDarkMode = true;

  // Performance Settings
  static const int maxFieldsPerRow = 6;
  static const int maxTotalRows = 12;
  static const double performanceThreshold = 100.0; // milliseconds

  // Storage Keys
  static const String fieldConfigStoragePrefix = 'field_config_';
  static const String userPreferencesKey = 'user_preferences';
  static const String themePreferenceKey = 'theme_preference';
}