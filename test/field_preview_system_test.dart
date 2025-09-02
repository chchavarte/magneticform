import 'package:flutter_test/flutter_test.dart';
import 'package:field_collision_test/features/customizable_form/presentation/systems/field_preview_system.dart';
import 'package:field_collision_test/features/customizable_form/data/models/field_config.dart';

void main() {
  group('FieldPreviewSystem', () {
    late Map<String, FieldConfig> testConfigs;
    const double containerWidth = 600.0;

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

    test('should detect available space in row', () {
      // Row 0 has field1 (columns 0-1), so columns 2-5 are available
      final hasSpace = FieldPreviewSystem.hasSpaceInRow(
        targetRow: 0,
        excludeFieldId: 'field2',
        fieldWidth: 3/6, // 3 columns
        currentConfigs: testConfigs,
        containerWidth: containerWidth,
      );

      expect(hasSpace, true);
    });

    test('should detect no space when row is full', () {
      // Add a field that fills the remaining space in row 0
      testConfigs['field3'] = FieldConfig(
        id: 'field3',
        width: 4/6, // 4 columns
        position: const Offset(2/6, 0), // Row 0, columns 2-5
      );

      final hasSpace = FieldPreviewSystem.hasSpaceInRow(
        targetRow: 0,
        excludeFieldId: 'field2',
        fieldWidth: 3/6, // 3 columns - won't fit
        currentConfigs: testConfigs,
        containerWidth: containerWidth,
      );

      expect(hasSpace, false);
    });

    test('should calculate correct preview positions', () {
      final previewConfigs = FieldPreviewSystem.calculatePreviewPositions(
        targetRow: 0,
        draggedFieldId: 'field2',
        currentConfigs: testConfigs,
        containerWidth: containerWidth,
      );

      // field2 should be auto-resized to 4 columns (expanded from 3) and positioned at columns 2-5 in row 0
      expect(previewConfigs['field2']?.position.dy, 0); // Row 0
      expect(previewConfigs['field2']?.position.dx, 2/6); // Column 2
      expect(previewConfigs['field2']?.width, 4/6); // Expanded to 4 columns

      // field1 should remain unchanged
      expect(previewConfigs['field1']?.position, testConfigs['field1']?.position);
    });

    test('should provide correct preview info', () {
      final previewInfo = FieldPreviewSystem.getPreviewInfo(
        targetRow: 0,
        draggedFieldId: 'field2',
        currentConfigs: testConfigs,
        containerWidth: containerWidth,
      );

      expect(previewInfo.hasSpace, true);
      expect(previewInfo.targetPosition?.dy, 0); // Row 0
      expect(previewInfo.targetPosition?.dx, 2/6); // Column 2
      expect(previewInfo.targetColumns?.start, 2); // Start at column 2
      expect(previewInfo.targetColumns?.span, 4); // Expanded to 4 columns
      expect(previewInfo.message, contains('columns 3-6')); // Human-readable (1-indexed)
      expect(previewInfo.isPushDown, false); // Auto-resize, not push down
    });

    test('should handle empty row correctly', () {
      final previewConfigs = FieldPreviewSystem.calculatePreviewPositions(
        targetRow: 2, // Empty row
        draggedFieldId: 'field2',
        currentConfigs: testConfigs,
        containerWidth: containerWidth,
      );

      // field2 should be positioned at the start of row 2
      expect(previewConfigs['field2']?.position.dy, 2 * 70); // Row 2
      expect(previewConfigs['field2']?.position.dx, 0); // Column 0
    });

    test('should handle push down when no space available', () {
      // Fill row 0 completely
      testConfigs['field3'] = FieldConfig(
        id: 'field3',
        width: 4/6, // 4 columns
        position: const Offset(2/6, 0), // Row 0, columns 2-5
      );

      final previewConfigs = FieldPreviewSystem.calculatePreviewPositions(
        targetRow: 0, // Target row 0 (full)
        draggedFieldId: 'field2',
        currentConfigs: testConfigs,
        containerWidth: containerWidth,
      );

      // field2 should be placed at start of row 0
      expect(previewConfigs['field2']?.position.dy, 0); // Row 0
      expect(previewConfigs['field2']?.position.dx, 0); // Column 0

      // field1 should be pushed down to row 1
      expect(previewConfigs['field1']?.position.dy, 70); // Row 1
      expect(previewConfigs['field1']?.position.dx, 0); // Same column

      // field3 should be pushed down to row 1
      expect(previewConfigs['field3']?.position.dy, 70); // Row 1
      expect(previewConfigs['field3']?.position.dx, 2/6); // Same column
    });

    test('should auto-resize to fit available space (expand)', () {
      // Row 0 has field1 (2 columns), leaving 4 columns available
      // field2 (3 columns) should expand to 4 columns to fill the space
      final previewConfigs = FieldPreviewSystem.calculatePreviewPositions(
        targetRow: 0,
        draggedFieldId: 'field2',
        currentConfigs: testConfigs,
        containerWidth: containerWidth,
      );

      // field2 should be expanded to 4 columns and placed at columns 2-5
      expect(previewConfigs['field2']?.position.dy, 0); // Row 0
      expect(previewConfigs['field2']?.position.dx, 2/6); // Column 2
      expect(previewConfigs['field2']?.width, 4/6); // Expanded to 4 columns

      // field1 should remain unchanged
      expect(previewConfigs['field1']?.position, testConfigs['field1']?.position);
    });

    test('should auto-resize to fit available space (shrink)', () {
      // Create a scenario where field needs to shrink
      testConfigs['field3'] = FieldConfig(
        id: 'field3',
        width: 2/6, // 2 columns
        position: const Offset(4/6, 0), // Row 0, columns 4-5
      );

      // Now row 0 has: field1 (0-1), gap (2-3), field3 (4-5)
      // field2 (3 columns) should shrink to 2 columns to fit in columns 2-3
      final previewConfigs = FieldPreviewSystem.calculatePreviewPositions(
        targetRow: 0,
        draggedFieldId: 'field2',
        currentConfigs: testConfigs,
        containerWidth: containerWidth,
      );

      // field2 should be shrunk to 2 columns and placed at columns 2-3
      expect(previewConfigs['field2']?.position.dy, 0); // Row 0
      expect(previewConfigs['field2']?.position.dx, 2/6); // Column 2
      expect(previewConfigs['field2']?.width, 2/6); // Shrunk to 2 columns
    });

    test('should provide auto-resize preview info', () {
      final previewInfo = FieldPreviewSystem.getPreviewInfo(
        targetRow: 0,
        draggedFieldId: 'field2',
        currentConfigs: testConfigs,
        containerWidth: containerWidth,
      );

      expect(previewInfo.hasSpace, true);
      expect(previewInfo.targetPosition?.dy, 0); // Row 0
      expect(previewInfo.targetPosition?.dx, 2/6); // Column 2
      expect(previewInfo.isPushDown, false); // Auto-resize, not push down
      expect(previewInfo.message, contains('expand')); // Should expand
      expect(previewInfo.message, contains('66%')); // 4/6 = 66%
    });

    test('should provide push down preview info', () {
      // Fill row 0 completely
      testConfigs['field3'] = FieldConfig(
        id: 'field3',
        width: 4/6, // 4 columns
        position: const Offset(2/6, 0), // Row 0, columns 2-5
      );

      final previewInfo = FieldPreviewSystem.getPreviewInfo(
        targetRow: 0,
        draggedFieldId: 'field2',
        currentConfigs: testConfigs,
        containerWidth: containerWidth,
      );

      expect(previewInfo.hasSpace, true); // Can still place with push down
      expect(previewInfo.targetPosition?.dy, 0); // Row 0
      expect(previewInfo.targetPosition?.dx, 0); // Column 0
      expect(previewInfo.isPushDown, true); // Push down required
      expect(previewInfo.message, contains('push other fields down'));
    });
  });
}