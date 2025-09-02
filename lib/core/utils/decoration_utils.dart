import 'package:flutter/material.dart';
import '../constants/field_constants.dart';

/// Utility class for creating consistent decorations across the app
class DecorationUtils {
  // Private constructor to prevent instantiation
  DecorationUtils._();

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
            width: FieldConstants.draggedFieldBorderWidth,
          ),
          borderRadius: BorderRadius.circular(FieldConstants.fieldBorderRadius),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(
                alpha: FieldConstants.primaryShadowOpacity,
              ),
              blurRadius: FieldConstants.primaryShadowBlurRadius,
              offset: FieldConstants.primaryShadowOffset,
            ),
          ],
        );
        
      case FieldDecorationState.preview:
        return BoxDecoration(
          border: Border.all(
            color: customBorderColor ?? theme.colorScheme.secondary,
            width: FieldConstants.previewFieldBorderWidth,
          ),
          borderRadius: BorderRadius.circular(FieldConstants.fieldBorderRadius),
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.secondary.withValues(
                alpha: FieldConstants.secondaryShadowOpacity,
              ),
              blurRadius: FieldConstants.secondaryShadowBlurRadius,
              offset: FieldConstants.secondaryShadowOffset,
            ),
          ],
        );
        
      case FieldDecorationState.selected:
        return BoxDecoration(
          border: Border.all(
            color: customBorderColor ?? theme.colorScheme.primary,
            width: FieldConstants.selectedFieldBorderWidth,
          ),
          borderRadius: BorderRadius.circular(FieldConstants.fieldBorderRadius),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(
                alpha: FieldConstants.selectedShadowOpacity,
              ),
              blurRadius: FieldConstants.primaryShadowBlurRadius,
              offset: FieldConstants.primaryShadowOffset,
            ),
          ],
        );
        
      case FieldDecorationState.customization:
        return BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            width: FieldConstants.fieldBorderWidth,
          ),
          borderRadius: BorderRadius.circular(FieldConstants.fieldBorderRadius),
        );
        
      case FieldDecorationState.previewIndicator:
        return BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
            width: FieldConstants.previewFieldBorderWidth,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(FieldConstants.fieldBorderRadius),
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        );
        
      case FieldDecorationState.normal:
        return BoxDecoration(
          color: customColor ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(FieldConstants.fieldBorderRadius),
          border: Border.all(
            color: customBorderColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.2),
            width: FieldConstants.fieldBorderWidth,
          ),
        );
    }
  }

  /// Create auto-resize message decoration
  static BoxDecoration createAutoResizeMessageDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(FieldConstants.autoResizeMessageBorderRadius),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.onSurface.withValues(
            alpha: FieldConstants.autoResizeMessageShadowOpacity,
          ),
          blurRadius: FieldConstants.autoResizeMessageBlurRadius,
          offset: FieldConstants.autoResizeMessageShadowOffset,
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
          alpha: FieldConstants.snapGuideOpacityPrimary,
        ),
        width: FieldConstants.snapGuideBorderWidth,
      ),
      borderRadius: BorderRadius.circular(FieldConstants.snapGuideBorderRadius),
      color: theme.colorScheme.onSurface.withValues(
        alpha: FieldConstants.snapGuideBackgroundOpacity,
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
        alpha: isEvenColumn 
          ? FieldConstants.snapGuideColumnOpacityEven 
          : FieldConstants.snapGuideColumnOpacityOdd,
      ),
      borderRadius: BorderRadius.circular(FieldConstants.snapGuideColumnBorderRadius),
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
        left: isLeft
          ? BorderSide(
              color: theme.colorScheme.primary, 
              width: FieldConstants.previewFieldBorderWidth,
            )
          : BorderSide.none,
        right: !isLeft
          ? BorderSide(
              color: theme.colorScheme.primary, 
              width: FieldConstants.previewFieldBorderWidth,
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
  static BoxDecoration createAdditionalFieldsContainerDecoration(BuildContext context) {
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
        color: isOnPage
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.2),
      ),
      borderRadius: BorderRadius.circular(16),
    );
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