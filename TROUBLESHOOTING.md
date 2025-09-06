# 🔧 Troubleshooting Guide

Common issues and solutions when using Magnetic Form Builder.

## 📋 Table of Contents

- [Installation Issues](#installation-issues)
- [Configuration Errors](#configuration-errors)
- [Runtime Errors](#runtime-errors)
- [Performance Issues](#performance-issues)
- [UI/UX Problems](#uiux-problems)
- [Integration Issues](#integration-issues)
- [Best Practices](#best-practices)

---

## 📦 Installation Issues

### Package Not Found

**Error**: `Could not find package magnetic_form_builder`

**Solution**:
```yaml
# pubspec.yaml
dependencies:
  magnetic_form_builder:
    git:
      url: https://github.com/chchavarte/magneticform.git
```

Then run:
```bash
flutter pub get
```

### Import Errors

**Error**: `Target of URI doesn't exist: 'package:magnetic_form_builder/magnetic_form_builder.dart'`

**Solution**:
1. Ensure the package is properly added to `pubspec.yaml`
2. Run `flutter pub get`
3. Restart your IDE
4. Use the correct import:
```dart
import 'package:magnetic_form_builder/magnetic_form_builder.dart';
```

---

## ⚙️ Configuration Errors

### Mismatched Field IDs

**Error**: `FieldConfig.id 'userName' doesn't match any MagneticFormField.id`

**Problem**: Field IDs in `defaultFieldConfigs` don't match `availableFields` IDs.

**Solution**:
```dart
// ❌ Wrong - IDs don't match
availableFields: [
  MagneticFormField(id: 'user_name', ...),
],
defaultFieldConfigs: {
  'userName': FieldConfig(...), // Different ID!
}

// ✅ Correct - IDs match exactly
availableFields: [
  MagneticFormField(id: 'userName', ...),
],
defaultFieldConfigs: {
  'userName': FieldConfig(id: 'userName', ...), // Matching ID
}
```

### Missing Required Parameters

**Error**: `The parameter 'builder' is required`

**Problem**: Missing required parameters in `MagneticFormField`.

**Solution**:
```dart
// ❌ Wrong - missing required parameters
MagneticFormField(
  id: 'name',
  // Missing: label, icon, builder
)

// ✅ Correct - all required parameters provided
MagneticFormField(
  id: 'name',
  label: 'Full Name',        // Required
  icon: Icons.person,        // Required
  builder: (context, isCustomizationMode) => TextField(...), // Required
)
```

### Invalid Position Values

**Error**: Fields appear in wrong positions or overlap incorrectly.

**Problem**: Invalid `Offset` values in `FieldConfig`.

**Solution**:
```dart
// ❌ Wrong - invalid position values
FieldConfig(
  position: Offset(-1, 0),    // Negative x not allowed
  width: 1.5,                 // Width > 1.0 not allowed
)

// ✅ Correct - valid position values
FieldConfig(
  position: Offset(0, 0),     // x: 0.0-1.0, y: 0+
  width: 1.0,                 // width: 0.0-1.0
)
```

---

## 🚨 Runtime Errors

### Fields Remain Interactive During Customization

**Problem**: Fields can be edited while in layout customization mode.

**Solution**: Always disable fields during customization:
```dart
// ❌ Wrong - field stays interactive
builder: (context, isCustomizationMode) => TextField(
  decoration: InputDecoration(labelText: 'Name'),
  // Missing enabled check!
)

// ✅ Correct - field disabled during customization
builder: (context, isCustomizationMode) => TextField(
  decoration: InputDecoration(labelText: 'Name'),
  enabled: !isCustomizationMode, // Essential!
)
```

### Form Data Not Updating

**Problem**: `onFormDataChanged` not called or form data not persisting.

**Solution**:
```dart
// ❌ Wrong - not handling form data changes
MagneticFormBuilder(
  onFormDataChanged: (formData) {
    print(formData); // Only logging, not storing
  },
)

// ✅ Correct - properly handling form data
class MyFormState extends State<MyForm> {
  final Map<String, dynamic> _formData = {};

  @override
  Widget build(BuildContext context) {
    return MagneticFormBuilder(
      onFormDataChanged: (formData) {
        setState(() {
          _formData.addAll(formData); // Store the data
        });
      },
    );
  }
}
```

### Layout Not Persisting

**Problem**: Field layout changes are lost when app restarts.

**Solution**: Provide a unique `storageKey`:
```dart
// ❌ Wrong - no persistence
MagneticFormBuilder(
  // Missing storageKey
)

// ✅ Correct - layout persists
MagneticFormBuilder(
  storageKey: 'my_form_layout', // Unique key for this form
)
```

### Null Safety Errors

**Error**: `Null check operator used on a null value`

**Problem**: Not handling null values properly in form data.

**Solution**:
```dart
// ❌ Wrong - not handling nulls
onChanged: (value) {
  _formData['field'] = value.toUpperCase(); // Crashes if value is null
}

// ✅ Correct - safe null handling
onChanged: (value) {
  _formData['field'] = value?.toUpperCase() ?? '';
}

// Or check for null explicitly
onChanged: (value) {
  if (value != null && value.isNotEmpty) {
    _formData['field'] = value;
  }
}
```

---

## 🐌 Performance Issues

### Slow Drag Operations

**Problem**: Laggy or stuttering animations during field dragging.

**Solutions**:

1. **Reduce field count**:
```dart
// Optimal performance with < 50 fields
// Consider pagination for larger forms
```

2. **Use RepaintBoundary for expensive widgets**:
```dart
builder: (context, isCustomizationMode) => RepaintBoundary(
  child: ExpensiveCustomWidget(),
)
```

3. **Simplify widgets during customization**:
```dart
builder: (context, isCustomizationMode) {
  if (isCustomizationMode) {
    return Container(
      height: 48,
      child: Text('Field Preview'), // Lightweight preview
    );
  }
  return ComplexFormField(); // Full widget only when needed
}
```

### Memory Usage Issues

**Problem**: High memory usage with many fields.

**Solutions**:

1. **Dispose controllers properly**:
```dart
class MyFormState extends State<MyForm> {
  final List<TextEditingController> _controllers = [];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose(); // Important!
    }
    super.dispose();
  }
}
```

2. **Use lazy loading for large forms**:
```dart
// Only create fields that are currently visible
builder: (context, isCustomizationMode) {
  return LazyLoadingField(
    onVisible: () => createExpensiveField(),
  );
}
```

### Animation Performance

**Problem**: Choppy animations or frame drops.

**Solutions**:

1. **Disable animations during testing**:
```dart
// In main.dart for testing
AnimationConstants.previewDuration = Duration.zero;
AnimationConstants.commitDuration = Duration.zero;
```

2. **Use lighter animation curves**:
```dart
// Custom animation settings
AnimationConstants.previewCurve = Curves.linear; // Lighter than easeOut
```

---

## 🎨 UI/UX Problems

### Fields Overlapping

**Problem**: Fields appear on top of each other.

**Cause**: Incorrect position calculations or width values.

**Solution**:
```dart
// ❌ Wrong - overlapping fields
'field1': FieldConfig(position: Offset(0, 0), width: 0.7),
'field2': FieldConfig(position: Offset(0.5, 0), width: 0.7), // Overlaps!

// ✅ Correct - non-overlapping fields
'field1': FieldConfig(position: Offset(0, 0), width: 0.5),
'field2': FieldConfig(position: Offset(0.5, 0), width: 0.5), // Perfect fit
```

### Theme Not Applied

**Problem**: Custom theme not showing up.

**Solutions**:

1. **Use MagneticTheme.withFieldExtensions**:
```dart
// ❌ Wrong - theme not processed
MagneticFormBuilder(
  theme: ThemeData(primarySwatch: Colors.blue),
)

// ✅ Correct - theme properly processed
MagneticFormBuilder(
  theme: MagneticTheme.withFieldExtensions(
    ThemeData(primarySwatch: Colors.blue),
  ),
)
```

2. **Check theme inheritance**:
```dart
// If no theme provided, inherits from MaterialApp
MaterialApp(
  theme: ThemeData(primarySwatch: Colors.green),
  home: MagneticFormBuilder(
    // Will use green theme from MaterialApp
  ),
)
```

### Responsive Issues

**Problem**: Form doesn't look good on different screen sizes.

**Solutions**:

1. **Use percentage-based widths**:
```dart
// ✅ Good - responsive widths
'field': FieldConfig(width: 0.5), // Always 50% of container

// ❌ Avoid - fixed pixel widths in custom calculations
```

2. **Test on different screen sizes**:
```dart
// Use device preview or physical devices
// Consider tablet layouts vs phone layouts
```

---

## 🔗 Integration Issues

### State Management Integration

**Problem**: Integrating with Provider, Bloc, or other state management.

**Solution with Provider**:
```dart
class FormProvider extends ChangeNotifier {
  Map<String, dynamic> _formData = {};
  
  void updateFormData(Map<String, dynamic> newData) {
    _formData.addAll(newData);
    notifyListeners();
  }
}

// In widget
Consumer<FormProvider>(
  builder: (context, formProvider, child) {
    return MagneticFormBuilder(
      onFormDataChanged: formProvider.updateFormData,
    );
  },
)
```

**Solution with Bloc**:
```dart
class FormBloc extends Bloc<FormEvent, FormState> {
  FormBloc() : super(FormInitial()) {
    on<FormDataChanged>((event, emit) {
      emit(FormUpdated(event.formData));
    });
  }
}

// In widget
BlocBuilder<FormBloc, FormState>(
  builder: (context, state) {
    return MagneticFormBuilder(
      onFormDataChanged: (formData) {
        context.read<FormBloc>().add(FormDataChanged(formData));
      },
    );
  },
)
```

### Navigation Integration

**Problem**: Form data lost during navigation.

**Solution**:
```dart
// Save form data before navigation
void navigateToNextPage() {
  // Save current form state
  final formState = {
    'formData': _formData,
    'fieldConfigs': _fieldConfigs,
  };
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => NextPage(formState: formState),
    ),
  );
}
```

### Validation Library Integration

**Problem**: Integrating with form validation packages.

**Solution with form_validator**:
```dart
import 'package:form_validator/form_validator.dart';

final validator = ValidationBuilder()
    .email()
    .maxLength(50)
    .build();

builder: (context, isCustomizationMode) => TextField(
  decoration: InputDecoration(
    errorText: _errors['email'],
  ),
  onChanged: (value) {
    final error = validator(value);
    setState(() {
      _errors['email'] = error;
    });
  },
)
```

---

## ✅ Best Practices

### 1. Field ID Naming

```dart
// ✅ Good - descriptive, consistent naming
'userEmail'
'billingAddress'
'phoneNumber'
'birthDate'

// ❌ Avoid - generic or inconsistent naming
'field1'
'input_2'
'textField'
'data'
```

### 2. Error Handling

```dart
// ✅ Good - comprehensive error handling
class MyFormState extends State<MyForm> {
  final Map<String, String?> _errors = {};
  
  void _validateField(String fieldId, String? value) {
    String? error;
    
    try {
      // Validation logic
      if (fieldId == 'email' && !isValidEmail(value)) {
        error = 'Invalid email format';
      }
    } catch (e) {
      error = 'Validation error: ${e.toString()}';
    }
    
    setState(() {
      _errors[fieldId] = error;
    });
  }
}
```

### 3. Performance Optimization

```dart
// ✅ Good - optimized field builders
builder: (context, isCustomizationMode) {
  // Cache expensive computations
  final decoration = _cachedDecorations[fieldId] ??= InputDecoration(
    labelText: label,
    border: OutlineInputBorder(),
  );
  
  return TextField(
    decoration: decoration,
    enabled: !isCustomizationMode,
  );
}
```

### 4. Accessibility

```dart
// ✅ Good - accessible form fields
builder: (context, isCustomizationMode) => Semantics(
  label: 'Email address input field',
  hint: 'Enter your email address',
  child: TextField(
    decoration: InputDecoration(
      labelText: 'Email',
      helperText: 'We will not share your email',
    ),
  ),
)
```

### 5. Testing

```dart
// ✅ Good - testable form structure
class TestableForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>)? onDataChanged;
  
  // Expose data for testing
  static Map<String, dynamic>? getFormData(BuildContext context) {
    final state = context.findAncestorStateOfType<_TestableFormState>();
    return state?._formData;
  }
}
```

---

## 🆘 Getting Help

If you're still experiencing issues:

1. **Check the examples**: [EXAMPLES.md](EXAMPLES.md)
2. **Review the API reference**: [API_REFERENCE.md](API_REFERENCE.md)
3. **Search existing issues**: [GitHub Issues](https://github.com/chchavarte/magneticform/issues)
4. **Create a new issue** with:
   - Flutter version (`flutter --version`)
   - Package version
   - Minimal reproduction code
   - Expected vs actual behavior
   - Error messages (full stack trace)

## 📞 Support Channels

- 🐛 [Bug Reports](https://github.com/chchavarte/magneticform/issues/new?template=bug_report.md)
- 💡 [Feature Requests](https://github.com/chchavarte/magneticform/issues/new?template=feature_request.md)
- 💬 [Discussions](https://github.com/chchavarte/magneticform/discussions)
- 📖 [Documentation](https://pub.dev/documentation/magnetic_form_builder/latest/)