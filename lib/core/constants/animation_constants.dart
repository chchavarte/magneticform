import 'package:flutter/material.dart';

/// Animation durations, curves, and timing constants used throughout the app
class AnimationConstants {
  // Private constructor to prevent instantiation
  AnimationConstants._();

  // Field Preview Animation Durations
  static const Duration previewDuration = Duration(milliseconds: 150); // Fast preview
  static const Duration commitDuration = Duration(milliseconds: 300); // Smooth commit
  static const Duration revertDuration = Duration(milliseconds: 200); // Quick revert

  // Field Animation Durations
  static const Duration defaultFieldAnimationDuration = Duration(milliseconds: 300);
  static const Duration autoResizeMessageDuration = Duration(seconds: 3);

  // Animation Curves
  static const Curve previewCurve = Curves.easeOutQuart;
  static const Curve commitCurve = Curves.easeOutCubic;
  static const Curve revertCurve = Curves.easeInOut;
  static const Curve defaultFieldAnimationCurve = Curves.easeOutCubic;
}