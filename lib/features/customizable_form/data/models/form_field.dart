import 'package:flutter/material.dart';

// Field definition for the form
class CustomFormField {
  final String id;
  final String label;
  final IconData icon;
  final Widget Function(BuildContext context, bool isCustomizationMode) builder;
  final bool isMandatory;
  final String? defaultValue;

  const CustomFormField({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
    this.isMandatory = false,
    this.defaultValue,
  });
}