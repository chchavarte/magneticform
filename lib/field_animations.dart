import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;
import 'form_models.dart';

// Reusable animation system for field resize operations
class FieldAnimations {
  static const Duration _defaultDuration = Duration(milliseconds: 300);
  static const Curve _defaultCurve = Curves.easeOutCubic;

  // Animate field width changes (for resize snap-back and auto-resize)
  static void animateFieldResize({
    required TickerProvider vsync,
    required String fieldId,
    required double fromWidth,
    required double toWidth,
    required Function(String, double) onWidthUpdate,
    VoidCallback? onComplete,
    Duration? duration,
    Curve? curve,
  }) {
    if (fromWidth == toWidth) {
      onComplete?.call();
      return;
    }

    final animationController = AnimationController(
      duration: duration ?? _defaultDuration,
      vsync: vsync,
    );

    final animation = Tween<double>(
      begin: fromWidth,
      end: toWidth,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: curve ?? _defaultCurve,
    ));

    animation.addListener(() {
      onWidthUpdate(fieldId, animation.value);
    });

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationController.dispose();
        onComplete?.call();
      }
    });

    animationController.forward();
  }

  // Animate field position changes (for drag snap-back)
  static void animateFieldPosition({
    required TickerProvider vsync,
    required String fieldId,
    required Offset fromPosition,
    required Offset toPosition,
    required Function(String, Offset) onPositionUpdate,
    VoidCallback? onComplete,
    Duration? duration,
    Curve? curve,
  }) {
    if (fromPosition == toPosition) {
      onComplete?.call();
      return;
    }

    final animationController = AnimationController(
      duration: duration ?? _defaultDuration,
      vsync: vsync,
    );

    final animation = Tween<Offset>(
      begin: fromPosition,
      end: toPosition,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: curve ?? _defaultCurve,
    ));

    animation.addListener(() {
      onPositionUpdate(fieldId, animation.value);
    });

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationController.dispose();
        onComplete?.call();
      }
    });

    animationController.forward();
  }

  // Animate complete field config changes (position + width)
  static void animateFieldConfig({
    required TickerProvider vsync,
    required String fieldId,
    required FieldConfig fromConfig,
    required FieldConfig toConfig,
    required Function(String, FieldConfig) onConfigUpdate,
    VoidCallback? onComplete,
    Duration? duration,
    Curve? curve,
  }) {
    if (fromConfig.position == toConfig.position && 
        fromConfig.width == toConfig.width) {
      onConfigUpdate(fieldId, toConfig);
      onComplete?.call();
      return;
    }

    final animationController = AnimationController(
      duration: duration ?? _defaultDuration,
      vsync: vsync,
    );

    final positionAnimation = Tween<Offset>(
      begin: fromConfig.position,
      end: toConfig.position,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: curve ?? _defaultCurve,
    ));

    final widthAnimation = Tween<double>(
      begin: fromConfig.width,
      end: toConfig.width,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: curve ?? _defaultCurve,
    ));

    animationController.addListener(() {
      final animatedConfig = fromConfig.copyWith(
        position: positionAnimation.value,
        width: widthAnimation.value,
      );
      onConfigUpdate(fieldId, animatedConfig);
    });

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationController.dispose();
        onComplete?.call();
      }
    });

    animationController.forward();
  }

  // Batch animate multiple fields (for auto-resize scenarios)
  static void animateMultipleFields({
    required TickerProvider vsync,
    required Map<String, FieldConfig> fromConfigs,
    required Map<String, FieldConfig> toConfigs,
    required Function(Map<String, FieldConfig>) onUpdate,
    VoidCallback? onComplete,
    Duration? duration,
    Curve? curve,
  }) {
    final animationController = AnimationController(
      duration: duration ?? _defaultDuration,
      vsync: vsync,
    );

    final animations = <String, Animation<FieldConfig>>{};
    
    for (final fieldId in fromConfigs.keys) {
      final fromConfig = fromConfigs[fieldId]!;
      final toConfig = toConfigs[fieldId]!;
      
      animations[fieldId] = FieldConfigTween(
        begin: fromConfig,
        end: toConfig,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: curve ?? _defaultCurve,
      ));
    }

    animationController.addListener(() {
      final animatedConfigs = <String, FieldConfig>{};
      for (final entry in animations.entries) {
        animatedConfigs[entry.key] = entry.value.value;
      }
      onUpdate(animatedConfigs);
    });

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationController.dispose();
        onComplete?.call();
      }
    });

    animationController.forward();
  }
}

// Custom Tween for FieldConfig interpolation
class FieldConfigTween extends Tween<FieldConfig> {
  FieldConfigTween({required FieldConfig begin, required FieldConfig end})
      : super(begin: begin, end: end);

  @override
  FieldConfig lerp(double t) {
    return FieldConfig(
      id: begin!.id,
      width: lerpDouble(begin!.width, end!.width, t) ?? begin!.width,
      position: Offset.lerp(begin!.position, end!.position, t) ?? begin!.position,
    );
  }
}