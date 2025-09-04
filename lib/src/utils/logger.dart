import 'dart:developer' as developer;

/// Improved logging utility using Flutter's developer package
class Logger {
  // Private constructor to prevent instantiation
  Logger._();

  static bool _debugMode = true;

  /// Enable or disable debug logging
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }

  /// Debug level logging (most verbose)
  static void debug(String message) {
    if (_debugMode) {
      developer.log('🐛 $message', name: 'DEBUG');
    }
  }

  /// Info level logging
  static void info(String message) {
    if (_debugMode) {
      developer.log('ℹ️ $message', name: 'INFO');
    }
  }

  /// Warning level logging
  static void warning(String message) {
    if (_debugMode) {
      developer.log('⚠️ $message', name: 'WARNING');
    }
  }

  /// Error level logging (always shown)
  static void error(String message) {
    developer.log('❌ $message', name: 'ERROR');
  }

  /// Success level logging
  static void success(String message) {
    if (_debugMode) {
      developer.log('✅ $message', name: 'SUCCESS');
    }
  }

  /// Preview/drag operation logging
  static void preview(String message) {
    if (_debugMode) {
      developer.log('🎯 $message', name: 'PREVIEW');
    }
  }

  /// Auto-expand operation logging
  static void autoExpand(String message) {
    if (_debugMode) {
      developer.log('🔧 $message', name: 'AUTO-EXPAND');
    }
  }

  /// Overlap detection logging
  static void overlap(String message) {
    if (_debugMode) {
      developer.log('🔍 $message', name: 'OVERLAP');
    }
  }

  /// Resize operation logging
  static void resize(String message) {
    if (_debugMode) {
      developer.log('📏 $message', name: 'RESIZE');
    }
  }

  /// Grid operation logging
  static void grid(String message) {
    if (_debugMode) {
      developer.log('📐 $message', name: 'GRID');
    }
  }
}