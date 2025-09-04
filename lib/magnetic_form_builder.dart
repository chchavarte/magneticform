/// A sophisticated Flutter package for building drag-and-drop forms with magnetic grid positioning.
/// 
/// This package provides advanced form building capabilities including:
/// - 6-column magnetic grid system with precise snapping
/// - Real-time preview-on-hover during drag operations
/// - Intelligent field placement with auto-resize and collision detection
/// - Smooth animations for all interactions
/// - Customizable theming system
/// 
/// ## Quick Start
/// 
/// ```dart
/// import 'package:magnetic_form_builder/magnetic_form_builder.dart';
/// 
/// MagneticFormBuilder(
///   availableFields: [
///     MagneticFormField(
///       id: 'name',
///       label: 'Full Name',
///       builder: (context, isCustomizationMode) => TextField(
///         decoration: InputDecoration(labelText: 'Full Name'),
///       ),
///     ),
///   ],
///   defaultFieldConfigs: {
///     'name': FieldConfig(
///       id: 'name',
///       position: Offset(0, 0),
///       size: Size(6, 1),
///     ),
///   },
/// )
/// ```
library;

// Main widget - MagneticFormBuilder
export 'src/widgets/magnetic_form_builder.dart';

// Core models - MagneticFormField and FieldConfig
export 'src/models/form_field.dart';
export 'src/models/field_config.dart';

// Theme classes for customization
export 'src/theme/magnetic_theme.dart';
export 'src/theme/field_theme_extension.dart';

// Constants for customization
export 'src/constants/animation_constants.dart';

// Field builders for creating test fields
export 'src/components/field_builders.dart';