import 'package:flutter/material.dart';

/// Animation durations, curves, and timing constants for the magnetic form builder.
/// 
/// Provides consistent animation timing across all form builder interactions,
/// ensuring smooth and responsive user experience. All animations are optimized
/// for 60fps performance and follow Material Design motion principles.
/// 
/// ## Animation Types
/// 
/// - **Preview**: Fast animations for hover and drag previews (150ms)
/// - **Commit**: Smooth animations for field placement (300ms)  
/// - **Revert**: Quick animations for cancelled operations (200ms)
/// 
/// ## Usage
/// 
/// ```dart
/// AnimationController(
///   duration: AnimationConstants.previewDuration,
///   vsync: this,
/// )
/// 
/// Tween<double>(begin: 0.0, end: 1.0).animate(
///   CurvedAnimation(
///     parent: controller,
///     curve: AnimationConstants.previewCurve,
///   ),
/// )
/// ```
class AnimationConstants {
  // Private constructor to prevent instantiation
  AnimationConstants._();

  /// Duration for field preview animations during drag operations.
  /// 
  /// Used for real-time preview feedback when hovering over grid positions.
  /// Fast timing (150ms) ensures responsive visual feedback without lag.
  static const Duration previewDuration = Duration(milliseconds: 150);

  /// Duration for field commit animations when placing fields.
  /// 
  /// Used when fields are successfully placed on the grid. Smooth timing
  /// (300ms) provides satisfying visual confirmation of the action.
  static const Duration commitDuration = Duration(milliseconds: 300);

  /// Duration for field revert animations when cancelling operations.
  /// 
  /// Used when drag operations are cancelled or fields return to original
  /// positions. Quick timing (200ms) provides immediate feedback.
  static const Duration revertDuration = Duration(milliseconds: 200);

  /// Default duration for general field animations.
  /// 
  /// Used for resize operations, field movements, and other general
  /// field-related animations that don't fall into specific categories.
  static const Duration defaultFieldAnimationDuration = Duration(milliseconds: 300);

  /// Duration for auto-resize feedback messages.
  /// 
  /// Controls how long auto-resize notifications are displayed to users
  /// after automatic field sizing operations.
  static const Duration autoResizeMessageDuration = Duration(seconds: 3);

  /// Animation curve for preview animations.
  /// 
  /// Provides fast, responsive easing for preview operations. The
  /// [Curves.easeOutQuart] curve starts fast and decelerates smoothly.
  static const Curve previewCurve = Curves.easeOutQuart;

  /// Animation curve for commit animations.
  /// 
  /// Provides smooth, natural easing for field placement operations.
  /// The [Curves.easeOutCubic] curve creates satisfying motion.
  static const Curve commitCurve = Curves.easeOutCubic;

  /// Animation curve for revert animations.
  /// 
  /// Provides balanced easing for cancelled operations. The
  /// [Curves.easeInOut] curve creates smooth bidirectional motion.
  static const Curve revertCurve = Curves.easeInOut;

  /// Default animation curve for general field operations.
  /// 
  /// Used for resize, movement, and other general field animations.
  /// Provides consistent motion feel across different operations.
  static const Curve defaultFieldAnimationCurve = Curves.easeOutCubic;
}