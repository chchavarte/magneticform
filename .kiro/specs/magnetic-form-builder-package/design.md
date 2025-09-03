# Design Document

## Overview

The Magnetic Form Builder package will be architected as a modular, extensible Flutter package that provides drag-and-drop form building capabilities with magnetic grid positioning. The design follows Flutter package best practices with a clean separation of concerns, extensible architecture, and comprehensive theming support.

The package will transform from a tightly-coupled app-specific implementation to a generic, reusable solution that can be easily integrated into any Flutter application while maintaining high performance and flexibility.

## Architecture

### Package Structure

```
magnetic_form_builder/
├── lib/
│   ├── magnetic_form_builder.dart          # Main export file
│   └── src/
│       ├── core/                           # Core functionality
│       │   ├── models/                     # Data models and configurations
│       │   ├── systems/                    # Grid and animation systems
│       │   └── constants/                  # Default configurations
│       ├── widgets/                        # UI components
│       │   ├── magnetic_form_builder.dart  # Main widget
│       │   ├── field_widgets/              # Field implementations
│       │   └── preview_widgets/            # Preview and drag components
│       ├── controllers/                    # State management
│       ├── themes/                         # Theming system
│       └── utils/                          # Utility functions
├── example/                                # Example application
├── test/                                   # Package tests
└── pubspec.yaml                           # Package configuration
```

### Core Design Principles

1. **Separation of Concerns**: Clear boundaries between UI, business logic, and data models
2. **Extensibility**: Plugin architecture for custom field types and behaviors
3. **Configurability**: Comprehensive configuration options without breaking simplicity
4. **Performance**: Efficient rendering and state management for complex forms
5. **Accessibility**: Full accessibility support following Flutter guidelines

## Components and Interfaces

### 1. Core Models

#### MagneticField Abstract Class
```dart
abstract class MagneticField {
  String get id;
  String get type;
  FieldCategory get category;
  
  Widget build(BuildContext context, FieldConfig config);
  Map<String, dynamic> get defaultProperties;
  List<PropertyDescriptor> get configurableProperties;
  
  // Validation support
  String? validate(dynamic value, List<ValidationRule> rules);
  
  // Serialization support
  Map<String, dynamic> toJson();
  static MagneticField fromJson(Map<String, dynamic> json);
}
```

#### FieldConfig Model
```dart
class FieldConfig {
  final String id;
  final String type;
  final GridPosition position;
  final Map<String, dynamic> properties;
  final List<ValidationRule> validationRules;
  final List<ConditionalRule> conditionalRules;
  
  // Immutable updates
  FieldConfig copyWith({...});
  
  // Serialization
  Map<String, dynamic> toJson();
  static FieldConfig fromJson(Map<String, dynamic> json);
}
```

#### GridPosition Model
```dart
class GridPosition {
  final int row;
  final int column;
  final int width;  // In grid units
  final int height; // In grid units
  
  // Validation and constraints
  bool isValidForGrid(MagneticGridConfig config);
  GridPosition snapToGrid(MagneticGridConfig config);
}
```

### 2. Configuration System

#### MagneticGridConfig
```dart
class MagneticGridConfig {
  final int columns;
  final double rowHeight;
  final List<double> allowedWidths;
  final EdgeInsets fieldPadding;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool enableSnapping;
  final double snapThreshold;
  
  // Grid calculations
  double getFieldWidth(int widthUnits);
  Size getFieldSize(int widthUnits, int heightUnits);
  Offset snapPosition(Offset position);
}
```

#### MagneticFormTheme
```dart
class MagneticFormTheme extends ThemeExtension<MagneticFormTheme> {
  final Color gridLineColor;
  final Color previewColor;
  final Color dragColor;
  final Color selectionColor;
  final TextStyle fieldLabelStyle;
  final TextStyle fieldValueStyle;
  final BoxDecoration fieldDecoration;
  final BoxDecoration previewDecoration;
  final BoxDecoration dragDecoration;
  final EdgeInsets fieldPadding;
  final BorderRadius fieldBorderRadius;
  
  @override
  MagneticFormTheme copyWith({...});
  
  @override
  MagneticFormTheme lerp(ThemeExtension<MagneticFormTheme>? other, double t);
}
```

### 3. State Management

#### FormBuilderController
```dart
class FormBuilderController extends ChangeNotifier {
  Map<String, FieldConfig> _fieldConfigs = {};
  String? _selectedFieldId;
  bool _isDragging = false;
  
  // Public API
  Map<String, FieldConfig> get fieldConfigs => Map.unmodifiable(_fieldConfigs);
  String? get selectedFieldId => _selectedFieldId;
  bool get isDragging => _isDragging;
  
  // Field management
  void addField(String type, {GridPosition? position});
  void removeField(String fieldId);
  void updateField(String fieldId, FieldConfig config);
  void moveField(String fieldId, GridPosition newPosition);
  void selectField(String? fieldId);
  void clearAll();
  
  // Drag operations
  void startDrag(String fieldId);
  void updateDragPosition(String fieldId, Offset position);
  void endDrag(String fieldId, GridPosition? finalPosition);
  
  // Serialization
  Map<String, dynamic> toJson();
  void fromJson(Map<String, dynamic> json);
  
  // Validation
  Map<String, String> validateAll();
  bool get isValid => validateAll().isEmpty;
}
```

### 4. Widget Architecture

#### MagneticFormBuilder (Main Widget)
```dart
class MagneticFormBuilder extends StatefulWidget {
  final List<MagneticField> availableFields;
  final MagneticGridConfig? gridConfig;
  final MagneticFormTheme? theme;
  final FormBuilderController? controller;
  
  // Callbacks
  final void Function(Map<String, FieldConfig>)? onFieldsChanged;
  final void Function(String fieldId, Map<String, dynamic> data)? onFieldConfigured;
  final void Function(String fieldId)? onFieldSelected;
  
  // Customization
  final Widget Function(BuildContext, MagneticField)? fieldBuilder;
  final Widget Function(BuildContext, String fieldId)? fieldConfigPanel;
  
  // Features
  final bool enablePreview;
  final bool enableHapticFeedback;
  final bool enableUndo;
  final bool showGrid;
  final bool allowFieldResize;
}
```

#### Field Registry System
```dart
class FieldRegistry {
  static final Map<String, MagneticField Function()> _factories = {};
  static final Map<String, FieldCategory> _categories = {};
  
  static void register<T extends MagneticField>(
    String type, 
    T Function() factory,
    FieldCategory category,
  );
  
  static MagneticField? create(String type);
  static List<String> getFieldTypes([FieldCategory? category]);
  static List<MagneticField> createDefaults();
}
```

### 5. Built-in Field Types

#### Standard Field Implementations
- **TextFieldWidget**: Single-line text input with validation
- **TextAreaFieldWidget**: Multi-line text input
- **EmailFieldWidget**: Email input with built-in validation
- **NumberFieldWidget**: Numeric input with formatting options
- **DateFieldWidget**: Date picker with customizable format
- **TimeFieldWidget**: Time picker
- **DropdownFieldWidget**: Single-select dropdown
- **MultiSelectFieldWidget**: Multi-select dropdown
- **CheckboxFieldWidget**: Single checkbox
- **CheckboxGroupFieldWidget**: Multiple checkboxes
- **RadioFieldWidget**: Radio button group
- **SliderFieldWidget**: Numeric slider
- **SwitchFieldWidget**: Toggle switch
- **FileUploadFieldWidget**: File selection
- **ImageFieldWidget**: Image upload and preview

#### Field Categories
```dart
enum FieldCategory {
  input,      // Text, email, number inputs
  selection,  // Dropdown, radio, checkbox
  date,       // Date, time, datetime
  media,      // Image, file upload
  layout,     // Divider, spacer, header
  custom,     // User-defined fields
}
```

## Data Models

### Field Property System
```dart
class PropertyDescriptor {
  final String key;
  final String label;
  final PropertyType type;
  final dynamic defaultValue;
  final List<dynamic>? options;
  final bool required;
  final String? helpText;
  
  Widget buildEditor(dynamic currentValue, ValueChanged<dynamic> onChanged);
}

enum PropertyType {
  string, number, boolean, color, list, object
}
```

### Validation System
```dart
abstract class FieldValidator {
  String? validate(dynamic value);
}

class ValidationRule {
  final FieldValidator validator;
  final String errorMessage;
  final bool required;
}

// Built-in validators
class RequiredValidator extends FieldValidator { ... }
class EmailValidator extends FieldValidator { ... }
class MinLengthValidator extends FieldValidator { ... }
class MaxLengthValidator extends FieldValidator { ... }
class RegexValidator extends FieldValidator { ... }
```

### Conditional Logic System
```dart
class ConditionalRule {
  final String triggerFieldId;
  final ConditionalOperator operator;
  final dynamic triggerValue;
  final ConditionalAction action;
  final dynamic actionValue;
}

enum ConditionalOperator {
  equals, notEquals, contains, greaterThan, lessThan, isEmpty, isNotEmpty
}

enum ConditionalAction {
  show, hide, enable, disable, setValue, setOptions
}
```

## Error Handling

### Error Types and Handling Strategy

1. **Configuration Errors**: Invalid grid configurations, theme properties
   - Validation at configuration time with helpful error messages
   - Fallback to default values with warnings

2. **Field Registration Errors**: Duplicate field types, invalid field implementations
   - Runtime validation with clear error messages
   - Graceful degradation by skipping invalid fields

3. **Serialization Errors**: Invalid JSON data, missing required fields
   - Comprehensive error handling with detailed error messages
   - Partial recovery where possible

4. **Validation Errors**: Field validation failures, conditional logic errors
   - User-friendly error messages with field highlighting
   - Non-blocking errors that allow continued editing

### Error Reporting System
```dart
class MagneticFormError {
  final String code;
  final String message;
  final String? fieldId;
  final Map<String, dynamic>? context;
  
  @override
  String toString() => 'MagneticFormError($code): $message';
}

typedef ErrorHandler = void Function(MagneticFormError error);
```

## Testing Strategy

### Unit Testing
- **Model Tests**: Serialization, validation, immutability
- **Controller Tests**: State management, field operations, callbacks
- **Validator Tests**: All built-in validation rules
- **Utility Tests**: Grid calculations, positioning algorithms

### Widget Testing
- **Field Widget Tests**: Rendering, interaction, configuration
- **Main Widget Tests**: Layout, drag-and-drop, theming
- **Integration Tests**: Complete user workflows

### Performance Testing
- **Large Form Tests**: Performance with 100+ fields
- **Animation Tests**: Smooth animations under load
- **Memory Tests**: Memory usage and leak detection

### Accessibility Testing
- **Screen Reader Tests**: Proper semantic labels and navigation
- **Keyboard Navigation**: Full keyboard accessibility
- **High Contrast**: Proper contrast ratios and theming

## Implementation Phases

### Phase 1: Core Infrastructure
- Package structure and build system
- Core models and interfaces
- Basic grid system
- Simple field implementations

### Phase 2: Advanced Features
- Complete theming system
- All built-in field types
- Validation system
- State management and controllers

### Phase 3: Extended Functionality
- Conditional logic system
- Form generation capabilities
- Advanced customization options
- Performance optimizations

### Phase 4: Polish and Distribution
- Comprehensive testing
- Documentation and examples
- Accessibility compliance
- Pub.dev publication

## Performance Considerations

### Rendering Optimization
- **Lazy Loading**: Only render visible fields during scrolling
- **Widget Recycling**: Reuse field widgets where possible
- **Efficient Rebuilds**: Minimize widget rebuilds during drag operations

### Memory Management
- **Weak References**: Prevent memory leaks in controller relationships
- **Disposal**: Proper cleanup of controllers and listeners
- **Image Caching**: Efficient handling of field icons and previews

### Animation Performance
- **Hardware Acceleration**: Use Transform widgets for smooth animations
- **Animation Batching**: Batch multiple field movements
- **Reduced Complexity**: Simplify animations during heavy operations

This design provides a solid foundation for creating a highly reusable, performant, and extensible Flutter form builder package that meets all the specified requirements while maintaining clean architecture and excellent developer experience.