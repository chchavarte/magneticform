# 🔄 Migration Guide

This guide helps you migrate from other form building solutions to Magnetic Form Builder.

## 📋 Table of Contents

- [From Flutter Form Builder](#from-flutter-form-builder)
- [From Manual Form Layout](#from-manual-form-layout)
- [From Reactive Forms](#from-reactive-forms)
- [From Custom Form Solutions](#from-custom-form-solutions)
- [Common Migration Patterns](#common-migration-patterns)
- [Best Practices](#best-practices)

---

## 🔧 From Flutter Form Builder

### Before (FormBuilder)

```dart
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class OldFormScreen extends StatefulWidget {
  @override
  _OldFormScreenState createState() => _OldFormScreenState();
}

class _OldFormScreenState extends State<OldFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Form')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              FormBuilderTextField(
                name: 'name',
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: FormBuilderValidators.required(),
              ),
              SizedBox(height: 16),
              FormBuilderTextField(
                name: 'email',
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.email(),
                ]),
              ),
              SizedBox(height: 16),
              FormBuilderDropdown(
                name: 'country',
                decoration: InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
                items: ['USA', 'Canada', 'UK']
                    .map((country) => DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        ))
                    .toList(),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final formData = _formKey.currentState!.value;
                    print('Form Data: $formData');
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### After (MagneticFormBuilder)

```dart
import 'package:flutter/material.dart';
import 'package:magnetic_form_builder/magnetic_form_builder.dart';

class NewFormScreen extends StatefulWidget {
  @override
  _NewFormScreenState createState() => _NewFormScreenState();
}

class _NewFormScreenState extends State<NewFormScreen> {
  final Map<String, dynamic> _formData = {};
  final Map<String, String?> _errors = {};

  // Validation functions
  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return _validateRequired(value);
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MagneticFormBuilder(
        availableFields: [
          MagneticFormField(
            id: 'name',
            label: 'Full Name',
            icon: Icons.person,
            isMandatory: true, // Equivalent to FormBuilderValidators.required()
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                errorText: _errors['name'],
              ),
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['name'] = value;
                  _errors['name'] = _validateRequired(value);
                });
              },
            ),
          ),
          MagneticFormField(
            id: 'email',
            label: 'Email',
            icon: Icons.email,
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                errorText: _errors['email'],
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['email'] = value;
                  _errors['email'] = _validateEmail(value);
                });
              },
            ),
          ),
          MagneticFormField(
            id: 'country',
            label: 'Country',
            icon: Icons.public,
            builder: (context, isCustomizationMode) => DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
              ),
              value: _formData['country'],
              items: ['USA', 'Canada', 'UK']
                  .map((country) => DropdownMenuItem(
                        value: country,
                        child: Text(country),
                      ))
                  .toList(),
              onChanged: isCustomizationMode ? null : (value) {
                setState(() {
                  _formData['country'] = value;
                });
              },
            ),
          ),
        ],
        
        defaultFieldConfigs: {
          'name': FieldConfig(
            id: 'name',
            position: Offset(0, 0),
            width: 1.0, // Full width
          ),
          'email': FieldConfig(
            id: 'email',
            position: Offset(0, 70),
            width: 1.0, // Full width
          ),
          'country': FieldConfig(
            id: 'country',
            position: Offset(0, 140),
            width: 0.5, // Half width - users can resize!
          ),
        },
        
        appBarTitle: 'User Form',
        storageKey: 'user_form_layout', // Persists layout changes
        
        onFormDataChanged: (formData) {
          // Real-time form data updates
          setState(() {
            _formData.addAll(formData);
          });
        },
        
        formDataBuilder: (context, formData) {
          final isValid = _errors.values.every((error) => error == null) &&
                         _formData['name']?.isNotEmpty == true &&
                         _formData['email']?.isNotEmpty == true;
          
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: isValid ? () {
                    print('Form Data: $_formData');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Form submitted successfully!')),
                    );
                  } : null,
                  child: Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
                SizedBox(height: 8),
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

### Key Migration Points

| FormBuilder Concept | MagneticFormBuilder Equivalent | Notes |
|---------------------|--------------------------------|-------|
| `FormBuilderTextField(name: 'field')` | `MagneticFormField(id: 'field')` | ID replaces name |
| `FormBuilderValidators.required()` | `isMandatory: true` + custom validation | More flexible validation |
| `_formKey.currentState?.value` | `onFormDataChanged` callback | Real-time data access |
| Fixed layout | User-customizable layout | Users can drag and resize fields |
| `FormBuilder(child: Column(...))` | `availableFields` + `defaultFieldConfigs` | Declarative field definition |

---

## 🏗️ From Manual Form Layout

### Before (Manual Layout)

```dart
class ManualFormScreen extends StatefulWidget {
  @override
  _ManualFormScreenState createState() => _ManualFormScreenState();
}

class _ManualFormScreenState extends State<ManualFormScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contact Form')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Row 1: First Name + Last Name
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Row 2: Email (full width)
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            
            // Row 3: Phone (full width)
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: () {
                final formData = {
                  'firstName': _firstNameController.text,
                  'lastName': _lastNameController.text,
                  'email': _emailController.text,
                  'phone': _phoneController.text,
                };
                print('Form Data: $formData');
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
```

### After (MagneticFormBuilder)

```dart
class MagneticContactFormScreen extends StatefulWidget {
  @override
  _MagneticContactFormScreenState createState() => _MagneticContactFormScreenState();
}

class _MagneticContactFormScreenState extends State<MagneticContactFormScreen> {
  final Map<String, dynamic> _formData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MagneticFormBuilder(
        availableFields: [
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
        ],
        
        defaultFieldConfigs: {
          // Recreate the same layout as before, but now users can customize it!
          'firstName': FieldConfig(
            id: 'firstName',
            position: Offset(0, 0),     // Left side of first row
            width: 0.5,                // Half width
          ),
          'lastName': FieldConfig(
            id: 'lastName',
            position: Offset(0.5, 0),   // Right side of first row
            width: 0.5,                // Half width
          ),
          'email': FieldConfig(
            id: 'email',
            position: Offset(0, 70),    // Second row, full width
            width: 1.0,
          ),
          'phone': FieldConfig(
            id: 'phone',
            position: Offset(0, 140),   // Third row, full width
            width: 1.0,
          ),
        },
        
        appBarTitle: 'Contact Form',
        storageKey: 'contact_form_layout',
        
        onFormDataChanged: (formData) {
          setState(() {
            _formData.addAll(formData);
          });
        },
        
        formDataBuilder: (context, formData) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                print('Form Data: $_formData');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Form submitted!')),
                );
              },
              child: Text('Submit'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### Key Migration Benefits

| Manual Layout | MagneticFormBuilder | Benefit |
|---------------|---------------------|---------|
| Fixed `Row`/`Column` structure | User-draggable layout | Users can customize to their preference |
| Manual `TextEditingController` management | Automatic form data handling | Less boilerplate code |
| Hard-coded spacing with `SizedBox` | Automatic grid spacing | Consistent, responsive spacing |
| Static layout | Dynamic, saveable layouts | Layouts persist across app sessions |

---

## ⚡ From Reactive Forms

### Before (Reactive Forms)

```dart
import 'package:reactive_forms/reactive_forms.dart';

class ReactiveFormScreen extends StatelessWidget {
  final FormGroup form = FormGroup({
    'name': FormControl<String>(
      validators: [Validators.required],
    ),
    'email': FormControl<String>(
      validators: [Validators.required, Validators.email],
    ),
    'age': FormControl<int>(
      validators: [Validators.required, Validators.min(18)],
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reactive Form')),
      body: ReactiveFormBuilder(
        form: () => form,
        builder: (context, form, child) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ReactiveTextField<String>(
                  formControlName: 'name',
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ReactiveTextField<String>(
                  formControlName: 'email',
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ReactiveTextField<int>(
                  formControlName: 'age',
                  decoration: InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 24),
                ReactiveFormConsumer(
                  builder: (context, form, child) {
                    return ElevatedButton(
                      onPressed: form.valid ? () {
                        print('Form Value: ${form.value}');
                      } : null,
                      child: Text('Submit'),
                    );
                  },
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

### After (MagneticFormBuilder with Reactive-like Features)

```dart
class MagneticReactiveFormScreen extends StatefulWidget {
  @override
  _MagneticReactiveFormScreenState createState() => _MagneticReactiveFormScreenState();
}

class _MagneticReactiveFormScreenState extends State<MagneticReactiveFormScreen> {
  final Map<String, dynamic> _formData = {};
  final Map<String, String?> _errors = {};

  // Validation rules (similar to reactive forms validators)
  final Map<String, List<String? Function(dynamic)>> _validators = {
    'name': [
      (value) => value == null || value.isEmpty ? 'Name is required' : null,
    ],
    'email': [
      (value) => value == null || value.isEmpty ? 'Email is required' : null,
      (value) => value != null && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value) 
          ? 'Invalid email format' : null,
    ],
    'age': [
      (value) => value == null || value.isEmpty ? 'Age is required' : null,
      (value) {
        final age = int.tryParse(value?.toString() ?? '');
        return age != null && age < 18 ? 'Must be at least 18 years old' : null;
      },
    ],
  };

  void _validateField(String fieldId, dynamic value) {
    final validators = _validators[fieldId] ?? [];
    String? error;
    
    for (final validator in validators) {
      error = validator(value);
      if (error != null) break;
    }
    
    setState(() {
      _errors[fieldId] = error;
      if (error == null) {
        _formData[fieldId] = value;
      }
    });
  }

  bool get _isFormValid {
    return _errors.values.every((error) => error == null) &&
           _validators.keys.every((key) => _formData.containsKey(key));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MagneticFormBuilder(
        availableFields: [
          MagneticFormField(
            id: 'name',
            label: 'Name',
            icon: Icons.person,
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                errorText: _errors['name'],
              ),
              enabled: !isCustomizationMode,
              onChanged: (value) => _validateField('name', value),
            ),
          ),
          MagneticFormField(
            id: 'email',
            label: 'Email',
            icon: Icons.email,
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                errorText: _errors['email'],
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isCustomizationMode,
              onChanged: (value) => _validateField('email', value),
            ),
          ),
          MagneticFormField(
            id: 'age',
            label: 'Age',
            icon: Icons.cake,
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
                errorText: _errors['age'],
              ),
              keyboardType: TextInputType.number,
              enabled: !isCustomizationMode,
              onChanged: (value) => _validateField('age', value),
            ),
          ),
        ],
        
        defaultFieldConfigs: {
          'name': FieldConfig(id: 'name', position: Offset(0, 0), width: 1.0),
          'email': FieldConfig(id: 'email', position: Offset(0, 70), width: 1.0),
          'age': FieldConfig(id: 'age', position: Offset(0, 140), width: 0.5),
        },
        
        appBarTitle: 'Reactive-style Form',
        storageKey: 'reactive_form_layout',
        
        onFormDataChanged: (formData) {
          // Real-time form updates (similar to reactive forms stream)
          print('Form data changed: $formData');
        },
        
        formDataBuilder: (context, formData) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _isFormValid ? () {
                    print('Form Value: $_formData');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Form submitted successfully!')),
                    );
                  } : null,
                  child: Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Form Valid: $_isFormValid',
                  style: TextStyle(
                    color: _isFormValid ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Errors: ${_errors.entries.where((e) => e.value != null).map((e) => '${e.key}: ${e.value}').join(', ')}',
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

---

## 🎯 Common Migration Patterns

### 1. Field Validation Migration

```dart
// Before: Various validation approaches
FormBuilderValidators.compose([
  FormBuilderValidators.required(),
  FormBuilderValidators.email(),
])

// After: Custom validation in MagneticFormBuilder
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Email is required';
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Invalid email format';
  }
  return null;
}
```

### 2. Form State Management Migration

```dart
// Before: FormKey or FormGroup
final _formKey = GlobalKey<FormBuilderState>();
final formData = _formKey.currentState?.value;

// After: State management in MagneticFormBuilder
final Map<String, dynamic> _formData = {};

onFormDataChanged: (formData) {
  setState(() {
    _formData.addAll(formData);
  });
}
```

### 3. Layout Definition Migration

```dart
// Before: Widget tree structure
Column(
  children: [
    Row(children: [field1, field2]),
    field3,
  ],
)

// After: Declarative configuration
defaultFieldConfigs: {
  'field1': FieldConfig(id: 'field1', position: Offset(0, 0), width: 0.5),
  'field2': FieldConfig(id: 'field2', position: Offset(0.5, 0), width: 0.5),
  'field3': FieldConfig(id: 'field3', position: Offset(0, 70), width: 1.0),
}
```

---

## ✅ Best Practices

### 1. Always Disable Fields During Customization

```dart
// ✅ Correct
builder: (context, isCustomizationMode) => TextField(
  enabled: !isCustomizationMode, // Always include this
  // ... other properties
)

// ❌ Incorrect
builder: (context, isCustomizationMode) => TextField(
  // Missing enabled check - fields will be interactive during layout editing
)
```

### 2. Use Meaningful Field IDs

```dart
// ✅ Correct - descriptive IDs
MagneticFormField(id: 'userEmail', ...)
MagneticFormField(id: 'billingAddress', ...)
MagneticFormField(id: 'phoneNumber', ...)

// ❌ Incorrect - generic IDs
MagneticFormField(id: 'field1', ...)
MagneticFormField(id: 'input2', ...)
MagneticFormField(id: 'text3', ...)
```

### 3. Provide Storage Keys for Persistence

```dart
// ✅ Correct - unique storage key per form
MagneticFormBuilder(
  storageKey: 'user_registration_form', // Unique identifier
  // ...
)

// ❌ Incorrect - no persistence
MagneticFormBuilder(
  // Missing storageKey - layout changes won't be saved
)
```

### 4. Handle Form Data Properly

```dart
// ✅ Correct - maintain form state
final Map<String, dynamic> _formData = {};

onFormDataChanged: (formData) {
  setState(() {
    _formData.addAll(formData); // Merge new data
  });
}

// ❌ Incorrect - losing form state
onFormDataChanged: (formData) {
  print(formData); // Only logging, not storing
}
```

### 5. Use Appropriate Field Widths

```dart
// ✅ Correct - logical field sizing
defaultFieldConfigs: {
  'fullName': FieldConfig(width: 1.0),      // Full width for names
  'firstName': FieldConfig(width: 0.5),     // Half width when split
  'lastName': FieldConfig(width: 0.5),      // Half width when split
  'zipCode': FieldConfig(width: 0.25),      // Quarter width for short fields
}

// ❌ Incorrect - poor field sizing
defaultFieldConfigs: {
  'zipCode': FieldConfig(width: 1.0),       // Too wide for zip code
  'description': FieldConfig(width: 0.25),  // Too narrow for long text
}
```

---

## 🎉 Migration Complete!

After following this guide, you should have:

- ✅ Converted your static forms to dynamic, user-customizable layouts
- ✅ Maintained all existing functionality while adding drag-and-drop capabilities
- ✅ Improved user experience with magnetic grid positioning
- ✅ Added form layout persistence across app sessions
- ✅ Reduced boilerplate code with declarative field definitions

Need help with your specific migration? Check out our [examples](example/) or [open an issue](https://github.com/chchavarte/magneticform/issues)!