# 🧲 Magnetic Form Builder

A sophisticated Flutter package for building **drag-and-drop forms** with magnetic grid positioning, intelligent field placement, and smooth animations.

[![pub package](https://img.shields.io/pub/v/magnetic_form_builder.svg)](https://pub.dev/packages/magnetic_form_builder)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- 🎯 **Drag & Drop Interface** - Users can customize form layouts by dragging fields
- 🧲 **Magnetic Grid System** - 6-column responsive grid with intelligent snapping
- 🔄 **Real-time Preview** - See field placement before dropping
- 🤖 **Auto-resize & Collision Detection** - Fields automatically adjust to fit available space
- 📱 **Responsive Design** - Works on mobile, tablet, and desktop
- 🎨 **Customizable Themes** - Full Material Design integration
- ⚡ **Smooth Animations** - 60fps performance with optimized animations

## 🚀 Quick Start

### 1. Add to pubspec.yaml

```yaml
dependencies:
  magnetic_form_builder: ^1.0.0
```

### 2. Import the package

```dart
import 'package:magnetic_form_builder/magnetic_form_builder.dart';
```

### 3. Create your first magnetic form

```dart
import 'package:flutter/material.dart';
import 'package:magnetic_form_builder/magnetic_form_builder.dart';

class MyFormScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MagneticFormBuilder(
        availableFields: [
          // Define your form fields
          MagneticFormField(
            id: 'name',
            label: 'Full Name',
            icon: Icons.person,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              enabled: !isCustomizationMode, // Disable during layout editing
            ),
          ),
          MagneticFormField(
            id: 'email',
            label: 'Email',
            icon: Icons.email,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isCustomizationMode,
            ),
          ),
        ],
        defaultFieldConfigs: {
          // Set initial positions and sizes
          'name': FieldConfig(
            id: 'name',
            position: Offset(0, 0),    // Top-left corner
            width: 1.0,               // Full width (100%)
          ),
          'email': FieldConfig(
            id: 'email',
            position: Offset(0, 70),   // Second row
            width: 0.5,               // Half width (50%)
          ),
        },
        appBarTitle: 'My Custom Form',
        onFormDataChanged: (formData) {
          print('Form data: $formData');
        },
        onFieldConfigChanged: (fieldConfigs) {
          print('Layout changed: $fieldConfigs');
        },
      ),
    );
  }
}
```

**That's it!** 🎉 You now have a fully functional drag-and-drop form builder.

## 📖 Complete Example

Here's a more comprehensive example showing common form patterns:

<details>
<summary>Click to expand complete example</summary>

```dart
import 'package:flutter/material.dart';
import 'package:magnetic_form_builder/magnetic_form_builder.dart';

class ComprehensiveFormExample extends StatefulWidget {
  @override
  _ComprehensiveFormExampleState createState() => _ComprehensiveFormExampleState();
}

class _ComprehensiveFormExampleState extends State<ComprehensiveFormExample> {
  final Map<String, dynamic> _formData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MagneticFormBuilder(
        availableFields: [
          // Text Fields
          MagneticFormField(
            id: 'firstName',
            label: 'First Name',
            icon: Icons.person_outline,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
              enabled: !isCustomizationMode,
              onChanged: (value) => _formData['firstName'] = value,
            ),
          ),
          MagneticFormField(
            id: 'lastName',
            label: 'Last Name',
            icon: Icons.person,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
              enabled: !isCustomizationMode,
              onChanged: (value) => _formData['lastName'] = value,
            ),
          ),
          
          // Email Field
          MagneticFormField(
            id: 'email',
            label: 'Email',
            icon: Icons.email,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isCustomizationMode,
              onChanged: (value) => _formData['email'] = value,
            ),
          ),
          
          // Phone Field
          MagneticFormField(
            id: 'phone',
            label: 'Phone',
            icon: Icons.phone,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              enabled: !isCustomizationMode,
              onChanged: (value) => _formData['phone'] = value,
            ),
          ),
          
          // Dropdown Field
          MagneticFormField(
            id: 'country',
            label: 'Country',
            icon: Icons.public,
            builder: (context, isCustomizationMode) => DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
              ),
              items: ['USA', 'Canada', 'UK', 'Australia']
                  .map((country) => DropdownMenuItem(
                        value: country,
                        child: Text(country),
                      ))
                  .toList(),
              onChanged: isCustomizationMode ? null : (value) => _formData['country'] = value,
            ),
          ),
          
          // Date Field
          MagneticFormField(
            id: 'birthDate',
            label: 'Birth Date',
            icon: Icons.calendar_today,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Birth Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              enabled: !isCustomizationMode,
              onTap: isCustomizationMode ? null : () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _formData['birthDate'] = date.toIso8601String();
                }
              },
            ),
          ),
          
          // Multi-line Text Field
          MagneticFormField(
            id: 'notes',
            label: 'Notes',
            icon: Icons.note,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              enabled: !isCustomizationMode,
              onChanged: (value) => _formData['notes'] = value,
            ),
          ),
        ],
        
        defaultFieldConfigs: {
          // Row 1: First Name (50%) + Last Name (50%)
          'firstName': FieldConfig(
            id: 'firstName',
            position: Offset(0, 0),
            width: 0.5,
          ),
          'lastName': FieldConfig(
            id: 'lastName',
            position: Offset(0.5, 0),
            width: 0.5,
          ),
          
          // Row 2: Email (full width)
          'email': FieldConfig(
            id: 'email',
            position: Offset(0, 70),
            width: 1.0,
          ),
          
          // Row 3: Phone (50%) + Country (50%)
          'phone': FieldConfig(
            id: 'phone',
            position: Offset(0, 140),
            width: 0.5,
          ),
          'country': FieldConfig(
            id: 'country',
            position: Offset(0.5, 140),
            width: 0.5,
          ),
          
          // Row 4: Birth Date (50%)
          'birthDate': FieldConfig(
            id: 'birthDate',
            position: Offset(0, 210),
            width: 0.5,
          ),
          
          // Row 5: Notes (full width)
          'notes': FieldConfig(
            id: 'notes',
            position: Offset(0, 280),
            width: 1.0,
          ),
        },
        
        appBarTitle: 'User Registration Form',
        storageKey: 'user_registration_form',
        
        onFormDataChanged: (formData) {
          setState(() {
            _formData.addAll(formData);
          });
          print('Form data updated: $formData');
        },
        
        onFieldConfigChanged: (fieldConfigs) {
          print('Layout changed - ${fieldConfigs.length} fields configured');
        },
        
        // Custom form data builder for submit button
        formDataBuilder: (context, formData) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    print('Submitting form: $_formData');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Form submitted successfully!')),
                    );
                  },
                  child: Text('Submit Form'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Form Data: ${_formData.toString()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

</details>

## 🎯 Common Layout Patterns

### Side-by-Side Fields (50/50)
```dart
defaultFieldConfigs: {
  'firstName': FieldConfig(id: 'firstName', position: Offset(0, 0), width: 0.5),
  'lastName': FieldConfig(id: 'lastName', position: Offset(0.5, 0), width: 0.5),
}
```

### Three Columns (33/33/33)
```dart
defaultFieldConfigs: {
  'day': FieldConfig(id: 'day', position: Offset(0, 0), width: 0.33),
  'month': FieldConfig(id: 'month', position: Offset(0.33, 0), width: 0.33),
  'year': FieldConfig(id: 'year', position: Offset(0.66, 0), width: 0.33),
}
```

### Full Width Header + Two Columns
```dart
defaultFieldConfigs: {
  'title': FieldConfig(id: 'title', position: Offset(0, 0), width: 1.0),
  'address1': FieldConfig(id: 'address1', position: Offset(0, 70), width: 0.5),
  'address2': FieldConfig(id: 'address2', position: Offset(0.5, 70), width: 0.5),
}
```

### Responsive Layout (Large field + Small field)
```dart
defaultFieldConfigs: {
  'description': FieldConfig(id: 'description', position: Offset(0, 0), width: 0.75),
  'priority': FieldConfig(id: 'priority', position: Offset(0.75, 0), width: 0.25),
}
```

## 📐 Understanding the Grid System

The Magnetic Form Builder uses a **6-column responsive grid**:

- **Position**: `Offset(x, y)` where:
  - `x`: Horizontal position (0.0 = left edge, 1.0 = right edge)
  - `y`: Vertical position (0 = top, increments by row height ~70px)
- **Width**: Percentage of container width (0.0 to 1.0)
  - `1.0` = Full width (100%)
  - `0.5` = Half width (50%)
  - `0.33` = One third (33%)

### Visual Grid Reference
```
┌─────────────────────────────────────────┐
│ 0.0    0.17   0.33   0.5    0.67   0.83 │ 1.0
├─────────────────────────────────────────┤
│ [    Field 1 (width: 1.0)             ] │ Row 0 (y: 0)
├─────────────────────────────────────────┤
│ [ Field 2 ] │ [ Field 3 ] │ [ Field 4 ] │ Row 1 (y: 70)
│ (width:0.33)│ (width:0.33)│ (width:0.33)│
├─────────────────────────────────────────┤
│ [    Field 5 (width: 0.5)  ] │ Field 6 │ Row 2 (y: 140)
│                              │(w: 0.5) │
└─────────────────────────────────────────┘
```

## 🎨 Theming & Customization

### Using Built-in Themes
```dart
MagneticFormBuilder(
  // ... your fields
  theme: MagneticTheme.lightTheme,  // or MagneticTheme.darkTheme
)
```

### Custom Theme
```dart
final customTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
);

MagneticFormBuilder(
  // ... your fields
  theme: MagneticTheme.withFieldExtensions(customTheme),
)
```

### No Theme (Inherit from App)
```dart
MagneticFormBuilder(
  // ... your fields
  // No theme parameter - automatically inherits from your app
)
```

## 🔄 Migration Guide

### From Flutter Form Builder

<details>
<summary>Click to see migration example</summary>

```dart
// OLD: FormBuilder approach
FormBuilder(
  key: _formKey,
  child: Column(
    children: [
      FormBuilderTextField(
        name: 'name',
        decoration: InputDecoration(labelText: 'Name'),
      ),
      FormBuilderTextField(
        name: 'email',
        decoration: InputDecoration(labelText: 'Email'),
      ),
    ],
  ),
)

// NEW: MagneticFormBuilder approach
MagneticFormBuilder(
  availableFields: [
    MagneticFormField(
      id: 'name',  // was 'name' in FormBuilder
      label: 'Name',
      icon: Icons.person,
      builder: (context, isCustomizationMode) => TextField(
        decoration: InputDecoration(labelText: 'Name'),
        enabled: !isCustomizationMode,
      ),
    ),
    MagneticFormField(
      id: 'email',  // was 'name' in FormBuilder
      label: 'Email',
      icon: Icons.email,
      builder: (context, isCustomizationMode) => TextField(
        decoration: InputDecoration(labelText: 'Email'),
        enabled: !isCustomizationMode,
      ),
    ),
  ],
  defaultFieldConfigs: {
    'name': FieldConfig(id: 'name', position: Offset(0, 0), width: 1.0),
    'email': FieldConfig(id: 'email', position: Offset(0, 70), width: 1.0),
  },
)
```

</details>

### From Manual Form Layout

<details>
<summary>Click to see migration example</summary>

```dart
// OLD: Manual Column/Row layout
Column(
  children: [
    Row(
      children: [
        Expanded(child: TextField(decoration: InputDecoration(labelText: 'First Name'))),
        SizedBox(width: 16),
        Expanded(child: TextField(decoration: InputDecoration(labelText: 'Last Name'))),
      ],
    ),
    SizedBox(height: 16),
    TextField(decoration: InputDecoration(labelText: 'Email')),
  ],
)

// NEW: MagneticFormBuilder (users can customize the layout!)
MagneticFormBuilder(
  availableFields: [
    MagneticFormField(
      id: 'firstName',
      label: 'First Name',
      icon: Icons.person_outline,
      builder: (context, isCustomizationMode) => TextField(
        decoration: InputDecoration(labelText: 'First Name'),
        enabled: !isCustomizationMode,
      ),
    ),
    MagneticFormField(
      id: 'lastName',
      label: 'Last Name',
      icon: Icons.person,
      builder: (context, isCustomizationMode) => TextField(
        decoration: InputDecoration(labelText: 'Last Name'),
        enabled: !isCustomizationMode,
      ),
    ),
    MagneticFormField(
      id: 'email',
      label: 'Email',
      icon: Icons.email,
      builder: (context, isCustomizationMode) => TextField(
        decoration: InputDecoration(labelText: 'Email'),
        enabled: !isCustomizationMode,
      ),
    ),
  ],
  defaultFieldConfigs: {
    'firstName': FieldConfig(id: 'firstName', position: Offset(0, 0), width: 0.5),
    'lastName': FieldConfig(id: 'lastName', position: Offset(0.5, 0), width: 0.5),
    'email': FieldConfig(id: 'email', position: Offset(0, 70), width: 1.0),
  },
)
```

</details>

## 🔧 Advanced Features

### Form Data Persistence
```dart
MagneticFormBuilder(
  // ... your fields
  storageKey: 'my_form_layout', // Automatically saves/restores layout
)
```

### Custom Form Actions
```dart
MagneticFormBuilder(
  // ... your fields
  formDataBuilder: (context, formData) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => submitForm(formData),
          child: Text('Submit'),
        ),
        TextButton(
          onPressed: () => resetForm(),
          child: Text('Reset'),
        ),
      ],
    );
  },
)
```

### Real-time Form Validation
```dart
MagneticFormBuilder(
  // ... your fields
  onFormDataChanged: (formData) {
    // Validate form data in real-time
    final isValid = validateFormData(formData);
    setState(() {
      _isFormValid = isValid;
    });
  },
)
```

## 🎯 Use Cases

### Perfect For:
- **Admin Dashboards** - Let users customize data entry forms
- **Survey Builders** - Drag-and-drop survey creation
- **CRM Systems** - Customizable contact forms
- **Report Builders** - Dynamic form layouts
- **Settings Screens** - User-configurable interfaces

### Not Ideal For:
- Simple static forms (use regular Flutter forms)
- Forms that never need layout changes
- Performance-critical applications with 100+ fields

## 🚀 Performance Tips

1. **Limit Field Count**: Best performance with < 50 fields
2. **Use RepaintBoundary**: Wrap expensive field widgets
3. **Disable Animations**: Set `AnimationConstants.previewDuration = Duration.zero` for testing
4. **Optimize Builders**: Keep field builders lightweight

## 📚 API Reference

### MagneticFormBuilder

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `availableFields` | `List<MagneticFormField>` | ✅ | List of form fields that can be placed |
| `defaultFieldConfigs` | `Map<String, FieldConfig>` | ✅ | Initial positions and sizes |
| `appBarTitle` | `String?` | ❌ | Title for the app bar |
| `theme` | `ThemeData?` | ❌ | Custom theme (inherits from app if null) |
| `storageKey` | `String?` | ❌ | Key for persisting layout changes |
| `onFormDataChanged` | `Function(Map<String, dynamic>)?` | ❌ | Called when form data changes |
| `onFieldConfigChanged` | `Function(Map<String, FieldConfig>)?` | ❌ | Called when layout changes |
| `formDataBuilder` | `Widget Function(BuildContext, Map<String, dynamic>)?` | ❌ | Builder for custom form actions |

### MagneticFormField

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | `String` | ✅ | Unique identifier for the field |
| `label` | `String` | ✅ | Display name for the field |
| `icon` | `IconData` | ✅ | Icon shown in field selector |
| `builder` | `Widget Function(BuildContext, bool)` | ✅ | Function that builds the field widget |
| `isMandatory` | `bool` | ❌ | Whether field is required (default: false) |
| `defaultValue` | `dynamic` | ❌ | Initial value for the field |

### FieldConfig

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | `String` | ✅ | Must match MagneticFormField.id |
| `position` | `Offset` | ✅ | Position on grid (x: 0.0-1.0, y: 0+) |
| `width` | `double` | ✅ | Width as percentage (0.0-1.0) |
| `isVisible` | `bool` | ❌ | Whether field is shown (default: true) |

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📖 [Documentation](https://pub.dev/documentation/magnetic_form_builder/latest/)
- 🐛 [Issue Tracker](https://github.com/chchavarte/magneticform/issues)
- 💬 [Discussions](https://github.com/chchavarte/magneticform/discussions)

---

Made with ❤️ by the Flutter community