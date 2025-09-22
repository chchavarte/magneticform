import 'package:flutter/material.dart';
import 'field_models.dart';
import '../constants/magnetic_constants.dart';

// Magnetic card system for snapping fields
class MagneticCardSystem {
  // Use constants from MagneticConstants to avoid duplication
  static const double cardHeight = MagneticConstants.cardHeight;
  static const int maxRows = MagneticConstants.maxRows;
  static const double snapThreshold = MagneticConstants.snapThreshold;
  static const double fieldGap = MagneticConstants.fieldGap;
  static const List<double> cardWidths = MagneticConstants.cardWidths;

  static Offset getMagneticSnapPosition(
    Offset currentPos,
    double containerWidth,
  ) {
    final targetRow = (currentPos.dy / cardHeight).round().clamp(
      0,
      maxRows - 1,
    );
    final snappedY = targetRow * cardHeight;

    // Snap to grid positions based on sixths for 6-column grid
    // currentPos.dx is normalized (0.0-1.0), so multiply by 6 to get column
    final targetSlot = (currentPos.dx * 6).round().clamp(0, 5);
    final snappedX = targetSlot / 6.0; // Convert back to normalized position

    return Offset(snappedX, snappedY);
  }

  static double getMagneticWidth(double currentWidth) {
    double closestWidth = cardWidths.first;
    double minDifference = (currentWidth - closestWidth).abs();

    for (final cardWidth in cardWidths) {
      final difference = (currentWidth - cardWidth).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestWidth = cardWidth;
      }
    }

    return closestWidth;
  }

  static bool isInMagneticRange(Offset current, Offset target) {
    return (current - target).distance <= snapThreshold;
  }

  // Get the actual column span based on width and starting position
  static int getActualColumnSpan(double width, int startColumn) {
    final baseSpan = FieldConfig.getColumnsFromWidth(width);
    // Ensure we don't exceed the grid (6 columns max)
    return (startColumn + baseSpan <= 6) ? baseSpan : (6 - startColumn);
  }



  // Helper method to get both column and row from position
  static ({int column, int row}) getGridPosition(
    Offset position,
    double containerWidth,
  ) {
    return (
      column: FieldConfig.getColumnFromPosition(position.dx, containerWidth),
      row: FieldConfig.getRowFromPosition(position.dy),
    );
  }

  // Helper method for resize calculations
  static ({int startColumn, int columnSpan, double actualWidth}) getResizeInfo(
    Offset position,
    double width,
    double containerWidth,
  ) {
    final startColumn = FieldConfig.getColumnFromPosition(position.dx, containerWidth);
    final columnSpan = getActualColumnSpan(width, startColumn);
    final actualWidth = columnSpan / 6.0; // Convert span to width percentage
    return (
      startColumn: startColumn,
      columnSpan: columnSpan,
      actualWidth: actualWidth,
    );
  }

  // Check if a field placement would cause overlap
  static bool wouldOverlap(
    Offset newPosition,
    double newWidth,
    double containerWidth,
    Map<String, FieldConfig> existingFields,
    String excludeFieldId,
  ) {
    print('🔍 DEBUG OVERLAP CHECK:');
    print('  Testing field: $excludeFieldId');
    print('  New position: ${newPosition.dx}, width: $newWidth');
    print('  Container width: $containerWidth');
    
    final newRow = FieldConfig.getRowFromPosition(newPosition.dy);
    final newStartColumn = FieldConfig.getColumnFromPosition(
      newPosition.dx,
      containerWidth,
    );
    final newColumnSpan = getActualColumnSpan(newWidth, newStartColumn);
    final newEndColumn = newStartColumn + newColumnSpan - 1;

    print('  New field: row=$newRow, columns $newStartColumn-$newEndColumn (span: $newColumnSpan)');
    print('  New field actual positions: ${newPosition.dx} to ${newPosition.dx + newWidth}');

    // Check against all existing fields in the same row
    for (final entry in existingFields.entries) {
      if (entry.key == excludeFieldId) continue; // Skip the field being moved

      final config = entry.value;
      // Skip hidden fields
      if (!config.isVisible) continue;

      final existingRow = FieldConfig.getRowFromPosition(config.position.dy);
      if (existingRow != newRow) continue; // Different row, no conflict

      final existingStartColumn = FieldConfig.getColumnFromPosition(
        config.position.dx,
        containerWidth,
      );
      final existingColumnSpan = getActualColumnSpan(
        config.width,
        existingStartColumn,
      );
      final existingEndColumn = existingStartColumn + existingColumnSpan - 1;

      print('  Existing field ${entry.key}: row=$existingRow, columns $existingStartColumn-$existingEndColumn');
      print('  Existing field actual positions: ${config.position.dx} to ${config.position.dx + config.width}');

      // Use actual position-based overlap detection instead of column-based
      // This fixes the bug where fields touching at exact boundaries were incorrectly flagged as overlapping
      final actualOverlap = !(newPosition.dx + newWidth <= config.position.dx || 
                             newPosition.dx >= config.position.dx + config.width);
      
      print('  Position-based overlap: !(${newPosition.dx + newWidth} <= ${config.position.dx} || ${newPosition.dx} >= ${config.position.dx + config.width}) = $actualOverlap');

      if (actualOverlap) {
        print('  ❌ OVERLAP DETECTED with ${entry.key}!');
        print('  Position-based overlap: $actualOverlap');
        return true; // Overlap detected
      }
    }

    print('  ✅ No overlap found');
    return false; // No overlap
  }

  // Find the next available position for a field
  static Offset findNextAvailablePosition(
    double fieldWidth,
    double containerWidth,
    Map<String, FieldConfig> existingFields,
    String excludeFieldId, {
    int startFromRow = 0,
  }) {
    final columnSpan = FieldConfig.getColumnsFromWidth(fieldWidth);

    for (int row = startFromRow; row < maxRows; row++) {
      // Try each possible starting column in this row (6-column grid)
      for (int startCol = 0; startCol <= 6 - columnSpan; startCol++) {
        final testPosition = Offset(
          FieldConfig.getColumnPositionNormalized(
            startCol,
          ), // Use proper 6-column positioning
          row * cardHeight,
        );

        if (!wouldOverlap(
          testPosition,
          fieldWidth,
          containerWidth,
          existingFields,
          excludeFieldId,
        )) {
          return testPosition;
        }
      }
    }

    // If no space found, place at bottom
    final bottomRow =
        existingFields.values
            .where((config) => config.isVisible)
            .map((config) => FieldConfig.getRowFromPosition(config.position.dy))
            .fold(0, (max, row) => row > max ? row : max) +
        1;

    return Offset(0, bottomRow * cardHeight);
  }

  // Get row occupancy information for visualization
  static Map<int, List<Map<String, dynamic>>> getRowOccupancy(
    Map<String, FieldConfig> fields,
    double containerWidth,
  ) {
    final Map<int, List<Map<String, dynamic>>> occupancy = {};

    for (final entry in fields.entries) {
      final config = entry.value;
      if (!config.isVisible) continue;

      final row = FieldConfig.getRowFromPosition(config.position.dy);
      final startColumn = FieldConfig.getColumnFromPosition(
        config.position.dx,
        containerWidth,
      );
      final columnSpan = getActualColumnSpan(config.width, startColumn);

      occupancy[row] ??= [];
      occupancy[row]!.add({
        'fieldId': entry.key,
        'startColumn': startColumn,
        'columnSpan': columnSpan,
        'endColumn': startColumn + columnSpan - 1,
      });
    }

    return occupancy;
  }

  // Calculate effective width accounting for gaps
  static double getEffectiveWidth(
    double containerWidth,
    double widthPercentage,
    double positionX,
  ) {
    final baseWidth = widthPercentage * containerWidth;
    // Subtract gap if not in first column
    return positionX > 0 ? baseWidth - fieldGap : baseWidth;
  }

  // Calculate available space accounting for gaps between fields
  static double getAvailableSpaceWithGaps(
    double containerWidth,
    List<FieldConfig> fieldsInRow,
  ) {
    if (fieldsInRow.isEmpty) return 1.0;

    double totalOccupied = 0.0;
    int gapCount = 0;

    for (final field in fieldsInRow) {
      totalOccupied += field.width;
      if (field.position.dx > 0) {
        gapCount++; // Count gaps for non-first-column fields
      }
    }

    // Account for gap space in percentage terms
    final gapSpacePercentage = (gapCount * fieldGap) / containerWidth;
    return (1.0 - totalOccupied - gapSpacePercentage).clamp(0.0, 1.0);
  }
}