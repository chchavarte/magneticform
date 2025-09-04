import 'package:flutter/material.dart';

/// Represents a form field that can be placed on the magnetic grid.
/// 
/// Each [MagneticFormField] defines a reusable form component with its own
/// unique identifier, display properties, and widget builder function.
/// 
/// ## Example
/// 
/// ```dart
/// MagneticFormField(
///   id: 'email',
///   label: 'Email Address',
///   icon: Icons.email,
///   builder: (context, isCustomizationMode) => TextField(
///     decoration: InputDecoration(
///       labelText: 'Email Address',
///       border: OutlineInputBorder(),
///     ),
///     enabled: !isCustomizationMode, // Disable during customization
///   ),
///   isMandatory: true,
///   defaultValue: 'user@example.com',
/// )
/// ```
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