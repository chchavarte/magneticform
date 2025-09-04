# Magnetic Form Builder

A sophisticated Flutter package for building drag-and-drop forms with magnetic grid positioning, collision detection, and smooth animations.

## Features

**6-Column Magnetic Grid System** - Precise field snapping with responsive grid layout  
**Real-time Preview-on-Hover** - Visual feedback during drag operations  
**Intelligent Field Placement** - Auto-resize, push-down, and collision detection  
**Smooth Animations** - Polished interactions with customizable timing  
**Customizable Theming** - Full theme support with field-specific styling  
**Cross-Platform** - Works on iOS, Android, Web, and Desktop  

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  magnetic_form_builder: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:magnetic_form_builder/magnetic_form_builder.dart';

class MyFormScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Define your form fields
    final List<MagneticFormField> fields = [
      MagneticFormField(
        id: 'name',
        label: 'Full Name',
        builder: (context, isCustomizationMode) => TextField(
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      MagneticFormField(
        id: 'email',
        label: 'Email',
        builder: (context, isCustomizationMode) => TextField(
          decoration: InputDecoration(
            labelText: 'Email Address',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    ];

    // Define default field configurations
    final Map<String, FieldConfig> defaultConfigs = {
      'name': FieldConfig(
        id: 'name',
        position: Offset(0, 0),
        size: Size(6, 1), // Full width, 1 row height
      ),
      'email': FieldConfig(
        id: 'email',
        position: Offset(0, 1),
        size: Size(6, 1),
      ),
    };

    return MagneticFormBuilder(
      availableFields: fields,
      defaultFieldConfigs: defaultConfigs,
      appBarTitle: 'My Custom Form',
      storageKey: 'my_form_storage',
    );
  }
}
```

## Parameters

### MagneticFormBuilder Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `availableFields` | `List<MagneticFormField>` | ✅ | - | List of form fields that can be placed on the grid |
| `defaultFieldConfigs` | `Map<String, FieldConfig>` | ✅ | - | Default positions and sizes for fields |
| `theme` | `ThemeData?` | ❌ | `null` | Custom theme data (uses default if not provided) |
| `appBarTitle` | `String` | ❌ | `'Custom Form'` | Title displayed in the app bar |
| `showAppBar` | `bool` | ❌ | `true` | Whether to show the app bar |
| `storageKey` | `String` | ❌ | `'magnetic_form_field_configs'` | Key for persisting field configurations |
| `onFormDataChanged` | `Function(Map<String, dynamic>)?` | ❌ | `null` | Callback when form data changes |
| `onFieldConfigChanged` | `Function(Map<String, FieldConfig>)?` | ❌ | `null` | Callback when field configurations change |
| `bottomWidget` | `Widget Function(BuildContext, Map<String, dynamic>)?` | ❌ | `null` | Custom widget to display below the form |

### MagneticFormField Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | `String` | ✅ | Unique identifier for the field |
| `label` | `String` | ✅ | Display label for the field |
| `builder` | `Widget Function(BuildContext, bool)` | ✅ | Function that builds the field widget |
| `defaultValue` | `String?` | ❌ | Default value for the field |

### FieldConfig Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | `String` | ✅ | Unique identifier matching the field |
| `position` | `Offset` | ✅ | Grid position (column, row) |
| `size` | `Size` | ✅ | Field size (width in columns, height in rows) |

## Theme Customization

### Using Default Theme

The package provides a default theme that matches the original magnetic form builder appearance:

```dart
MagneticFormBuilder(
  availableFields: fields,
  defaultFieldConfigs: configs,
  // No theme parameter - uses default theme automatically
)
```

### Using Custom Theme

You can provide your own theme data for complete customization:

```dart
// Create your custom theme
final customTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
);

// Apply it to the form builder
MagneticFormBuilder(
  availableFields: fields,
  defaultFieldConfigs: configs,
  theme: MagneticTheme.withFieldExtensions(customTheme),
)
```

### Theme Integration in Your App

For consistent theming across your entire app:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: MagneticTheme.withFieldExtensions(MagneticTheme.lightTheme),
      darkTheme: MagneticTheme.withFieldExtensions(MagneticTheme.darkTheme),
      themeMode: ThemeMode.system,
      home: MyFormScreen(),
    );
  }
}
```

## Advanced Usage

### Handling Form Data Changes

```dart
MagneticFormBuilder(
  availableFields: fields,
  defaultFieldConfigs: configs,
  onFormDataChanged: (formData) {
    print('Form data updated: $formData');
    // Save to database, validate, etc.
  },
  onFieldConfigChanged: (fieldConfigs) {
    print('Field layout changed: $fieldConfigs');
    // Save layout preferences, etc.
  },
)
```

### Custom Field Types

Create sophisticated custom fields with validation and styling:

```dart
MagneticFormField(
  id: 'rating',
  label: 'Rating',
  builder: (context, isCustomizationMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rate this product:'),
        Row(
          children: List.generate(5, (index) => 
            IconButton(
              icon: Icon(Icons.star),
              onPressed: isCustomizationMode ? null : () {
                // Handle rating selection
              },
            ),
          ),
        ),
      ],
    );
  },
)
```

### Adding Bottom Widgets

Display additional content below the form:

```dart
MagneticFormBuilder(
  availableFields: fields,
  defaultFieldConfigs: configs,
  bottomWidget: (context, formData) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Form Summary: ${formData.length} fields filled'),
          ElevatedButton(
            onPressed: () {
              // Submit form
              print('Submitting: $formData');
            },
            child: Text('Submit Form'),
          ),
        ],
      ),
    );
  },
)
```

## Grid System

The magnetic form builder uses a **6-column grid system**:

- **Columns**: 0-5 (6 total columns)
- **Rows**: 0+ (unlimited rows, auto-expanding)
- **Field Sizes**: Width 1-6 columns, Height 1+ rows
- **Positioning**: Automatic snapping to grid boundaries

### Grid Positioning Examples

```dart
// Full width field (spans all 6 columns)
FieldConfig(
  id: 'title',
  position: Offset(0, 0), // Column 0, Row 0
  size: Size(6, 1),       // 6 columns wide, 1 row tall
)

// Half width fields (3 columns each)
FieldConfig(
  id: 'first_name',
  position: Offset(0, 1), // Left half
  size: Size(3, 1),
)
FieldConfig(
  id: 'last_name',
  position: Offset(3, 1), // Right half
  size: Size(3, 1),
)

// Third width fields (2 columns each)
FieldConfig(
  id: 'day',
  position: Offset(0, 2),
  size: Size(2, 1),
)
FieldConfig(
  id: 'month',
  position: Offset(2, 2),
  size: Size(2, 1),
)
FieldConfig(
  id: 'year',
  position: Offset(4, 2),
  size: Size(2, 1),
)
```

## Animations and Interactions

The package includes sophisticated animations for all interactions:

- **Preview Animation**: 150ms for hover previews
- **Commit Animation**: 300ms for field placement
- **Revert Animation**: 200ms for cancelled operations
- **Collision Detection**: Real-time with visual feedback
- **Auto-resize**: Intelligent field sizing with user feedback

All animations use optimized curves and maintain 60fps performance.

## Data Persistence

Field configurations are automatically saved and restored using the provided `storageKey`:

```dart
MagneticFormBuilder(
  storageKey: 'user_profile_form', // Unique key for this form
  // ... other parameters
)
```

Each form instance should use a unique storage key to prevent configuration conflicts.

## Examples

The package includes comprehensive examples demonstrating:

- **Basic Usage**: Simple form with default theme
- **Custom Theming**: Teal color scheme with custom styling
- **Advanced Fields**: Complex field types with validation
- **Data Handling**: Form submission and data processing

Run the example app:

```bash
cd example
flutter run
```

## Requirements

- **Flutter**: >=3.7.2
- **Dart**: ^3.7.2
- **Platforms**: iOS, Android, Web, macOS, Windows, Linux

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or feature requests, please visit our GitHub repository or contact our support team.

---

**Made with ❤️ for the Flutter community**