import 'package:flutter/material.dart';

// Resize direction enum
enum ResizeDirection { left, right }

// Field configuration model
class FieldConfig {
  final String id;
  final double width; // 0.0 to 1.0 (percentage of parent width)
  final Offset position;

  FieldConfig({
    required this.id,
    this.width = 1.0,
    this.position = Offset.zero,
  });

  FieldConfig copyWith({String? id, double? width, Offset? position}) {
    return FieldConfig(
      id: id ?? this.id,
      width: width ?? this.width,
      position: position ?? this.position,
    );
  }

  // Helper method to check if field is visible/active
  bool get isVisible => width > 0 && position.dx >= 0 && position.dy >= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'width': width,
      'positionX': position.dx,
      'positionY': position.dy,
    };
  }

  factory FieldConfig.fromMap(Map<String, dynamic> map) {
    return FieldConfig(
      id: map['id'],
      width: map['width'],
      position: Offset(map['positionX'], map['positionY']),
    );
  }
}