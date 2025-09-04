import 'package:flutter/material.dart';

/// Theme extension for field-specific colors
@immutable
class FieldThemeExtension extends ThemeExtension<FieldThemeExtension> {
  final Color draggedFieldBorderColor;
  final Color selectedFieldBorderColor;
  final Color previewFieldBackgroundColor;
  final Color snapGuideColor;
  final Color snapGuideBackgroundColor;

  const FieldThemeExtension({
    required this.draggedFieldBorderColor,
    required this.selectedFieldBorderColor,
    required this.previewFieldBackgroundColor,
    required this.snapGuideColor,
    required this.snapGuideBackgroundColor,
  });

  @override
  FieldThemeExtension copyWith({
    Color? draggedFieldBorderColor,
    Color? selectedFieldBorderColor,
    Color? previewFieldBackgroundColor,
    Color? snapGuideColor,
    Color? snapGuideBackgroundColor,
  }) {
    return FieldThemeExtension(
      draggedFieldBorderColor: draggedFieldBorderColor ?? this.draggedFieldBorderColor,
      selectedFieldBorderColor: selectedFieldBorderColor ?? this.selectedFieldBorderColor,
      previewFieldBackgroundColor: previewFieldBackgroundColor ?? this.previewFieldBackgroundColor,
      snapGuideColor: snapGuideColor ?? this.snapGuideColor,
      snapGuideBackgroundColor: snapGuideBackgroundColor ?? this.snapGuideBackgroundColor,
    );
  }

  @override
  FieldThemeExtension lerp(FieldThemeExtension? other, double t) {
    if (other is! FieldThemeExtension) {
      return this;
    }
    return FieldThemeExtension(
      draggedFieldBorderColor: Color.lerp(draggedFieldBorderColor, other.draggedFieldBorderColor, t)!,
      selectedFieldBorderColor: Color.lerp(selectedFieldBorderColor, other.selectedFieldBorderColor, t)!,
      previewFieldBackgroundColor: Color.lerp(previewFieldBackgroundColor, other.previewFieldBackgroundColor, t)!,
      snapGuideColor: Color.lerp(snapGuideColor, other.snapGuideColor, t)!,
      snapGuideBackgroundColor: Color.lerp(snapGuideBackgroundColor, other.snapGuideBackgroundColor, t)!,
    );
  }
}