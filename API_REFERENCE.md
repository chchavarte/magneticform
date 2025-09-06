# 📚 API Reference

Complete reference for all classes, methods, and properties in the Magnetic Form Builder package.

## 📋 Table of Contents

- [MagneticFormBuilder](#magneticformbuilder)
- [MagneticFormField](#magneticformfield)
- [FieldConfig](#fieldconfig)
- [MagneticTheme](#magnetictheme)
- [AnimationConstants](#animationconstants)
- [TestFieldBuilder](#testfieldbuilder)

---

## 🧲 MagneticFormBuilder

The main widget that creates a drag-and-drop form builder interface.

### Constructor

```dart
MagneticFormBuilder({
  Key? key,
  required List<MagneticFormField> availableFields,
  required Map<String, FieldConfig> defaultFieldConfigs,
  ThemeData? theme,
  String? appBarTitle,
  String? storageKey,
  Function(Map<String, dynamic>)? onFormDataChanged,
  Function(Map<String, FieldConfig>)? onFieldConfigChanged,
  Widget Function(BuildContext, Map<String, dynamic>)? formDataBuilder,
})
```

### Parameters

#### `availableFields` (required)
- **Type**: `List<MagneticFormField>`
- **Description**: List of form fields that can be placed on the grid
- **Example**:
```dart
availableFields: [
  MagneticFormField(
    id: 'name',
    label: 'Full Name',
    icon: Icons.person,
    builder: (context, isCustomizationMode) => TextField(
      decoration: InputDecoration(labelText: 'Full Name'),
      enabled: !isCustomizationMode,
    ),
  ),
]
```

#### `defaultFieldConfigs` (required)
- **Type**: `Map<String, FieldConfig>`
- **Description**: Initial positions and sizes for fields on the grid
- **Example**:
```dart
defaultFieldConfigs: {
  'name': FieldConfig(
    id: 'name',
    position: Offset(0, 0),    // Top-left corner
    width: 1.0,               // Full width
  ),
}
```

#### `theme` (optional)
- **Type**: `ThemeData?`
- **Default**: `null` (inherits from app theme)
- **Description**: Custom theme for styling the form builder
- **Example**:
```dart
theme: MagneticTheme.withFieldExtensions(
  ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
  ),
)
```

#### `appBarTitle` (optional)
- **Type**: `String?`
- **Default**: `'Magnetic Form Builder'`
- **Description**: Title displayed in the app bar
- **Example**:
```dart
appBarTitle: 'User Registration Form'
```

#### `storageKey` (optional)
- **Type**: `String?`
- **Default**: `null`
- **Description**: Unique key for persisting layout changes across app sessions
- **Example**:
```dart
storageKey: 'user_registration_layout'
```

#### `onFormDataChanged` (optional)
- **Type**: `Function(Map<String, dynamic>)?`
- **Default**: `null`
- **Description**: Callback fired when form field values change
- **Example**:
```dart
onFormDataChanged: (formData) {
  print('Form data updated: $formData');
  setState(() {
    _currentFormData = formData;
  });
}
```

#### `onFieldConfigChanged` (optional)
- **Type**: `Function(Map<String, FieldConfig>)?`
- **Default**: `null`
- **Description**: Callback fired when field positions or sizes change
- **Example**:
```dart
onFieldConfigChanged: (fieldConfigs) {
  print('Layout changed: ${fieldConfigs.length} fields');
  _saveLayoutToDatabase(fieldConfigs);
}
```

#### `formDataBuilder` (optional)
- **Type**: `Widget Function(BuildContext, Map<String, dynamic>)?`
- **Default**: `null`
- **Description**: Builder for custom content below the form (e.g., submit buttons)
- **Example**:
```dart
formDataBuilder: (context, formData) => Column(
  children: [
    ElevatedButton(
      onPressed: () => _submitForm(formData),
      child: Text('Submit Form'),
    ),
    Text('Fields completed: ${formData.length}'),
  ],
)
```

### Methods

#### `createState()`
- **Returns**: `_MagneticFormBuilderState`
- **Description**: Creates the mutable state for this widget

---

## 📝 MagneticFormField

Represents a single form field that can be placed on the magnetic grid.

### Constructor

```dart
MagneticFormField({
  required String id,
  required String label,
  required IconData icon,
  required Widget Function(BuildContext, bool) builder,
  bool isMandatory = false,
  dynamic defaultValue,
})
```

### Parameters

#### `id` (required)
- **Type**: `String`
- **Description**: Unique identifier for the field (must match FieldConfig keys)
- **Constraints**: Must be unique across all fields in the form
- **Example**: `'userEmail'`, `'firstName'`, `'phoneNumber'`

#### `label` (required)
- **Type**: `String`
- **Description**: Display name shown in the field selector
- **Example**: `'Email Address'`, `'First Name'`, `'Phone Number'`

#### `icon` (required)
- **Type**: `IconData`
- **Description**: Icon displayed in the field selector
- **Example**: `Icons.email`, `Icons.person`, `Icons.phone`

#### `builder` (required)
- **Type**: `Widget Function(BuildContext context, bool isCustomizationMode)`
- **Description**: Function that builds the actual form field widget
- **Parameters**:
  - `context`: The build context
  - `isCustomizationMode`: `true` when user is editing layout, `false` during normal use
- **Example**:
```dart
builder: (context, isCustomizationMode) => TextField(
  decoration: InputDecoration(
    labelText: 'Email Address',
    border: OutlineInputBorder(),
  ),
  enabled: !isCustomizationMode, // Important: disable during layout editing
  keyboardType: TextInputType.emailAddress,
  onChanged: (value) => _handleEmailChange(value),
)
```

#### `isMandatory` (optional)
- **Type**: `bool`
- **Default**: `false`
- **Description**: Whether this field is required (affects visual indicators)
- **Example**: `true` for required fields, `false` for optional fields

#### `defaultValue` (optional)
- **Type**: `dynamic`
- **Default**: `null`
- **Description**: Initial value for the field
- **Example**: `'john@example.com'`, `'John Doe'`, `25`

### Properties

All constructor parameters are available as read-only properties:

```dart
final field = MagneticFormField(id: 'email', ...);
print(field.id);          // 'email'
print(field.label);       // Field label
print(field.isMandatory); // true/false
```

---

## ⚙️ FieldConfig

Defines the position, size, and visibility of a field on the magnetic grid.

### Constructor

```dart
FieldConfig({
  required String id,
  required Offset position,
  required double width,
  bool isVisible = true,
})
```

### Parameters

#### `id` (required)
- **Type**: `String`
- **Description**: Must match a MagneticFormField.id
- **Example**: `'userEmail'`, `'firstName'`

#### `position` (required)
- **Type**: `Offset`
- **Description**: Position on the grid
- **Format**: `Offset(x, y)` where:
  - `x`: Horizontal position (0.0 = left edge, 1.0 = right edge)
  - `y`: Vertical position (0 = top, increments by ~70px per row)
- **Examples**:
```dart
Offset(0, 0)      // Top-left corner
Offset(0.5, 0)    // Top-right half
Offset(0, 70)     // Second row, left edge
Offset(0.33, 140) // Third row, one-third from left
```

#### `width` (required)
- **Type**: `double`
- **Description**: Field width as percentage of container width
- **Range**: `0.0` to `1.0`
- **Examples**:
```dart
1.0   // Full width (100%)
0.5   // Half width (50%)
0.33  // One third width (33%)
0.25  // Quarter width (25%)
```

#### `isVisible` (optional)
- **Type**: `bool`
- **Default**: `true`
- **Description**: Whether the field is currently displayed on the grid
- **Example**: `false` to hide field, `true` to show field

### Methods

#### `copyWith()`
```dart
FieldConfig copyWith({
  String? id,
  Offset? position,
  double? width,
  bool? isVisible,
})
```
- **Returns**: `FieldConfig`
- **Description**: Creates a copy with modified properties
- **Example**:
```dart
final newConfig = originalConfig.copyWith(
  position: Offset(0.5, 70),
  width: 0.75,
);
```

### Common Patterns

#### Side-by-Side Fields (50/50)
```dart
'firstName': FieldConfig(id: 'firstName', position: Offset(0, 0), width: 0.5),
'lastName': FieldConfig(id: 'lastName', position: Offset(0.5, 0), width: 0.5),
```

#### Three Equal Columns
```dart
'day': FieldConfig(id: 'day', position: Offset(0, 0), width: 0.33),
'month': FieldConfig(id: 'month', position: Offset(0.33, 0), width: 0.33),
'year': FieldConfig(id: 'year', position: Offset(0.66, 0), width: 0.33),
```

#### Full Width Header + Two Columns
```dart
'title': FieldConfig(id: 'title', position: Offset(0, 0), width: 1.0),
'address1': FieldConfig(id: 'address1', position: Offset(0, 70), width: 0.5),
'address2': FieldConfig(id: 'address2', position: Offset(0.5, 70), width: 0.5),
```

---

## 🎨 MagneticTheme

Provides theming utilities for the magnetic form builder.

### Static Properties

#### `lightTheme`
- **Type**: `ThemeData`
- **Description**: Built-in light theme optimized for magnetic forms
- **Example**:
```dart
MagneticFormBuilder(
  theme: MagneticTheme.lightTheme,
  // ...
)
```

#### `darkTheme`
- **Type**: `ThemeData`
- **Description**: Built-in dark theme optimized for magnetic forms
- **Example**:
```dart
MagneticFormBuilder(
  theme: MagneticTheme.darkTheme,
  // ...
)
```

### Static Methods

#### `withFieldExtensions()`
```dart
static ThemeData withFieldExtensions(ThemeData baseTheme)
```
- **Parameters**: `baseTheme` - Your custom theme
- **Returns**: `ThemeData` with field-specific extensions applied
- **Description**: Adds magnetic form field styling to your custom theme
- **Example**:
```dart
final customTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
);

MagneticFormBuilder(
  theme: MagneticTheme.withFieldExtensions(customTheme),
  // ...
)
```

---

## ⏱️ AnimationConstants

Contains timing and curve constants for form animations.

### Duration Constants

#### `previewDuration`
- **Type**: `Duration`
- **Value**: `Duration(milliseconds: 150)`
- **Description**: Animation duration for field preview during drag operations

#### `commitDuration`
- **Type**: `Duration`
- **Value**: `Duration(milliseconds: 300)`
- **Description**: Animation duration for field placement when dropping

#### `revertDuration`
- **Type**: `Duration`
- **Value**: `Duration(milliseconds: 200)`
- **Description**: Animation duration for reverting to original position

#### `defaultFieldAnimationDuration`
- **Type**: `Duration`
- **Value**: `Duration(milliseconds: 300)`
- **Description**: Default duration for general field animations

### Curve Constants

#### `previewCurve`
- **Type**: `Curve`
- **Value**: `Curves.easeOutQuart`
- **Description**: Animation curve for preview operations

#### `commitCurve`
- **Type**: `Curve`
- **Value**: `Curves.easeOutCubic`
- **Description**: Animation curve for field placement

#### `revertCurve`
- **Type**: `Curve`
- **Value**: `Curves.easeInOut`
- **Description**: Animation curve for reverting operations

#### `defaultFieldAnimationCurve`
- **Type**: `Curve`
- **Value**: `Curves.easeOutCubic`
- **Description**: Default curve for general field animations

### Usage Example

```dart
// Custom animation timing
AnimatedContainer(
  duration: AnimationConstants.commitDuration,
  curve: AnimationConstants.commitCurve,
  // ...
)
```

---

## 🧪 TestFieldBuilder

Utility class for creating test fields and configurations (used in examples).

### Static Methods

#### `createTestFields()`
```dart
static List<MagneticFormField> createTestFields()
```
- **Returns**: `List<MagneticFormField>`
- **Description**: Creates a comprehensive set of test form fields
- **Example**:
```dart
final testFields = TestFieldBuilder.createTestFields();
// Returns fields for: name, email, phone, address, etc.
```

#### `createDefaultConfigs()`
```dart
static Map<String, FieldConfig> createDefaultConfigs()
```
- **Returns**: `Map<String, FieldConfig>`
- **Description**: Creates default configurations for test fields
- **Example**:
```dart
final defaultConfigs = TestFieldBuilder.createDefaultConfigs();
// Returns optimized layout for test fields
```

### Usage Example

```dart
class ExampleFormScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MagneticFormBuilder(
      availableFields: TestFieldBuilder.createTestFields(),
      defaultFieldConfigs: TestFieldBuilder.createDefaultConfigs(),
      appBarTitle: 'Test Form',
    );
  }
}
```

---

## 🔧 Error Handling

### Common Errors and Solutions

#### `FieldConfig.id doesn't match any MagneticFormField.id`
```dart
// ❌ Error: Mismatched IDs
availableFields: [
  MagneticFormField(id: 'userName', ...),
],
defaultFieldConfigs: {
  'user_name': FieldConfig(...), // Different ID!
}

// ✅ Solution: Match IDs exactly
availableFields: [
  MagneticFormField(id: 'userName', ...),
],
defaultFieldConfigs: {
  'userName': FieldConfig(id: 'userName', ...), // Matching ID
}
```

#### `MagneticFormField.builder is required`
```dart
// ❌ Error: Missing builder
MagneticFormField(
  id: 'name',
  label: 'Name',
  icon: Icons.person,
  // Missing builder!
)

// ✅ Solution: Always provide builder
MagneticFormField(
  id: 'name',
  label: 'Name',
  icon: Icons.person,
  builder: (context, isCustomizationMode) => TextField(...),
)
```

#### `Field remains interactive during layout editing`
```dart
// ❌ Error: Field stays enabled during customization
builder: (context, isCustomizationMode) => TextField(
  // Missing enabled check
)

// ✅ Solution: Disable during customization
builder: (context, isCustomizationMode) => TextField(
  enabled: !isCustomizationMode, // Always include this
)
```

---

## 📊 Performance Considerations

### Best Practices

1. **Limit Field Count**: Optimal performance with < 50 fields
2. **Use RepaintBoundary**: Wrap expensive field widgets
3. **Optimize Builders**: Keep field builders lightweight
4. **Disable Animations**: For testing, set durations to `Duration.zero`

### Example Optimizations

```dart
// Wrap expensive widgets
builder: (context, isCustomizationMode) => RepaintBoundary(
  child: ComplexCustomWidget(),
)

// Lightweight builders
builder: (context, isCustomizationMode) => TextField(
  // Simple, fast widget
)

// Conditional complexity
builder: (context, isCustomizationMode) {
  if (isCustomizationMode) {
    return SimplePreviewWidget(); // Lightweight during editing
  }
  return FullFeaturedWidget();    // Full features during use
}
```

---

## 🔗 Related Documentation

- [README.md](README.md) - Getting started guide
- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Migration from other form builders
- [CHANGELOG.md](CHANGELOG.md) - Version history and changes
- [Example App](example/) - Complete working examples

---

## 📞 Support

- 🐛 [Report Issues](https://github.com/chchavarte/magneticform/issues)
- 💬 [Discussions](https://github.com/chchavarte/magneticform/discussions)
- 📖 [Documentation](https://pub.dev/documentation/magnetic_form_builder/latest/)