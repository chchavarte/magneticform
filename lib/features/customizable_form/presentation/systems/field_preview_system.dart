import 'package:flutter/material.dart';
import 'package:field_collision_test/core/constants/animation_constants.dart';
import 'field_animations.dart';
import 'grid_utils.dart';
import '../../data/models/field_config.dart';
import '../../data/models/magnetic_card_system.dart';

// Preview-on-hover system for field positioning
class FieldPreviewSystem {

  // Calculate preview positions for a field being dragged to a target row
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

    print(
      '🔍 DEBUG CONDITION: Row $targetRow - Total columns: 6, Occupied columns: ${rowAnalysis.occupiedColumns}, Is full: ${rowAnalysis.isRowFull}',
    );

    if (rowAnalysis.isRowFull) {
      // Row is completely full (total columns = occupied columns) → Push down
      print('❌ DEBUG CONDITION: Row is full, using push down');
      return _calculatePushDownPreview(
        targetRow: targetRow,
        draggedFieldId: draggedFieldId,
        currentConfigs: currentConfigs,
        containerWidth: containerWidth,
      );
    } else {
      // Row has available space (total columns ≠ occupied columns) → Expand/Shrink
      print('✅ DEBUG CONDITION: Row has space, trying auto-resize');
      final autoResizeResult = _calculateAutoResizePreview(
        targetRow: targetRow,
        draggedFieldId: draggedFieldId,
        currentConfigs: currentConfigs,
        containerWidth: containerWidth,
      );

      if (autoResizeResult != null) {
        print('✅ AUTO-RESIZE SUCCESS: Returning auto-resize result');
        return autoResizeResult;
      } else {
        print('❌ AUTO-RESIZE FAILED: Trying direct placement');
      }

      // If auto-resize fails, try direct placement
      print(
        '🔄 TRYING DIRECT PLACEMENT: Field width ${(draggedField.width * 100).toInt()}%',
      );
      final availablePosition = _findAvailablePositionInRow(
        targetRow: targetRow,
        fieldWidth: draggedField.width,
        currentConfigs: currentConfigs,
        excludeFieldId: draggedFieldId,
        containerWidth: containerWidth,
      );

      if (availablePosition != null) {
        print(
          '✅ DIRECT PLACEMENT SUCCESS: Position found at $availablePosition',
        );
        final previewConfigs = <String, FieldConfig>{};
        previewConfigs[draggedFieldId] = draggedField.copyWith(
          position: availablePosition,
        );

        print(
          '⚠️  WARNING: Using original width ${(draggedField.width * 100).toInt()}% - NO RESIZE APPLIED',
        );

        // Other fields keep their current positions
        for (final entry in currentConfigs.entries) {
          if (entry.key != draggedFieldId) {
            previewConfigs[entry.key] = entry.value;
          }
        }
        return previewConfigs;
      } else {
        print(
          '❌ DIRECT PLACEMENT FAILED: No position found for original width',
        );
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

  // Calculate preview positions using auto-resize logic
  static Map<String, FieldConfig>? _calculateAutoResizePreview({
    required int targetRow,
    required String draggedFieldId,
    required Map<String, FieldConfig> currentConfigs,
    required double containerWidth,
  }) {
    final draggedField = currentConfigs[draggedFieldId]!;

    print(
      'DEBUG AUTO-RESIZE: Field $draggedFieldId (${draggedField.width}) targeting row $targetRow',
    );

    // Calculate total available space in the row (including the dragged field's space)
    final totalAvailableSpace = _calculateTotalAvailableSpace(
      targetRow: targetRow,
      excludeFieldId: draggedFieldId,
      currentConfigs: currentConfigs,
    );

    print('DEBUG AUTO-RESIZE: Total available space: $totalAvailableSpace');

    if (totalAvailableSpace <= 0) {
      print('DEBUG AUTO-RESIZE: No space available');
      return null;
    }

    // Find the best width to fill the available space
    final optimalWidth = _findBestFitWidth(
      totalAvailableSpace,
      draggedField.width,
    );

    print(
      'DEBUG AUTO-RESIZE: Optimal width: $optimalWidth (current: ${draggedField.width})',
    );

    if (optimalWidth != null && optimalWidth != draggedField.width) {
      print(
        'DEBUG AUTO-RESIZE: Auto-resize successful! ${draggedField.width} -> $optimalWidth',
      );

      // Find the best position for the resized field
      final bestPosition = _findBestPositionForWidth(
        targetRow: targetRow,
        fieldWidth: optimalWidth,
        excludeFieldId: draggedFieldId,
        currentConfigs: currentConfigs,
      );

      if (bestPosition != null) {
        print('✅ RESIZE & POSITION SUCCESS: Creating preview configs');
        final previewConfigs = <String, FieldConfig>{};

        // Place resized field at the best position
        final resizedField = draggedField.copyWith(
          position: bestPosition,
          width: optimalWidth,
        );
        previewConfigs[draggedFieldId] = resizedField;

        print(
          '📝 RESIZED FIELD CONFIG: $draggedFieldId -> width: ${(optimalWidth * 100).toInt()}%, position: $bestPosition',
        );

        // Other fields keep their current positions
        for (final entry in currentConfigs.entries) {
          if (entry.key != draggedFieldId) {
            previewConfigs[entry.key] = entry.value;
          }
        }

        return previewConfigs;
      } else {
        print(
          '❌ POSITION FAILED: Could not find valid position for resized field',
        );
      }
    }

    print('DEBUG AUTO-RESIZE: Auto-resize not possible');
    return null;
  }

  // Analyze row occupancy to determine if it's completely full
  static ({int occupiedColumns, bool isRowFull}) _analyzeRowOccupancy({
    required int targetRow,
    required String excludeFieldId,
    required Map<String, FieldConfig> currentConfigs,
  }) {
    print('🔍 ANALYZING ROW $targetRow OCCUPANCY (excluding $excludeFieldId):');

    // Track which columns are occupied (6-column grid: 0-5)
    final occupiedColumns = <bool>[false, false, false, false, false, false];

    // Check all fields in the target row (excluding the dragged field)
    for (final entry in currentConfigs.entries) {
      if (entry.key == excludeFieldId) continue;

      final config = entry.value;
      final fieldRow = MagneticCardSystem.getRowFromPosition(
        config.position.dy,
      );
      if (fieldRow == targetRow) {
        // Calculate which columns this field occupies
        final startColumn = MagneticCardSystem.getColumnFromPosition(
          config.position.dx,
          400,
        ); // Use dummy width for column calculation
        final columnSpan = MagneticCardSystem.getColumnsFromWidth(config.width);

        print(
          '  Field ${entry.key}: Columns $startColumn-${startColumn + columnSpan - 1} (width: ${(config.width * 100).toInt()}%)',
        );

        // Mark columns as occupied
        for (int i = startColumn; i < startColumn + columnSpan && i < 6; i++) {
          occupiedColumns[i] = true;
        }
      }
    }

    // Count occupied columns
    final totalOccupied = occupiedColumns.where((occupied) => occupied).length;
    final isRowFull = totalOccupied == 6; // All 6 columns are occupied

    print(
      '  Column occupancy: [${occupiedColumns.map((o) => o ? 'X' : '_').join(', ')}]',
    );
    print('  Total occupied: $totalOccupied/6, Is full: $isRowFull');

    return (occupiedColumns: totalOccupied, isRowFull: isRowFull);
  }

  // Calculate available space in a row
  static ({double totalSpace, Offset startPosition})
  _calculateAvailableSpaceInRow({
    required int targetRow,
    required String excludeFieldId,
    required Map<String, FieldConfig> currentConfigs,
    required double containerWidth,
  }) {
    // Get all fields in the target row (excluding the dragged field)
    final fieldsInRow = <FieldConfig>[];
    for (final entry in currentConfigs.entries) {
      if (entry.key == excludeFieldId) continue;

      final config = entry.value;
      final fieldRow = MagneticCardSystem.getRowFromPosition(
        config.position.dy,
      );
      if (fieldRow == targetRow) {
        fieldsInRow.add(config);
      }
    }

    if (fieldsInRow.isEmpty) {
      // Empty row - full width available
      return (
        totalSpace: 1.0,
        startPosition: Offset(0, targetRow * MagneticCardSystem.cardHeight),
      );
    }

    // Sort fields by position to find gaps
    fieldsInRow.sort((a, b) => a.position.dx.compareTo(b.position.dx));

    // Find the largest continuous gap
    double maxGapSize = 0;
    Offset? maxGapStart;

    // Check gap at the beginning
    final firstField = fieldsInRow.first;
    if (firstField.position.dx > 0) {
      final gapSize = firstField.position.dx;
      if (gapSize > maxGapSize) {
        maxGapSize = gapSize;
        maxGapStart = Offset(0, targetRow * MagneticCardSystem.cardHeight);
      }
    }

    // Check gaps between fields
    for (int i = 0; i < fieldsInRow.length - 1; i++) {
      final currentField = fieldsInRow[i];
      final nextField = fieldsInRow[i + 1];

      final currentEnd = currentField.position.dx + currentField.width;
      final gapSize = nextField.position.dx - currentEnd;

      if (gapSize > maxGapSize) {
        maxGapSize = gapSize;
        maxGapStart = Offset(
          currentEnd,
          targetRow * MagneticCardSystem.cardHeight,
        );
      }
    }

    // Check gap at the end
    final lastField = fieldsInRow.last;
    final lastEnd = lastField.position.dx + lastField.width;
    if (lastEnd < 1.0) {
      final gapSize = 1.0 - lastEnd;
      if (gapSize > maxGapSize) {
        maxGapSize = gapSize;
        maxGapStart = Offset(
          lastEnd,
          targetRow * MagneticCardSystem.cardHeight,
        );
      }
    }

    return (
      totalSpace: maxGapSize,
      startPosition:
          maxGapStart ?? Offset(0, targetRow * MagneticCardSystem.cardHeight),
    );
  }

  // Calculate total available space in a row (sum of all unoccupied space)
  static double calculateTotalAvailableSpace({
    required int targetRow,
    required String excludeFieldId,
    required Map<String, FieldConfig> currentConfigs,
  }) {
    return GridUtils.calculateRowAvailableSpace(
      targetRow,
      currentConfigs,
      excludeFieldId: excludeFieldId,
    );
  }

  // Private version for internal use
  static double _calculateTotalAvailableSpace({
    required int targetRow,
    required String excludeFieldId,
    required Map<String, FieldConfig> currentConfigs,
  }) {
    return calculateTotalAvailableSpace(
      targetRow: targetRow,
      excludeFieldId: excludeFieldId,
      currentConfigs: currentConfigs,
    );
  }

  // Find the best width to fill available space
  static double? _findBestFitWidth(double availableSpace, double currentWidth) {
    print(
      'DEBUG BEST FIT: Available space: $availableSpace, current width: $currentWidth',
    );
    print('DEBUG BEST FIT: Card widths: ${MagneticCardSystem.cardWidths}');

    // Try to find the largest width that fits and is different from current
    for (final width in MagneticCardSystem.cardWidths.reversed) {
      print(
        'DEBUG BEST FIT: Testing width $width - fits: ${width <= availableSpace}, different: ${width != currentWidth}',
      );
      if (width <= availableSpace && width != currentWidth) {
        print('DEBUG BEST FIT: Found best width: $width');
        return width;
      }
    }

    print('DEBUG BEST FIT: No suitable width found');
    return null;
  }

  // Find the best position for a field with given width
  static Offset? _findBestPositionForWidth({
    required int targetRow,
    required double fieldWidth,
    required String excludeFieldId,
    required Map<String, FieldConfig> currentConfigs,
  }) {
    final containerWidth = 400.0; // Use dummy width for column calculations
    final columnSpan = MagneticCardSystem.getColumnsFromWidth(fieldWidth);

    print(
      'DEBUG POSITION: Finding position for width $fieldWidth ($columnSpan columns)',
    );

    // Try each possible starting column
    for (int startCol = 0; startCol <= 6 - columnSpan; startCol++) {
      final testPosition = Offset(
        MagneticCardSystem.getColumnPositionNormalized(startCol),
        targetRow * MagneticCardSystem.cardHeight,
      );

      print(
        'DEBUG POSITION: Testing column $startCol, position: ${testPosition.dx}',
      );

      // Check if this position would overlap with existing fields
      bool hasOverlap = false;
      for (final entry in currentConfigs.entries) {
        if (entry.key == excludeFieldId) continue;

        final config = entry.value;
        final fieldRow = MagneticCardSystem.getRowFromPosition(
          config.position.dy,
        );
        if (fieldRow != targetRow) continue;

        // Check for overlap
        final existingStart = MagneticCardSystem.getColumnFromPosition(
          config.position.dx,
          containerWidth,
        );
        final existingSpan = MagneticCardSystem.getColumnsFromWidth(
          config.width,
        );
        final existingEnd = existingStart + existingSpan - 1;

        final testEnd = startCol + columnSpan - 1;

        print(
          '🔍 OVERLAP CHECK: Testing cols $startCol-$testEnd vs existing ${entry.key} cols $existingStart-$existingEnd',
        );

        if (!(testEnd < existingStart || startCol > existingEnd)) {
          hasOverlap = true;
          print('❌ OVERLAP DETECTED: Field ${entry.key} blocks position');
          break;
        } else {
          print('✅ NO OVERLAP: Position is clear');
        }
      }

      if (!hasOverlap) {
        print('DEBUG POSITION: Found valid position at column $startCol');
        return testPosition;
      }
    }

    print('DEBUG POSITION: No valid position found');
    return null;
  }

  // Calculate preview positions using push down logic
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
      position: Offset(0, targetRow * MagneticCardSystem.cardHeight),
    );

    // Group all other fields by their current row
    final fieldsByRow = <int, List<MapEntry<String, FieldConfig>>>{};
    for (final entry in currentConfigs.entries) {
      if (entry.key == draggedFieldId) continue;

      final row = MagneticCardSystem.getRowFromPosition(
        entry.value.position.dy,
      );
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
            nextAvailableRow * MagneticCardSystem.cardHeight,
          ),
        );
      }

      nextAvailableRow++;
    }

    return previewConfigs;
  }

  // Find available position in a specific row
  static Offset? _findAvailablePositionInRow({
    required int targetRow,
    required double fieldWidth,
    required Map<String, FieldConfig> currentConfigs,
    required String excludeFieldId,
    required double containerWidth,
  }) {
    final columnSpan = MagneticCardSystem.getColumnsFromWidth(fieldWidth);

    // Try each possible starting column in the target row (6-column grid)
    for (int startCol = 0; startCol <= 6 - columnSpan; startCol++) {
      final testPosition = Offset(
        MagneticCardSystem.getColumnPositionNormalized(startCol),
        targetRow * MagneticCardSystem.cardHeight,
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

  // Check if there's space available in a row for a field
  static bool hasSpaceInRow({
    required int targetRow,
    required String excludeFieldId,
    required double fieldWidth,
    required Map<String, FieldConfig> currentConfigs,
    required double containerWidth,
  }) {
    return _findAvailablePositionInRow(
          targetRow: targetRow,
          fieldWidth: fieldWidth,
          currentConfigs: currentConfigs,
          excludeFieldId: excludeFieldId,
          containerWidth: containerWidth,
        ) !=
        null;
  }

  // Animate to preview positions
  static void animateToPreview({
    required TickerProvider vsync,
    required Map<String, FieldConfig> fromConfigs,
    required Map<String, FieldConfig> toConfigs,
    required Function(Map<String, FieldConfig>) onUpdate,
    VoidCallback? onComplete,
  }) {
    FieldAnimations.animateMultipleFields(
      vsync: vsync,
      fromConfigs: fromConfigs,
      toConfigs: toConfigs,
      onUpdate: onUpdate,
      onComplete: onComplete,
      duration: AnimationConstants.previewDuration,
      curve: AnimationConstants.previewCurve,
    );
  }

  // Animate to commit final positions
  static void animateToCommit({
    required TickerProvider vsync,
    required Map<String, FieldConfig> fromConfigs,
    required Map<String, FieldConfig> toConfigs,
    required Function(Map<String, FieldConfig>) onUpdate,
    VoidCallback? onComplete,
  }) {
    FieldAnimations.animateMultipleFields(
      vsync: vsync,
      fromConfigs: fromConfigs,
      toConfigs: toConfigs,
      onUpdate: onUpdate,
      onComplete: onComplete,
      duration: AnimationConstants.commitDuration,
      curve: AnimationConstants.commitCurve,
    );
  }

  // Animate to revert to original positions
  static void animateToRevert({
    required TickerProvider vsync,
    required Map<String, FieldConfig> fromConfigs,
    required Map<String, FieldConfig> toConfigs,
    required Function(Map<String, FieldConfig>) onUpdate,
    VoidCallback? onComplete,
  }) {
    FieldAnimations.animateMultipleFields(
      vsync: vsync,
      fromConfigs: fromConfigs,
      toConfigs: toConfigs,
      onUpdate: onUpdate,
      onComplete: onComplete,
      duration: AnimationConstants.revertDuration,
      curve: AnimationConstants.revertCurve,
    );
  }

  // Animate smooth hover enter (when dropzone is detected)
  static void animateHoverEnter({
    required TickerProvider vsync,
    required Map<String, FieldConfig> fromConfigs,
    required Map<String, FieldConfig> toConfigs,
    required Function(Map<String, FieldConfig>) onUpdate,
    VoidCallback? onComplete,
  }) {
    FieldAnimations.animateMultipleFields(
      vsync: vsync,
      fromConfigs: fromConfigs,
      toConfigs: toConfigs,
      onUpdate: onUpdate,
      onComplete: onComplete,
      duration: AnimationConstants.hoverEnterDuration,
      curve: AnimationConstants.hoverEnterCurve,
    );
  }

  // Animate smooth hover exit (when leaving dropzone)
  static void animateHoverExit({
    required TickerProvider vsync,
    required Map<String, FieldConfig> fromConfigs,
    required Map<String, FieldConfig> toConfigs,
    required Function(Map<String, FieldConfig>) onUpdate,
    VoidCallback? onComplete,
  }) {
    FieldAnimations.animateMultipleFields(
      vsync: vsync,
      fromConfigs: fromConfigs,
      toConfigs: toConfigs,
      onUpdate: onUpdate,
      onComplete: onComplete,
      duration: AnimationConstants.hoverExitDuration,
      curve: AnimationConstants.hoverExitCurve,
    );
  }

  // Get visual feedback information for preview state
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
        message: 'Field not found',
        isPushDown: false,
      );
    }

    // Priority 1: Check auto-resize first
    final availableSpace = _calculateAvailableSpaceInRow(
      targetRow: targetRow,
      excludeFieldId: draggedFieldId,
      currentConfigs: currentConfigs,
      containerWidth: containerWidth,
    );

    final totalAvailable = _calculateTotalAvailableSpace(
      targetRow: targetRow,
      excludeFieldId: draggedFieldId,
      currentConfigs: currentConfigs,
    );

    final optimalWidth = _findBestFitWidth(totalAvailable, draggedField.width);

    if (optimalWidth != null) {
      // Auto-resize possible
      final startColumn = MagneticCardSystem.getColumnFromPosition(
        availableSpace.startPosition.dx,
        containerWidth,
      );
      final columnSpan = MagneticCardSystem.getColumnsFromWidth(optimalWidth);
      final widthPercent = (optimalWidth * 100).toInt();
      final action = optimalWidth > draggedField.width ? 'expand' : 'shrink';

      return PreviewInfo(
        hasSpace: true,
        targetPosition: availableSpace.startPosition,
        targetColumns: (start: startColumn, span: columnSpan),
        message:
            'Will $action to $widthPercent% width and place in columns ${startColumn + 1}-${startColumn + columnSpan}',
        isPushDown: false,
      );
    }

    // Priority 2: Check direct placement at current width
    final directPosition = _findAvailablePositionInRow(
      targetRow: targetRow,
      fieldWidth: draggedField.width,
      currentConfigs: currentConfigs,
      excludeFieldId: draggedFieldId,
      containerWidth: containerWidth,
    );

    if (directPosition != null) {
      // Space available at current width - direct placement
      final startColumn = MagneticCardSystem.getColumnFromPosition(
        directPosition.dx,
        containerWidth,
      );
      final columnSpan = MagneticCardSystem.getColumnsFromWidth(
        draggedField.width,
      );

      return PreviewInfo(
        hasSpace: true,
        targetPosition: directPosition,
        targetColumns: (start: startColumn, span: columnSpan),
        message:
            'Will place in columns ${startColumn + 1}-${startColumn + columnSpan}',
        isPushDown: false,
      );
    } else {
      // Priority 3: Push down required
      final pushDownPosition = Offset(
        0,
        targetRow * MagneticCardSystem.cardHeight,
      );
      final columnSpan = MagneticCardSystem.getColumnsFromWidth(
        draggedField.width,
      );

      return PreviewInfo(
        hasSpace: true, // We can still place it, just need to push down
        targetPosition: pushDownPosition,
        targetColumns: (start: 0, span: columnSpan),
        message: 'Will push other fields down to make space',
        isPushDown: true,
      );
    }
  }
}

// Information about preview state
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

// Preview state management
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

  // Create initial preview state
  static PreviewState initial() {
    return const PreviewState();
  }

  // Create active preview state
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