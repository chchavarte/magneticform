import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;
import '../constants/magnetic_constants.dart';
import '../utils/magnetic_utils.dart';
import '../models/field_models.dart';
import '../models/magnetic_card_system.dart';

/// Consolidated system for all magnetic form operations including
/// preview calculations, grid utilities, and animations
class MagneticSystem {
  // Private constructor to prevent instantiation
  MagneticSystem._();

  // =============================================================================
  // PREVIEW SYSTEM (from FieldPreviewSystem)
  // =============================================================================

  /// Calculate preview positions for a field being dragged to a target row
  static Map<String, FieldConfig> calculatePreviewPositions({
    required int targetRow,
    required String draggedFieldId,
    required Map<String, FieldConfig> currentConfigs,
    required double containerWidth,
  }) {
    final draggedField = currentConfigs[draggedFieldId];

    if (draggedField == null) return currentConfigs;

    // Check if row is completely full (total columns = occupied columns)
    final rowAnalysis = _analyzeRowOccupancy(
      targetRow: targetRow,
      excludeFieldId: draggedFieldId,
      currentConfigs: currentConfigs,
    );

    if (rowAnalysis.isRowFull) {
      // Row is completely full (total columns = occupied columns) → Push down
      return _calculatePushDownPreview(
        targetRow: targetRow,
        draggedFieldId: draggedFieldId,
        currentConfigs: currentConfigs,
        containerWidth: containerWidth,
      );
    } else {
      // Row has available space (total columns ≠ occupied columns) → Expand/Shrink
      final autoResizeResult = _calculateAutoResizePreview(
        targetRow: targetRow,
        draggedFieldId: draggedFieldId,
        currentConfigs: currentConfigs,
        containerWidth: containerWidth,
      );

      if (autoResizeResult != null) {
        return autoResizeResult;
      }

      // If auto-resize fails, try direct placement
      final availablePosition = findAvailablePositionInRow(
        targetRow: targetRow,
        fieldWidth: draggedField.width,
        currentConfigs: currentConfigs,
        excludeFieldId: draggedFieldId,
        containerWidth: containerWidth,
      );

      if (availablePosition != null) {
        final previewConfigs = <String, FieldConfig>{};
        previewConfigs[draggedFieldId] = draggedField.copyWith(
          position: availablePosition,
        );

        // Other fields keep their current positions
        for (final entry in currentConfigs.entries) {
          if (entry.key != draggedFieldId) {
            previewConfigs[entry.key] = entry.value;
          }
        }
        return previewConfigs;
      }

      // Last resort: push down
      return _calculatePushDownPreview(
        targetRow: targetRow,
        draggedFieldId: draggedFieldId,
        currentConfigs: currentConfigs,
        containerWidth: containerWidth,
      );
    }
  }

  /// Calculate preview positions using auto-resize logic
  static Map<String, FieldConfig>? _calculateAutoResizePreview({
    required int targetRow,
    required String draggedFieldId,
    required Map<String, FieldConfig> currentConfigs,
    required double containerWidth,
  }) {
    final draggedField = currentConfigs[draggedFieldId]!;

    // Calculate total available space in the row (including the dragged field's space)
    final totalAvailableSpace = calculateRowAvailableSpace(
      targetRow,
      currentConfigs,
      excludeFieldId: draggedFieldId,
    );

    if (totalAvailableSpace <= 0) {
      return null;
    }

    // Find the best width to fill the available space
    final optimalWidth = _findBestFitWidth(
      totalAvailableSpace,
      draggedField.width,
    );

    if (optimalWidth != null && optimalWidth != draggedField.width) {
      // Find the best position for the resized field
      final bestPosition = _findBestPositionForWidth(
        targetRow: targetRow,
        fieldWidth: optimalWidth,
        excludeFieldId: draggedFieldId,
        currentConfigs: currentConfigs,
      );

      if (bestPosition != null) {
        final previewConfigs = <String, FieldConfig>{};

        // Place resized field at the best position
        final resizedField = draggedField.copyWith(
          position: bestPosition,
          width: optimalWidth,
        );
        previewConfigs[draggedFieldId] = resizedField;

        // Other fields keep their current positions
        for (final entry in currentConfigs.entries) {
          if (entry.key != draggedFieldId) {
            previewConfigs[entry.key] = entry.value;
          }
        }

        return previewConfigs;
      }
    }

    return null;
  }

  /// Analyze row occupancy to determine if it's completely full
  static ({int occupiedColumns, bool isRowFull}) _analyzeRowOccupancy({
    required int targetRow,
    required String excludeFieldId,
    required Map<String, FieldConfig> currentConfigs,
  }) {
    // Track which columns are occupied (6-column grid: 0-5)
    final occupiedColumns = <bool>[false, false, false, false, false, false];

    // Check all fields in the target row (excluding the dragged field)
    for (final entry in currentConfigs.entries) {
      if (entry.key == excludeFieldId) continue;

      final config = entry.value;
      final fieldRow = FieldConfig.getRowFromPosition(config.position.dy);
      if (fieldRow == targetRow) {
        // Calculate which columns this field occupies
        final startColumn = FieldConfig.getColumnFromPosition(config.position.dx, 400);
        final columnSpan = FieldConfig.getColumnsFromWidth(config.width);

        // Mark columns as occupied
        for (int i = startColumn; i < startColumn + columnSpan && i < 6; i++) {
          occupiedColumns[i] = true;
        }
      }
    }

    // Count occupied columns
    final totalOccupied = occupiedColumns.where((occupied) => occupied).length;
    final isRowFull = totalOccupied == 6; // All 6 columns are occupied

    return (occupiedColumns: totalOccupied, isRowFull: isRowFull);
  }

  /// Calculate preview positions using push down logic
  static Map<String, FieldConfig> _calculatePushDownPreview({
    required int targetRow,
    required String draggedFieldId,
    required Map<String, FieldConfig> currentConfigs,
    required double containerWidth,
  }) {
    final previewConfigs = <String, FieldConfig>{};
    final draggedField = currentConfigs[draggedFieldId]!;

    // Place dragged field at the beginning of target row
    previewConfigs[draggedFieldId] = draggedField.copyWith(
      position: Offset(0, targetRow * MagneticConstants.cardHeight),
    );

    // Group all other fields by their current row
    final fieldsByRow = <int, List<MapEntry<String, FieldConfig>>>{};
    for (final entry in currentConfigs.entries) {
      if (entry.key == draggedFieldId) continue;

      final row = FieldConfig.getRowFromPosition(entry.value.position.dy);
      fieldsByRow.putIfAbsent(row, () => []).add(entry);
    }

    // Rearrange fields: compact all rows and skip target row
    final sortedRows = fieldsByRow.keys.toList()..sort();
    int nextAvailableRow = 0;

    for (final originalRow in sortedRows) {
      // Skip the target row - it's reserved for the dragged field
      if (nextAvailableRow == targetRow) {
        nextAvailableRow++;
      }

      final fieldsInRow = fieldsByRow[originalRow]!;
      for (final entry in fieldsInRow) {
        final fieldId = entry.key;
        final originalConfig = entry.value;

        previewConfigs[fieldId] = originalConfig.copyWith(
          position: Offset(
            originalConfig.position.dx,
            nextAvailableRow * MagneticConstants.cardHeight,
          ),
        );
      }

      nextAvailableRow++;
    }

    return previewConfigs;
  }

  /// Find the best width to fill available space
  static double? _findBestFitWidth(double availableSpace, double currentWidth) {
    // Try to find the largest width that fits and is different from current
    for (final width in MagneticConstants.cardWidths.reversed) {
      if (width <= availableSpace && width != currentWidth) {
        return width;
      }
    }

    return null;
  }

  /// Find the best position for a field with given width
  static Offset? _findBestPositionForWidth({
    required int targetRow,
    required double fieldWidth,
    required String excludeFieldId,
    required Map<String, FieldConfig> currentConfigs,
  }) {
    final containerWidth = 400.0; // Use dummy width for column calculations
    final columnSpan = FieldConfig.getColumnsFromWidth(fieldWidth);

    // Try each possible starting column
    for (int startCol = 0; startCol <= 6 - columnSpan; startCol++) {
      final testPosition = Offset(
        FieldConfig.getColumnPositionNormalized(startCol),
        targetRow * MagneticConstants.cardHeight,
      );

      // Check if this position would overlap with existing fields
      bool hasOverlap = false;
      for (final entry in currentConfigs.entries) {
        if (entry.key == excludeFieldId) continue;

        final config = entry.value;
        final fieldRow = FieldConfig.getRowFromPosition(config.position.dy);
        if (fieldRow != targetRow) continue;

        // Check for overlap
        final existingStart = FieldConfig.getColumnFromPosition(config.position.dx, containerWidth);
        final existingSpan = FieldConfig.getColumnsFromWidth(config.width);
        final existingEnd = existingStart + existingSpan - 1;

        final testEnd = startCol + columnSpan - 1;

        if (!(testEnd < existingStart || startCol > existingEnd)) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        return testPosition;
      }
    }

    return null;
  }

  /// Check if there's space available in a row for a field
  static bool hasSpaceInRow({
    required int targetRow,
    required String excludeFieldId,
    required double fieldWidth,
    required Map<String, FieldConfig> currentConfigs,
    required double containerWidth,
  }) {
    return findAvailablePositionInRow(
          targetRow: targetRow,
          fieldWidth: fieldWidth,
          currentConfigs: currentConfigs,
          excludeFieldId: excludeFieldId,
          containerWidth: containerWidth,
        ) !=
        null;
  }

  /// Get visual feedback information for preview state
  static PreviewInfo getPreviewInfo({
    required int targetRow,
    required String draggedFieldId,
    required Map<String, FieldConfig> currentConfigs,
    required double containerWidth,
  }) {
    final draggedField = currentConfigs[draggedFieldId];
    if (draggedField == null) {
      return PreviewInfo(
        hasSpace: false,
        targetPosition: null,
        targetColumns: null,
        message: '',
        isPushDown: false,
      );
    }

    // Priority 1: Check auto-resize first
    final totalAvailable = calculateRowAvailableSpace(
      targetRow,
      currentConfigs,
      excludeFieldId: draggedFieldId,
    );

    final optimalWidth = _findBestFitWidth(totalAvailable, draggedField.width);

    if (optimalWidth != null) {
      // Auto-resize possible
      final bestPosition = _findBestPositionForWidth(
        targetRow: targetRow,
        fieldWidth: optimalWidth,
        excludeFieldId: draggedFieldId,
        currentConfigs: currentConfigs,
      );

      if (bestPosition != null) {
        final startColumn = FieldConfig.getColumnFromPosition(bestPosition.dx, containerWidth);
        final columnSpan = FieldConfig.getColumnsFromWidth(optimalWidth);

        return PreviewInfo(
          hasSpace: true,
          targetPosition: bestPosition,
          targetColumns: (start: startColumn, span: columnSpan),
          message: '',
          isPushDown: false,
        );
      }
    }

    // Priority 2: Check direct placement at current width
    final directPosition = findAvailablePositionInRow(
      targetRow: targetRow,
      fieldWidth: draggedField.width,
      currentConfigs: currentConfigs,
      excludeFieldId: draggedFieldId,
      containerWidth: containerWidth,
    );

    if (directPosition != null) {
      // Space available at current width - direct placement
      final startColumn = FieldConfig.getColumnFromPosition(directPosition.dx, containerWidth);
      final columnSpan = FieldConfig.getColumnsFromWidth(draggedField.width);

      return PreviewInfo(
        hasSpace: true,
        targetPosition: directPosition,
        targetColumns: (start: startColumn, span: columnSpan),
        message: '',
        isPushDown: false,
      );
    } else {
      // Priority 3: Push down required
      final pushDownPosition = Offset(
        0,
        targetRow * MagneticConstants.cardHeight,
      );
      final columnSpan = FieldConfig.getColumnsFromWidth(draggedField.width);

      return PreviewInfo(
        hasSpace: true, // We can still place it, just need to push down
        targetPosition: pushDownPosition,
        targetColumns: (start: 0, span: columnSpan),
        message: '',
        isPushDown: true,
      );
    }
  }

  // =============================================================================
  // GRID UTILITIES (from GridUtils)
  // =============================================================================

  /// Get complete grid information for a field configuration
  static FieldGridInfo getFieldGridInfo(
    FieldConfig config,
    double containerWidth,
  ) {
    final row = FieldConfig.getRowFromPosition(config.position.dy);
    final startColumn = FieldConfig.getColumnFromPosition(config.position.dx, containerWidth);
    final columnSpan = FieldConfig.getColumnsFromWidth(config.width);
    final endColumn = startColumn + columnSpan - 1;
    final widthPercent = (config.width * 100).toInt();
    
    return FieldGridInfo(
      row: row,
      startColumn: startColumn,
      columnSpan: columnSpan,
      endColumn: endColumn,
      displayRange: 'Row $row, Columns $startColumn-$endColumn, Width $widthPercent%',
    );
  }

  /// Check if a field configuration would cause overlap with existing fields
  static bool wouldFieldOverlap(
    FieldConfig testConfig,
    Map<String, FieldConfig> existingConfigs,
    String excludeFieldId,
    double containerWidth,
  ) {
    return MagneticCardSystem.wouldOverlap(
      testConfig.position,
      testConfig.width,
      containerWidth,
      existingConfigs,
      excludeFieldId,
    );
  }

  /// Find all fields in a specific row
  static List<String> getFieldsInRow(
    int targetRow,
    Map<String, FieldConfig> fieldConfigs, {
    String? excludeFieldId,
  }) {
    final fieldsInRow = <String>[];
    
    for (final entry in fieldConfigs.entries) {
      if (excludeFieldId != null && entry.key == excludeFieldId) continue;
      
      final config = entry.value;
      if (!config.isVisible) continue;
      
      final row = FieldConfig.getRowFromPosition(config.position.dy);
      if (row == targetRow) {
        fieldsInRow.add(entry.key);
      }
    }
    
    return fieldsInRow;
  }

  /// Group all fields by their row positions
  static Map<int, List<String>> groupFieldsByRow(
    Map<String, FieldConfig> fieldConfigs, {
    String? excludeFieldId,
  }) {
    final fieldsByRow = <int, List<String>>{};
    
    for (final entry in fieldConfigs.entries) {
      if (excludeFieldId != null && entry.key == excludeFieldId) continue;
      
      final config = entry.value;
      if (!config.isVisible) continue;
      
      final row = FieldConfig.getRowFromPosition(config.position.dy);
      fieldsByRow.putIfAbsent(row, () => []).add(entry.key);
    }
    
    return fieldsByRow;
  }

  /// Calculate total occupied width in a specific row
  static double calculateRowOccupiedWidth(
    int targetRow,
    Map<String, FieldConfig> fieldConfigs, {
    String? excludeFieldId,
  }) {
    double totalOccupied = 0.0;
    
    for (final entry in fieldConfigs.entries) {
      if (excludeFieldId != null && entry.key == excludeFieldId) continue;
      
      final config = entry.value;
      if (!config.isVisible) continue;
      
      final row = FieldConfig.getRowFromPosition(config.position.dy);
      if (row == targetRow) {
        totalOccupied += config.width;
      }
    }
    
    return totalOccupied;
  }

  /// Calculate available space in a specific row
  static double calculateRowAvailableSpace(
    int targetRow,
    Map<String, FieldConfig> fieldConfigs, {
    String? excludeFieldId,
  }) {
    final occupiedWidth = calculateRowOccupiedWidth(
      targetRow,
      fieldConfigs,
      excludeFieldId: excludeFieldId,
    );
    return (1.0 - occupiedWidth).clamp(0.0, 1.0);
  }

  /// Check if a field can fit in a specific row without overlap
  static bool canFieldFitInRow(
    int targetRow,
    double fieldWidth,
    Map<String, FieldConfig> fieldConfigs,
    double containerWidth, {
    String? excludeFieldId,
  }) {
    final columnSpan = FieldConfig.getColumnsFromWidth(fieldWidth);
    
    // Try each possible starting column in the target row
    for (int startCol = 0; startCol <= 6 - columnSpan; startCol++) {
      final testPosition = Offset(
        FieldConfig.getColumnPositionNormalized(startCol),
        targetRow * MagneticConstants.cardHeight,
      );

      final hasOverlap = MagneticCardSystem.wouldOverlap(
        testPosition,
        fieldWidth,
        containerWidth,
        fieldConfigs,
        excludeFieldId ?? '',
      );

      if (!hasOverlap) {
        return true; // Found a spot
      }
    }
    return false; // No space available
  }

  /// Find the first available position for a field in a specific row
  static Offset? findAvailablePositionInRow({
    required int targetRow,
    required double fieldWidth,
    required Map<String, FieldConfig> currentConfigs,
    required String excludeFieldId,
    required double containerWidth,
  }) {
    final columnSpan = FieldConfig.getColumnsFromWidth(fieldWidth);
    
    // Try each possible starting column in the target row
    for (int startCol = 0; startCol <= 6 - columnSpan; startCol++) {
      final testPosition = Offset(
        FieldConfig.getColumnPositionNormalized(startCol),
        targetRow * MagneticConstants.cardHeight,
      );

      final hasOverlap = MagneticCardSystem.wouldOverlap(
        testPosition,
        fieldWidth,
        containerWidth,
        currentConfigs,
        excludeFieldId,
      );

      if (!hasOverlap) {
        return testPosition; // Found available position
      }
    }
    return null; // No available position found
  }

  /// Print field configurations in a consistent format (for debugging)
  static void printFieldConfigs(
    String title,
    Map<String, FieldConfig> fieldConfigs,
    double containerWidth,
  ) {
    MagneticUtils.grid(title);
    for (final entry in fieldConfigs.entries) {
      final config = entry.value;
      final gridInfo = getFieldGridInfo(config, containerWidth);
      MagneticUtils.grid('  ${entry.key}: $gridInfo');
    }
  }

  /// Validate that a field configuration is within grid boundaries
  static bool isValidFieldConfig(
    FieldConfig config,
    double containerWidth,
  ) {
    final gridInfo = getFieldGridInfo(config, containerWidth);
    
    // Check if field is within grid boundaries
    if (gridInfo.row < 0 || gridInfo.row >= MagneticConstants.maxRows) {
      return false;
    }
    
    if (gridInfo.startColumn < 0 || gridInfo.endColumn >= 6) {
      return false;
    }
    
    if (config.width <= 0 || config.width > 1.0) {
      return false;
    }
    
    return true;
  }

  /// Get the maximum row number currently occupied by any field
  static int getMaxOccupiedRow(Map<String, FieldConfig> fieldConfigs) {
    int maxRow = -1;
    
    for (final config in fieldConfigs.values) {
      if (!config.isVisible) continue;
      
      final row = FieldConfig.getRowFromPosition(config.position.dy);
      if (row > maxRow) {
        maxRow = row;
      }
    }
    
    return maxRow;
  }

  /// Create a new field configuration at a specific grid position
  static FieldConfig createFieldAtGridPosition({
    required String fieldId,
    required int row,
    required int startColumn,
    required double width,
  }) {
    final position = Offset(
      FieldConfig.getColumnPositionNormalized(startColumn),
      row * MagneticConstants.cardHeight,
    );
    
    return FieldConfig(
      id: fieldId,
      width: width,
      position: position,
    );
  }

  // =============================================================================
  // ANIMATION SYSTEM (from FieldAnimations)
  // =============================================================================

  /// Animate field width changes (for resize snap-back and auto-resize)
  static void animateFieldResize({
    required TickerProvider vsync,
    required String fieldId,
    required double fromWidth,
    required double toWidth,
    required Function(String, double) onWidthUpdate,
    VoidCallback? onComplete,
    Duration? duration,
    Curve? curve,
  }) {
    if (fromWidth == toWidth) {
      onComplete?.call();
      return;
    }

    final animationController = AnimationController(
      duration: duration ?? MagneticConstants.defaultFieldAnimationDuration,
      vsync: vsync,
    );

    final animation = Tween<double>(
      begin: fromWidth,
      end: toWidth,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: curve ?? MagneticConstants.defaultFieldAnimationCurve,
    ));

    animation.addListener(() {
      onWidthUpdate(fieldId, animation.value);
    });

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationController.dispose();
        onComplete?.call();
      }
    });

    animationController.forward();
  }

  /// Animate field position changes (for drag snap-back)
  static void animateFieldPosition({
    required TickerProvider vsync,
    required String fieldId,
    required Offset fromPosition,
    required Offset toPosition,
    required Function(String, Offset) onPositionUpdate,
    VoidCallback? onComplete,
    Duration? duration,
    Curve? curve,
  }) {
    if (fromPosition == toPosition) {
      onComplete?.call();
      return;
    }

    final animationController = AnimationController(
      duration: duration ?? MagneticConstants.defaultFieldAnimationDuration,
      vsync: vsync,
    );

    final animation = Tween<Offset>(
      begin: fromPosition,
      end: toPosition,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: curve ?? MagneticConstants.defaultFieldAnimationCurve,
    ));

    animation.addListener(() {
      onPositionUpdate(fieldId, animation.value);
    });

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationController.dispose();
        onComplete?.call();
      }
    });

    animationController.forward();
  }

  /// Animate complete field config changes (position + width)
  static void animateFieldConfig({
    required TickerProvider vsync,
    required String fieldId,
    required FieldConfig fromConfig,
    required FieldConfig toConfig,
    required Function(String, FieldConfig) onConfigUpdate,
    VoidCallback? onComplete,
    Duration? duration,
    Curve? curve,
  }) {
    if (fromConfig.position == toConfig.position && 
        fromConfig.width == toConfig.width) {
      onConfigUpdate(fieldId, toConfig);
      onComplete?.call();
      return;
    }

    final animationController = AnimationController(
      duration: duration ?? MagneticConstants.defaultFieldAnimationDuration,
      vsync: vsync,
    );

    final positionAnimation = Tween<Offset>(
      begin: fromConfig.position,
      end: toConfig.position,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: curve ?? MagneticConstants.defaultFieldAnimationCurve,
    ));

    final widthAnimation = Tween<double>(
      begin: fromConfig.width,
      end: toConfig.width,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: curve ?? MagneticConstants.defaultFieldAnimationCurve,
    ));

    animationController.addListener(() {
      final animatedConfig = fromConfig.copyWith(
        position: positionAnimation.value,
        width: widthAnimation.value,
      );
      onConfigUpdate(fieldId, animatedConfig);
    });

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationController.dispose();
        onComplete?.call();
      }
    });

    animationController.forward();
  }

  /// Batch animate multiple fields (for auto-resize scenarios)
  static void animateMultipleFields({
    required TickerProvider vsync,
    required Map<String, FieldConfig> fromConfigs,
    required Map<String, FieldConfig> toConfigs,
    required Function(Map<String, FieldConfig>) onUpdate,
    VoidCallback? onComplete,
    Duration? duration,
    Curve? curve,
  }) {
    final animationController = AnimationController(
      duration: duration ?? MagneticConstants.defaultFieldAnimationDuration,
      vsync: vsync,
    );

    final animations = <String, Animation<FieldConfig>>{};
    
    for (final fieldId in fromConfigs.keys) {
      final fromConfig = fromConfigs[fieldId]!;
      final toConfig = toConfigs[fieldId]!;
      
      animations[fieldId] = FieldConfigTween(
        begin: fromConfig,
        end: toConfig,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: curve ?? MagneticConstants.defaultFieldAnimationCurve,
      ));
    }

    animationController.addListener(() {
      final animatedConfigs = <String, FieldConfig>{};
      for (final entry in animations.entries) {
        animatedConfigs[entry.key] = entry.value.value;
      }
      onUpdate(animatedConfigs);
    });

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationController.dispose();
        onComplete?.call();
      }
    });

    animationController.forward();
  }

  /// Animate to preview positions
  static void animateToPreview({
    required TickerProvider vsync,
    required Map<String, FieldConfig> fromConfigs,
    required Map<String, FieldConfig> toConfigs,
    required Function(Map<String, FieldConfig>) onUpdate,
    VoidCallback? onComplete,
  }) {
    animateMultipleFields(
      vsync: vsync,
      fromConfigs: fromConfigs,
      toConfigs: toConfigs,
      onUpdate: onUpdate,
      onComplete: onComplete,
      duration: MagneticConstants.previewDuration,
      curve: MagneticConstants.previewCurve,
    );
  }

  /// Animate to commit final positions
  static void animateToCommit({
    required TickerProvider vsync,
    required Map<String, FieldConfig> fromConfigs,
    required Map<String, FieldConfig> toConfigs,
    required Function(Map<String, FieldConfig>) onUpdate,
    VoidCallback? onComplete,
  }) {
    animateMultipleFields(
      vsync: vsync,
      fromConfigs: fromConfigs,
      toConfigs: toConfigs,
      onUpdate: onUpdate,
      onComplete: onComplete,
      duration: MagneticConstants.commitDuration,
      curve: MagneticConstants.commitCurve,
    );
  }

  /// Animate to revert to original positions
  static void animateToRevert({
    required TickerProvider vsync,
    required Map<String, FieldConfig> fromConfigs,
    required Map<String, FieldConfig> toConfigs,
    required Function(Map<String, FieldConfig>) onUpdate,
    VoidCallback? onComplete,
  }) {
    animateMultipleFields(
      vsync: vsync,
      fromConfigs: fromConfigs,
      toConfigs: toConfigs,
      onUpdate: onUpdate,
      onComplete: onComplete,
      duration: MagneticConstants.revertDuration,
      curve: MagneticConstants.revertCurve,
    );
  }
}

// =============================================================================
// SUPPORTING CLASSES
// =============================================================================

/// Represents complete grid information for a field
class FieldGridInfo {
  final int row;
  final int startColumn;
  final int columnSpan;
  final int endColumn;
  final String displayRange;

  const FieldGridInfo({
    required this.row,
    required this.startColumn,
    required this.columnSpan,
    required this.endColumn,
    required this.displayRange,
  });

  @override
  String toString() => displayRange;
}

/// Information about preview state
class PreviewInfo {
  final bool hasSpace;
  final Offset? targetPosition;
  final ({int start, int span})? targetColumns;
  final String message;
  final bool isPushDown;

  const PreviewInfo({
    required this.hasSpace,
    required this.targetPosition,
    required this.targetColumns,
    required this.message,
    required this.isPushDown,
  });
}

/// Preview state management
class PreviewState {
  final bool isActive;
  final String? draggedFieldId;
  final int? targetRow;
  final Map<String, FieldConfig> previewConfigs;
  final Map<String, FieldConfig> originalConfigs;
  final PreviewInfo? previewInfo;

  const PreviewState({
    this.isActive = false,
    this.draggedFieldId,
    this.targetRow,
    this.previewConfigs = const {},
    this.originalConfigs = const {},
    this.previewInfo,
  });

  PreviewState copyWith({
    bool? isActive,
    String? draggedFieldId,
    int? targetRow,
    Map<String, FieldConfig>? previewConfigs,
    Map<String, FieldConfig>? originalConfigs,
    PreviewInfo? previewInfo,
  }) {
    return PreviewState(
      isActive: isActive ?? this.isActive,
      draggedFieldId: draggedFieldId ?? this.draggedFieldId,
      targetRow: targetRow ?? this.targetRow,
      previewConfigs: previewConfigs ?? this.previewConfigs,
      originalConfigs: originalConfigs ?? this.originalConfigs,
      previewInfo: previewInfo ?? this.previewInfo,
    );
  }

  /// Create initial preview state
  static PreviewState initial() {
    return const PreviewState();
  }

  /// Create active preview state
  static PreviewState active({
    required String draggedFieldId,
    required int targetRow,
    required Map<String, FieldConfig> previewConfigs,
    required Map<String, FieldConfig> originalConfigs,
    required PreviewInfo previewInfo,
  }) {
    return PreviewState(
      isActive: true,
      draggedFieldId: draggedFieldId,
      targetRow: targetRow,
      previewConfigs: previewConfigs,
      originalConfigs: originalConfigs,
      previewInfo: previewInfo,
    );
  }
}

/// Custom Tween for FieldConfig interpolation
class FieldConfigTween extends Tween<FieldConfig> {
  FieldConfigTween({required FieldConfig begin, required FieldConfig end})
      : super(begin: begin, end: end);

  @override
  FieldConfig lerp(double t) {
    return FieldConfig(
      id: begin!.id,
      width: lerpDouble(begin!.width, end!.width, t) ?? begin!.width,
      position: Offset.lerp(begin!.position, end!.position, t) ?? begin!.position,
    );
  }
}