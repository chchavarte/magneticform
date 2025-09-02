import 'package:flutter/material.dart';
import '../components/field_builders.dart';
import 'customizable_form_screen.dart';

/// Demo screen showcasing the customizable form functionality
class FormDemoScreen extends StatelessWidget {
  const FormDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Demo'),
        centerTitle: true,
      ),
      body: CustomizableFormScreen(
        availableFields: TestFieldBuilder.createTestFields(),
        defaultFieldConfigs: TestFieldBuilder.createDefaultConfigs(),
        appBarTitle: 'Demo Form',
        storageKey: 'demo_form_configs',
        cartSummaryButton: (context, formData) => Container(
          height: 80,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Form Data',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${formData.length} fields filled',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _showFormData(context, formData);
                },
                child: const Text('View Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFormData(BuildContext context, Map<String, dynamic> formData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Form Data'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: formData.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(entry.value?.toString() ?? 'null'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}