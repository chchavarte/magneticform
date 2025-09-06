import 'package:flutter/material.dart';

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