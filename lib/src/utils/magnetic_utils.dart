import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../constants/magnetic_constants.dart';

/// Consolidated utility class for decorations, logging, and helper operations
class MagneticUtils {
  // Private constructor to prevent instantiation
  MagneticUtils._();

  // ============================================================================
  // DECORATION UTILITIES (from DecorationUtils)
  // ============================================================================

  /// Create field decoration for different states
  static BoxDecoration createFieldDecoration({
    required BuildContext context,
    required FieldDecorationState state,
    Color? customColor,
    Color? customBorderColor,
  }) {
    final theme = Theme.of(context);

    switch (state) {
      case FieldDecorationState.dragged:
        return BoxDecoration(
          border: Border.all(
            color: customBorderColor ?? theme.colorScheme.primary,
            width: MagneticConstants.draggedFieldBorderWidth,
          ),
          borderRadius: BorderRadius.circular(
            MagneticConstants.fieldBorderRadius,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(
                alpha: MagneticConstants.primaryShadowOpacity,
              ),
              blurRadius: MagneticConstants.primaryShadowBlurRadius,
              offset: MagneticConstants.primaryShadowOffset,
            ),
          ],
        );

      case FieldDecorationState.preview:
        return BoxDecoration(
          border: Border.all(
            color: customBorderColor ?? theme.colorScheme.secondary,
            width: MagneticConstants.previewFieldBorderWidth,
          ),
          borderRadius: BorderRadius.circular(
            MagneticConstants.fieldBorderRadius,
          ),
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.secondary.withValues(
                alpha: MagneticConstants.secondaryShadowOpacity,
              ),
              blurRadius: MagneticConstants.secondaryShadowBlurRadius,
              offset: MagneticConstants.secondaryShadowOffset,
            ),
          ],
        );

      case FieldDecorationState.selected:
        return BoxDecoration(
          border: Border.all(
            color: customBorderColor ?? theme.colorScheme.primary,
            width: MagneticConstants.selectedFieldBorderWidth,
          ),
          borderRadius: BorderRadius.circular(
            MagneticConstants.fieldBorderRadius,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(
                alpha: MagneticConstants.selectedShadowOpacity,
              ),
              blurRadius: MagneticConstants.primaryShadowBlurRadius,
              offset: MagneticConstants.primaryShadowOffset,
            ),
          ],
        );

      case FieldDecorationState.customization:
        return BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            width: MagneticConstants.fieldBorderWidth,
          ),
          borderRadius: BorderRadius.circular(
            MagneticConstants.fieldBorderRadius,
          ),
        );

      case FieldDecorationState.previewIndicator:
        return BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
            width: MagneticConstants.previewFieldBorderWidth,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(
            MagneticConstants.fieldBorderRadius,
          ),
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        );

      case FieldDecorationState.normal:
        return BoxDecoration(
          color: customColor ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(
            MagneticConstants.fieldBorderRadius,
          ),
          border: Border.all(
            color:
                customBorderColor ??
                theme.colorScheme.onSurface.withValues(alpha: 0.2),
            width: MagneticConstants.fieldBorderWidth,
          ),
        );
    }
  }

  /// Create auto-resize message decoration
  static BoxDecoration createAutoResizeMessageDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(
        MagneticConstants.autoResizeMessageBorderRadius,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.onSurface.withValues(
            alpha: MagneticConstants.autoResizeMessageShadowOpacity,
          ),
          blurRadius: MagneticConstants.autoResizeMessageBlurRadius,
          offset: MagneticConstants.autoResizeMessageShadowOffset,
        ),
      ],
    );
  }

  /// Create snap guide decoration
  static BoxDecoration createSnapGuideDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      border: Border.all(
        color: theme.colorScheme.onSurface.withValues(
          alpha: MagneticConstants.snapGuideOpacityPrimary,
        ),
        width: MagneticConstants.snapGuideBorderWidth,
      ),
      borderRadius: BorderRadius.circular(
        MagneticConstants.snapGuideBorderRadius,
      ),
      color: theme.colorScheme.onSurface.withValues(
        alpha: MagneticConstants.snapGuideBackgroundOpacity,
      ),
    );
  }

  /// Create snap guide column decoration
  static BoxDecoration createSnapGuideColumnDecoration(
    BuildContext context,
    bool isEvenColumn,
  ) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.onSurface.withValues(
        alpha:
            isEvenColumn
                ? MagneticConstants.snapGuideColumnOpacityEven
                : MagneticConstants.snapGuideColumnOpacityOdd,
      ),
      borderRadius: BorderRadius.circular(
        MagneticConstants.snapGuideColumnBorderRadius,
      ),
    );
  }

  /// Create resize handle decoration
  static BoxDecoration createResizeHandleDecoration(
    BuildContext context,
    bool isLeft,
  ) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: Colors.transparent,
      border: Border(
        left:
            isLeft
                ? BorderSide(
                  color: theme.colorScheme.primary,
                  width: MagneticConstants.previewFieldBorderWidth,
                )
                : BorderSide.none,
        right:
            !isLeft
                ? BorderSide(
                  color: theme.colorScheme.primary,
                  width: MagneticConstants.previewFieldBorderWidth,
                )
                : BorderSide.none,
      ),
    );
  }

  /// Create resize handle inner decoration
  static BoxDecoration createResizeHandleInnerDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border.all(color: theme.colorScheme.primary),
      borderRadius: BorderRadius.circular(4),
    );
  }

  /// Create additional fields container decoration
  static BoxDecoration createAdditionalFieldsContainerDecoration(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, -2),
        ),
      ],
      border: Border(
        top: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  /// Create fields header decoration
  static BoxDecoration createFieldsHeaderDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      border: Border(
        bottom: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  /// Create field chip decoration
  static BoxDecoration createFieldChipDecoration(
    BuildContext context,
    bool isOnPage,
  ) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: isOnPage ? theme.colorScheme.primary : theme.colorScheme.surface,
      border: Border.all(
        color:
            isOnPage
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
      ),
      borderRadius: BorderRadius.circular(16),
    );
  }

  // ============================================================================
  // LOGGING UTILITIES (from Logger) - Production optimized
  // ============================================================================

  /// Debug level logging (most verbose) - Only in debug builds
  static void debug(String message) {
    // Conditional compilation for debug builds only
    assert(() {
      developer.log('🐛 $message', name: 'DEBUG');
      return true;
    }());
  }

  /// Info level logging - Only in debug builds
  static void info(String message) {
    // Conditional compilation for debug builds only
    assert(() {
      developer.log('ℹ️ $message', name: 'INFO');
      return true;
    }());
  }

  /// Warning level logging - Only in debug builds
  static void warning(String message) {
    // Conditional compilation for debug builds only
    assert(() {
      developer.log('⚠️ $message', name: 'WARNING');
      return true;
    }());
  }

  /// Error level logging (always shown)
  static void error(String message) {
    developer.log('❌ $message', name: 'ERROR');
  }

  /// Success level logging - Only in debug builds
  static void success(String message) {
    // Conditional compilation for debug builds only
    assert(() {
      developer.log('✅ $message', name: 'SUCCESS');
      return true;
    }());
  }

  /// Preview/drag operation logging - Only in debug builds
  static void preview(String message) {
    // Conditional compilation for debug builds only
    assert(() {
      developer.log('🎯 $message', name: 'PREVIEW');
      return true;
    }());
  }

  /// Auto-expand operation logging - Only in debug builds
  static void autoExpand(String message) {
    // Conditional compilation for debug builds only
    assert(() {
      developer.log('🔧 $message', name: 'AUTO-EXPAND');
      return true;
    }());
  }

  /// Overlap detection logging - Only in debug builds
  static void overlap(String message) {
    // Conditional compilation for debug builds only
    assert(() {
      developer.log('🔍 $message', name: 'OVERLAP');
      return true;
    }());
  }

  /// Resize operation logging - Only in debug builds
  static void resize(String message) {
    // Conditional compilation for debug builds only
    assert(() {
      developer.log('📏 $message', name: 'RESIZE');
      return true;
    }());
  }

  /// Grid operation logging - Only in debug builds
  static void grid(String message) {
    // Conditional compilation for debug builds only
    assert(() {
      developer.log('📐 $message', name: 'GRID');
      return true;
    }());
  }
}

/// Enum for different field decoration states
enum FieldDecorationState {
  dragged,
  preview,
  selected,
  customization,
  previewIndicator,
  normal,
}