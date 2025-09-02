import 'package:flutter/material.dart';
import 'package:field_collision_test/core/constants/field_constants.dart';
import 'package:field_collision_test/core/utils/decoration_utils.dart';
import '../handlers/resize_handler.dart';
import '../systems/field_preview_system.dart';
import '../../data/models/field_config.dart';
import '../../data/models/form_field.dart';
import '../../data/models/magnetic_card_system.dart';

/// Builds UI components for the customizable form
class FormUIBuilder {
  // Private constructor to prevent instantiation
  FormUIBuilder._();

  /// Build the main app bar
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required String title,
    required bool isCustomizationMode,
    required VoidCallback onToggleMode,
  }) {
    final theme = Theme.of(context);
    
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0.5,
      centerTitle: true,
      title: Text(title, style: theme.appBarTheme.titleTextStyle),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(
            isCustomizationMode ? Icons.done : Icons.tune,
            size: 24,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: onToggleMode,
        ),
      ],
    );
  }

  /// Build snap guides for customization mode
  static Widget buildSnapGuides({
    required BuildContext context,
    required double containerWidth,
  }) {
    return Container(
      margin: const EdgeInsets.all(FieldConstants.containerPadding),
      child: Stack(
        children: [
          // Row guides
          for (int row = 0; row < MagneticCardSystem.maxRows; row++)
            Positioned(
              left: 0,
              right: 0,
              top: row * MagneticCardSystem.cardHeight - 2,
              child: Container(
                height: MagneticCardSystem.cardHeight + FieldConstants.snapGuideHeight,
                decoration: DecorationUtils.createSnapGuideDecoration(context),
              ),
            ),

          // Column guides
          for (int col = 1; col < 6; col++)
            Positioned(
              left: (containerWidth / 6) * col - 1,
              top: 0,
              bottom: 0,
              child: Container(
                width: FieldConstants.snapGuideColumnWidth,
                decoration: DecorationUtils.createSnapGuideColumnDecoration(
                  context,
                  col % 2 == 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build preview target indicator
  static Widget buildPreviewIndicator({
    required BuildContext context,
    required PreviewState previewState,
    required double containerWidth,
    required Map<String, FieldConfig> fieldConfigs,
  }) {
    if (!previewState.isActive ||
        previewState.previewInfo?.targetPosition == null ||
        previewState.previewInfo?.hasSpace != true) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final targetPosition = previewState.previewInfo!.targetPosition!;
    final draggedField = fieldConfigs[previewState.draggedFieldId!]!;

    final fieldWidth = draggedField.width * containerWidth;
    final leftPosition = targetPosition.dx * containerWidth;

    return Positioned(
      left: leftPosition,
      top: targetPosition.dy + 8,
      child: Container(
        width: fieldWidth - (targetPosition.dx > 0 ? MagneticCardSystem.fieldGap : 0),
        height: MagneticCardSystem.cardHeight,
        margin: EdgeInsets.only(
          left: targetPosition.dx > 0 ? MagneticCardSystem.fieldGap : 0,
        ),
        decoration: DecorationUtils.createFieldDecoration(
          context: context,
          state: FieldDecorationState.previewIndicator,
        ),
        child: Center(
          child: Icon(
            Icons.place,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Build auto-resize message
  static Widget buildAutoResizeMessage({
    required BuildContext context,
    required String message,
  }) {
    final theme = Theme.of(context);
    
    return Positioned(
      top: FieldConstants.autoResizeMessageTopOffset,
      left: FieldConstants.autoResizeMessageHorizontalOffset,
      right: FieldConstants.autoResizeMessageHorizontalOffset,
      child: Container(
        padding: const EdgeInsets.all(FieldConstants.autoResizeMessagePadding),
        decoration: DecorationUtils.createAutoResizeMessageDecoration(context),
        child: Text(
          message,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Build magnetic field with all states
  static Widget buildMagneticField({
    required BuildContext context,
    required String fieldId,
    required Widget field,
    required FieldConfig config,
    required bool isCustomizationMode,
    required bool isSelected,
    required bool isDragged,
    required bool isInPreview,
    required double containerWidth,
    required Function(String) onTap,
    required Function(String, LongPressStartDetails) onLongPressStart,
    required Function(String, LongPressMoveUpdateDetails) onLongPressMoveUpdate,
    required Function(String, LongPressEndDetails) onLongPressEnd,
    required Function(String, DragUpdateDetails, ResizeDirection) onResize,
    required Function(String, ResizeDirection) onResizeStart,
    required Function(String, ResizeDirection) onResizeEnd,
  }) {
    if (!config.isVisible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final fieldWidth = config.width * containerWidth;
    final leftPosition = config.position.dx * containerWidth;

    return Positioned(
      left: leftPosition,
      top: config.position.dy + 8,
      child: Stack(
        children: [
          GestureDetector(
            onTap: isCustomizationMode ? () => onTap(fieldId) : null,
            onLongPressStart: isCustomizationMode ? (details) => onLongPressStart(fieldId, details) : null,
            onLongPressMoveUpdate: isCustomizationMode ? (details) => onLongPressMoveUpdate(fieldId, details) : null,
            onLongPressEnd: isCustomizationMode ? (details) => onLongPressEnd(fieldId, details) : null,
            behavior: HitTestBehavior.opaque,
            child: AbsorbPointer(
              absorbing: isCustomizationMode,
              child: Container(
                width: fieldWidth - (config.position.dx > 0 ? MagneticCardSystem.fieldGap : 0),
                margin: EdgeInsets.only(
                  left: config.position.dx > 0 ? MagneticCardSystem.fieldGap : 0,
                ),
                decoration: _getFieldDecoration(
                  context,
                  isDragged: isDragged,
                  isInPreview: isInPreview,
                  isSelected: isSelected,
                  isCustomizationMode: isCustomizationMode,
                ),
                child: field,
              ),
            ),
          ),
          if (isCustomizationMode && isSelected) ...[
            // Resize handles
            FieldResizeHandler.buildResizeHandle(
              context: context,
              direction: ResizeDirection.left,
              fieldId: fieldId,
              theme: theme,
              onResize: onResize,
              onResizeStart: onResizeStart,
              onResizeEnd: onResizeEnd,
            ),
            FieldResizeHandler.buildResizeHandle(
              context: context,
              direction: ResizeDirection.right,
              fieldId: fieldId,
              theme: theme,
              onResize: onResize,
              onResizeStart: onResizeStart,
              onResizeEnd: onResizeEnd,
            ),
          ],
        ],
      ),
    );
  }

  /// Get field decoration based on state
  static BoxDecoration? _getFieldDecoration(
    BuildContext context, {
    required bool isDragged,
    required bool isInPreview,
    required bool isSelected,
    required bool isCustomizationMode,
  }) {
    if (isDragged) {
      return DecorationUtils.createFieldDecoration(
        context: context,
        state: FieldDecorationState.dragged,
      );
    } else if (isInPreview) {
      return DecorationUtils.createFieldDecoration(
        context: context,
        state: FieldDecorationState.preview,
      );
    } else if (isCustomizationMode && isSelected) {
      return DecorationUtils.createFieldDecoration(
        context: context,
        state: FieldDecorationState.selected,
      );
    } else if (isCustomizationMode) {
      return DecorationUtils.createFieldDecoration(
        context: context,
        state: FieldDecorationState.customization,
      );
    }

    return null;
  }

  /// Build additional fields container
  static Widget buildAdditionalFieldsContainer({
    required BuildContext context,
    required List<CustomFormField> availableFields,
    required Map<String, FieldConfig> fieldConfigs,
    required Function(String) onToggleField,
  }) {
    return Container(
      height: 100,
      decoration: DecorationUtils.createAdditionalFieldsContainerDecoration(context),
      child: Column(
        children: [
          _buildFieldsHeader(context),
          _buildFieldsList(context, availableFields, fieldConfigs, onToggleField),
        ],
      ),
    );
  }

  /// Build fields header
  static Widget _buildFieldsHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: DecorationUtils.createFieldsHeaderDecoration(context),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'All Entry Fields',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            'Tap to add/remove →',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build fields list
  static Widget _buildFieldsList(
    BuildContext context,
    List<CustomFormField> availableFields,
    Map<String, FieldConfig> fieldConfigs,
    Function(String) onToggleField,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: availableFields.map((field) {
            final config = fieldConfigs[field.id];
            final isOnPage = config != null && config.isVisible;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFieldChip(context, field, isOnPage, onToggleField),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Build individual field chip
  static Widget _buildFieldChip(
    BuildContext context,
    CustomFormField field,
    bool isOnPage,
    Function(String) onToggleField,
  ) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => onToggleField(field.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: DecorationUtils.createFieldChipDecoration(context, isOnPage),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOnPage ? Icons.check_circle : field.icon,
              size: 14,
              color: isOnPage
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              field.label,
              style: TextStyle(
                fontSize: 12,
                color: isOnPage
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isOnPage ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (isOnPage) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.close,
                size: 12,
                color: theme.colorScheme.onPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}