import 'package:flutter/material.dart';

// Resize direction enum
enum ResizeDirection { left, right }

// Field configuration model
class FieldConfig {
  final String id;
  final double width; // 0.0 to 1.0 (percentage of parent width)
  final Offset position;

  FieldConfig({
    required this.id,
    this.width = 1.0,
    this.position = Offset.zero,
  });

  FieldConfig copyWith({String? id, double? width, Offset? position}) {
    return FieldConfig(
      id: id ?? this.id,
      width: width ?? this.width,
      position: position ?? this.position,
    );
  }

  // Helper method to check if field is visible/active
  bool get isVisible => width > 0 && position.dx >= 0 && position.dy >= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'width': width,
      'positionX': position.dx,
      'positionY': position.dy,
    };
  }

  factory FieldConfig.fromMap(Map<String, dynamic> map) {
    return FieldConfig(
      id: map['id'],
      width: map['width'],
      position: Offset(map['positionX'], map['positionY']),
    );
  }
}

// Magnetic card system for snapping fields
class MagneticCardSystem {
  static const double cardHeight = 70.0;
  static const int maxRows = 12;
  static const double snapThreshold = 30.0;
  static const double fieldGap = 4.0;

  // Base widths for 6-column grid (2, 3, 4, 6 columns)
  static const List<double> cardWidths = [
    2 / 6, // 2 columns (1/3 width)
    3 / 6, // 3 columns (1/2 width)
    4 / 6, // 4 columns (2/3 width)
    6 / 6, // 6 columns (full width)
  ];

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

  // Column-aware overlap detection
  static int getColumnFromPosition(double xPosition, double containerWidth) {
    // 6-column grid: proper boundary detection
    // Column boundaries: 0-0.167, 0.167-0.333, 0.333-0.5, 0.5-0.667, 0.667-0.833, 0.833-1.0
    final column = (xPosition * 6).floor().clamp(0, 5);
    return column;
  }

  static int getColumnsFromWidth(double width) {
    // Width to column span mapping for 6-column grid
    // Use precise fractions to avoid rounding issues
    if (width <= 2 / 6 + 0.001) return 2; // 2/6 width = 2 columns
    if (width <= 3 / 6 + 0.001) return 3; // 3/6 width = 3 columns
    if (width <= 4 / 6 + 0.001) return 4; // 4/6 width = 4 columns
    return 6; // 6/6 width = 6 columns (full row)
  }

  // Get the actual column span based on width and starting position
  static int getActualColumnSpan(double width, int startColumn) {
    final baseSpan = getColumnsFromWidth(width);
    // Ensure we don't exceed the grid (6 columns max)
    return (startColumn + baseSpan <= 6) ? baseSpan : (6 - startColumn);
  }

  static int getRowFromPosition(double yPosition) {
    return (yPosition / cardHeight).round();
  }

  // Helper method for normalized column position calculation
  static double getColumnPositionNormalized(int column) {
    return column / 6.0; // Convert column index to normalized position (0-1)
  }

  // Helper method for column width calculation
  static double getColumnWidth(double containerWidth) {
    return containerWidth / 6; // 6-column grid
  }

  // Helper method for position from column index
  static double getPositionFromColumn(int column, double containerWidth) {
    return (column * containerWidth / 6) / containerWidth; // Normalize to 0-1
  }

  // Helper method to get both column and row from position
  static ({int column, int row}) getGridPosition(
    Offset position,
    double containerWidth,
  ) {
    return (
      column: getColumnFromPosition(position.dx, containerWidth),
      row: getRowFromPosition(position.dy),
    );
  }

  // Helper method for resize calculations
  static ({int startColumn, int columnSpan, double actualWidth}) getResizeInfo(
    Offset position,
    double width,
    double containerWidth,
  ) {
    final startColumn = getColumnFromPosition(position.dx, containerWidth);
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
    final newRow = getRowFromPosition(newPosition.dy);
    final newStartColumn = getColumnFromPosition(
      newPosition.dx,
      containerWidth,
    );
    final newColumnSpan = getActualColumnSpan(newWidth, newStartColumn);
    final newEndColumn = newStartColumn + newColumnSpan - 1;

    print(
      'DEBUG OVERLAP: Testing position ${newPosition.dx} -> columns $newStartColumn-$newEndColumn (span: $newColumnSpan)',
    );

    // Check against all existing fields in the same row
    for (final entry in existingFields.entries) {
      if (entry.key == excludeFieldId) continue; // Skip the field being moved

      final config = entry.value;
      // Skip hidden fields
      if (!config.isVisible) continue;

      final existingRow = getRowFromPosition(config.position.dy);
      if (existingRow != newRow) continue; // Different row, no conflict

      final existingStartColumn = getColumnFromPosition(
        config.position.dx,
        containerWidth,
      );
      final existingColumnSpan = getActualColumnSpan(
        config.width,
        existingStartColumn,
      );
      final existingEndColumn = existingStartColumn + existingColumnSpan - 1;

      print(
        'DEBUG OVERLAP: Existing field ${entry.key} at position ${config.position.dx} -> columns $existingStartColumn-$existingEndColumn',
      );

      // Check for column overlap
      final wouldOverlapResult =
          !(newEndColumn < existingStartColumn ||
              newStartColumn > existingEndColumn);

      print(
        'DEBUG OVERLAP: Overlap check: !($newEndColumn < $existingStartColumn || $newStartColumn > $existingEndColumn) = $wouldOverlapResult',
      );

      if (wouldOverlapResult) {
        print('DEBUG OVERLAP: OVERLAP DETECTED!');
        return true; // Overlap detected
      }
    }

    print('DEBUG OVERLAP: No overlap found');
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
    final columnSpan = getColumnsFromWidth(fieldWidth);

    for (int row = startFromRow; row < maxRows; row++) {
      // Try each possible starting column in this row (6-column grid)
      for (int startCol = 0; startCol <= 6 - columnSpan; startCol++) {
        final testPosition = Offset(
          getColumnPositionNormalized(
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
            .map((config) => getRowFromPosition(config.position.dy))
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

      final row = getRowFromPosition(config.position.dy);
      final startColumn = getColumnFromPosition(
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

// Field definition for the form
class CustomFormField {
  final String id;
  final String label;
  final IconData icon;
  final Widget Function(BuildContext context, bool isCustomizationMode) builder;
  final bool isMandatory;
  final String? defaultValue;

  const CustomFormField({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
    this.isMandatory = false,
    this.defaultValue,
  });
}
