import 'package:flutter/material.dart';

/// Animation durations, curves, and timing constants used throughout the app
class AnimationConstants {
  // Private constructor to prevent instantiation
  AnimationConstants._();

  // Field Preview Animation Durations
  static const Duration previewDuration = Duration(milliseconds: 150); // Fast preview
  static const Duration commitDuration = Duration(milliseconds: 300); // Smooth commit
  static const Duration revertDuration = Duration(milliseconds: 200); // Quick revert
  
  // Hover Transition Durations (for smooth dropzone detection)
  static const Duration hoverEnterDuration = Duration(milliseconds: 120); // Smooth enter
  static const Duration hoverExitDuration = Duration(milliseconds: 100); // Quick exit

  // Field Animation Durations
  static const Duration defaultFieldAnimationDuration = Duration(milliseconds: 300);
  static const Duration autoResizeMessageDuration = Duration(seconds: 3);

  // Animation Curves
  static const Curve previewCurve = Curves.easeOutQuart;
  static const Curve commitCurve = Curves.easeOutCubic;
  static const Curve revertCurve = Curves.easeInOut;
  static const Curve defaultFieldAnimationCurve = Curves.easeOutCubic;
  
  // Hover Transition Curves (for smooth dropzone detection)
  static const Curve hoverEnterCurve = Curves.easeOutCubic; // Smooth acceleration
  static const Curve hoverExitCurve = Curves.easeInCubic; // Quick deceleration
}