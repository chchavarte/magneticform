import 'package:flutter/material.dart';
import '../constants/magnetic_constants.dart';
import '../utils/magnetic_utils.dart';
import '../handlers/interaction_handler.dart';
import '../systems/magnetic_system.dart';
import '../models/field_models.dart';
import '../models/magnetic_card_system.dart';

/// Builds UI components for the customizable form
class FormUIBuilder {
  // Private constructor to prevent instantiation
  FormUIBuilder._();

  // Common UI patterns
  static const EdgeInsets _standardPadding = EdgeInsets.all(MagneticConstants.containerPadding);
  static const EdgeInsets _chipPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static const EdgeInsets _headerPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets _listPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);

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
        _buildToggleButton(context, isCustomizationMode, onToggleMode),
      ],
    );
  }

  /// Build toggle mode button
  static Widget _buildToggleButton(
    BuildContext context,
    bool isCustomizationMode,
    VoidCallback onToggleMode,
  ) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(
        isCustomizationMode ? Icons.done : Icons.tune,
        size: 24,
        color: theme.colorScheme.onSurface,
      ),
      onPressed: onToggleMode,
    );
  }

  /// Build snap guides for customization mode
  static Widget buildSnapGuides({
    required BuildContext context,
    required double containerWidth,
  }) {
    return Container(
      margin: _standardPadding,
      child: Stack(
        children: [
          ..._buildRowGuides(context),
          ..._buildColumnGuides(context, containerWidth),
        ],
      ),
    );
  }

  /// Build row guide widgets
  static List<Widget> _buildRowGuides(BuildContext context) {
    return List.generate(MagneticCardSystem.maxRows, (row) =>
      Positioned(
        left: 0,
        right: 0,
        top: row * MagneticCardSystem.cardHeight - 2,
        child: Container(
          height: MagneticCardSystem.cardHeight + MagneticConstants.snapGuideHeight,
          decoration: MagneticUtils.createSnapGuideDecoration(context),
        ),
      ),
    );
  }

  /// Build column guide widgets
  static List<Widget> _buildColumnGuides(BuildContext context, double containerWidth) {
    return List.generate(5, (index) {
      final col = index + 1;
      return Positioned(
        left: (containerWidth / 6) * col - 1,
        top: 0,
        bottom: 0,
        child: Container(
          width: MagneticConstants.snapGuideColumnWidth,
          decoration: MagneticUtils.createSnapGuideColumnDecoration(
            context,
            col % 2 == 0,
          ),
        ),
      );
    });
  }

  /// Build preview target indicator
  static Widget buildPreviewIndicator({
    required BuildContext context,
    required PreviewState previewState,
    required double containerWidth,
    required Map<String, FieldConfig> fieldConfigs,
  }) {
    if (!_shouldShowPreviewIndicator(previewState)) {
      return const SizedBox.shrink();
    }

    final targetPosition = previewState.previewInfo!.targetPosition!;
    final draggedField = fieldConfigs[previewState.draggedFieldId!]!;

    return _buildPreviewContainer(
      context,
      targetPosition,
      draggedField,
      containerWidth,
    );
  }

  /// Check if preview indicator should be shown
  static bool _shouldShowPreviewIndicator(PreviewState previewState) {
    return previewState.isActive &&
           previewState.previewInfo?.targetPosition != null &&
           previewState.previewInfo?.hasSpace == true;
  }

  /// Build preview indicator container
  static Widget _buildPreviewContainer(
    BuildContext context,
    Offset targetPosition,
    FieldConfig draggedField,
    double containerWidth,
  ) {
    final theme = Theme.of(context);
    final fieldWidth = draggedField.width * containerWidth;
    final leftPosition = targetPosition.dx * containerWidth;
    final hasLeftMargin = targetPosition.dx > 0;

    return Positioned(
      left: leftPosition,
      top: targetPosition.dy + 8,
      child: Container(
        width: fieldWidth - (hasLeftMargin ? MagneticCardSystem.fieldGap : 0),
        height: MagneticCardSystem.cardHeight,
        margin: EdgeInsets.only(
          left: hasLeftMargin ? MagneticCardSystem.fieldGap : 0,
        ),
        decoration: MagneticUtils.createFieldDecoration(
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
    return Positioned(
      top: MagneticConstants.autoResizeMessageTopOffset,
      left: MagneticConstants.autoResizeMessageHorizontalOffset,
      right: MagneticConstants.autoResizeMessageHorizontalOffset,
      child: _buildMessageContainer(context, message),
    );
  }

  /// Build message container with styling
  static Widget _buildMessageContainer(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(MagneticConstants.autoResizeMessagePadding),
      decoration: MagneticUtils.createAutoResizeMessageDecoration(context),
      child: Text(
        message,
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
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

    final fieldWidth = config.width * containerWidth;
    final leftPosition = config.position.dx * containerWidth;

    return Positioned(
      left: leftPosition,
      top: config.position.dy + 8,
      child: Stack(
        children: [
          _buildFieldContainer(
            context,
            fieldId,
            field,
            config,
            fieldWidth,
            isCustomizationMode,
            isDragged,
            isInPreview,
            isSelected,
            onTap,
            onLongPressStart,
            onLongPressMoveUpdate,
            onLongPressEnd,
          ),
          ..._buildResizeHandles(
            context,
            fieldId,
            isCustomizationMode,
            isSelected,
            onResize,
            onResizeStart,
            onResizeEnd,
          ),
        ],
      ),
    );
  }

  /// Build field container with gestures
  static Widget _buildFieldContainer(
    BuildContext context,
    String fieldId,
    Widget field,
    FieldConfig config,
    double fieldWidth,
    bool isCustomizationMode,
    bool isDragged,
    bool isInPreview,
    bool isSelected,
    Function(String) onTap,
    Function(String, LongPressStartDetails) onLongPressStart,
    Function(String, LongPressMoveUpdateDetails) onLongPressMoveUpdate,
    Function(String, LongPressEndDetails) onLongPressEnd,
  ) {
    final hasLeftMargin = config.position.dx > 0;
    
    return GestureDetector(
      onTap: isCustomizationMode ? () => onTap(fieldId) : null,
      onLongPressStart: isCustomizationMode ? (details) => onLongPressStart(fieldId, details) : null,
      onLongPressMoveUpdate: isCustomizationMode ? (details) => onLongPressMoveUpdate(fieldId, details) : null,
      onLongPressEnd: isCustomizationMode ? (details) => onLongPressEnd(fieldId, details) : null,
      behavior: HitTestBehavior.opaque,
      child: AbsorbPointer(
        absorbing: isCustomizationMode,
        child: Container(
          width: fieldWidth - (hasLeftMargin ? MagneticCardSystem.fieldGap : 0),
          margin: EdgeInsets.only(
            left: hasLeftMargin ? MagneticCardSystem.fieldGap : 0,
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
    );
  }

  /// Build resize handles if needed
  static List<Widget> _buildResizeHandles(
    BuildContext context,
    String fieldId,
    bool isCustomizationMode,
    bool isSelected,
    Function(String, DragUpdateDetails, ResizeDirection) onResize,
    Function(String, ResizeDirection) onResizeStart,
    Function(String, ResizeDirection) onResizeEnd,
  ) {
    if (!isCustomizationMode || !isSelected) {
      return [];
    }

    final theme = Theme.of(context);
    return [
      InteractionHandler.buildResizeHandle(
        context: context,
        direction: ResizeDirection.left,
        fieldId: fieldId,
        theme: theme,
        onResize: onResize,
        onResizeStart: onResizeStart,
        onResizeEnd: onResizeEnd,
      ),
      InteractionHandler.buildResizeHandle(
        context: context,
        direction: ResizeDirection.right,
        fieldId: fieldId,
        theme: theme,
        onResize: onResize,
        onResizeStart: onResizeStart,
        onResizeEnd: onResizeEnd,
      ),
    ];
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
      return MagneticUtils.createFieldDecoration(
        context: context,
        state: FieldDecorationState.dragged,
      );
    } else if (isInPreview) {
      return MagneticUtils.createFieldDecoration(
        context: context,
        state: FieldDecorationState.preview,
      );
    } else if (isCustomizationMode && isSelected) {
      return MagneticUtils.createFieldDecoration(
        context: context,
        state: FieldDecorationState.selected,
      );
    } else if (isCustomizationMode) {
      return MagneticUtils.createFieldDecoration(
        context: context,
        state: FieldDecorationState.customization,
      );
    }

    return null;
  }

  /// Build additional fields container
  static Widget buildAdditionalFieldsContainer({
    required BuildContext context,
    required List<MagneticFormField> availableFields,
    required Map<String, FieldConfig> fieldConfigs,
    required Function(String) onToggleField,
  }) {
    return Container(
      height: 100,
      decoration: MagneticUtils.createAdditionalFieldsContainerDecoration(context),
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
      padding: _headerPadding,
      decoration: MagneticUtils.createFieldsHeaderDecoration(context),
      child: Row(
        children: [
          _buildHeaderIcon(theme),
          const SizedBox(width: 8),
          _buildHeaderTitle(theme),
          const Spacer(),
          _buildHeaderHint(theme),
        ],
      ),
    );
  }

  /// Build header icon
  static Widget _buildHeaderIcon(ThemeData theme) {
    return Icon(
      Icons.tune,
      size: 16,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// Build header title
  static Widget _buildHeaderTitle(ThemeData theme) {
    return Text(
      'All Entry Fields',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Build header hint
  static Widget _buildHeaderHint(ThemeData theme) {
    return Text(
      'Tap to add/remove →',
      style: TextStyle(
        fontSize: 12,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Build fields list
  static Widget _buildFieldsList(
    BuildContext context,
    List<MagneticFormField> availableFields,
    Map<String, FieldConfig> fieldConfigs,
    Function(String) onToggleField,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: _listPadding,
        child: Row(
          children: _buildFieldChips(context, availableFields, fieldConfigs, onToggleField),
        ),
      ),
    );
  }

  /// Build field chips list
  static List<Widget> _buildFieldChips(
    BuildContext context,
    List<MagneticFormField> availableFields,
    Map<String, FieldConfig> fieldConfigs,
    Function(String) onToggleField,
  ) {
    return availableFields.map((field) {
      final config = fieldConfigs[field.id];
      final isOnPage = config != null && config.isVisible;
      
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _buildFieldChip(context, field, isOnPage, onToggleField),
      );
    }).toList();
  }

  /// Build individual field chip
  static Widget _buildFieldChip(
    BuildContext context,
    MagneticFormField field,
    bool isOnPage,
    Function(String) onToggleField,
  ) {
    return GestureDetector(
      onTap: () => onToggleField(field.id),
      child: Container(
        padding: _chipPadding,
        decoration: MagneticUtils.createFieldChipDecoration(context, isOnPage),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildChipContent(context, field, isOnPage),
        ),
      ),
    );
  }

  /// Build chip content elements
  static List<Widget> _buildChipContent(
    BuildContext context,
    MagneticFormField field,
    bool isOnPage,
  ) {
    final theme = Theme.of(context);
    final iconColor = isOnPage ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant;
    final textColor = isOnPage ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant;

    return [
      Icon(
        isOnPage ? Icons.check_circle : field.icon,
        size: 14,
        color: iconColor,
      ),
      const SizedBox(width: 4),
      Text(
        field.label,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
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
    ];
  }
}