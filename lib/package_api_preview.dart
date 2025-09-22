// PREVIEW: How the package API would look after transformation
// This is a conceptual preview of the reusable package structure

import 'package:flutter/material.dart';

// ============================================================================
// MAIN PACKAGE API - What users would import and use
// ============================================================================

/// Main widget for the Magnetic Form Builder package
class MagneticFormBuilder extends StatefulWidget {
  /// Available field types that can be dragged onto the form
  final List<MagneticField> availableFields;
  
  /// Configuration for the magnetic grid system
  final MagneticGridConfig? gridConfig;
  
  /// Theme configuration for visual styling
  final MagneticFormTheme? theme;
  
  /// Controller for programmatic form manipulation
  final FormBuilderController? controller;
  
  /// Callback when field configuration changes
  final void Function(Map<String, FieldConfig>)? onFieldsChanged;
  
  /// Callback when a field is configured/edited
  final void Function(String fieldId, Map<String, dynamic> data)? onFieldConfigured;
  
  /// Custom builder for field widgets
  final Widget Function(BuildContext, MagneticField, FieldConfig)? fieldBuilder;
  
  /// Enable/disable preview-on-hover functionality
  final bool enablePreview;
  
  /// Enable/disable haptic feedback
  final bool enableHapticFeedback;
  
  /// Enable/disable field editing
  final bool enableFieldEditing;
  
  /// Custom validation rules
  final Map<String, List<ValidationRule>>? validationRules;

  const MagneticFormBuilder({
    super.key,
    required this.availableFields,
    this.gridConfig,
    this.theme,
    this.controller,
    this.onFieldsChanged,
    this.onFieldConfigured,
    this.fieldBuilder,
    this.enablePreview = true,
    this.enableHapticFeedback = true,
    this.enableFieldEditing = true,
    this.validationRules,
  });

  @override
  State<MagneticFormBuilder> createState() => _MagneticFormBuilderState();
}

class _MagneticFormBuilderState extends State<MagneticFormBuilder> {
  @override
  Widget build(BuildContext context) {
    // Implementation would use the existing sophisticated logic
    // but with configurable parameters and clean API
    return Container(
      child: Text('Magnetic Form Builder Implementation'),
    );
  }
}

// ============================================================================
// CONFIGURATION CLASSES
// ============================================================================

/// Configuration for the magnetic grid system
class MagneticGridConfig {
  /// Number of columns in the grid (default: 6)
  final int columns;
  
  /// Height of each row in pixels (default: 70.0)
  final double rowHeight;
  
  /// Allowed field widths as fractions (default: [2/6, 3/6, 4/6, 6/6])
  final List<double> allowedWidths;
  
  /// Padding around each field (default: EdgeInsets.all(4.0))
  final EdgeInsets fieldPadding;
  
  /// Animation duration for transitions (default: 300ms)
  final Duration animationDuration;
  
  /// Animation curve for transitions (default: Curves.easeInOut)
  final Curve animationCurve;
  
  /// Snap threshold for magnetic positioning (default: 30.0)
  final double snapThreshold;
  
  /// Maximum number of rows (default: 12)
  final int maxRows;

  const MagneticGridConfig({
    this.columns = 6,
    this.rowHeight = 70.0,
    this.allowedWidths = const [2/6, 3/6, 4/6, 6/6],
    this.fieldPadding = const EdgeInsets.all(4.0),
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.snapThreshold = 30.0,
    this.maxRows = 12,
  });
}

/// Theme configuration for visual styling
class MagneticFormTheme extends ThemeExtension<MagneticFormTheme> {
  /// Color for grid lines
  final Color gridLineColor;
  
  /// Color for preview indicators
  final Color previewColor;
  
  /// Color for dragged fields
  final Color dragColor;
  
  /// Text style for field labels
  final TextStyle fieldLabelStyle;
  
  /// Decoration for normal fields
  final BoxDecoration fieldDecoration;
  
  /// Decoration for preview fields
  final BoxDecoration previewDecoration;
  
  /// Decoration for dragged fields
  final BoxDecoration dragDecoration;

  const MagneticFormTheme({
    required this.gridLineColor,
    required this.previewColor,
    required this.dragColor,
    required this.fieldLabelStyle,
    required this.fieldDecoration,
    required this.previewDecoration,
    required this.dragDecoration,
  });

  @override
  MagneticFormTheme copyWith({
    Color? gridLineColor,
    Color? previewColor,
    Color? dragColor,
    TextStyle? fieldLabelStyle,
    BoxDecoration? fieldDecoration,
    BoxDecoration? previewDecoration,
    BoxDecoration? dragDecoration,
  }) {
    return MagneticFormTheme(
      gridLineColor: gridLineColor ?? this.gridLineColor,
      previewColor: previewColor ?? this.previewColor,
      dragColor: dragColor ?? this.dragColor,
      fieldLabelStyle: fieldLabelStyle ?? this.fieldLabelStyle,
      fieldDecoration: fieldDecoration ?? this.fieldDecoration,
      previewDecoration: previewDecoration ?? this.previewDecoration,
      dragDecoration: dragDecoration ?? this.dragDecoration,
    );
  }

  @override
  MagneticFormTheme lerp(ThemeExtension<MagneticFormTheme>? other, double t) {
    if (other is! MagneticFormTheme) return this;
    return MagneticFormTheme(
      gridLineColor: Color.lerp(gridLineColor, other.gridLineColor, t)!,
      previewColor: Color.lerp(previewColor, other.previewColor, t)!,
      dragColor: Color.lerp(dragColor, other.dragColor, t)!,
      fieldLabelStyle: TextStyle.lerp(fieldLabelStyle, other.fieldLabelStyle, t)!,
      fieldDecoration: BoxDecoration.lerp(fieldDecoration, other.fieldDecoration, t)!,
      previewDecoration: BoxDecoration.lerp(previewDecoration, other.previewDecoration, t)!,
      dragDecoration: BoxDecoration.lerp(dragDecoration, other.dragDecoration, t)!,
    );
  }
}

// ============================================================================
// ABSTRACT FIELD SYSTEM
// ============================================================================

/// Abstract base class for all magnetic fields
abstract class MagneticField {
  /// Unique identifier for this field type
  String get type;
  
  /// Display name for this field type
  String get displayName;
  
  /// Icon representing this field type
  IconData get icon;
  
  /// Category this field belongs to
  FieldCategory get category;
  
  /// Default properties for new instances
  Map<String, dynamic> get defaultProperties;
  
  /// List of configurable properties
  List<PropertyDescriptor> get configurableProperties;
  
  /// Build the field widget
  Widget build(BuildContext context, FieldConfig config);
  
  /// Validate field data
  String? validate(dynamic value, Map<String, ValidationRule> rules);
}

/// Categories for organizing fields
enum FieldCategory {
  input,      // Text, email, number
  selection,  // Dropdown, radio, checkbox
  date,       // Date, time, datetime
  media,      // Image, file upload
  layout,     // Divider, spacer, header
  custom,     // User-defined fields
}

/// Descriptor for configurable properties
class PropertyDescriptor {
  final String key;
  final String displayName;
  final PropertyType type;
  final dynamic defaultValue;
  final List<dynamic>? options; // For enum/selection types
  final String? description;

  const PropertyDescriptor({
    required this.key,
    required this.displayName,
    required this.type,
    required this.defaultValue,
    this.options,
    this.description,
  });
}

enum PropertyType {
  string,
  number,
  boolean,
  color,
  selection,
  multiSelection,
}

// ============================================================================
// CONTROLLER PATTERN
// ============================================================================

/// Controller for programmatic form manipulation
class FormBuilderController extends ChangeNotifier {
  Map<String, FieldConfig> _fieldConfigs = {};
  
  /// Get all field configurations (read-only)
  Map<String, FieldConfig> get fieldConfigs => Map.unmodifiable(_fieldConfigs);
  
  /// Add a new field to the form
  void addField(String type, {Offset? position, Map<String, dynamic>? properties}) {
    // Implementation
    notifyListeners();
  }
  
  /// Remove a field from the form
  void removeField(String fieldId) {
    _fieldConfigs.remove(fieldId);
    notifyListeners();
  }
  
  /// Update field configuration
  void updateField(String fieldId, FieldConfig config) {
    _fieldConfigs[fieldId] = config;
    notifyListeners();
  }
  
  /// Clear all fields
  void clearAll() {
    _fieldConfigs.clear();
    notifyListeners();
  }
  
  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'fields': _fieldConfigs.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
  
  /// Deserialize from JSON
  void fromJson(Map<String, dynamic> json) {
    final fieldsData = json['fields'] as Map<String, dynamic>? ?? {};
    _fieldConfigs = fieldsData.map(
      (key, value) => MapEntry(key, FieldConfig.fromJson(value)),
    );
    notifyListeners();
  }
}

// ============================================================================
// VALIDATION SYSTEM
// ============================================================================

/// Abstract validator for field values
abstract class FieldValidator {
  String? validate(dynamic value);
}

/// Validation rule combining validator and error message
class ValidationRule {
  final FieldValidator validator;
  final String errorMessage;
  
  const ValidationRule(this.validator, this.errorMessage);
}

/// Built-in validators
class Validators {
  static FieldValidator required() => RequiredValidator();
  static FieldValidator email() => EmailValidator();
  static FieldValidator minLength(int length) => MinLengthValidator(length);
  static FieldValidator maxLength(int length) => MaxLengthValidator(length);
  static FieldValidator pattern(String pattern) => PatternValidator(pattern);
}

class RequiredValidator extends FieldValidator {
  @override
  String? validate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}

class EmailValidator extends FieldValidator {
  @override
  String? validate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.toString())) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}

class MinLengthValidator extends FieldValidator {
  final int minLength;
  
  MinLengthValidator(this.minLength);
  
  @override
  String? validate(dynamic value) {
    if (value == null || value.toString().length < minLength) {
      return 'Must be at least $minLength characters';
    }
    return null;
  }
}

class MaxLengthValidator extends FieldValidator {
  final int maxLength;
  
  MaxLengthValidator(this.maxLength);
  
  @override
  String? validate(dynamic value) {
    if (value != null && value.toString().length > maxLength) {
      return 'Must be no more than $maxLength characters';
    }
    return null;
  }
}

class PatternValidator extends FieldValidator {
  final String pattern;
  
  PatternValidator(this.pattern);
  
  @override
  String? validate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    
    final regex = RegExp(pattern);
    if (!regex.hasMatch(value.toString())) {
      return 'Invalid format';
    }
    return null;
  }
}

// ============================================================================
// BUILT-IN FIELD TYPES
// ============================================================================

/// Text input field
class TextFieldWidget extends MagneticField {
  @override
  String get type => 'text';
  
  @override
  String get displayName => 'Text Field';
  
  @override
  IconData get icon => Icons.text_fields;
  
  @override
  FieldCategory get category => FieldCategory.input;
  
  @override
  Map<String, dynamic> get defaultProperties => {
    'label': 'Text Field',
    'placeholder': 'Enter text...',
    'required': false,
    'maxLength': null,
  };
  
  @override
  List<PropertyDescriptor> get configurableProperties => [
    PropertyDescriptor(
      key: 'label',
      displayName: 'Label',
      type: PropertyType.string,
      defaultValue: 'Text Field',
    ),
    PropertyDescriptor(
      key: 'placeholder',
      displayName: 'Placeholder',
      type: PropertyType.string,
      defaultValue: 'Enter text...',
    ),
    PropertyDescriptor(
      key: 'required',
      displayName: 'Required',
      type: PropertyType.boolean,
      defaultValue: false,
    ),
    PropertyDescriptor(
      key: 'maxLength',
      displayName: 'Max Length',
      type: PropertyType.number,
      defaultValue: null,
    ),
  ];
  
  @override
  Widget build(BuildContext context, FieldConfig config) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: config.metadata['label'] as String?,
        hintText: config.metadata['placeholder'] as String?,
      ),
      maxLength: config.metadata['maxLength'] as int?,
    );
  }
  
  @override
  String? validate(dynamic value, Map<String, ValidationRule> rules) {
    for (final rule in rules.values) {
      final error = rule.validator.validate(value);
      if (error != null) return error;
    }
    return null;
  }
}

/// Email input field
class EmailFieldWidget extends MagneticField {
  @override
  String get type => 'email';
  
  @override
  String get displayName => 'Email Field';
  
  @override
  IconData get icon => Icons.email;
  
  @override
  FieldCategory get category => FieldCategory.input;
  
  @override
  Map<String, dynamic> get defaultProperties => {
    'label': 'Email',
    'placeholder': 'Enter email address...',
    'required': false,
  };
  
  @override
  List<PropertyDescriptor> get configurableProperties => [
    PropertyDescriptor(
      key: 'label',
      displayName: 'Label',
      type: PropertyType.string,
      defaultValue: 'Email',
    ),
    PropertyDescriptor(
      key: 'placeholder',
      displayName: 'Placeholder',
      type: PropertyType.string,
      defaultValue: 'Enter email address...',
    ),
    PropertyDescriptor(
      key: 'required',
      displayName: 'Required',
      type: PropertyType.boolean,
      defaultValue: false,
    ),
  ];
  
  @override
  Widget build(BuildContext context, FieldConfig config) {
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: config.metadata['label'] as String?,
        hintText: config.metadata['placeholder'] as String?,
      ),
    );
  }
  
  @override
  String? validate(dynamic value, Map<String, ValidationRule> rules) {
    for (final rule in rules.values) {
      final error = rule.validator.validate(value);
      if (error != null) return error;
    }
    return null;
  }
}

// ============================================================================
// FIELD REGISTRY SYSTEM
// ============================================================================

/// Registry for managing field types
class FieldRegistry {
  static final Map<String, MagneticField Function()> _fields = {};
  
  /// Register a field type
  static void register<T extends MagneticField>(
    String type, 
    T Function() factory,
  ) {
    _fields[type] = factory;
  }
  
  /// Create a field instance by type
  static MagneticField? create(String type) {
    return _fields[type]?.call();
  }
  
  /// Get all registered field types
  static List<String> get registeredTypes => _fields.keys.toList();
  
  /// Get all registered fields
  static List<MagneticField> get registeredFields {
    return _fields.values.map((factory) => factory()).toList();
  }
  
  /// Register built-in field types
  static void registerBuiltInFields() {
    register('text', () => TextFieldWidget());
    register('email', () => EmailFieldWidget());
    // Add more built-in types...
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

class ExampleUsage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Register built-in fields
    FieldRegistry.registerBuiltInFields();
    
    // Simple usage
    return MagneticFormBuilder(
      availableFields: FieldRegistry.registeredFields,
      onFieldsChanged: (configs) {
        // Form updated callback
      },
    );
  }
}

class AdvancedExampleUsage extends StatelessWidget {
  final FormBuilderController controller = FormBuilderController();
  
  @override
  Widget build(BuildContext context) {
    return MagneticFormBuilder(
      availableFields: [
        TextFieldWidget(),
        EmailFieldWidget(),
      ],
      gridConfig: MagneticGridConfig(
        columns: 8,
        rowHeight: 80.0,
        allowedWidths: [1/8, 2/8, 3/8, 4/8, 6/8, 8/8],
      ),
      theme: MagneticFormTheme(
        gridLineColor: Colors.blue.withOpacity(0.3),
        previewColor: Colors.green.withOpacity(0.3),
        dragColor: Colors.orange.withOpacity(0.5),
        fieldLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        fieldDecoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        previewDecoration: BoxDecoration(
          border: Border.all(color: Colors.green, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
        ),
        dragDecoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
      ),
      controller: controller,
      validationRules: {
        'email': [
          ValidationRule(Validators.required(), 'Email is required'),
          ValidationRule(Validators.email(), 'Invalid email format'),
        ],
      },
      onFieldsChanged: (configs) {
        // Form configuration changed callback
      },
      onFieldConfigured: (fieldId, data) {
        // Field configured callback
      },
    );
  }
}

// Placeholder for existing FieldConfig class
class FieldConfig {
  final String id;
  final String type;
  final String label;
  final Offset position;
  final double width;
  final bool isVisible;
  final bool isRequired;
  final Map<String, dynamic> metadata;

  const FieldConfig({
    required this.id,
    required this.type,
    required this.label,
    required this.position,
    required this.width,
    this.isVisible = true,
    this.isRequired = false,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'position': {'dx': position.dx, 'dy': position.dy},
    'width': width,
    'isVisible': isVisible,
    'isRequired': isRequired,
    'metadata': metadata,
  };

  factory FieldConfig.fromJson(Map<String, dynamic> json) {
    return FieldConfig(
      id: json['id'],
      type: json['type'],
      label: json['label'],
      position: Offset(json['position']['dx'], json['position']['dy']),
      width: json['width'],
      isVisible: json['isVisible'] ?? true,
      isRequired: json['isRequired'] ?? false,
      metadata: json['metadata'] ?? {},
    );
  }
}