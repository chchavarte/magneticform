import 'package:flutter/material.dart';
import '../constants/magnetic_constants.dart';

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

/// Represents a form field that can be placed on the magnetic grid.
/// 
/// Each [MagneticFormField] defines a reusable form component with its own
/// unique identifier, display properties, and widget builder function. Fields
/// can be dragged, resized, and repositioned by users in customization mode.
/// 
/// ## Key Concepts
/// 
/// - **Unique ID**: Each field must have a unique identifier that matches
///   the keys in [MagneticFormBuilder.defaultFieldConfigs]
/// - **Builder Pattern**: The builder function creates the actual widget,
///   receiving context and customization mode state
/// - **Customization Mode**: When `isCustomizationMode` is true, fields
///   should be disabled to prevent interaction during layout editing
/// 
/// ## Common Field Types
/// 
/// ```dart
/// // Text Input Field
/// MagneticFormField(
///   id: 'name',
///   label: 'Full Name',
///   icon: Icons.person,
///   builder: (context, isCustomizationMode) => TextField(
///     decoration: InputDecoration(labelText: 'Full Name'),
///     enabled: !isCustomizationMode,
///   ),
/// )
/// 
/// // Email Field
/// MagneticFormField(
///   id: 'email',
///   label: 'Email Address',
///   icon: Icons.email,
///   builder: (context, isCustomizationMode) => TextField(
///     decoration: InputDecoration(labelText: 'Email'),
///     keyboardType: TextInputType.emailAddress,
///     enabled: !isCustomizationMode,
///   ),
/// )
/// 
/// // Dropdown Field
/// MagneticFormField(
///   id: 'country',
///   label: 'Country',
///   icon: Icons.public,
///   builder: (context, isCustomizationMode) => DropdownButtonFormField<String>(
///     decoration: InputDecoration(labelText: 'Country'),
///     items: ['USA', 'Canada', 'UK'].map((country) => 
///       DropdownMenuItem(value: country, child: Text(country))
///     ).toList(),
///     onChanged: isCustomizationMode ? null : (value) => handleChange(value),
///   ),
/// )
/// 
/// // Date Picker Field
/// MagneticFormField(
///   id: 'birthDate',
///   label: 'Birth Date',
///   icon: Icons.calendar_today,
///   builder: (context, isCustomizationMode) => TextField(
///     decoration: InputDecoration(
///       labelText: 'Birth Date',
///       suffixIcon: Icon(Icons.calendar_today),
///     ),
///     readOnly: true,
///     enabled: !isCustomizationMode,
///     onTap: isCustomizationMode ? null : () => showDatePicker(...),
///   ),
/// )
/// ```
/// 
/// ## Best Practices
/// 
/// 1. **Always disable fields during customization**:
///    ```dart
///    enabled: !isCustomizationMode, // Essential for proper UX
///    ```
/// 
/// 2. **Use descriptive IDs**:
///    ```dart
///    id: 'userEmail',        // ✅ Clear and descriptive
///    id: 'field1',          // ❌ Generic and unclear
///    ```
/// 
/// 3. **Choose appropriate icons**:
///    ```dart
///    Icons.email,           // ✅ Matches field purpose
///    Icons.text_fields,     // ✅ Generic text input
///    Icons.calendar_today,  // ✅ Date fields
///    ```
/// 
/// 4. **Handle null callbacks in customization mode**:
///    ```dart
///    onChanged: isCustomizationMode ? null : (value) => handleChange(value),
///    ```
class MagneticFormField {
  /// Unique identifier for this field.
  /// 
  /// Must be unique across all fields in the same form. Used for data
  /// storage, configuration persistence, and field referencing.
  final String id;

  /// Display label for this field.
  /// 
  /// Shown in the field selection interface and can be used within
  /// the field widget itself for consistent labeling.
  final String label;

  /// Icon representing this field type.
  /// 
  /// Displayed in the field selection interface to help users identify
  /// different field types visually.
  final IconData icon;

  /// Function that builds the actual field widget.
  /// 
  /// The builder receives two parameters:
  /// - [context]: The current build context
  /// - [isCustomizationMode]: Whether the form is in customization mode
  /// 
  /// When [isCustomizationMode] is `true`, the field should typically be
  /// disabled or show a preview state to prevent user interaction during
  /// layout customization.
  /// 
  /// Example:
  /// ```dart
  /// builder: (context, isCustomizationMode) => TextField(
  ///   decoration: InputDecoration(labelText: label),
  ///   enabled: !isCustomizationMode,
  /// )
  /// ```
  final Widget Function(BuildContext context, bool isCustomizationMode) builder;

  /// Whether this field is mandatory for form completion.
  /// 
  /// Can be used by validation logic or UI indicators to show required fields.
  /// Defaults to `false`.
  final bool isMandatory;

  /// Default value for this field.
  /// 
  /// Used to pre-populate the field when it's first added to the form.
  /// Can be `null` if no default value is needed.
  final String? defaultValue;

  /// Creates a magnetic form field.
  /// 
  /// The [id], [label], [icon], and [builder] parameters are required.
  /// The [id] must be unique within the form.
  /// 
  /// Example:
  /// ```dart
  /// MagneticFormField(
  ///   id: 'phone',
  ///   label: 'Phone Number',
  ///   icon: Icons.phone,
  ///   builder: (context, isCustomizationMode) => TextField(
  ///     decoration: InputDecoration(labelText: 'Phone Number'),
  ///     keyboardType: TextInputType.phone,
  ///     enabled: !isCustomizationMode,
  ///   ),
  ///   isMandatory: true,
  /// )
  /// ```
  const MagneticFormField({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
    this.isMandatory = false,
    this.defaultValue,
  });
}

/// Configuration data for a field's position and size on the magnetic grid.
/// 
/// Each [FieldConfig] defines where a form field appears on the grid and how
/// much space it occupies. The configuration uses a normalized coordinate system
/// where positions and sizes are expressed as percentages of the container.
/// 
/// ## Coordinate System
/// 
/// - **Position**: `Offset(x, y)` where:
///   - `x`: Horizontal position (0.0 = left edge, 1.0 = right edge)
///   - `y`: Vertical position (0 = top, increments by ~70px per row)
/// - **Width**: Percentage of container width (0.0 to 1.0)
/// - **Grid**: 6-column responsive system with intelligent snapping
/// 
/// ## Common Layout Patterns
/// 
/// ```dart
/// // Full width field
/// FieldConfig(
///   id: 'description',
///   position: Offset(0, 0),    // Top-left corner
///   width: 1.0,               // Full width (100%)
/// )
/// 
/// // Side-by-side fields (50/50)
/// FieldConfig(id: 'firstName', position: Offset(0, 0), width: 0.5),
/// FieldConfig(id: 'lastName', position: Offset(0.5, 0), width: 0.5),
/// 
/// // Three equal columns (33/33/33)
/// FieldConfig(id: 'day', position: Offset(0, 70), width: 0.33),
/// FieldConfig(id: 'month', position: Offset(0.33, 70), width: 0.33),
/// FieldConfig(id: 'year', position: Offset(0.66, 70), width: 0.33),
/// 
/// // Large field + small field (75/25)
/// FieldConfig(id: 'address', position: Offset(0, 140), width: 0.75),
/// FieldConfig(id: 'unit', position: Offset(0.75, 140), width: 0.25),
/// 
/// // Stacked full-width fields
/// FieldConfig(id: 'name', position: Offset(0, 0), width: 1.0),
/// FieldConfig(id: 'email', position: Offset(0, 70), width: 1.0),
/// FieldConfig(id: 'phone', position: Offset(0, 140), width: 1.0),
/// ```
/// 
/// ## Position Calculation
/// 
/// The `y` coordinate represents the vertical position in pixels:
/// ```dart
/// Row 0: y = 0      // Top row
/// Row 1: y = 70     // Second row
/// Row 2: y = 140    // Third row
/// Row 3: y = 210    // Fourth row
/// // ... and so on
/// ```
/// 
/// ## Width Guidelines
/// 
/// | Width | Percentage | Use Case |
/// |-------|------------|----------|
/// | 1.0   | 100%       | Full-width fields (names, descriptions) |
/// | 0.5   | 50%        | Side-by-side pairs (first/last name) |
/// | 0.33  | 33%        | Three-column layouts (date components) |
/// | 0.25  | 25%        | Four-column layouts (small inputs) |
/// | 0.75  | 75%        | Asymmetric layouts (address + unit) |
/// 
/// ## Advanced Features
/// 
/// - **Auto-resize**: Fields automatically adjust width to fit available space
/// - **Collision Detection**: Prevents overlapping field placement
/// - **Push-down Logic**: Fields move down when space is needed above
/// - **Magnetic Snapping**: Fields snap to grid positions for alignment
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

  // Grid utility methods (moved from MagneticCardSystem)
  
  /// Get the row index from a y position.
  /// 
  /// Converts a pixel-based y coordinate to a row index in the grid system.
  /// Each row is approximately 70 pixels tall.
  static int getRowFromPosition(double yPosition) {
    return (yPosition / MagneticConstants.cardHeight).round();
  }

  /// Get the column index from an x position and container width.
  /// 
  /// Converts a normalized x position (0.0-1.0) to a column index (0-5)
  /// in the 6-column grid system.
  static int getColumnFromPosition(double xPosition, double containerWidth) {
    final column = (xPosition * 6).floor().clamp(0, 5);
    return column;
  }

  /// Get the normalized column position from a column index.
  /// 
  /// Converts a column index (0-5) to a normalized position (0.0-1.0).
  static double getColumnPositionNormalized(int column) {
    return column / 6.0;
  }

  /// Get the number of columns from a width percentage.
  /// 
  /// Converts a width percentage to the number of columns it spans
  /// in the 6-column grid system.
  static int getColumnsFromWidth(double width) {
    if (width <= 2 / 6 + 0.001) return 2; // 2/6 width = 2 columns
    if (width <= 3 / 6 + 0.001) return 3; // 3/6 width = 3 columns
    if (width <= 4 / 6 + 0.001) return 4; // 4/6 width = 4 columns
    return 6; // 6/6 width = 6 columns (full row)
  }
}