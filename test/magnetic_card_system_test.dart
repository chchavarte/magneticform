import 'package:flutter_test/flutter_test.dart';
import 'package:magnetic_form_builder/src/models/magnetic_card_system.dart';
import 'package:magnetic_form_builder/src/models/field_config.dart';

void main() {
  group('MagneticCardSystem', () {
    const double containerWidth = 600.0;
    late Map<String, FieldConfig> testConfigs;

    setUp(() {
      testConfigs = {
        'field1': FieldConfig(
          id: 'field1',
          width: 2/6, // 2 columns
          position: const Offset(0, 0), // Row 0, columns 0-1
        ),
        'field2': FieldConfig(
          id: 'field2',
          width: 3/6, // 3 columns
          position: const Offset(0, 70), // Row 1, columns 0-2
        ),
      };
    });

    test('should calculate magnetic snap position correctly', () {
      // Test snapping to grid positions
      final snapPos1 = MagneticCardSystem.getMagneticSnapPosition(
        const Offset(0.05, 35), // Near column 0, row 0.5
        containerWidth,
      );
      expect(snapPos1.dx, 0.0); // Should snap to column 0
      expect(snapPos1.dy, 70.0); // Should snap to row 1

      final snapPos2 = MagneticCardSystem.getMagneticSnapPosition(
        const Offset(0.9, 140), // Near column 5, row 2
        containerWidth,
      );
      expect(snapPos2.dx, 5/6); // Should snap to column 5
      expect(snapPos2.dy, 140.0); // Should snap to row 2
    });

    test('should calculate magnetic width correctly', () {
      // Test width snapping to valid card widths
      expect(MagneticCardSystem.getMagneticWidth(0.3), 2/6); // Should snap to 2/6
      expect(MagneticCardSystem.getMagneticWidth(0.45), 3/6); // Should snap to 3/6
      expect(MagneticCardSystem.getMagneticWidth(0.7), 4/6); // Should snap to 4/6
      expect(MagneticCardSystem.getMagneticWidth(0.9), 6/6); // Should snap to 6/6
    });

    test('should detect column from position correctly', () {
      expect(MagneticCardSystem.getColumnFromPosition(0.0, containerWidth), 0);
      expect(MagneticCardSystem.getColumnFromPosition(0.16, containerWidth), 0);
      expect(MagneticCardSystem.getColumnFromPosition(0.17, containerWidth), 1);
      expect(MagneticCardSystem.getColumnFromPosition(0.5, containerWidth), 3);
      expect(MagneticCardSystem.getColumnFromPosition(0.83, containerWidth), 4);
      expect(MagneticCardSystem.getColumnFromPosition(1.0, containerWidth), 5);
    });

    test('should calculate columns from width correctly', () {
      expect(MagneticCardSystem.getColumnsFromWidth(2/6), 2);
      expect(MagneticCardSystem.getColumnsFromWidth(3/6), 3);
      expect(MagneticCardSystem.getColumnsFromWidth(4/6), 4);
      expect(MagneticCardSystem.getColumnsFromWidth(6/6), 6);
    });

    test('should detect overlap correctly', () {
      // Test overlap detection
      final wouldOverlap1 = MagneticCardSystem.wouldOverlap(
        const Offset(0, 0), // Same position as field1
        2/6, // Same width as field1
        containerWidth,
        testConfigs,
        'field2', // Exclude field2
      );
      expect(wouldOverlap1, true); // Should overlap with field1

      final wouldOverlap2 = MagneticCardSystem.wouldOverlap(
        const Offset(2/6, 0), // Different position from field1
        2/6, // Same width as field1
        containerWidth,
        testConfigs,
        'field2', // Exclude field2
      );
      expect(wouldOverlap2, false); // Should not overlap

      final wouldOverlap3 = MagneticCardSystem.wouldOverlap(
        const Offset(0, 70), // Same position as field2
        3/6, // Same width as field2
        containerWidth,
        testConfigs,
        'field1', // Exclude field1
      );
      expect(wouldOverlap3, true); // Should overlap with field2
    });

    test('should find next available position correctly', () {
      // Test finding available position
      final nextPos = MagneticCardSystem.findNextAvailablePosition(
        2/6, // 2 columns width
        containerWidth,
        testConfigs,
        'new_field',
      );

      // Should find position at columns 2-3 in row 0 (after field1)
      expect(nextPos.dx, 2/6);
      expect(nextPos.dy, 0);
    });

    test('should calculate grid position correctly', () {
      final gridPos = MagneticCardSystem.getGridPosition(
        const Offset(2/6, 140), // Column 2, row 2
        containerWidth,
      );
      expect(gridPos.column, 2);
      expect(gridPos.row, 2);
    });

    test('should calculate resize info correctly', () {
      final resizeInfo = MagneticCardSystem.getResizeInfo(
        const Offset(1/6, 70), // Column 1, row 1
        4/6, // 4 columns width
        containerWidth,
      );
      expect(resizeInfo.startColumn, 1);
      expect(resizeInfo.columnSpan, 4);
      expect(resizeInfo.actualWidth, 4/6);
    });

    test('should calculate row occupancy correctly', () {
      final occupancy = MagneticCardSystem.getRowOccupancy(
        testConfigs,
        containerWidth,
      );

      // Row 0 should have field1
      expect(occupancy[0]?.length, 1);
      expect(occupancy[0]?[0]['fieldId'], 'field1');
      expect(occupancy[0]?[0]['startColumn'], 0);
      expect(occupancy[0]?[0]['columnSpan'], 2);

      // Row 1 should have field2
      expect(occupancy[1]?.length, 1);
      expect(occupancy[1]?[0]['fieldId'], 'field2');
      expect(occupancy[1]?[0]['startColumn'], 0);
      expect(occupancy[1]?[0]['columnSpan'], 3);
    });
  });
}