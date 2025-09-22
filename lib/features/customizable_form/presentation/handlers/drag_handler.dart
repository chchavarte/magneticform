import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:field_collision_test/core/constants/field_constants.dart';
import 'package:field_collision_test/core/utils/logger.dart';
import '../systems/field_preview_system.dart';
import '../systems/grid_utils.dart';
import '../../data/models/field_config.dart';
import '../../data/models/magnetic_card_system.dart';

/// Handles all drag and drop operations for fields
class DragHandler {
  // Private constructor to prevent instantiation
  DragHandler._();

  /// Handle field drag start
  static DragState startFieldDrag({
    required String fieldId,
    required LongPressStartDetails details,
    required Map<String, FieldConfig> fieldConfigs,
  }) {
    HapticFeedback.mediumImpact();
    final config = fieldConfigs[fieldId]!;

    Logger.preview('Starting drag for field $fieldId');

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
    final distanceMoved = (details.globalPosition - dragState.dragStartPosition).distance;

    // Check if we've moved beyond the threshold
    bool hasMovedBeyondThreshold = dragState.hasMovedBeyondThreshold;
    if (!hasMovedBeyondThreshold && distanceMoved > FieldConstants.hoverThreshold) {
      hasMovedBeyondThreshold = true;
    }

    // Calculate delta from start position
    final deltaX = (details.globalPosition.dx - dragState.dragStartPosition.dx) / containerWidth;
    final deltaY = details.globalPosition.dy - dragState.dragStartPosition.dy;

    // Calculate new position for visual feedback
    final newX = (dragState.dragStartFieldPosition.dx + deltaX).clamp(0.0, 1.0 - config.width);
    final newY = (dragState.dragStartFieldPosition.dy + deltaY).clamp(
      0.0,
      MagneticCardSystem.maxRows * MagneticCardSystem.cardHeight,
    );

    final newPosition = Offset(newX, newY);
    
    // Debug field2 drag calculation
    if (fieldId == 'field2') {
      print('FIELD2 DRAG DEBUG: dragStartFieldPosition=${dragState.dragStartFieldPosition.dx}, deltaX=$deltaX, newX=$newX');
    }

    // Get hovered grid position
    final gridPosition = MagneticCardSystem.getGridPosition(newPosition, containerWidth);

    return DragUpdateResult(
      newPosition: newPosition,
      hoveredColumn: gridPosition.column,
      hoveredRow: gridPosition.row,
      hasMovedBeyondThreshold: hasMovedBeyondThreshold,
      shouldShowPreview: hasMovedBeyondThreshold,
    );
  }

  /// Detect drop zone based on position
  static DropZoneResult detectDropZone({
    required Offset position,
    required double containerWidth,
  }) {
    final gridPosition = MagneticCardSystem.getGridPosition(position, containerWidth);
    final row = gridPosition.row;
    final column = gridPosition.column;
    
    // Calculate relative position within the row
    final rowY = row * MagneticCardSystem.cardHeight;
    final relativeY = (position.dy - rowY) / MagneticCardSystem.cardHeight;
    
    // Push down zones (top/bottom 10% of row)
    if (relativeY < 0.1 || relativeY > 0.9) {
      return DropZoneResult(zone: DropZone.pushDown, row: row, column: column);
    }
    
    // Drop zones in middle 60% of row based on horizontal position
    final x = position.dx;
    DropZone zone;
    if (x < 0.35) {           // Left zone: 0-35% (was 0-33%)
      zone = DropZone.leftDrop;
    } else if (x < 0.65) {    // Center zone: 35-65% (was 33-67%)
      zone = DropZone.centerDrop;
    } else {                  // Right zone: 65-100% (was 67-100%)
      zone = DropZone.rightDrop;
    }
    
    return DropZoneResult(zone: zone, row: row, column: column);
  }

  /// Handle field drag end
  static DragEndResult handleFieldDragEnd({
    required String fieldId,
    required Map<String, FieldConfig> fieldConfigs,
    required double containerWidth,
    required PreviewState previewState,
  }) {
    Logger.preview('Ending drag for field $fieldId');

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
      final wouldOverlap = GridUtils.wouldFieldOverlap(
        testConfig,
        fieldConfigs,
        fieldId,
        containerWidth,
      );

      final finalPosition = wouldOverlap
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
}

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
      dragStartFieldPosition: dragStartFieldPosition ?? this.dragStartFieldPosition,
      hasMovedBeyondThreshold: hasMovedBeyondThreshold ?? this.hasMovedBeyondThreshold,
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

/// Drop zones for clear behavior definition
enum DropZone {
  leftDrop,   // Left third - push fields right
  centerDrop, // Center third - split fields
  rightDrop,  // Right third - push fields left
  pushDown,   // Top/bottom 20% - push to next row
}

/// Result of drop zone detection
class DropZoneResult {
  final DropZone zone;
  final int row;
  final int column;

  const DropZoneResult({
    required this.zone,
    required this.row,
    required this.column,
  });
}