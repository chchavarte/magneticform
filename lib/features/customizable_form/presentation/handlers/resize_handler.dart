import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:field_collision_test/core/constants/field_constants.dart';
import 'package:field_collision_test/core/utils/logger.dart';
import 'package:field_collision_test/core/utils/decoration_utils.dart';
import '../systems/field_animations.dart';
import '../systems/grid_utils.dart';
import '../../data/models/field_config.dart';
import '../../data/models/magnetic_card_system.dart';

// Field resize handler - manages all drag-to-resize functionality
class FieldResizeHandler {
  static const double _accumulationThreshold = FieldConstants.accumulationThreshold;

  // Store original configs before resize starts
  static final Map<String, FieldConfig> _originalConfigs = {};

  // Handle resize drag start
  static void handleResizeStart({
    required String fieldId,
    required Map<String, FieldConfig> fieldConfigs,
  }) {
    _originalConfigs[fieldId] = fieldConfigs[fieldId]!;
  }

  // Handle resize drag updates
  static void handleResize({
    required String fieldId,
    required DragUpdateDetails details,
    required ResizeDirection direction,
    required Map<String, FieldConfig> fieldConfigs,
    required double containerWidth,
    required double accumulatedDrag,
    required Function(String, FieldConfig) onFieldUpdate,
    required Function(double) onAccumulatedDragUpdate,
    required VoidCallback onSave,
    required TickerProvider vsync,
  }) {
    final config = fieldConfigs[fieldId];
    if (config == null) return;

    // Update accumulated drag
    final newAccumulatedDrag = accumulatedDrag + (details.primaryDelta ?? 0);
    onAccumulatedDragUpdate(newAccumulatedDrag);

    // Check if we've moved enough to trigger a resize
    if (newAccumulatedDrag.abs() < containerWidth * _accumulationThreshold) {
      return;
    }

    // Calculate new dimensions (allowing temporary visual expansion)
    final visualResult = _calculateNewDimensions(
      config: config,
      direction: direction,
      accumulatedDrag: newAccumulatedDrag,
      containerWidth: containerWidth,
      fieldConfigs: fieldConfigs,
      fieldId: fieldId,
      allowOverlap: true, // Allow visual expansion during drag
    );

    if (visualResult != null) {
      // Apply visual resize immediately (may overlap temporarily)
      onFieldUpdate(fieldId, visualResult);
      onAccumulatedDragUpdate(0); // Reset accumulation
      HapticFeedback.mediumImpact();
    }
  }

  // Calculate new width and position based on resize direction
  static FieldConfig? _calculateNewDimensions({
    required FieldConfig config,
    required ResizeDirection direction,
    required double accumulatedDrag,
    required double containerWidth,
    required Map<String, FieldConfig> fieldConfigs,
    required String fieldId,
    bool allowOverlap = false,
  }) {
    final currentIndex = MagneticCardSystem.cardWidths.indexOf(config.width);
    if (currentIndex == -1) return null;

    double newWidth = config.width;
    double newX = config.position.dx;

    if (direction == ResizeDirection.right) {
      // Right resize: Only change width
      newWidth = _calculateRightResize(
        currentIndex: currentIndex,
        accumulatedDrag: accumulatedDrag,
        currentWidth: config.width,
        position: config.position,
        containerWidth: containerWidth,
      );
    } else {
      // Left resize: Change both width and position
      final leftResizeResult = _calculateLeftResize(
        currentIndex: currentIndex,
        accumulatedDrag: accumulatedDrag,
        currentWidth: config.width,
        currentX: config.position.dx,
        containerWidth: containerWidth,
      );
      newWidth = leftResizeResult.width;
      newX = leftResizeResult.x;
    }

    // Only return new config if something changed
    if (newWidth != config.width || newX != config.position.dx) {
      final newConfig = config.copyWith(
        width: newWidth,
        position: Offset(newX, config.position.dy),
      );

      // Check if new dimensions would cause overlap
      if (!allowOverlap) {
        final wouldOverlap = GridUtils.wouldFieldOverlap(
          newConfig,
          fieldConfigs,
          fieldId,
          containerWidth,
        );

        // Only allow resize if no overlap
        if (wouldOverlap) return null;
      }

      return newConfig;
    }

    return null;
  }

  // Calculate new width for right resize
  static double _calculateRightResize({
    required int currentIndex,
    required double accumulatedDrag,
    required double currentWidth,
    required Offset position,
    required double containerWidth,
  }) {
    if (accumulatedDrag > 0 &&
        currentIndex < MagneticCardSystem.cardWidths.length - 1) {
      // Expanding right
      final candidateWidth = MagneticCardSystem.cardWidths[currentIndex + 1];
      final resizeInfo = MagneticCardSystem.getResizeInfo(
        position,
        candidateWidth,
        containerWidth,
      );
      return resizeInfo.actualWidth;
    } else if (accumulatedDrag < 0 && currentIndex > 0) {
      // Shrinking right
      return MagneticCardSystem.cardWidths[currentIndex - 1];
    }

    return currentWidth;
  }

  // Calculate new width and position for left resize
  static ({double width, double x}) _calculateLeftResize({
    required int currentIndex,
    required double accumulatedDrag,
    required double currentWidth,
    required double currentX,
    required double containerWidth,
  }) {
    final rightEdge = currentX + currentWidth; // Fixed anchor point
    
    if (accumulatedDrag < 0 &&
        currentIndex < MagneticCardSystem.cardWidths.length - 1) {
      // Expanding left - keep right edge fixed
      final newWidth = MagneticCardSystem.cardWidths[currentIndex + 1];
      final newX = (rightEdge - newWidth).clamp(0.0, 1.0);
      return (width: newWidth, x: newX);
    } else if (accumulatedDrag > 0 && currentIndex > 0) {
      // Shrinking from left - keep right edge fixed  
      final newWidth = MagneticCardSystem.cardWidths[currentIndex - 1];
      final newX = rightEdge - newWidth;
      return (width: newWidth, x: newX);
    }

    return (width: currentWidth, x: currentX);
  }

  // Handle resize drag end with snap-back animation
  static void handleResizeEnd({
    required String fieldId,
    required Map<String, FieldConfig> fieldConfigs,
    required double containerWidth,
    required Function(String, FieldConfig) onFieldUpdate,
    required VoidCallback onSave,
    required TickerProvider vsync,
    required ResizeDirection direction, // Add this parameter
  }) {
    Logger.resize('Called for field $fieldId');
    final currentConfig = fieldConfigs[fieldId];
    if (currentConfig == null) return;

    Logger.resize('Current config - width: ${currentConfig.width}, position: ${currentConfig.position}');

    // Check if current position would cause overlap
    final wouldOverlap = GridUtils.wouldFieldOverlap(
      currentConfig,
      fieldConfigs,
      fieldId,
      containerWidth,
    );

    Logger.resize('Would overlap: $wouldOverlap');

    if (wouldOverlap) {
      // Find the last valid configuration
      final validConfig = _findLastValidConfig(
        currentConfig: currentConfig,
        fieldConfigs: fieldConfigs,
        containerWidth: containerWidth,
        fieldId: fieldId,
        direction: direction, // Pass direction
      );

      Logger.resize('Valid config found: ${validConfig?.width}, ${validConfig?.position}');

      if (validConfig != null && validConfig != currentConfig) {
        Logger.resize('Starting snap-back animation');
        // Animate snap-back to valid configuration
        FieldAnimations.animateFieldConfig(
          vsync: vsync,
          fieldId: fieldId,
          fromConfig: currentConfig,
          toConfig: validConfig,
          onConfigUpdate: onFieldUpdate,
          onComplete: onSave,
        );
        return;
      }
    }

    Logger.resize('No snap-back needed, just saving');
    // No snap-back needed, just save
    onSave();
  }

  // Find the last valid configuration for a field
  static FieldConfig? _findLastValidConfig({
    required FieldConfig currentConfig,
    required Map<String, FieldConfig> fieldConfigs,
    required double containerWidth,
    required String fieldId,
    ResizeDirection? direction, // Add this parameter
  }) {
    // For left resize, keep right edge fixed; for right resize, keep left edge fixed
    final rightEdge = direction == ResizeDirection.left 
        ? currentConfig.position.dx + currentConfig.width
        : null;
    
    final currentIndex = MagneticCardSystem.cardWidths.indexOf(
      currentConfig.width,
    );

    for (int i = currentIndex - 1; i >= 0; i--) {
      final testWidth = MagneticCardSystem.cardWidths[i];
      
      // Calculate position based on resize direction
      final testX = direction == ResizeDirection.left 
          ? rightEdge! - testWidth  // Keep right edge fixed
          : currentConfig.position.dx; // Keep left edge fixed
      
      final testConfig = currentConfig.copyWith(
        width: testWidth,
        position: Offset(testX, currentConfig.position.dy),
      );

      final wouldOverlap = GridUtils.wouldFieldOverlap(
        testConfig,
        fieldConfigs,
        fieldId,
        containerWidth,
      );

      if (!wouldOverlap) {
        Logger.resize('Found valid width $testWidth at current position');
        return testConfig;
      }
    }

    // If no valid width found, revert to original config
    Logger.resize('No valid width found, reverting to original config');
    final originalConfig = _originalConfigs[fieldId];
    if (originalConfig != null) {
      return originalConfig;
    }

    // Fallback: return current config (shouldn't happen)
    return currentConfig;
  }

  // Build resize handle widget
  static Widget buildResizeHandle({
    required BuildContext context,
    required ResizeDirection direction,
    required String fieldId,
    required ThemeData theme,
    required Function(String, DragUpdateDetails, ResizeDirection) onResize,
    Function(String, ResizeDirection)? onResizeStart,
    Function(String, ResizeDirection)? onResizeEnd,
  }) {
    final isLeft = direction == ResizeDirection.left;

    return Positioned(
      left: isLeft ? -12 : null,
      right: isLeft ? null : -12,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onHorizontalDragStart:
            onResizeStart != null
                ? (details) => onResizeStart(fieldId, direction)
                : null,
        onHorizontalDragUpdate:
            (details) => onResize(fieldId, details, direction),
        onHorizontalDragEnd:
            onResizeEnd != null
                ? (details) => onResizeEnd(fieldId, direction)
                : null,
        child: Container(
          width: FieldConstants.resizeHandleWidth,
          decoration: DecorationUtils.createResizeHandleDecoration(
            context,
            isLeft,
          ),
          child: Center(
            child: Container(
              width: 12,
              height: FieldConstants.resizeHandleHeight,
              decoration: DecorationUtils.createResizeHandleInnerDecoration(context),
              child: Icon(
                Icons.drag_indicator,
                size: FieldConstants.resizeHandleIconSize,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}