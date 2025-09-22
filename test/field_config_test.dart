import 'package:flutter_test/flutter_test.dart';
import 'package:magnetic_form_builder/src/models/field_models.dart';

void main() {
  group('FieldConfig', () {
    test('should create FieldConfig with default values', () {
      final config = FieldConfig(id: 'test_field');
      
      expect(config.id, 'test_field');
      expect(config.width, 1.0);
      expect(config.position, Offset.zero);
    });

    test('should create FieldConfig with custom values', () {
      final config = FieldConfig(
        id: 'custom_field',
        width: 0.5,
        position: const Offset(0.25, 70.0),
      );
      
      expect(config.id, 'custom_field');
      expect(config.width, 0.5);
      expect(config.position, const Offset(0.25, 70.0));
    });

    test('should copy FieldConfig with modified values', () {
      final original = FieldConfig(
        id: 'original',
        width: 0.5,
        position: const Offset(0.1, 35.0),
      );
      
      final copied = original.copyWith(
        id: 'copied',
        width: 0.75,
      );
      
      expect(copied.id, 'copied');
      expect(copied.width, 0.75);
      expect(copied.position, const Offset(0.1, 35.0)); // Should remain unchanged
    });

    test('should copy FieldConfig with no changes', () {
      final original = FieldConfig(
        id: 'original',
        width: 0.5,
        position: const Offset(0.1, 35.0),
      );
      
      final copied = original.copyWith();
      
      expect(copied.id, 'original');
      expect(copied.width, 0.5);
      expect(copied.position, const Offset(0.1, 35.0));
    });

    test('should correctly determine visibility', () {
      // Visible field
      final visibleField = FieldConfig(
        id: 'visible',
        width: 0.5,
        position: const Offset(0.25, 70.0),
      );
      expect(visibleField.isVisible, true);

      // Hidden field (width = 0)
      final hiddenByWidth = FieldConfig(
        id: 'hidden_width',
        width: 0.0,
        position: const Offset(0.25, 70.0),
      );
      expect(hiddenByWidth.isVisible, false);

      // Hidden field (negative x position)
      final hiddenByX = FieldConfig(
        id: 'hidden_x',
        width: 0.5,
        position: const Offset(-0.1, 70.0),
      );
      expect(hiddenByX.isVisible, false);

      // Hidden field (negative y position)
      final hiddenByY = FieldConfig(
        id: 'hidden_y',
        width: 0.5,
        position: const Offset(0.25, -10.0),
      );
      expect(hiddenByY.isVisible, false);

      // Edge case: zero position should be visible
      final zeroPosition = FieldConfig(
        id: 'zero_pos',
        width: 0.5,
        position: Offset.zero,
      );
      expect(zeroPosition.isVisible, true);
    });

    test('should serialize to Map correctly', () {
      final config = FieldConfig(
        id: 'test_field',
        width: 0.75,
        position: const Offset(0.33, 140.0),
      );
      
      final map = config.toMap();
      
      expect(map['id'], 'test_field');
      expect(map['width'], 0.75);
      expect(map['positionX'], 0.33);
      expect(map['positionY'], 140.0);
    });

    test('should deserialize from Map correctly', () {
      final map = {
        'id': 'deserialized_field',
        'width': 0.6,
        'positionX': 0.4,
        'positionY': 210.0,
      };
      
      final config = FieldConfig.fromMap(map);
      
      expect(config.id, 'deserialized_field');
      expect(config.width, 0.6);
      expect(config.position.dx, 0.4);
      expect(config.position.dy, 210.0);
    });

    test('should maintain data integrity through serialization round-trip', () {
      final original = FieldConfig(
        id: 'round_trip_test',
        width: 0.8333,
        position: const Offset(0.1667, 280.0),
      );
      
      final map = original.toMap();
      final deserialized = FieldConfig.fromMap(map);
      
      expect(deserialized.id, original.id);
      expect(deserialized.width, original.width);
      expect(deserialized.position.dx, original.position.dx);
      expect(deserialized.position.dy, original.position.dy);
      expect(deserialized.isVisible, original.isVisible);
    });

    test('should handle edge cases in serialization', () {
      // Test with zero values
      final zeroConfig = FieldConfig(
        id: 'zero_test',
        width: 0.0,
        position: Offset.zero,
      );
      
      final zeroMap = zeroConfig.toMap();
      final zeroDeserialized = FieldConfig.fromMap(zeroMap);
      
      expect(zeroDeserialized.id, 'zero_test');
      expect(zeroDeserialized.width, 0.0);
      expect(zeroDeserialized.position, Offset.zero);

      // Test with maximum values
      final maxConfig = FieldConfig(
        id: 'max_test',
        width: 1.0,
        position: const Offset(1.0, 840.0), // 12 rows * 70 height
      );
      
      final maxMap = maxConfig.toMap();
      final maxDeserialized = FieldConfig.fromMap(maxMap);
      
      expect(maxDeserialized.id, 'max_test');
      expect(maxDeserialized.width, 1.0);
      expect(maxDeserialized.position.dx, 1.0);
      expect(maxDeserialized.position.dy, 840.0);
    });
  });
}