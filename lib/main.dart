import 'package:flutter/material.dart';
import 'customizable_item_form.dart';
import 'form_models.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Field Collision Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TestFormScreen(),
    );
  }
}

class TestFormScreen extends StatelessWidget {
  const TestFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define some test fields
    final List<CustomFormField> testFields = [
      CustomFormField(
        id: 'field1',
        label: 'Name',
        icon: Icons.person,
        builder:
            (context, isCustomizationMode) => Container(
              height: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: const Center(
                child: Text(
                  'field1 - Name Field',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
      ),
      CustomFormField(
        id: 'field2',
        label: 'Email',
        icon: Icons.email,
        builder:
            (context, isCustomizationMode) => Container(
              height: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: const Center(
                child: Text(
                  'field2 - Email Field',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
      ),
      CustomFormField(
        id: 'field3',
        label: 'Phone',
        icon: Icons.phone,
        builder:
            (context, isCustomizationMode) => Container(
              height: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: const Center(
                child: Text(
                  'field3 - Phone Field',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
      ),
      CustomFormField(
        id: 'field4',
        label: 'Address',
        icon: Icons.location_on,
        builder:
            (context, isCustomizationMode) => Container(
              height: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade300),
              ),
              child: const Center(
                child: Text(
                  'field4 - Address Field',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
      ),
      CustomFormField(
        id: 'field5',
        label: 'Notes',
        icon: Icons.note,
        builder:
            (context, isCustomizationMode) => Container(
              height: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: const Center(
                child: Text(
                  'field5 - Notes Field',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
      ),
    ];

    // Define default field configurations with magnetic widths and positions
    final Map<String, FieldConfig> defaultConfigs = {
      'field1': FieldConfig(
        id: 'field1',
        position: const Offset(0.0, 0.0),
        width: 1.0, // Full width
      ),
      'field2': FieldConfig(
        id: 'field2',
        position: const Offset(0.0, 70.0),
        width: 1 / 2, // Half width
      ),
      'field3': FieldConfig(
        id: 'field3',
        position: const Offset(1 / 2, 70.0),
        width: 1 / 3, // Third width
      ),
      'field4': FieldConfig(
        id: 'field4',
        position: const Offset(0.0, 140.0),
        width: 2 / 3, // Two-thirds width
      ),
      'field5': FieldConfig(
        id: 'field5',
        position: const Offset(2 / 3, 140.0),
        width: 1 / 3, // Third width
      ),
    };

    return CustomizableForm(
      availableFields: testFields,
      defaultFieldConfigs: defaultConfigs,
      appBarTitle: 'Field Collision Test',
      storageKey: 'collision_test_configs',
    );
  }
}
