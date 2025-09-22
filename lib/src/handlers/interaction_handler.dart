import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/magnetic_constants.dart';
import '../utils/magnetic_utils.dart';
import '../systems/magnetic_system.dart';
import '../models/field_models.dart';
import '../models/magnetic_card_system.dart';

/// Consolidated handler for all field interactions including drag, resize, and auto-expand operations.
///
/// This class merges the functionality from DragHandler, ResizeHandler, and AutoExpandHandler
/// into a single, cohesive interface while preserving all existing behaviors and functionality.
///
/// ## Interaction Types
///
/// - **Drag Operations**: Long-press drag and drop with magnetic snapping
/// - **Resize Operations**: Edge-based resizing with collision detection
/// - **Auto-Expand Operations**: Intelligent field expansion to fill gaps
///
/// ## Usage
///
/// ```dart
/// // Start drag operation
/// final dragState = InteractionHandler.startFieldDrag(
///   fieldId: 'email',
///   details: longPressDetails,
///   fieldConfigs: currentConfigs,
/// );
///
/// // Handle resize
/// InteractionHandler.handleResize(
///   fieldId: 'name',
///   details: dragDetails,
///   direction: ResizeDirection.right,
///   // ... other parameters
/// );
///
/// // Auto-expand fields
/// InteractionHandler.autoExpandToFillGaps(
///   fieldConfigs: currentConfigs,
///   vsync: this,
///   onUpdate: updateConfigs,
///   onComplete: saveConfigs,
/// );
/// ```
class InteractionHandler {
  // Private constructor to prevent instantiation
  InteractionHandler._();

  // ============================================================================
  // DRAG OPERATIONS (from DragHandler)
  // ============================================================================

  /// Handle field drag start
  static DragState startFieldDrag({
    required String fieldId,
    required LongPressStartDetails details,
    required Map<String, FieldConfig> fieldConfigs,
  }) {
    HapticFeedback.mediumImpact();
    final config = fieldConfigs[fieldId]!;

    MagneticUtils.preview('Starting drag for field $fieldId');

    return DragState(
      draggedFieldId: fieldId,
      dragStartPosition: details.globalPosition,
      dragStartFieldPosition: config.position,
      hasMovedBeyondThreshold: false,
      originalPositions: Map.fromEntries(
        fieldConfigs.entries.map((e) => MapEntry(e.key, e.value.position)),
      ),
    );
  }

  /// Handle field drag movement
  static DragUpdateResult handleFieldDrag({
    required String fieldId,
    required LongPressMoveUpdateDetails details,
    required DragState dragState,
    required Map<String, FieldConfig> fieldConfigs,
    required double containerWidth,
  }) {
    final config = fieldConfigs[fieldId]!;

    // Calculate distance moved from start position
    final distanceMoved =
        (details.globalPosition - dragState.dragStartPosition).distance;

    // Check if we've moved beyond the threshold
    bool hasMovedBeyondThreshold = dragState.hasMovedBeyondThreshold;
    if (!hasMovedBeyondThreshold &&
        distanceMoved > MagneticConstants.hoverThreshold) {
      hasMovedBeyondThreshold = true;
    }

    // Calculate delta from start position
    final deltaX =
        (details.globalPosition.dx - dragState.dragStartPosition.dx) /
        containerWidth;
    final deltaY = details.globalPosition.dy - dragState.dragStartPosition.dy;

    // Calculate new position for visual feedback
    final newX = (dragState.dragStartFieldPosition.dx + deltaX).clamp(
      0.0,
      1.0 - config.width,
    );
    final newY = (dragState.dragStartFieldPosition.dy + deltaY).clamp(
      0.0,
      MagneticCardSystem.maxRows * MagneticCardSystem.cardHeight,
    );

    final newPosition = Offset(newX, newY);

    // Get hovered grid position
    final gridPosition = MagneticCardSystem.getGridPosition(
      newPosition,
      containerWidth,
    );

    return DragUpdateResult(
      newPosition: newPosition,
      hoveredColumn: gridPosition.column,
      hoveredRow: gridPosition.row,
      hasMovedBeyondThreshold: hasMovedBeyondThreshold,
      shouldShowPreview: hasMovedBeyondThreshold,
    );
  }

  /// Handle field drag end
  static DragEndResult handleFieldDragEnd({
    required String fieldId,
    required Map<String, FieldConfig> fieldConfigs,
    required double containerWidth,
    required PreviewState previewState,
  }) {
    MagneticUtils.preview('Ending drag for field $fieldId');

    if (previewState.isActive && previewState.previewInfo?.hasSpace == true) {
      return DragEndResult(
        shouldCommitPreview: true,
        finalPosition: previewState.previewInfo!.targetPosition!,
        finalConfigs: previewState.previewConfigs,
      );
    } else {
      // Standard snap logic
      final config = fieldConfigs[fieldId]!;
      final snappedPosition = MagneticCardSystem.getMagneticSnapPosition(
        config.position,
        containerWidth,
      );

      // Check for overlap
      final testConfig = config.copyWith(position: snappedPosition);
      final wouldOverlap = MagneticSystem.wouldFieldOverlap(
        testConfig,
        fieldConfigs,
        fieldId,
        containerWidth,
      );

      final finalPosition =
          wouldOverlap
              ? MagneticCardSystem.findNextAvailablePosition(
                config.width,
                containerWidth,
                fieldConfigs,
                fieldId,
              )
              : snappedPosition;

      return DragEndResult(
        shouldCommitPreview: false,
        finalPosition: finalPosition,
        finalConfigs: {fieldId: config.copyWith(position: finalPosition)},
      );
    }
  }

  // ============================================================================
  // RESIZE OPERATIONS (from ResizeHandler)
  // ============================================================================

  static const double _accumulationThreshold =
      MagneticConstants.accumulationThreshold;

  // Store original configs before resize starts
  static final Map<String, FieldConfig> _originalConfigs = {};

  /// Handle resize drag start
  static void handleResizeStart({
    required String fieldId,
    required Map<String, FieldConfig> fieldConfigs,
  }) {
    _originalConfigs[fieldId] = fieldConfigs[fieldId]!;
  }

  /// Handle resize drag updates
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
    print('🎯 DEBUG HANDLE RESIZE:');
    print('  fieldId: $fieldId');
    print('  direction: $direction');
    print('  primaryDelta: ${details.primaryDelta}');
    print('  accumulatedDrag: $accumulatedDrag');

    final config = fieldConfigs[fieldId];
    if (config == null) {
      print('  ❌ Config not found for field $fieldId');
      return;
    }

    print(
      '  Current config: position=${config.position}, width=${config.width}',
    );

    // Update accumulated drag
    final newAccumulatedDrag = accumulatedDrag + (details.primaryDelta ?? 0);
    print('  New accumulated drag: $newAccumulatedDrag');
    onAccumulatedDragUpdate(newAccumulatedDrag);

    // Check if we've moved enough to trigger a resize
    final threshold = containerWidth * _accumulationThreshold;
    print(
      '  Threshold: $threshold (${_accumulationThreshold} * $containerWidth)',
    );
    print('  Abs accumulated drag: ${newAccumulatedDrag.abs()}');

    if (newAccumulatedDrag.abs() < threshold) {
      print('  ⚪ Below threshold, no resize triggered');
      return;
    }

    print('  ✅ Above threshold, calculating new dimensions...');

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
      print('  ✅ Visual result obtained, applying update');
      // Apply visual resize immediately (may overlap temporarily)
      onFieldUpdate(fieldId, visualResult);
      onAccumulatedDragUpdate(0); // Reset accumulation
      HapticFeedback.mediumImpact();
    } else {
      print('  ❌ No visual result, resize blocked');
    }
  }

  /// Handle resize drag end with snap-back animation
  static void handleResizeEnd({
    required String fieldId,
    required Map<String, FieldConfig> fieldConfigs,
    required double containerWidth,
    required Function(String, FieldConfig) onFieldUpdate,
    required VoidCallback onSave,
    required TickerProvider vsync,
  }) {
    print('🎯 DEBUG RESIZE END for field $fieldId');
    final currentConfig = fieldConfigs[fieldId];
    if (currentConfig == null) return;

    print('  Current config - width: ${currentConfig.width}, position: ${currentConfig.position}');

    // First, try to find a magnetic snap position to adjacent fields
    final magneticConfig = _findMagneticSnapPosition(
      currentConfig: currentConfig,
      fieldConfigs: fieldConfigs,
      containerWidth: containerWidth,
      fieldId: fieldId,
    );

    if (magneticConfig != null && magneticConfig != currentConfig) {
      print('  🧲 Magnetic snap found, animating to: ${magneticConfig.position}, width=${magneticConfig.width}');
      MagneticSystem.animateFieldConfig(
        vsync: vsync,
        fieldId: fieldId,
        fromConfig: currentConfig,
        toConfig: magneticConfig,
        onConfigUpdate: onFieldUpdate,
        onComplete: onSave,
      );
      return;
    }

    // Check if current position would cause overlap
    final wouldOverlap = MagneticSystem.wouldFieldOverlap(
      currentConfig,
      fieldConfigs,
      fieldId,
      containerWidth,
    );

    print('  Would overlap: $wouldOverlap');

    if (wouldOverlap) {
      // Find the last valid configuration
      final validConfig = _findLastValidConfig(
        currentConfig: currentConfig,
        fieldConfigs: fieldConfigs,
        containerWidth: containerWidth,
        fieldId: fieldId,
      );

      print('  Valid config found: ${validConfig?.width}, ${validConfig?.position}');

      if (validConfig != null && validConfig != currentConfig) {
        print('  Starting snap-back animation');
        MagneticSystem.animateFieldConfig(
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

    print('  No snap-back needed, just saving');
    onSave();
  }

  /// Find magnetic snap position to adjacent field boundaries
  static FieldConfig? _findMagneticSnapPosition({
    required FieldConfig currentConfig,
    required Map<String, FieldConfig> fieldConfigs,
    required double containerWidth,
    required String fieldId,
  }) {
    final currentRow = FieldConfig.getRowFromPosition(currentConfig.position.dy);
    
    // Find all fields in the same row
    final fieldsInSameRow = <FieldConfig>[];
    for (final entry in fieldConfigs.entries) {
      if (entry.key == fieldId) continue;
      final config = entry.value;
      if (!config.isVisible) continue;
      
      final fieldRow = FieldConfig.getRowFromPosition(config.position.dy);
      if (fieldRow == currentRow) {
        fieldsInSameRow.add(config);
      }
    }
    
    // Sort fields by position for easier boundary detection
    fieldsInSameRow.sort((a, b) => a.position.dx.compareTo(b.position.dx));
    
    // Try to snap to adjacent field boundaries
    for (final adjacentConfig in fieldsInSameRow) {
      final adjacentStart = adjacentConfig.position.dx;
      final adjacentEnd = adjacentConfig.position.dx + adjacentConfig.width;
      
      // Check if current field should snap to start right after the adjacent field
      final snapToRightBoundary = adjacentEnd;
      final distanceToRightBoundary = (currentConfig.position.dx - snapToRightBoundary).abs();
      
      // Check if current field should snap to start right before the adjacent field
      final snapToLeftBoundary = adjacentStart - currentConfig.width;
      final distanceToLeftBoundary = (currentConfig.position.dx - snapToLeftBoundary).abs();
      
      const snapThreshold = 0.15; // 15% threshold for snapping
      
      // Try snapping to right boundary (field starts after adjacent field ends)
      if (distanceToRightBoundary < snapThreshold) {
        final availableWidth = 1.0 - snapToRightBoundary;
        
        // Find the best fitting width
        for (final candidateWidth in MagneticCardSystem.cardWidths.reversed) {
          if (candidateWidth <= availableWidth) {
            final testConfig = currentConfig.copyWith(
              position: Offset(snapToRightBoundary, currentConfig.position.dy),
              width: candidateWidth,
            );
            
            if (!MagneticSystem.wouldFieldOverlap(testConfig, fieldConfigs, fieldId, containerWidth)) {
              return testConfig;
            }
          }
        }
      }
      
      // Try snapping to left boundary (field ends before adjacent field starts)
      if (distanceToLeftBoundary < snapThreshold && snapToLeftBoundary >= 0) {
        final testConfig = currentConfig.copyWith(
          position: Offset(snapToLeftBoundary, currentConfig.position.dy),
        );
        
        if (!MagneticSystem.wouldFieldOverlap(testConfig, fieldConfigs, fieldId, containerWidth)) {
          return testConfig;
        }
      }
    }
    
    return null;
  }

  /// Build resize handle widget
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
          width: MagneticConstants.resizeHandleWidth,
          decoration: MagneticUtils.createResizeHandleDecoration(
            context,
            isLeft,
          ),
          child: Center(
            child: Container(
              width: 12,
              height: MagneticConstants.resizeHandleHeight,
              decoration: MagneticUtils.createResizeHandleInnerDecoration(
                context,
              ),
              child: Icon(
                Icons.drag_indicator,
                size: MagneticConstants.resizeHandleIconSize,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // AUTO-EXPAND OPERATIONS (from AutoExpandHandler)
  // ============================================================================

  /// Auto-expand fields to fill remaining gaps after drag operations
  static void autoExpandToFillGaps({
    required Map<String, FieldConfig> fieldConfigs,
    required TickerProvider vsync,
    required Function(Map<String, FieldConfig>) onUpdate,
    required VoidCallback onComplete,
  }) {
    MagneticUtils.autoExpand('Starting auto-expand to fill gaps');

    // Find all rows that have fields using utility method
    final fieldsByRow = MagneticSystem.groupFieldsByRow(fieldConfigs);

    Map<String, FieldConfig> expandedConfigs = {};
    bool hasExpansions = false;

    // Check each row for gaps and expand fields
    for (final entry in fieldsByRow.entries) {
      final row = entry.key;
      final fieldsInRow = entry.value;

      MagneticUtils.autoExpand(
        'Checking row $row with ${fieldsInRow.length} fields',
      );

      // Calculate available space in this row using utility method
      final availableSpace = MagneticSystem.calculateRowAvailableSpace(
        row,
        fieldConfigs,
      );

      MagneticUtils.autoExpand(
        'Available space: ${(availableSpace * 100).toInt()}%',
      );

      if (availableSpace > MagneticConstants.significantGapThreshold) {
        // If there's significant space
        final expansionStrategy = _findBestExpansionStrategy(
          row,
          fieldsInRow,
          availableSpace,
          fieldConfigs,
        );

        if (expansionStrategy != null) {
          _applyExpansionStrategy(
            expansionStrategy,
            row,
            fieldsInRow,
            fieldConfigs,
            expandedConfigs,
          );
          hasExpansions = true;
        }
      }
    }

    // Apply expansions with animation
    if (hasExpansions) {
      MagneticUtils.autoExpand(
        'Applying ${expandedConfigs.length} field expansions',
      );

      // Create final configs with expansions
      final finalConfigs = Map<String, FieldConfig>.from(fieldConfigs);
      for (final entry in expandedConfigs.entries) {
        finalConfigs[entry.key] = entry.value;
      }

      // Animate the expansions
      MagneticSystem.animateToCommit(
        vsync: vsync,
        fromConfigs: fieldConfigs,
        toConfigs: finalConfigs,
        onUpdate: onUpdate,
        onComplete: () {
          MagneticUtils.autoExpand('Auto-expansion complete');
          onComplete();
        },
      );
    } else {
      MagneticUtils.autoExpand('No gaps found to fill');
      onComplete();
    }
  }

  // ============================================================================
  // SHARED UTILITIES (extracted from handlers)
  // ============================================================================

  /// Calculate new dimensions based on resize direction
  static FieldConfig? _calculateNewDimensions({
    required FieldConfig config,
    required ResizeDirection direction,
    required double accumulatedDrag,
    required double containerWidth,
    required Map<String, FieldConfig> fieldConfigs,
    required String fieldId,
    bool allowOverlap = false,
  }) {
    print('🎯 DEBUG CALCULATE NEW DIMENSIONS:');
    print('  fieldId: $fieldId');
    print('  direction: $direction');
    print(
      '  current config: position=${config.position}, width=${config.width}',
    );
    print('  allowOverlap: $allowOverlap');

    final currentIndex = MagneticCardSystem.cardWidths.indexOf(config.width);
    print('  currentIndex in cardWidths: $currentIndex');
    if (currentIndex == -1) {
      print('  ❌ Current width ${config.width} not found in cardWidths');
      return null;
    }

    double newWidth = config.width;
    double newX = config.position.dx;

    if (direction == ResizeDirection.right) {
      print('  → Processing RIGHT resize');
      // Right resize: Only change width
      newWidth = _calculateRightResize(
        currentIndex: currentIndex,
        accumulatedDrag: accumulatedDrag,
        currentWidth: config.width,
        position: config.position,
        containerWidth: containerWidth,
      );
    } else {
      print('  → Processing LEFT resize');
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

    print('  After resize calculation: newWidth=$newWidth, newX=$newX');

    // Only return new config if something changed
    if (newWidth != config.width || newX != config.position.dx) {
      final newConfig = config.copyWith(
        width: newWidth,
        position: Offset(newX, config.position.dy),
      );
      print(
        '  ✅ Dimensions changed, creating new config: ${newConfig.position}, width=${newConfig.width}',
      );

      // Check if new dimensions would cause overlap
      if (!allowOverlap) {
        print('  🔍 Checking for overlap...');
        final wouldOverlap = MagneticSystem.wouldFieldOverlap(
          newConfig,
          fieldConfigs,
          fieldId,
          containerWidth,
        );
        print('  Overlap result: $wouldOverlap');

        // Only allow resize if no overlap
        if (wouldOverlap) {
          print('  ❌ BLOCKED: Overlap detected, returning null');
          return null;
        }
      }

      print('  ✅ SUCCESS: Returning new config');
      return newConfig;
    }

    print('  ⚪ NO CHANGE: Dimensions unchanged');
    return null;
  }

  /// Unified resize calculation for both left and right handles
  static ({double width, double x}) _calculateUnifiedResize({
    required ResizeDirection direction,
    required int currentIndex,
    required double accumulatedDrag,
    required double currentWidth,
    required double currentX,
    required double containerWidth,
  }) {
    // Determine if we're expanding or shrinking
    final isExpanding = (direction == ResizeDirection.right && accumulatedDrag > 0) ||
                       (direction == ResizeDirection.left && accumulatedDrag < 0);
    final isShrinking = (direction == ResizeDirection.right && accumulatedDrag < 0) ||
                       (direction == ResizeDirection.left && accumulatedDrag > 0);

    if (isExpanding && currentIndex < MagneticCardSystem.cardWidths.length - 1) {
      // Expanding - get next larger width
      final candidateWidth = MagneticCardSystem.cardWidths[currentIndex + 1];
      
      // Calculate new position based on direction
      final newX = _calculateNewPosition(
        direction: direction,
        currentX: currentX,
        currentWidth: currentWidth,
        newWidth: candidateWidth,
      );
      
      // Use getResizeInfo to ensure proper grid alignment
      final resizeInfo = MagneticCardSystem.getResizeInfo(
        Offset(newX, 0),
        candidateWidth,
        containerWidth,
      );
      
      return (width: resizeInfo.actualWidth, x: newX);
    } else if (isShrinking && currentIndex > 0) {
      // Shrinking - get next smaller width
      final candidateWidth = MagneticCardSystem.cardWidths[currentIndex - 1];
      
      // Calculate new position based on direction
      final newX = _calculateNewPosition(
        direction: direction,
        currentX: currentX,
        currentWidth: currentWidth,
        newWidth: candidateWidth,
      );
      
      return (width: candidateWidth, x: newX);
    }

    return (width: currentWidth, x: currentX);
  }

  /// Calculate new position based on resize direction and anchor point
  static double _calculateNewPosition({
    required ResizeDirection direction,
    required double currentX,
    required double currentWidth,
    required double newWidth,
  }) {
    if (direction == ResizeDirection.right) {
      // Right resize: left edge stays fixed
      return currentX;
    } else {
      // Left resize: right edge stays fixed
      final rightEdge = currentX + currentWidth;
      final newX = rightEdge - newWidth;
      return newX.clamp(0.0, 1.0 - newWidth);
    }
  }

  /// Calculate new width for right resize (wrapper for unified logic)
  static double _calculateRightResize({
    required int currentIndex,
    required double accumulatedDrag,
    required double currentWidth,
    required Offset position,
    required double containerWidth,
  }) {
    final result = _calculateUnifiedResize(
      direction: ResizeDirection.right,
      currentIndex: currentIndex,
      accumulatedDrag: accumulatedDrag,
      currentWidth: currentWidth,
      currentX: position.dx,
      containerWidth: containerWidth,
    );
    return result.width;
  }

  /// Calculate new width and position for left resize (wrapper for unified logic)
  static ({double width, double x}) _calculateLeftResize({
    required int currentIndex,
    required double accumulatedDrag,
    required double currentWidth,
    required double currentX,
    required double containerWidth,
  }) {
    return _calculateUnifiedResize(
      direction: ResizeDirection.left,
      currentIndex: currentIndex,
      accumulatedDrag: accumulatedDrag,
      currentWidth: currentWidth,
      currentX: currentX,
      containerWidth: containerWidth,
    );
  }

  /// Find the last valid configuration for a field using unified logic
  static FieldConfig? _findLastValidConfig({
    required FieldConfig currentConfig,
    required Map<String, FieldConfig> fieldConfigs,
    required double containerWidth,
    required String fieldId,
  }) {
    // First, try to find the best fit using the same logic as magnetic snapping
    final bestFitConfig = _findBestFitConfiguration(
      currentConfig: currentConfig,
      fieldConfigs: fieldConfigs,
      containerWidth: containerWidth,
      fieldId: fieldId,
    );
    
    if (bestFitConfig != null) {
      return bestFitConfig;
    }

    // If no best fit found, revert to original config
    final originalConfig = _originalConfigs[fieldId];
    if (originalConfig != null) {
      return originalConfig;
    }

    // Fallback: return current config
    return currentConfig;
  }

  /// Find the best fit configuration using unified resize logic
  static FieldConfig? _findBestFitConfiguration({
    required FieldConfig currentConfig,
    required Map<String, FieldConfig> fieldConfigs,
    required double containerWidth,
    required String fieldId,
  }) {
    final currentIndex = MagneticCardSystem.cardWidths.indexOf(currentConfig.width);
    if (currentIndex == -1) return null;

    // Try smaller widths first (most common case)
    for (int i = currentIndex - 1; i >= 0; i--) {
      final testWidth = MagneticCardSystem.cardWidths[i];
      
      // Try both left and right anchored positions for this width
      final configs = _generatePositionVariants(
        currentConfig: currentConfig,
        newWidth: testWidth,
        containerWidth: containerWidth,
      );
      
      for (final testConfig in configs) {
        final wouldOverlap = MagneticSystem.wouldFieldOverlap(
          testConfig,
          fieldConfigs,
          fieldId,
          containerWidth,
        );
        
        if (!wouldOverlap) {
          return testConfig;
        }
      }
    }
    
    return null;
  }

  /// Generate position variants for a given width (unified for both handles)
  static List<FieldConfig> _generatePositionVariants({
    required FieldConfig currentConfig,
    required double newWidth,
    required double containerWidth,
  }) {
    final variants = <FieldConfig>[];
    
    // Variant 1: Keep current position (right-anchored behavior)
    if (currentConfig.position.dx + newWidth <= 1.0) {
      variants.add(currentConfig.copyWith(width: newWidth));
    }
    
    // Variant 2: Right edge stays fixed (left-anchored behavior)
    final rightEdge = currentConfig.position.dx + currentConfig.width;
    final leftAnchoredX = rightEdge - newWidth;
    if (leftAnchoredX >= 0.0) {
      variants.add(currentConfig.copyWith(
        width: newWidth,
        position: Offset(leftAnchoredX, currentConfig.position.dy),
      ));
    }
    
    // Variant 3: Grid-aligned positions
    final gridPositions = _findNearbyGridPositions(
      currentConfig.position.dx,
      newWidth,
      containerWidth,
    );
    
    for (final gridX in gridPositions) {
      variants.add(currentConfig.copyWith(
        width: newWidth,
        position: Offset(gridX, currentConfig.position.dy),
      ));
    }
    
    return variants;
  }

  /// Find nearby grid positions that could fit the width
  static List<double> _findNearbyGridPositions(
    double currentX,
    double width,
    double containerWidth,
  ) {
    final positions = <double>[];
    final maxColumns = 6;
    
    // Try positions within reasonable distance of current position
    for (int col = 0; col <= maxColumns - 1; col++) {
      final gridX = col / 6.0;
      if (gridX + width <= 1.0) {
        final distance = (gridX - currentX).abs();
        if (distance <= 0.5) { // Within 50% of container width
          positions.add(gridX);
        }
      }
    }
    
    // Sort by distance from current position
    positions.sort((a, b) => (a - currentX).abs().compareTo((b - currentX).abs()));
    
    return positions;
  }

  // ============================================================================
  // AUTO-EXPAND PRIVATE HELPERS
  // ============================================================================

  /// Find the best expansion strategy for fields in a row
  static Map<String, double>? _findBestExpansionStrategy(
    int row,
    List<String> fieldsInRow,
    double availableSpace,
    Map<String, FieldConfig> fieldConfigs,
  ) {
    if (fieldsInRow.isEmpty) return null;

    // If only one field, expand it to fill the row
    if (fieldsInRow.length == 1) {
      MagneticUtils.autoExpand(
        'Single field in row, expanding ${fieldsInRow.first} to 100%',
      );
      return {fieldsInRow.first: MagneticConstants.fullWidth};
    }

    // Check if all fields have equal or similar widths (within 5% tolerance)
    final fieldWidths =
        fieldsInRow.map((id) => fieldConfigs[id]!.width).toList();
    final avgWidth = fieldWidths.reduce((a, b) => a + b) / fieldWidths.length;
    final isEqualWidths = fieldWidths.every(
      (width) =>
          (width - avgWidth).abs() < MagneticConstants.significantGapThreshold,
    );

    MagneticUtils.autoExpand(
      'Field widths: ${fieldWidths.map((w) => '${(w * 100).toInt()}%').join(', ')}',
    );
    MagneticUtils.autoExpand(
      'Average width: ${(avgWidth * 100).toInt()}%, Equal widths: $isEqualWidths',
    );

    if (isEqualWidths) {
      return _createEqualDistribution(fieldsInRow);
    } else {
      return _createGapFillingStrategy(
        row,
        fieldsInRow,
        availableSpace,
        fieldConfigs,
      );
    }
  }

  /// Create equal distribution strategy
  static Map<String, double> _createEqualDistribution(
    List<String> fieldsInRow,
  ) {
    MagneticUtils.autoExpand('Equal widths detected - redistributing equally');
    final newWidth = MagneticConstants.fullWidth / fieldsInRow.length;
    final redistributions = <String, double>{};

    for (final fieldId in fieldsInRow) {
      redistributions[fieldId] = newWidth;
    }

    MagneticUtils.autoExpand(
      'New equal distribution: ${(newWidth * 100).toInt()}% each',
    );
    return redistributions;
  }

  /// Create gap-filling strategy
  static Map<String, double>? _createGapFillingStrategy(
    int row,
    List<String> fieldsInRow,
    double availableSpace,
    Map<String, FieldConfig> fieldConfigs,
  ) {
    MagneticUtils.autoExpand(
      'Unequal widths detected - using gap-filling strategy',
    );

    final gaps = _findGapsInRow(row, fieldsInRow, fieldConfigs);
    if (gaps.isEmpty) return null;

    // Find the largest gap
    var largestGap = gaps.reduce((a, b) => a.size > b.size ? a : b);
    MagneticUtils.autoExpand(
      'Largest gap: ${(largestGap.size * 100).toInt()}% at position ${largestGap.position}',
    );

    // Find the closest field to this gap
    final closestField = _findClosestFieldToGap(
      largestGap,
      fieldsInRow,
      fieldConfigs,
    );

    if (closestField != null) {
      final currentWidth = fieldConfigs[closestField]!.width;
      final newWidth = (currentWidth + availableSpace).clamp(
        0.0,
        MagneticConstants.fullWidth,
      );
      final snappedWidth = MagneticCardSystem.getMagneticWidth(newWidth);

      MagneticUtils.autoExpand(
        'Updating $closestField: ${(currentWidth * 100).toInt()}% → ${(snappedWidth * 100).toInt()}%',
      );
      return {closestField: snappedWidth};
    }

    return null;
  }

  /// Find gaps in a row
  static List<({double position, double size})> _findGapsInRow(
    int row,
    List<String> fieldsInRow,
    Map<String, FieldConfig> fieldConfigs,
  ) {
    final gaps = <({double position, double size})>[];

    // Get field positions and sort by x position
    final fieldConfigsList =
        fieldsInRow
            .map((id) => fieldConfigs[id]!)
            .where(
              (config) =>
                  FieldConfig.getRowFromPosition(config.position.dy) == row,
            )
            .toList();

    fieldConfigsList.sort((a, b) => a.position.dx.compareTo(b.position.dx));

    // Check gap at the beginning
    if (fieldConfigsList.isNotEmpty && fieldConfigsList.first.position.dx > 0) {
      gaps.add((position: 0.0, size: fieldConfigsList.first.position.dx));
    }

    // Check gaps between fields
    for (int i = 0; i < fieldConfigsList.length - 1; i++) {
      final currentEnd =
          fieldConfigsList[i].position.dx + fieldConfigsList[i].width;
      final nextStart = fieldConfigsList[i + 1].position.dx;
      final gapSize = nextStart - currentEnd;

      if (gapSize > MagneticConstants.significantGapThreshold) {
        gaps.add((position: currentEnd, size: gapSize));
      }
    }

    // Check gap at the end
    if (fieldConfigsList.isNotEmpty) {
      final lastEnd =
          fieldConfigsList.last.position.dx + fieldConfigsList.last.width;
      if (lastEnd < 0.95) {
        gaps.add((
          position: lastEnd,
          size: MagneticConstants.fullWidth - lastEnd,
        ));
      }
    }

    return gaps;
  }

  /// Find the closest field to a gap
  static String? _findClosestFieldToGap(
    ({double position, double size}) gap,
    List<String> fieldsInRow,
    Map<String, FieldConfig> fieldConfigs,
  ) {
    String? closestField;
    double minDistance = double.infinity;

    for (final fieldId in fieldsInRow) {
      final config = fieldConfigs[fieldId]!;
      final fieldCenter = config.position.dx + (config.width / 2);
      final gapCenter = gap.position + (gap.size / 2);
      final distance = (fieldCenter - gapCenter).abs();

      if (distance < minDistance) {
        minDistance = distance;
        closestField = fieldId;
      }
    }

    MagneticUtils.autoExpand(
      'Closest field to gap: $closestField (distance: ${(minDistance * 100).toInt()}%)',
    );

    return closestField;
  }

  /// Apply expansion strategy to configs
  static void _applyExpansionStrategy(
    Map<String, double> expansionStrategy,
    int row,
    List<String> fieldsInRow,
    Map<String, FieldConfig> fieldConfigs,
    Map<String, FieldConfig> expandedConfigs,
  ) {
    for (final entry in expansionStrategy.entries) {
      final fieldId = entry.key;
      final newWidth = entry.value;
      final currentConfig = fieldConfigs[fieldId]!;

      if ((newWidth - currentConfig.width).abs() >
          MagneticConstants.widthChangeThreshold) {
        MagneticUtils.autoExpand(
          'Updating $fieldId: ${(currentConfig.width * 100).toInt()}% → ${(newWidth * 100).toInt()}%',
        );

        if (expansionStrategy.length > 1) {
          // Multiple fields being redistributed - calculate new positions
          _redistributeFieldPositions(
            expansionStrategy,
            row,
            fieldsInRow,
            fieldConfigs,
            expandedConfigs,
          );
        } else {
          // Single field expansion
          _expandSingleField(
            fieldId,
            newWidth,
            row,
            currentConfig,
            expandedConfigs,
          );
        }
      }
    }
  }

  /// Redistribute positions for multiple fields
  static void _redistributeFieldPositions(
    Map<String, double> expansionStrategy,
    int row,
    List<String> fieldsInRow,
    Map<String, FieldConfig> fieldConfigs,
    Map<String, FieldConfig> expandedConfigs,
  ) {
    final sortedFields = fieldsInRow.toList();
    sortedFields.sort(
      (a, b) =>
          fieldConfigs[a]!.position.dx.compareTo(fieldConfigs[b]!.position.dx),
    );

    double currentX = 0.0;
    for (final sortedFieldId in sortedFields) {
      if (expansionStrategy.containsKey(sortedFieldId)) {
        final fieldWidth = expansionStrategy[sortedFieldId]!;
        final newPosition = Offset(
          currentX,
          row * MagneticCardSystem.cardHeight,
        );

        expandedConfigs[sortedFieldId] = fieldConfigs[sortedFieldId]!.copyWith(
          width: fieldWidth,
          position: newPosition,
        );

        currentX += fieldWidth;
      }
    }
  }

  /// Expand a single field
  static void _expandSingleField(
    String fieldId,
    double newWidth,
    int row,
    FieldConfig currentConfig,
    Map<String, FieldConfig> expandedConfigs,
  ) {
    Offset newPosition;

    if (newWidth >= 0.99) {
      // Full width - position at start of row
      newPosition = Offset(0.0, row * MagneticCardSystem.cardHeight);
    } else {
      // Partial width - ensure field doesn't overflow
      final currentX = currentConfig.position.dx;
      final maxAllowedX = MagneticConstants.fullWidth - newWidth;

      if (currentX + newWidth > MagneticConstants.fullWidth) {
        newPosition = Offset(maxAllowedX, row * MagneticCardSystem.cardHeight);
        MagneticUtils.autoExpand(
          'Repositioning $fieldId from ${(currentX * 100).toInt()}% to ${(maxAllowedX * 100).toInt()}% to prevent overflow',
        );
      } else {
        newPosition = currentConfig.position;
      }
    }

    expandedConfigs[fieldId] = currentConfig.copyWith(
      width: newWidth,
      position: newPosition,
    );
  }
}

// ============================================================================
// STATE CLASSES (from DragHandler)
// ============================================================================

/// State for drag operations
class DragState {
  final String draggedFieldId;
  final Offset dragStartPosition;
  final Offset dragStartFieldPosition;
  final bool hasMovedBeyondThreshold;
  final Map<String, Offset> originalPositions;

  const DragState({
    required this.draggedFieldId,
    required this.dragStartPosition,
    required this.dragStartFieldPosition,
    required this.hasMovedBeyondThreshold,
    required this.originalPositions,
  });

  DragState copyWith({
    String? draggedFieldId,
    Offset? dragStartPosition,
    Offset? dragStartFieldPosition,
    bool? hasMovedBeyondThreshold,
    Map<String, Offset>? originalPositions,
  }) {
    return DragState(
      draggedFieldId: draggedFieldId ?? this.draggedFieldId,
      dragStartPosition: dragStartPosition ?? this.dragStartPosition,
      dragStartFieldPosition:
          dragStartFieldPosition ?? this.dragStartFieldPosition,
      hasMovedBeyondThreshold:
          hasMovedBeyondThreshold ?? this.hasMovedBeyondThreshold,
      originalPositions: originalPositions ?? this.originalPositions,
    );
  }
}

/// Result of drag update
class DragUpdateResult {
  final Offset newPosition;
  final int hoveredColumn;
  final int hoveredRow;
  final bool hasMovedBeyondThreshold;
  final bool shouldShowPreview;

  const DragUpdateResult({
    required this.newPosition,
    required this.hoveredColumn,
    required this.hoveredRow,
    required this.hasMovedBeyondThreshold,
    required this.shouldShowPreview,
  });
}

/// Result of drag end
class DragEndResult {
  final bool shouldCommitPreview;
  final Offset finalPosition;
  final Map<String, FieldConfig> finalConfigs;

  const DragEndResult({
    required this.shouldCommitPreview,
    required this.finalPosition,
    required this.finalConfigs,
  });
}
