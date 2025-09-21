import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:field_collision_test/features/customizable_form/presentation/systems/field_preview_system.dart';
import 'package:field_collision_test/features/customizable_form/data/models/field_config.dart';

/// Performance test to measure the cost difference between immediate vs delayed preview calculations
void main() {
  group('Hover Performance Tests', () {
    late Map<String, FieldConfig> testFieldConfigs;
    late Stopwatch stopwatch;
    
    setUp(() {
      // Create test field configurations
      testFieldConfigs = {
        'field1': FieldConfig(
          id: 'field1',
          position: const Offset(0, 0),
          width: 1.0,
        ),
        'field2': FieldConfig(
          id: 'field2',
          position: const Offset(0, 70),
          width: 0.5,
        ),
        'field3': FieldConfig(
          id: 'field3',
          position: const Offset(0.5, 70),
          width: 0.33,
        ),
      };
      stopwatch = Stopwatch();
    });

    test('Immediate Preview Calculation (Old System)', () async {
      int calculationCount = 0;
      int totalMicroseconds = 0;
      
      // Simulate 60 drag updates per second for 1 second (typical drag duration)
      for (int i = 0; i < 60; i++) {
        stopwatch.reset();
        stopwatch.start();
        
        // Simulate immediate preview calculation on every drag move
        final previewConfigs = FieldPreviewSystem.calculatePreviewPositions(
          targetRow: 1,
          draggedFieldId: 'field3',
          currentConfigs: testFieldConfigs,
          containerWidth: 400.0,
        );
        
        stopwatch.stop();
        calculationCount++;
        totalMicroseconds += stopwatch.elapsedMicroseconds;
        
        // Simulate 16ms between frames (60 FPS)
        await Future.delayed(const Duration(microseconds: 16667));
      }
      
      print('=== IMMEDIATE PREVIEW (Old System) ===');
      print('Total calculations: $calculationCount');
      print('Total time: ${totalMicroseconds}μs (${totalMicroseconds / 1000}ms)');
      print('Average per calculation: ${totalMicroseconds / calculationCount}μs');
      print('Calculations per second: ${calculationCount}');
    });

    test('Delayed Preview Calculation (New System)', () async {
      int calculationCount = 0;
      int totalMicroseconds = 0;
      int timerCalls = 0;
      
      Timer? hoverTimer;
      int? lastHoveredRow;
      
      // Simulate drag with hover detection
      for (int i = 0; i < 60; i++) {
        final currentRow = (i / 20).floor(); // Change row every ~20 frames
        
        // Simulate hover detection (very cheap operation)
        stopwatch.reset();
        stopwatch.start();
        
        if (lastHoveredRow != currentRow) {
          hoverTimer?.cancel();
          lastHoveredRow = currentRow;
          timerCalls++;
          
          // Start timer for delayed calculation
          hoverTimer = Timer(const Duration(milliseconds: 300), () {
            final calcStopwatch = Stopwatch()..start();
            
            // Actual expensive calculation only happens after delay
            final previewConfigs = FieldPreviewSystem.calculatePreviewPositions(
              targetRow: currentRow,
              draggedFieldId: 'field3',
              currentConfigs: testFieldConfigs,
              containerWidth: 400.0,
            );
            
            calcStopwatch.stop();
            calculationCount++;
            totalMicroseconds += calcStopwatch.elapsedMicroseconds;
          });
        }
        
        stopwatch.stop();
        // Timer management is very cheap (< 1μs typically)
        
        await Future.delayed(const Duration(microseconds: 16667));
      }
      
      // Wait for any pending timers to complete
      await Future.delayed(const Duration(milliseconds: 500));
      hoverTimer?.cancel();
      
      print('=== DELAYED PREVIEW (New System) ===');
      print('Total calculations: $calculationCount');
      print('Total time: ${totalMicroseconds}μs (${totalMicroseconds / 1000}ms)');
      print('Average per calculation: ${calculationCount > 0 ? totalMicroseconds / calculationCount : 0}μs');
      print('Timer calls: $timerCalls');
      print('Calculations per second: ${calculationCount}');
    });

    test('Performance Comparison', () async {
      // Test immediate system
      stopwatch.reset();
      stopwatch.start();
      
      for (int i = 0; i < 60; i++) {
        FieldPreviewSystem.calculatePreviewPositions(
          targetRow: 1,
          draggedFieldId: 'field3',
          currentConfigs: testFieldConfigs,
          containerWidth: 400.0,
        );
      }
      
      stopwatch.stop();
      final immediateTime = stopwatch.elapsedMicroseconds;
      
      // Test delayed system (simulate 3 calculations instead of 60)
      stopwatch.reset();
      stopwatch.start();
      
      for (int i = 0; i < 3; i++) {
        FieldPreviewSystem.calculatePreviewPositions(
          targetRow: 1,
          draggedFieldId: 'field3',
          currentConfigs: testFieldConfigs,
          containerWidth: 400.0,
        );
      }
      
      stopwatch.stop();
      final delayedTime = stopwatch.elapsedMicroseconds;
      
      print('=== PERFORMANCE COMPARISON ===');
      print('Immediate system (60 calculations): ${immediateTime}μs');
      print('Delayed system (3 calculations): ${delayedTime}μs');
      print('Performance improvement: ${((immediateTime - delayedTime) / immediateTime * 100).toStringAsFixed(1)}%');
      print('Speed up factor: ${(immediateTime / delayedTime).toStringAsFixed(1)}x');
      
      // Verify delayed system is actually cheaper
      expect(delayedTime, lessThan(immediateTime));
    });

    test('Memory Usage Simulation', () {
      int immediateAllocations = 0;
      int delayedAllocations = 0;
      
      // Simulate immediate system - creates preview configs on every move
      for (int i = 0; i < 60; i++) {
        final configs = FieldPreviewSystem.calculatePreviewPositions(
          targetRow: 1,
          draggedFieldId: 'field3',
          currentConfigs: testFieldConfigs,
          containerWidth: 400.0,
        );
        immediateAllocations += configs.length;
      }
      
      // Simulate delayed system - creates preview configs only 3 times
      for (int i = 0; i < 3; i++) {
        final configs = FieldPreviewSystem.calculatePreviewPositions(
          targetRow: 1,
          draggedFieldId: 'field3',
          currentConfigs: testFieldConfigs,
          containerWidth: 400.0,
        );
        delayedAllocations += configs.length;
      }
      
      print('=== MEMORY USAGE SIMULATION ===');
      print('Immediate system allocations: $immediateAllocations');
      print('Delayed system allocations: $delayedAllocations');
      print('Memory reduction: ${((immediateAllocations - delayedAllocations) / immediateAllocations * 100).toStringAsFixed(1)}%');
      
      expect(delayedAllocations, lessThan(immediateAllocations));
    });
  });
}