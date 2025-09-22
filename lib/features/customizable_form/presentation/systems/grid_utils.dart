import 'package:flutter/material.dart';
import 'package:field_collision_test/core/utils/logger.dart';
import '../../data/models/field_config.dart';
import '../../data/models/magnetic_card_system.dart';

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

/// Utility class to consolidate redundant grid calculation methods
/// and provide higher-level abstractions for common operations
class GridUtils {
  // Private constructor to prevent instantiation
  GridUtils._();



  /// Get complete grid information for a field configuration
  static FieldGridInfo getFieldGridInfo(
    FieldConfig config,
    double containerWidth,
  ) {
    final row = MagneticCardSystem.getRowFromPosition(config.position.dy);
    final startColumn = MagneticCardSystem.getColumnFromPosition(
      config.position.dx,
      containerWidth,
    );
    final columnSpan = MagneticCardSystem.getColumnsFromWidth(config.width);
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
      
      final row = MagneticCardSystem.getRowFromPosition(config.position.dy);
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
      
      final row = MagneticCardSystem.getRowFromPosition(config.position.dy);
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
      
      final row = MagneticCardSystem.getRowFromPosition(config.position.dy);
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
    final columnSpan = MagneticCardSystem.getColumnsFromWidth(fieldWidth);
    
    // Try each possible starting column in the target row
    for (int startCol = 0; startCol <= 6 - columnSpan; startCol++) {
      final testPosition = Offset(
        MagneticCardSystem.getColumnPositionNormalized(startCol),
        targetRow * MagneticCardSystem.cardHeight,
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
  static Offset? findAvailablePositionInRow(
    int targetRow,
    double fieldWidth,
    Map<String, FieldConfig> fieldConfigs,
    double containerWidth, {
    String? excludeFieldId,
  }) {
    final columnSpan = MagneticCardSystem.getColumnsFromWidth(fieldWidth);
    
    // Try each possible starting column in the target row
    for (int startCol = 0; startCol <= 6 - columnSpan; startCol++) {
      final testPosition = Offset(
        MagneticCardSystem.getColumnPositionNormalized(startCol),
        targetRow * MagneticCardSystem.cardHeight,
      );

      final hasOverlap = MagneticCardSystem.wouldOverlap(
        testPosition,
        fieldWidth,
        containerWidth,
        fieldConfigs,
        excludeFieldId ?? '',
      );

      if (!hasOverlap) {
        return testPosition; // Found available position
      }
    }
    return null; // No available position found
  }

  /// Print field configurations in a consistent format
  static void printFieldConfigs(
    String title,
    Map<String, FieldConfig> fieldConfigs,
    double containerWidth,
  ) {
    Logger.grid(title);
    for (final entry in fieldConfigs.entries) {
      final config = entry.value;
      final gridInfo = getFieldGridInfo(config, containerWidth);
      Logger.grid('  ${entry.key}: $gridInfo');
    }
  }

  /// Validate that a field configuration is within grid boundaries
  static bool isValidFieldConfig(
    FieldConfig config,
    double containerWidth,
  ) {
    final gridInfo = getFieldGridInfo(config, containerWidth);
    
    // Check if field is within grid boundaries
    if (gridInfo.row < 0 || gridInfo.row >= MagneticCardSystem.maxRows) {
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
      
      final row = MagneticCardSystem.getRowFromPosition(config.position.dy);
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
      MagneticCardSystem.getColumnPositionNormalized(startColumn),
      row * MagneticCardSystem.cardHeight,
    );
    
    return FieldConfig(
      id: fieldId,
      width: width,
      position: position,
    );
  }
}