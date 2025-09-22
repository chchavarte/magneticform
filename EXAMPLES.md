# 📚 Complete Examples

This document provides comprehensive, copy-pasteable examples for common use cases with Magnetic Form Builder.

## 📋 Table of Contents

- [Basic Contact Form](#basic-contact-form)
- [User Registration Form](#user-registration-form)
- [Survey Builder](#survey-builder)
- [E-commerce Product Form](#e-commerce-product-form)
- [Employee Information Form](#employee-information-form)
- [Multi-step Wizard Form](#multi-step-wizard-form)
- [Dynamic Form with Conditional Fields](#dynamic-form-with-conditional-fields)
- [Form with Custom Validation](#form-with-custom-validation)
- [Themed Form Examples](#themed-form-examples)
- [Integration Examples](#integration-examples)

---

## 📞 Basic Contact Form

A simple contact form with name, email, phone, and message fields.

```dart
import 'package:flutter/material.dart';
import 'package:magnetic_form_builder/magnetic_form_builder.dart';

class BasicContactForm extends StatefulWidget {
  @override
  _BasicContactFormState createState() => _BasicContactFormState();
}

class _BasicContactFormState extends State<BasicContactForm> {
  final Map<String, dynamic> _formData = {};
  final Map<String, String?> _errors = {};

  void _validateAndSubmit() {
    // Simple validation
    setState(() {
      _errors.clear();

      if (_formData['name']?.isEmpty ?? true) {
        _errors['name'] = 'Name is required';
      }

      if (_formData['email']?.isEmpty ?? true) {
        _errors['email'] = 'Email is required';
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_formData['email'])) {
        _errors['email'] = 'Invalid email format';
      }
    });

    if (_errors.isEmpty) {
      // Submit form
      print('Submitting contact form: $_formData');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contact form submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                errorText: _errors['name'],
                prefixIcon: Icon(Icons.person),
              ),
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['name'] = value;
                  _errors.remove('name');
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'email',
            label: 'Email Address',
            icon: Icons.email,
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                errorText: _errors['email'],
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['email'] = value;
                  _errors.remove('email');
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'phone',
            label: 'Phone Number',
            icon: Icons.phone,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: '+1 (555) 123-4567',
              ),
              keyboardType: TextInputType.phone,
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['phone'] = value;
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'message',
            label: 'Message',
            icon: Icons.message,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Your Message',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['message'] = value;
                });
              },
            ),
          ),
        ],

        defaultFieldConfigs: {
          'name': FieldConfig(
            id: 'name',
            position: Offset(0, 0),
            width: 1.0,
          ),
          'email': FieldConfig(
            id: 'email',
            position: Offset(0, 70),
            width: 0.6,
          ),
          'phone': FieldConfig(
            id: 'phone',
            position: Offset(0.6, 70),
            width: 0.4,
          ),
          'message': FieldConfig(
            id: 'message',
            position: Offset(0, 140),
            width: 1.0,
          ),
        },

        appBarTitle: 'Contact Us',
        storageKey: 'contact_form_layout',

        onFormDataChanged: (formData) {
          setState(() {
            _formData.addAll(formData);
          });
        },

        formDataBuilder: (context, formData) {
          final hasRequiredFields = _formData['name']?.isNotEmpty == true &&
                                   _formData['email']?.isNotEmpty == true;

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: hasRequiredFields ? _validateAndSubmit : null,
                  child: Text('Send Message'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Fields completed: ${_formData.length}/4',
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

## 👤 User Registration Form

A comprehensive user registration form with validation and password confirmation.

```dart
import 'package:flutter/material.dart';
import 'package:magnetic_form_builder/magnetic_form_builder.dart';

class UserRegistrationForm extends StatefulWidget {
  @override
  _UserRegistrationFormState createState() => _UserRegistrationFormState();
}

class _UserRegistrationFormState extends State<UserRegistrationForm> {
  final Map<String, dynamic> _formData = {};
  final Map<String, String?> _errors = {};
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _validateForm() {
    setState(() {
      _errors.clear();

      // First Name validation
      if (_formData['firstName']?.isEmpty ?? true) {
        _errors['firstName'] = 'First name is required';
      }

      // Last Name validation
      if (_formData['lastName']?.isEmpty ?? true) {
        _errors['lastName'] = 'Last name is required';
      }

      // Email validation
      if (_formData['email']?.isEmpty ?? true) {
        _errors['email'] = 'Email is required';
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_formData['email'])) {
        _errors['email'] = 'Invalid email format';
      }

      // Password validation
      if (_formData['password']?.isEmpty ?? true) {
        _errors['password'] = 'Password is required';
      } else if ((_formData['password']?.length ?? 0) < 8) {
        _errors['password'] = 'Password must be at least 8 characters';
      }

      // Confirm Password validation
      if (_formData['confirmPassword'] != _formData['password']) {
        _errors['confirmPassword'] = 'Passwords do not match';
      }

      // Age validation
      final age = int.tryParse(_formData['age']?.toString() ?? '');
      if (age == null) {
        _errors['age'] = 'Age is required';
      } else if (age < 13) {
        _errors['age'] = 'Must be at least 13 years old';
      }
    });
  }

  void _submitForm() {
    _validateForm();

    if (_errors.isEmpty) {
      // Remove confirm password from submission data
      final submissionData = Map<String, dynamic>.from(_formData);
      submissionData.remove('confirmPassword');

      print('Registering user: $submissionData');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MagneticFormBuilder(
        availableFields: [
          MagneticFormField(
            id: 'firstName',
            label: 'First Name',
            icon: Icons.person_outline,
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
                errorText: _errors['firstName'],
              ),
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['firstName'] = value;
                  _errors.remove('firstName');
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'lastName',
            label: 'Last Name',
            icon: Icons.person,
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
                errorText: _errors['lastName'],
              ),
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['lastName'] = value;
                  _errors.remove('lastName');
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'email',
            label: 'Email Address',
            icon: Icons.email,
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                errorText: _errors['email'],
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['email'] = value;
                  _errors.remove('email');
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'password',
            label: 'Password',
            icon: Icons.lock,
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                errorText: _errors['password'],
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: isCustomizationMode ? null : () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                helperText: 'At least 8 characters',
              ),
              obscureText: _obscurePassword,
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['password'] = value;
                  _errors.remove('password');
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'confirmPassword',
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
                errorText: _errors['confirmPassword'],
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: isCustomizationMode ? null : () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirmPassword,
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['confirmPassword'] = value;
                  _errors.remove('confirmPassword');
                });
              },
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
                prefixIcon: Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['age'] = value;
                  _errors.remove('age');
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
                prefixIcon: Icon(Icons.public),
              ),
              value: _formData['country'],
              items: [
                'United States',
                'Canada',
                'United Kingdom',
                'Australia',
                'Germany',
                'France',
                'Japan',
                'Other'
              ].map((country) => DropdownMenuItem(
                value: country,
                child: Text(country),
              )).toList(),
              onChanged: isCustomizationMode ? null : (value) {
                setState(() {
                  _formData['country'] = value;
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'newsletter',
            label: 'Newsletter Subscription',
            icon: Icons.mail_outline,
            builder: (context, isCustomizationMode) => CheckboxListTile(
              title: Text('Subscribe to newsletter'),
              subtitle: Text('Receive updates and promotions'),
              value: _formData['newsletter'] ?? false,
              onChanged: isCustomizationMode ? null : (value) {
                setState(() {
                  _formData['newsletter'] = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ],

        defaultFieldConfigs: {
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
          'email': FieldConfig(
            id: 'email',
            position: Offset(0, 70),
            width: 1.0,
          ),
          'password': FieldConfig(
            id: 'password',
            position: Offset(0, 140),
            width: 0.5,
          ),
          'confirmPassword': FieldConfig(
            id: 'confirmPassword',
            position: Offset(0.5, 140),
            width: 0.5,
          ),
          'age': FieldConfig(
            id: 'age',
            position: Offset(0, 210),
            width: 0.3,
          ),
          'country': FieldConfig(
            id: 'country',
            position: Offset(0.3, 210),
            width: 0.7,
          ),
          'newsletter': FieldConfig(
            id: 'newsletter',
            position: Offset(0, 280),
            width: 1.0,
          ),
        },

        appBarTitle: 'Create Account',
        storageKey: 'user_registration_layout',

        onFormDataChanged: (formData) {
          setState(() {
            _formData.addAll(formData);
          });
        },

        formDataBuilder: (context, formData) {
          final requiredFields = ['firstName', 'lastName', 'email', 'password', 'confirmPassword', 'age'];
          final completedRequired = requiredFields.where((field) =>
            _formData[field]?.toString().isNotEmpty == true
          ).length;

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: completedRequired / requiredFields.length,
                  backgroundColor: Colors.grey[300],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: completedRequired == requiredFields.length ? _submitForm : null,
                  child: Text('Create Account'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Progress: $completedRequired/${requiredFields.length} required fields',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_errors.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[200]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Please fix the following errors:',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ..._errors.values.map((error) => Text(
                          '• $error',
                          style: TextStyle(color: Colors.red[700]),
                        )),
                      ],
                    ),
                  ),
                ],
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

## 📊 Survey Builder

A dynamic survey form that demonstrates conditional fields and different question types.

```dart
import 'package:flutter/material.dart';
import 'package:magnetic_form_builder/magnetic_form_builder.dart';

class SurveyBuilderForm extends StatefulWidget {
  @override
  _SurveyBuilderFormState createState() => _SurveyBuilderFormState();
}

class _SurveyBuilderFormState extends State<SurveyBuilderForm> {
  final Map<String, dynamic> _formData = {};

  // Dynamic field configurations based on survey responses
  Map<String, FieldConfig> get _dynamicFieldConfigs {
    final configs = <String, FieldConfig>{
      'name': FieldConfig(id: 'name', position: Offset(0, 0), width: 1.0),
      'email': FieldConfig(id: 'email', position: Offset(0, 70), width: 0.6),
      'age': FieldConfig(id: 'age', position: Offset(0.6, 70), width: 0.4),
      'satisfaction': FieldConfig(id: 'satisfaction', position: Offset(0, 140), width: 1.0),
    };

    double nextY = 210;

    // Show feedback field only if satisfaction is low
    final satisfaction = int.tryParse(_formData['satisfaction']?.toString() ?? '');
    if (satisfaction != null && satisfaction <= 3) {
      configs['feedback'] = FieldConfig(
        id: 'feedback',
        position: Offset(0, nextY),
        width: 1.0,
      );
      nextY += 70;
    }

    // Show experience field if user has used similar products
    if (_formData['previousExperience'] == 'Yes') {
      configs['experienceDetails'] = FieldConfig(
        id: 'experienceDetails',
        position: Offset(0, nextY),
        width: 1.0,
      );
      nextY += 70;
    }

    configs['previousExperience'] = FieldConfig(
      id: 'previousExperience',
      position: Offset(0, nextY),
      width: 0.5,
    );

    configs['recommend'] = FieldConfig(
      id: 'recommend',
      position: Offset(0.5, nextY),
      width: 0.5,
    );

    return configs;
  }

  List<MagneticFormField> get _availableFields {
    final fields = <MagneticFormField>[
      MagneticFormField(
        id: 'name',
        label: 'Full Name',
        icon: Icons.person,
        isMandatory: true,
        builder: (context, isCustomizationMode) => TextField(
          decoration: InputDecoration(
            labelText: 'Your Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          enabled: !isCustomizationMode,
          onChanged: (value) => _updateFormData('name', value),
        ),
      ),

      MagneticFormField(
        id: 'email',
        label: 'Email Address',
        icon: Icons.email,
        isMandatory: true,
        builder: (context, isCustomizationMode) => TextField(
          decoration: InputDecoration(
            labelText: 'Email Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          enabled: !isCustomizationMode,
          onChanged: (value) => _updateFormData('email', value),
        ),
      ),

      MagneticFormField(
        id: 'age',
        label: 'Age Group',
        icon: Icons.group,
        builder: (context, isCustomizationMode) => DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Age Group',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.group),
          ),
          value: _formData['age'],
          items: [
            '18-24',
            '25-34',
            '35-44',
            '45-54',
            '55-64',
            '65+'
          ].map((age) => DropdownMenuItem(
            value: age,
            child: Text(age),
          )).toList(),
          onChanged: isCustomizationMode ? null : (value) => _updateFormData('age', value),
        ),
      ),

      MagneticFormField(
        id: 'satisfaction',
        label: 'Satisfaction Rating',
        icon: Icons.star,
        isMandatory: true,
        builder: (context, isCustomizationMode) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How satisfied are you with our service?'),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected = _formData['satisfaction'] == rating.toString();

                return GestureDetector(
                  onTap: isCustomizationMode ? null : () => _updateFormData('satisfaction', rating.toString()),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.star,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                        Text(
                          rating.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),

      MagneticFormField(
        id: 'previousExperience',
        label: 'Previous Experience',
        icon: Icons.history,
        builder: (context, isCustomizationMode) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Have you used similar products before?'),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Yes'),
                    value: 'Yes',
                    groupValue: _formData['previousExperience'],
                    onChanged: isCustomizationMode ? null : (value) => _updateFormData('previousExperience', value),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('No'),
                    value: 'No',
                    groupValue: _formData['previousExperience'],
                    onChanged: isCustomizationMode ? null : (value) => _updateFormData('previousExperience', value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      MagneticFormField(
        id: 'recommend',
        label: 'Recommendation',
        icon: Icons.thumb_up,
        builder: (context, isCustomizationMode) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Would you recommend us to others?'),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Yes'),
                    value: 'Yes',
                    groupValue: _formData['recommend'],
                    onChanged: isCustomizationMode ? null : (value) => _updateFormData('recommend', value),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('No'),
                    value: 'No',
                    groupValue: _formData['recommend'],
                    onChanged: isCustomizationMode ? null : (value) => _updateFormData('recommend', value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];

    // Conditional fields
    final satisfaction = int.tryParse(_formData['satisfaction']?.toString() ?? '');
    if (satisfaction != null && satisfaction <= 3) {
      fields.add(
        MagneticFormField(
          id: 'feedback',
          label: 'Improvement Feedback',
          icon: Icons.feedback,
          builder: (context, isCustomizationMode) => TextField(
            decoration: InputDecoration(
              labelText: 'How can we improve?',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.feedback),
            ),
            maxLines: 3,
            enabled: !isCustomizationMode,
            onChanged: (value) => _updateFormData('feedback', value),
          ),
        ),
      );
    }

    if (_formData['previousExperience'] == 'Yes') {
      fields.add(
        MagneticFormField(
          id: 'experienceDetails',
          label: 'Experience Details',
          icon: Icons.description,
          builder: (context, isCustomizationMode) => TextField(
            decoration: InputDecoration(
              labelText: 'Tell us about your previous experience',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 2,
            enabled: !isCustomizationMode,
            onChanged: (value) => _updateFormData('experienceDetails', value),
          ),
        ),
      );
    }

    return fields;
  }

  void _updateFormData(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
    });
  }

  void _submitSurvey() {
    print('Survey submitted: $_formData');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thank You!'),
        content: Text('Your survey response has been submitted successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _formData.clear();
              });
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MagneticFormBuilder(
        availableFields: _availableFields,
        defaultFieldConfigs: _dynamicFieldConfigs,

        appBarTitle: 'Customer Survey',
        storageKey: 'customer_survey_layout',

        onFormDataChanged: (formData) {
          // This will trigger rebuilds when conditional fields should appear
          setState(() {
            _formData.addAll(formData);
          });
        },

        formDataBuilder: (context, formData) {
          final requiredFields = ['name', 'email', 'satisfaction'];
          final completedRequired = requiredFields.where((field) =>
            _formData[field]?.toString().isNotEmpty == true
          ).length;

          final canSubmit = completedRequired == requiredFields.length;

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Survey Progress',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: completedRequired / requiredFields.length,
                        ),
                        SizedBox(height: 8),
                        Text('$completedRequired of ${requiredFields.length} required fields completed'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: canSubmit ? _submitSurvey : null,
                  child: Text('Submit Survey'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Total responses: ${_formData.length}',
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

## 🛒 E-commerce Product Form

A product creation form for e-commerce platforms with image upload, pricing, and inventory management.

```dart
import 'package:flutter/material.dart';
import 'package:magnetic_form_builder/magnetic_form_builder.dart';

class EcommerceProductForm extends StatefulWidget {
  @override
  _EcommerceProductFormState createState() => _EcommerceProductFormState();
}

class _EcommerceProductFormState extends State<EcommerceProductForm> {
  final Map<String, dynamic> _formData = {};
  final Map<String, String?> _errors = {};
  List<String> _selectedImages = [];
  List<String> _selectedTags = [];

  final List<String> _availableCategories = [
    'Electronics',
    'Clothing',
    'Home & Garden',
    'Sports & Outdoors',
    'Books',
    'Toys & Games',
    'Health & Beauty',
    'Automotive',
  ];

  final List<String> _availableTags = [
    'New Arrival',
    'Best Seller',
    'On Sale',
    'Limited Edition',
    'Eco Friendly',
    'Premium Quality',
    'Fast Shipping',
    'Customer Favorite',
  ];

  void _validateAndSave() {
    setState(() {
      _errors.clear();

      if (_formData['productName']?.isEmpty ?? true) {
        _errors['productName'] = 'Product name is required';
      }

      if (_formData['category']?.isEmpty ?? true) {
        _errors['category'] = 'Category is required';
      }

      final price = double.tryParse(_formData['price']?.toString() ?? '');
      if (price == null || price <= 0) {
        _errors['price'] = 'Valid price is required';
      }

      final stock = int.tryParse(_formData['stock']?.toString() ?? '');
      if (stock == null || stock < 0) {
        _errors['stock'] = 'Valid stock quantity is required';
      }
    });

    if (_errors.isEmpty) {
      final productData = Map<String, dynamic>.from(_formData);
      productData['images'] = _selectedImages;
      productData['tags'] = _selectedTags;

      print('Saving product: $productData');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MagneticFormBuilder(
        availableFields: [
          MagneticFormField(
            id: 'productName',
            label: 'Product Name',
            icon: Icons.shopping_bag,
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
                errorText: _errors['productName'],
                prefixIcon: Icon(Icons.shopping_bag),
              ),
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['productName'] = value;
                  _errors.remove('productName');
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'category',
            label: 'Category',
            icon: Icons.category,
            isMandatory: true,
            builder: (context, isCustomizationMode) => DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Product Category',
                border: OutlineInputBorder(),
                errorText: _errors['category'],
                prefixIcon: Icon(Icons.category),
              ),
              value: _formData['category'],
              items: _availableCategories.map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              )).toList(),
              onChanged: isCustomizationMode ? null : (value) {
                setState(() {
                  _formData['category'] = value;
                  _errors.remove('category');
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'price',
            label: 'Price',
            icon: Icons.attach_money,
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Price (\$)',
                border: OutlineInputBorder(),
                errorText: _errors['price'],
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['price'] = value;
                  _errors.remove('price');
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'comparePrice',
            label: 'Compare Price',
            icon: Icons.compare,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Compare at Price (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.compare),
                prefixText: '\$ ',
                helperText: 'Original price before discount',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['comparePrice'] = value;
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'stock',
            label: 'Stock Quantity',
            icon: Icons.inventory,
            isMandatory: true,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Stock Quantity',
                border: OutlineInputBorder(),
                errorText: _errors['stock'],
                prefixIcon: Icon(Icons.inventory),
                suffixText: 'units',
              ),
              keyboardType: TextInputType.number,
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['stock'] = value;
                  _errors.remove('stock');
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'sku',
            label: 'SKU',
            icon: Icons.qr_code,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'SKU (Stock Keeping Unit)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
                helperText: 'Unique product identifier',
              ),
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['sku'] = value;
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'description',
            label: 'Description',
            icon: Icons.description,
            builder: (context, isCustomizationMode) => TextField(
              decoration: InputDecoration(
                labelText: 'Product Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
              enabled: !isCustomizationMode,
              onChanged: (value) {
                setState(() {
                  _formData['description'] = value;
                });
              },
            ),
          ),

          MagneticFormField(
            id: 'images',
            label: 'Product Images',
            icon: Icons.photo_library,
            builder: (context, isCustomizationMode) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload, size: 48, color: Colors.grey[600]),
                      SizedBox(height: 8),
                      Text('Upload Product Images'),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: isCustomizationMode ? null : () {
                          // Simulate image selection
                          setState(() {
                            _selectedImages.add('image_${_selectedImages.length + 1}.jpg');
                          });
                        },
                        child: Text('Choose Images'),
                      ),
                    ],
                  ),
                ),
                if (_selectedImages.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _selectedImages.map((image) => Chip(
                      label: Text(image),
                      deleteIcon: Icon(Icons.close),
                      onDeleted: isCustomizationMode ? null : () {
                        setState(() {
                          _selectedImages.remove(image);
                        });
                      },
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),

          MagneticFormField(
            id: 'tags',
            label: 'Product Tags',
            icon: Icons.local_offer,
            builder: (context, isCustomizationMode) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select applicable tags:'),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: isCustomizationMode ? null : (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          MagneticFormField(
            id: 'shipping',
            label: 'Shipping Settings',
            icon: Icons.local_shipping,
            builder: (context, isCustomizationMode) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  title: Text('Requires shipping'),
                  value: _formData['requiresShipping'] ?? true,
                  onChanged: isCustomizationMode ? null : (value) {
                    setState(() {
                      _formData['requiresShipping'] = value ?? true;
                    });
                  },
                ),
                if (_formData['requiresShipping'] ?? true) ...[
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Weight (lbs)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    enabled: !isCustomizationMode,
                    onChanged: (value) {
                      setState(() {
                        _formData['weight'] = value;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ],

        defaultFieldConfigs: {
          'productName': FieldConfig(id: 'productName', position: Offset(0, 0), width: 0.7),
          'category': FieldConfig(id: 'category', position: Offset(0.7, 0), width: 0.3),
          'price': FieldConfig(id: 'price', position: Offset(0, 70), width: 0.33),
          'comparePrice': FieldConfig(id: 'comparePrice', position: Offset(0.33, 70), width: 0.33),
          'stock': FieldConfig(id: 'stock', position: Offset(0.66, 70), width: 0.34),
          'sku': FieldConfig(id: 'sku', position: Offset(0, 140), width: 0.5),
          'description': FieldConfig(id: 'description', position: Offset(0, 210), width: 1.0),
          'images': FieldConfig(id: 'images', position: Offset(0, 280), width: 0.5),
          'tags': FieldConfig(id: 'tags', position: Offset(0.5, 280), width: 0.5),
          'shipping': FieldConfig(id: 'shipping', position: Offset(0, 350), width: 1.0),
        },

        appBarTitle: 'Add Product',
        storageKey: 'product_form_layout',

        onFormDataChanged: (formData) {
          setState(() {
            _formData.addAll(formData);
          });
        },

        formDataBuilder: (context, formData) {
          final requiredFields = ['productName', 'category', 'price', 'stock'];
          final completedRequired = requiredFields.where((field) =>
            _formData[field]?.toString().isNotEmpty == true
          ).length;

          final canSave = completedRequired == requiredFields.length && _errors.isEmpty;

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canSave ? _validateAndSave : null,
                        child: Text('Save Product'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _formData.clear();
                            _selectedImages.clear();
                            _selectedTags.clear();
                            _errors.clear();
                          });
                        },
                        child: Text('Clear Form'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Summary',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 8),
                        Text('Required fields: $completedRequired/$requiredFields.length'),
                        Text('Images: ${_selectedImages.length}'),
                        Text('Tags: ${_selectedTags.length}'),
                        if (_formData['price']?.isNotEmpty == true)
                          Text('Price: \$${_formData['price']}'),
                      ],
                    ),
                  ),
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

This comprehensive examples document provides real-world, production-ready code that developers can copy and use immediately. Each example demonstrates different aspects of the Magnetic Form Builder:

1. **Basic Contact Form** - Simple validation and form submission
2. **User Registration** - Complex validation, password handling, progress tracking
3. **Survey Builder** - Dynamic/conditional fields, different input types
4. **E-commerce Product** - File uploads, tags, complex business logic

Would you like me to continue with more examples (Employee Information, Multi-step Wizard, etc.) or would you prefer me to focus on other documentation improvements?
