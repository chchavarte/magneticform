/// A sophisticated Flutter package for building drag-and-drop forms with magnetic grid positioning.
/// 
/// ## Features
/// 
/// - 🎯 **Drag & Drop Interface** - Users can customize form layouts by dragging fields
/// - 🧲 **Magnetic Grid System** - 6-column responsive grid with intelligent snapping
/// - 🔄 **Real-time Preview** - See field placement before dropping
/// - 🤖 **Auto-resize & Collision Detection** - Fields automatically adjust to fit available space
/// - 📱 **Responsive Design** - Works on mobile, tablet, and desktop
/// - 🎨 **Customizable Themes** - Full Material Design integration
/// - ⚡ **Smooth Animations** - 60fps performance with optimized animations
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
///       icon: Icons.person,
///       builder: (context, isCustomizationMode) => TextField(
///         decoration: InputDecoration(labelText: 'Full Name'),
///         enabled: !isCustomizationMode, // Important: disable during layout editing
///       ),
///     ),
///     MagneticFormField(
///       id: 'email',
///       label: 'Email',
///       icon: Icons.email,
///       builder: (context, isCustomizationMode) => TextField(
///         decoration: InputDecoration(labelText: 'Email'),
///         enabled: !isCustomizationMode,
///         keyboardType: TextInputType.emailAddress,
///       ),
///     ),
///   ],
///   defaultFieldConfigs: {
///     'name': FieldConfig(
///       id: 'name',
///       position: Offset(0, 0),    // Top-left corner
///       width: 1.0,               // Full width (100%)
///     ),
///     'email': FieldConfig(
///       id: 'email',
///       position: Offset(0, 70),   // Second row
///       width: 0.5,               // Half width (50%)
///     ),
///   },
///   appBarTitle: 'My Custom Form',
///   onFormDataChanged: (formData) {
///     print('Form data: $formData');
///   },
/// )
/// ```
/// 
/// ## Grid System
/// 
/// The package uses a 6-column responsive grid where:
/// - **Position**: `Offset(x, y)` where x is 0.0-1.0 (left to right), y is row * 70
/// - **Width**: Percentage of container width (0.0 to 1.0)
/// - **Auto-resize**: Fields automatically adjust to fit available space
/// 
/// ## Common Layout Patterns
/// 
/// ```dart
/// // Side-by-side fields (50/50)
/// 'firstName': FieldConfig(id: 'firstName', position: Offset(0, 0), width: 0.5),
/// 'lastName': FieldConfig(id: 'lastName', position: Offset(0.5, 0), width: 0.5),
/// 
/// // Three columns (33/33/33)
/// 'day': FieldConfig(id: 'day', position: Offset(0, 0), width: 0.33),
/// 'month': FieldConfig(id: 'month', position: Offset(0.33, 0), width: 0.33),
/// 'year': FieldConfig(id: 'year', position: Offset(0.66, 0), width: 0.33),
/// 
/// // Full width header + two columns
/// 'title': FieldConfig(id: 'title', position: Offset(0, 0), width: 1.0),
/// 'address1': FieldConfig(id: 'address1', position: Offset(0, 70), width: 0.5),
/// 'address2': FieldConfig(id: 'address2', position: Offset(0.5, 70), width: 0.5),
/// ```
/// 
/// ## Theming
/// 
/// ```dart
/// // Use built-in themes
/// MagneticFormBuilder(
///   theme: MagneticTheme.lightTheme, // or MagneticTheme.darkTheme
///   // ...
/// )
/// 
/// // Custom theme
/// MagneticFormBuilder(
///   theme: MagneticTheme.withFieldExtensions(
///     ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
///   ),
///   // ...
/// )
/// 
/// // Inherit from app (default)
/// MagneticFormBuilder(
///   // No theme parameter - inherits from your app
///   // ...
/// )
/// ```
/// 
/// ## Advanced Features
/// 
/// - **Form Data Persistence**: Use `storageKey` to save/restore layouts
/// - **Real-time Validation**: Handle validation in `onFormDataChanged`
/// - **Custom Form Actions**: Use `formDataBuilder` for submit buttons
/// - **Field Visibility**: Toggle fields with `FieldConfig.isVisible`
/// 
/// For complete documentation, examples, and migration guides, visit:
/// https://github.com/chchavarte/magneticform
library;

// Main widget - MagneticFormBuilder
export 'src/widgets/magnetic_form_builder.dart';

// Core models - MagneticFormField and FieldConfig
export 'src/models/field_models.dart';

// Theme classes for customization
export 'src/theme/magnetic_theme.dart';
export 'src/theme/field_theme_extension.dart';

// Constants for customization
export 'src/constants/magnetic_constants.dart';

// Field builders for creating test fields
export 'src/components/field_builders.dart';