import 'package:flutter/material.dart';
import 'package:field_collision_test/core/constants/field_constants.dart';
import 'package:field_collision_test/core/utils/logger.dart';
import '../systems/grid_utils.dart';
import '../systems/field_preview_system.dart';
import '../../data/models/field_config.dart';
import '../../data/models/magnetic_card_system.dart';

/// Handles auto-expansion of fields to fill gaps
class AutoExpandHandler {
  // Private constructor to prevent instantiation
  AutoExpandHandler._();

  /// Auto-expand fields to fill remaining gaps after drag operations
  static void autoExpandToFillGaps({
    required Map<String, FieldConfig> fieldConfigs,
    required TickerProvider vsync,
    required Function(Map<String, FieldConfig>) onUpdate,
    required VoidCallback onComplete,
  }) {
    Logger.autoExpand('Starting auto-expand to fill gaps');

    // Find all rows that have fields using utility method
    final fieldsByRow = GridUtils.groupFieldsByRow(fieldConfigs);

    Map<String, FieldConfig> expandedConfigs = {};
    bool hasExpansions = false;

    // Check each row for gaps and expand fields
    for (final entry in fieldsByRow.entries) {
      final row = entry.key;
      final fieldsInRow = entry.value;

      Logger.autoExpand('Checking row $row with ${fieldsInRow.length} fields');

      // Calculate available space in this row using utility method
      final availableSpace = GridUtils.calculateRowAvailableSpace(
        row,
        fieldConfigs,
      );

      Logger.autoExpand('Available space: ${(availableSpace * 100).toInt()}%');

      if (availableSpace > FieldConstants.significantGapThreshold) {
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
      Logger.autoExpand('Applying ${expandedConfigs.length} field expansions');

      // Create final configs with expansions
      final finalConfigs = Map<String, FieldConfig>.from(fieldConfigs);
      for (final entry in expandedConfigs.entries) {
        finalConfigs[entry.key] = entry.value;
      }

      // Animate the expansions
      FieldPreviewSystem.animateToCommit(
        vsync: vsync,
        fromConfigs: fieldConfigs,
        toConfigs: finalConfigs,
        onUpdate: onUpdate,
        onComplete: () {
          Logger.autoExpand('Auto-expansion complete');
          onComplete();
        },
      );
    } else {
      Logger.autoExpand('No gaps found to fill');
      onComplete();
    }
  }

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
      Logger.autoExpand(
        'Single field in row, expanding ${fieldsInRow.first} to 100%',
      );
      return {fieldsInRow.first: FieldConstants.fullWidth};
    }

    // Check if all fields have equal or similar widths (within 5% tolerance)
    final fieldWidths =
        fieldsInRow.map((id) => fieldConfigs[id]!.width).toList();
    final avgWidth = fieldWidths.reduce((a, b) => a + b) / fieldWidths.length;
    final isEqualWidths = fieldWidths.every(
      (width) =>
          (width - avgWidth).abs() < FieldConstants.significantGapThreshold,
    );

    Logger.autoExpand(
      'Field widths: ${fieldWidths.map((w) => '${(w * 100).toInt()}%').join(', ')}',
    );
    Logger.autoExpand(
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
    Logger.autoExpand('Equal widths detected - redistributing equally');
    final newWidth = FieldConstants.fullWidth / fieldsInRow.length;
    final redistributions = <String, double>{};

    for (final fieldId in fieldsInRow) {
      redistributions[fieldId] = newWidth;
    }

    Logger.autoExpand(
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
    Logger.autoExpand('Unequal widths detected - using gap-filling strategy');

    final gaps = _findGapsInRow(row, fieldsInRow, fieldConfigs);
    if (gaps.isEmpty) return null;

    // Find the largest gap
    var largestGap = gaps.reduce((a, b) => a.size > b.size ? a : b);
    Logger.autoExpand(
      'Largest gap: ${(largestGap.size * 100).toInt()}% at position ${largestGap.position}',
    );

    // Check for different types of gaps
    final hasLeftGap = gaps.any(
      (gap) =>
          gap.position < 0.05 &&
          gap.size > FieldConstants.significantGapThreshold,
    );

    final hasMiddleGap = gaps.any(
      (gap) =>
          gap.position > 0.05 &&
          gap.position < 0.95 &&
          gap.size > FieldConstants.significantGapThreshold,
    );

    if ((hasLeftGap || hasMiddleGap) && fieldsInRow.length > 1) {
      // When there's a gap at the beginning or middle, redistribute all fields equally
      Logger.autoExpand(
        hasLeftGap
            ? 'Gap at beginning detected - redistributing all fields equally'
            : 'Gap in middle detected - redistributing all fields equally',
      );
      return _createEqualDistribution(fieldsInRow);
    }

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
        FieldConstants.fullWidth,
      );
      final snappedWidth = MagneticCardSystem.getMagneticWidth(newWidth);

      Logger.autoExpand(
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
                  MagneticCardSystem.getRowFromPosition(config.position.dy) ==
                  row,
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

      if (gapSize > FieldConstants.significantGapThreshold) {
        gaps.add((position: currentEnd, size: gapSize));
      }
    }

    // Check gap at the end
    if (fieldConfigsList.isNotEmpty) {
      final lastEnd =
          fieldConfigsList.last.position.dx + fieldConfigsList.last.width;
      if (lastEnd < 0.95) {
        gaps.add((position: lastEnd, size: FieldConstants.fullWidth - lastEnd));
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

    Logger.autoExpand(
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
          FieldConstants.widthChangeThreshold) {
        Logger.autoExpand(
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
          // Single field expansion - check if we need to reposition due to gaps
          final gaps = _findGapsInRow(row, fieldsInRow, fieldConfigs);
          final hasLeftGap = gaps.any(
            (gap) =>
                gap.position < 0.05 &&
                gap.size > FieldConstants.significantGapThreshold,
          );

          final hasMiddleGap = gaps.any(
            (gap) =>
                gap.position > 0.05 &&
                gap.position < 0.95 &&
                gap.size > FieldConstants.significantGapThreshold,
          );

          if (hasLeftGap) {
            // Move field to start of row and expand
            _expandFieldToFillRow(
              fieldId,
              newWidth,
              row,
              fieldConfigs,
              expandedConfigs,
            );
          } else if (hasMiddleGap) {
            // For middle gaps, this shouldn't happen as we should use redistribution
            // But fallback to standard expansion
            Logger.autoExpand(
              'Middle gap detected in single field expansion - using standard expansion',
            );
            _expandSingleField(
              fieldId,
              newWidth,
              row,
              currentConfig,
              expandedConfigs,
            );
          } else {
            // Standard single field expansion
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
      final maxAllowedX = FieldConstants.fullWidth - newWidth;

      if (currentX + newWidth > FieldConstants.fullWidth) {
        newPosition = Offset(maxAllowedX, row * MagneticCardSystem.cardHeight);
        Logger.autoExpand(
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

  /// Expand a field to fill row starting from left edge
  static void _expandFieldToFillRow(
    String fieldId,
    double newWidth,
    int row,
    Map<String, FieldConfig> fieldConfigs,
    Map<String, FieldConfig> expandedConfigs,
  ) {
    // Always position at start of row when filling from left
    final newPosition = Offset(0.0, row * MagneticCardSystem.cardHeight);
    final currentConfig = fieldConfigs[fieldId]!;

    Logger.autoExpand(
      'Moving $fieldId to start of row and expanding to ${(newWidth * 100).toInt()}%',
    );

    expandedConfigs[fieldId] = currentConfig.copyWith(
      width: newWidth,
      position: newPosition,
    );
  }
}
