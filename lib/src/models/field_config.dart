import 'package:flutter/material.dart';

/// Direction for field resizing operations.
/// 
/// Used internally by the resize handler to determine which edge of a field
/// is being resized during drag operations.
enum ResizeDirection { 
  /// Resize from the left edge
  left, 
  /// Resize from the right edge
  right 
}

/// Configuration data for a field's position and size on the magnetic grid.
/// 
/// Each [FieldConfig] represents the layout properties of a single form field,
/// including its position on the grid and its dimensions. This data is used
/// for rendering, collision detection, and persistence.
/// 
/// ## Grid System
/// 
/// The magnetic form builder uses a 6-column grid system:
/// - **Columns**: 0-5 (6 total columns)
/// - **Rows**: 0+ (unlimited rows, auto-expanding)
/// - **Position**: [Offset] where x = column, y = row
/// - **Size**: [Size] where width = columns (1-6), height = rows (1+)
/// 
/// ## Example
/// 
/// ```dart
/// // Full width field at top
/// FieldConfig(
///   id: 'title',
///   position: Offset(0, 0), // Column 0, Row 0
///   size: Size(6, 1),       // 6 columns wide, 1 row tall
/// )
/// 
/// // Half width fields side by side
/// FieldConfig(
///   id: 'first_name',
///   position: Offset(0, 1), // Left half
///   size: Size(3, 1),       // 3 columns wide
/// )
/// FieldConfig(
///   id: 'last_name',
///   position: Offset(3, 1), // Right half
///   size: Size(3, 1),       // 3 columns wide
/// )
/// ```
class FieldConfig {
  /// Unique identifier matching the corresponding [MagneticFormField.id].
  final String id;

  /// Width of the field as a percentage of the parent container width.
  /// 
  /// Value ranges from 0.0 to 1.0, where:
  /// - 0.0 = invisible/collapsed
  /// - 1.0 = full width (6 columns)
  /// - 0.5 = half width (3 columns)
  /// - 0.33 = third width (2 columns)
  final double width;

  /// Position of the field on the grid.
  /// 
  /// The [Offset] represents:
  /// - `dx` (x-coordinate): Column position (0-5)
  /// - `dy` (y-coordinate): Row position (0+)
  /// 
  /// Example positions:
  /// ```dart
  /// Offset(0, 0)  // Top-left corner
  /// Offset(3, 1)  // Column 3, Row 1 (right half of second row)
  /// Offset(2, 5)  // Column 2, Row 5 (middle of sixth row)
  /// ```
  final Offset position;

  /// Creates a field configuration.
  /// 
  /// The [id] parameter is required and must match a [MagneticFormField.id].
  /// The [width] defaults to 1.0 (full width) and [position] defaults to
  /// the origin (0, 0).
  /// 
  /// Example:
  /// ```dart
  /// FieldConfig(
  ///   id: 'email',
  ///   width: 0.5,              // Half width (3 columns)
  ///   position: Offset(0, 1),  // Column 0, Row 1
  /// )
  /// ```
  FieldConfig({
    required this.id,
    this.width = 1.0,
    this.position = Offset.zero,
  });

  /// Creates a copy of this field configuration with optional parameter overrides.
  /// 
  /// Useful for creating modified versions of existing configurations without
  /// mutating the original object.
  /// 
  /// Example:
  /// ```dart
  /// final newConfig = originalConfig.copyWith(
  ///   position: Offset(2, 3),
  ///   width: 0.33,
  /// );
  /// ```
  FieldConfig copyWith({String? id, double? width, Offset? position}) {
    return FieldConfig(
      id: id ?? this.id,
      width: width ?? this.width,
      position: position ?? this.position,
    );
  }

  /// Whether this field is visible and properly positioned on the grid.
  /// 
  /// Returns `true` if the field has a positive width and valid grid position.
  /// Fields with zero width or negative positions are considered invisible.
  bool get isVisible => width > 0 && position.dx >= 0 && position.dy >= 0;

  /// Converts this field configuration to a map for serialization.
  /// 
  /// Used internally for persisting field configurations to storage.
  /// The map contains all necessary data to reconstruct the configuration.
  /// 
  /// Returns a map with keys: 'id', 'width', 'positionX', 'positionY'.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'width': width,
      'positionX': position.dx,
      'positionY': position.dy,
    };
  }

  /// Creates a field configuration from a serialized map.
  /// 
  /// Used internally for restoring field configurations from storage.
  /// The map must contain the keys: 'id', 'width', 'positionX', 'positionY'.
  /// 
  /// Example:
  /// ```dart
  /// final config = FieldConfig.fromMap({
  ///   'id': 'email',
  ///   'width': 0.5,
  ///   'positionX': 0.0,
  ///   'positionY': 1.0,
  /// });
  /// ```
  factory FieldConfig.fromMap(Map<String, dynamic> map) {
    return FieldConfig(
      id: map['id'],
      width: map['width'],
      position: Offset(map['positionX'], map['positionY']),
    );
  }
}