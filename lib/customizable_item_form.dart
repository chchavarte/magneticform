import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'field_resize_handler.dart';
import 'form_models.dart';
import 'field_preview_system.dart';

// Main customizable form widget
class CustomizableForm extends StatefulWidget {
  final List<CustomFormField> availableFields;
  final Map<String, FieldConfig> defaultFieldConfigs;
  final Widget Function(BuildContext context, Map<String, dynamic> formData)?
  cartSummaryButton;
  final bool showAppBar;
  final String appBarTitle;
  final String storageKey;

  const CustomizableForm({
    super.key,
    required this.availableFields,
    required this.defaultFieldConfigs,
    this.cartSummaryButton,
    this.showAppBar = true,
    this.appBarTitle = 'Custom Form',
    this.storageKey = 'custom_form_field_configs',
  });

  @override
  CustomizableFormState createState() => CustomizableFormState();
}

class CustomizableFormState extends State<CustomizableForm>
    with TickerProviderStateMixin {
  late Map<String, FieldConfig> _fieldConfigs;
  final bool _isLoading = false;
  bool _isCustomizationMode = false;
  String? _selectedFieldId;
  String? _draggedFieldId;
  Offset? _dragStartPosition;
  Offset? _dragStartFieldPosition;
  double _accumulatedDrag = 0;

  // Hover state for push down logic
  int? _hoveredColumn;
  int? _hoveredRow;

  // Throttling for rearrangement to prevent excessive calls
  DateTime? _lastRearrangementTime;

  // Auto-resize feedback
  String? _autoResizeMessage;
  DateTime? _autoResizeTime;

  // Preview system state
  PreviewState _previewState = PreviewState.initial();

  // Magnetic timeline: Store original positions for restoration
  final Map<String, Offset> _originalPositions = {};
  final Set<String> _temporarilyMovedFields = {};

  // Hover threshold to prevent accidental triggering
  static const double hoverThreshold = 40.0; // pixels
  bool _hasMovedBeyondThreshold = false;

  // Form data storage
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};

  // Helper getter for container width calculation
  double get _containerWidth => MediaQuery.of(context).size.width - 32;

  // Helper getter for theme access
  ThemeData get _theme => Theme.of(context);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fieldConfigs = Map.from(widget.defaultFieldConfigs);
  }

  void _initializeControllers() {
    for (var field in widget.availableFields) {
      _controllers[field.id] = TextEditingController(text: field.defaultValue);
      _controllers[field.id]?.addListener(() {
        _formData[field.id] = _controllers[field.id]?.text;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveFieldConfigurations() {
    // For now, just store in memory. Could be extended to use shared_preferences
  }

  // Restore original positions of temporarily moved fields
  void _restoreOriginalPositions() {
    // Restore all temporarily moved fields to their original positions
    for (final fieldId in _temporarilyMovedFields) {
      if (_originalPositions.containsKey(fieldId)) {
        setState(() {
          // Preserve current width when restoring position
          final currentWidth = _fieldConfigs[fieldId]!.width;
          _fieldConfigs[fieldId] = _fieldConfigs[fieldId]!.copyWith(
            position: _originalPositions[fieldId]!,
            width: currentWidth, // Keep any width changes that were made
          );
        });
      }
    }
    _temporarilyMovedFields.clear();
  }

  // Check if there's space available in a row for a field
  bool _hasSpaceInRow(int targetRow, String excludeFieldId, double fieldWidth) {
    final containerWidth = _containerWidth;

    // Try different positions in the row to see if the field fits (6-column grid)
    for (int col = 0; col < 6; col++) {
      final testX = MagneticCardSystem.getPositionFromColumn(
        col,
        containerWidth,
      );
      final testPosition = Offset(
        testX,
        targetRow * MagneticCardSystem.cardHeight,
      );

      if (!MagneticCardSystem.wouldOverlap(
        testPosition,
        fieldWidth,
        containerWidth,
        _fieldConfigs,
        excludeFieldId,
      )) {
        return true; // Found a spot
      }
    }
    return false; // No space available
  }

  // Push down logic - main entry point
  void _pushDownAllFieldsAtRow(int targetRow, String excludeFieldId) {
    // First, restore any previously moved fields
    _restoreOriginalPositions();

    final currentWidth = _fieldConfigs[excludeFieldId]!.width;

    // Check if there's space available in the target row
    if (_hasSpaceInRow(targetRow, excludeFieldId, currentWidth)) {
      // There's space - find the exact position in the target row
      final containerWidth = _containerWidth;
      final columnSpan = MagneticCardSystem.getColumnsFromWidth(currentWidth);

      Offset? foundPosition;

      // Try each possible starting column in the target row only (6-column grid)
      print(
        'DEBUG: Testing positions for field $excludeFieldId in row $targetRow, columnSpan: $columnSpan',
      );
      for (int startCol = 0; startCol <= 6 - columnSpan; startCol++) {
        final testPosition = Offset(
          MagneticCardSystem.getColumnPositionNormalized(startCol),
          targetRow * MagneticCardSystem.cardHeight,
        );

        print('DEBUG: Testing column $startCol, position: ${testPosition.dx}');

        final hasOverlap = MagneticCardSystem.wouldOverlap(
          testPosition,
          currentWidth,
          containerWidth,
          _fieldConfigs,
          excludeFieldId,
        );

        print('DEBUG: Column $startCol overlap: $hasOverlap');

        if (!hasOverlap) {
          foundPosition = testPosition;
          print('DEBUG: Found position at column $startCol');
          break; // Use the first available position
        }
      }

      if (foundPosition != null) {
        setState(() {
          _fieldConfigs[excludeFieldId] = _fieldConfigs[excludeFieldId]!
              .copyWith(position: foundPosition);
          _temporarilyMovedFields.add(excludeFieldId);

          // DO NOT end drag here - let user continue dragging
          // The drag should only end when user releases their hold
        });

        // Show auto-fit feedback
        _showAutoResizeMessage(
          'Auto-fitted $excludeFieldId to available position (${(currentWidth * 100).toInt()}% width)',
        );
      } else {
        // This shouldn't happen if _hasSpaceInRow returned true, but fallback to rearrange
        _rearrangeFieldsWithPullUp(targetRow, excludeFieldId);
      }
    } else {
      // No space - use rearrangement logic
      _rearrangeFieldsWithPullUp(targetRow, excludeFieldId);
    }
  }

  void _rearrangeFieldsWithPullUp(int targetRow, String excludeFieldId) {
    final draggedFieldOriginalRow = MagneticCardSystem.getRowFromPosition(
      _originalPositions[excludeFieldId]!.dy,
    );

    // Get ALL fields except the dragged one
    final allOtherFields = <String, Offset>{};
    for (final entry in _originalPositions.entries) {
      final fieldId = entry.key;
      if (fieldId == excludeFieldId) continue;
      allOtherFields[fieldId] = entry.value;
    }

    // Group fields by their original row
    final fieldsByRow = <int, List<MapEntry<String, Offset>>>{};
    for (final entry in allOtherFields.entries) {
      final originalRow = MagneticCardSystem.getRowFromPosition(entry.value.dy);
      fieldsByRow.putIfAbsent(originalRow, () => []).add(entry);
    }

    // Sort rows to maintain order
    final sortedRows = fieldsByRow.keys.toList()..sort();

    // Compact all fields and reserve space for target row
    int nextAvailableRow = 0;

    for (final originalRow in sortedRows) {
      final fieldsInRow = fieldsByRow[originalRow]!;

      // Skip the target row - reserve it for the dragged field
      if (nextAvailableRow == targetRow) {
        nextAvailableRow++;
      }

      for (final entry in fieldsInRow) {
        final fieldId = entry.key;
        final originalPosition = entry.value;

        final newPosition = Offset(
          originalPosition.dx,
          nextAvailableRow * MagneticCardSystem.cardHeight,
        );

        setState(() {
          _fieldConfigs[fieldId] = _fieldConfigs[fieldId]!.copyWith(
            position: newPosition,
          );
          _temporarilyMovedFields.add(fieldId);
        });
      }

      nextAvailableRow++; // Move to next available row
    }
  }

  // Pull up fields to fill gaps after drag operations
  void _pullUpFieldsToFillGaps() {
    // Find all rows that have fields
    Map<int, List<String>> fieldsByRow = {};
    for (final entry in _fieldConfigs.entries) {
      final fieldId = entry.key;
      final config = entry.value;
      if (!config.isVisible) continue;

      final position = config.position;
      final row = MagneticCardSystem.getRowFromPosition(position.dy);

      if (!fieldsByRow.containsKey(row)) {
        fieldsByRow[row] = [];
      }
      fieldsByRow[row]!.add(fieldId);
    }

    // Get all rows with fields, sorted
    List<int> occupiedRows = fieldsByRow.keys.toList()..sort();

    // Calculate all position changes in one pass (no setState yet)
    Map<String, FieldConfig> updatedConfigs = {};
    bool hasChanges = false;

    // Simple single-pass algorithm: assign consecutive row numbers
    int targetRow = 0;
    for (int sourceRow in occupiedRows) {
      if (sourceRow != targetRow) {
        // This row needs to be moved up
        List<String> fieldsInRow = fieldsByRow[sourceRow]!;

        for (String fieldId in fieldsInRow) {
          final currentConfig = _fieldConfigs[fieldId]!;
          final newY = targetRow * MagneticCardSystem.cardHeight;
          final newPosition = Offset(currentConfig.position.dx, newY);

          updatedConfigs[fieldId] = currentConfig.copyWith(
            position: newPosition,
          );
          hasChanges = true;
        }
      }
      targetRow++;
    }

    // Apply all changes in a single setState
    if (hasChanges) {
      setState(() {
        for (final entry in updatedConfigs.entries) {
          _fieldConfigs[entry.key] = entry.value;
        }
      });
    }
  }

  // Auto-expand fields to fill remaining gaps after drag operations
  void _autoExpandToFillGaps() {
    print('\n🔧 AUTO-EXPAND TO FILL GAPS');
    
    // Find all rows that have fields
    Map<int, List<String>> fieldsByRow = {};
    for (final entry in _fieldConfigs.entries) {
      final fieldId = entry.key;
      final config = entry.value;
      if (!config.isVisible) continue;

      final row = MagneticCardSystem.getRowFromPosition(config.position.dy);
      fieldsByRow.putIfAbsent(row, () => []).add(fieldId);
    }

    Map<String, FieldConfig> expandedConfigs = {};
    bool hasExpansions = false;

    // Check each row for gaps and expand fields
    for (final entry in fieldsByRow.entries) {
      final row = entry.key;
      final fieldsInRow = entry.value;
      
      print('Checking row $row with ${fieldsInRow.length} fields');
      
      // Calculate available space in this row
      final availableSpace = FieldPreviewSystem.calculateTotalAvailableSpace(
        targetRow: row,
        excludeFieldId: '', // Don't exclude any field
        currentConfigs: _fieldConfigs,
      );
      
      print('  Available space: ${(availableSpace * 100).toInt()}%');
      
      if (availableSpace > 0.05) { // If there's significant space (>5%)
        // Find the best expansion strategy
        final expansionStrategy = _findBestExpansionStrategy(row, fieldsInRow, availableSpace);
        
        if (expansionStrategy != null) {
          // Apply the expansion strategy to all affected fields
          for (final entry in expansionStrategy.entries) {
            final fieldId = entry.key;
            final newWidth = entry.value;
            final currentConfig = _fieldConfigs[fieldId]!;
            
            if ((newWidth - currentConfig.width).abs() > 0.01) { // Only if significant change
              print('  Updating $fieldId: ${(currentConfig.width * 100).toInt()}% → ${(newWidth * 100).toInt()}%');
              
              // For equal redistribution, we need to recalculate positions
              if (expansionStrategy.length > 1) {
                // Multiple fields being redistributed - calculate new positions
                final sortedFields = fieldsInRow.toList();
                sortedFields.sort((a, b) => _fieldConfigs[a]!.position.dx.compareTo(_fieldConfigs[b]!.position.dx));
                
                double currentX = 0.0;
                for (int i = 0; i < sortedFields.length; i++) {
                  final sortedFieldId = sortedFields[i];
                  if (expansionStrategy.containsKey(sortedFieldId)) {
                    final fieldWidth = expansionStrategy[sortedFieldId]!;
                    final newPosition = Offset(currentX, row * MagneticCardSystem.cardHeight);
                    
                    expandedConfigs[sortedFieldId] = _fieldConfigs[sortedFieldId]!.copyWith(
                      width: fieldWidth,
                      position: newPosition,
                    );
                    
                    currentX += fieldWidth;
                    hasExpansions = true;
                  }
                }
              } else {
                // Single field expansion - recalculate position to prevent overflow
                Offset newPosition;
                
                if (newWidth >= 0.99) {
                  // Full width - position at start of row
                  newPosition = Offset(0.0, row * MagneticCardSystem.cardHeight);
                } else {
                  // Partial width - ensure field doesn't overflow beyond grid boundary
                  final currentX = currentConfig.position.dx;
                  final maxAllowedX = 1.0 - newWidth; // Maximum x position to prevent overflow
                  
                  if (currentX + newWidth > 1.0) {
                    // Field would overflow - reposition it to fit within grid
                    newPosition = Offset(maxAllowedX, row * MagneticCardSystem.cardHeight);
                    print('  Repositioning $fieldId from ${(currentX * 100).toInt()}% to ${(maxAllowedX * 100).toInt()}% to prevent overflow');
                  } else {
                    // Field fits at current position
                    newPosition = currentConfig.position;
                  }
                }
                    
                expandedConfigs[fieldId] = currentConfig.copyWith(
                  width: newWidth,
                  position: newPosition,
                );
                hasExpansions = true;
              }
            }
          }
        }
      }
    }

    // Apply expansions with animation
    if (hasExpansions) {
      print('Applying ${expandedConfigs.length} field expansions');
      
      // Create final configs with expansions
      final finalConfigs = Map<String, FieldConfig>.from(_fieldConfigs);
      for (final entry in expandedConfigs.entries) {
        finalConfigs[entry.key] = entry.value;
      }
      
      // Animate the expansions
      FieldPreviewSystem.animateToCommit(
        vsync: this,
        fromConfigs: _fieldConfigs,
        toConfigs: finalConfigs,
        onUpdate: (configs) {
          setState(() {
            _fieldConfigs = configs;
          });
        },
        onComplete: () {
          print('Auto-expansion complete');
        },
      );
    } else {
      print('No gaps found to fill');
    }
  }

  // Calculate total available space in a row
  double _calculateTotalAvailableSpace({
    required int targetRow,
    required String excludeFieldId,
    required Map<String, FieldConfig> currentConfigs,
  }) {
    double totalOccupied = 0.0;
    
    // Sum up all occupied space in the target row (excluding specified field)
    for (final entry in currentConfigs.entries) {
      if (entry.key == excludeFieldId) continue;
      
      final config = entry.value;
      final fieldRow = MagneticCardSystem.getRowFromPosition(config.position.dy);
      if (fieldRow == targetRow) {
        totalOccupied += config.width;
      }
    }
    
    // Available space is what's left (1.0 = 100% width)
    return (1.0 - totalOccupied).clamp(0.0, 1.0);
  }

  // Find the best expansion strategy for fields in a row
  Map<String, double>? _findBestExpansionStrategy(int row, List<String> fieldsInRow, double availableSpace) {
    if (fieldsInRow.isEmpty) return null;
    
    // If only one field, expand it to fill the row
    if (fieldsInRow.length == 1) {
      print('  Single field in row, expanding ${fieldsInRow.first} to 100%');
      return {fieldsInRow.first: 1.0};
    }
    
    // Check if all fields have equal or similar widths (within 5% tolerance)
    final fieldWidths = fieldsInRow.map((id) => _fieldConfigs[id]!.width).toList();
    final avgWidth = fieldWidths.reduce((a, b) => a + b) / fieldWidths.length;
    final isEqualWidths = fieldWidths.every((width) => (width - avgWidth).abs() < 0.05);
    
    print('  Field widths: ${fieldWidths.map((w) => '${(w * 100).toInt()}%').join(', ')}');
    print('  Average width: ${(avgWidth * 100).toInt()}%, Equal widths: $isEqualWidths');
    
    if (isEqualWidths) {
      // Equal widths: redistribute equally among remaining fields
      print('  Equal widths detected - redistributing equally');
      final newWidth = 1.0 / fieldsInRow.length; // Distribute 100% equally
      final redistributions = <String, double>{};
      
      for (final fieldId in fieldsInRow) {
        redistributions[fieldId] = newWidth;
      }
      
      print('  New equal distribution: ${(newWidth * 100).toInt()}% each');
      return redistributions;
    } else {
      // Unequal widths: use gap-filling strategy with smart positioning
      print('  Unequal widths detected - using gap-filling strategy');
      final expansionResult = _findBestFieldExpansion(row, fieldsInRow, availableSpace);
      
      if (expansionResult != null) {
        return expansionResult;
      }
    }
    
    return null;
  }

  // Find the best field expansion with smart positioning
  Map<String, double>? _findBestFieldExpansion(int row, List<String> fieldsInRow, double availableSpace) {
    final gaps = _findGapsInRow(row, fieldsInRow);
    if (gaps.isEmpty) return null;
    
    // Find the largest gap
    var largestGap = gaps.reduce((a, b) => a.size > b.size ? a : b);
    print('  Largest gap: ${(largestGap.size * 100).toInt()}% at position ${largestGap.position}');
    
    // Find the closest field to this gap
    String? closestField;
    double minDistance = double.infinity;
    
    for (final fieldId in fieldsInRow) {
      final config = _fieldConfigs[fieldId]!;
      final fieldCenter = config.position.dx + (config.width / 2);
      final gapCenter = largestGap.position + (largestGap.size / 2);
      final distance = (fieldCenter - gapCenter).abs();
      
      if (distance < minDistance) {
        minDistance = distance;
        closestField = fieldId;
      }
    }
    
    print('  Closest field to gap: $closestField (distance: ${(minDistance * 100).toInt()}%)');
    
    if (closestField != null) {
      final currentWidth = _fieldConfigs[closestField]!.width;
      final newWidth = (currentWidth + availableSpace).clamp(0.0, 1.0);
      final snappedWidth = MagneticCardSystem.getMagneticWidth(newWidth);
      
      print('  Updating $closestField: ${(currentWidth * 100).toInt()}% → ${(snappedWidth * 100).toInt()}%');
      return {closestField: snappedWidth};
    }
    
    return null;
  }

  // Find the field closest to the largest gap (original logic for unequal widths)
  String? _findClosestFieldToLargestGap(int row, List<String> fieldsInRow) {
    final gaps = _findGapsInRow(row, fieldsInRow);
    if (gaps.isEmpty) return null;
    
    // Find the largest gap
    var largestGap = gaps.reduce((a, b) => a.size > b.size ? a : b);
    print('  Largest gap: ${(largestGap.size * 100).toInt()}% at position ${largestGap.position}');
    
    // Find the closest field to this gap
    String? closestField;
    double minDistance = double.infinity;
    
    for (final fieldId in fieldsInRow) {
      final config = _fieldConfigs[fieldId]!;
      final fieldCenter = config.position.dx + (config.width / 2);
      final gapCenter = largestGap.position + (largestGap.size / 2);
      final distance = (fieldCenter - gapCenter).abs();
      
      if (distance < minDistance) {
        minDistance = distance;
        closestField = fieldId;
      }
    }
    
    print('  Closest field to gap: $closestField (distance: ${(minDistance * 100).toInt()}%)');
    return closestField;
  }

  // Find gaps in a row
  List<({double position, double size})> _findGapsInRow(int row, List<String> fieldsInRow) {
    final gaps = <({double position, double size})>[];
    
    // Get field positions and sort by x position
    final fieldConfigs = fieldsInRow
        .map((id) => _fieldConfigs[id]!)
        .where((config) => MagneticCardSystem.getRowFromPosition(config.position.dy) == row)
        .toList();
    
    fieldConfigs.sort((a, b) => a.position.dx.compareTo(b.position.dx));
    
    // Check gap at the beginning
    if (fieldConfigs.isNotEmpty && fieldConfigs.first.position.dx > 0) {
      gaps.add((position: 0.0, size: fieldConfigs.first.position.dx));
    }
    
    // Check gaps between fields
    for (int i = 0; i < fieldConfigs.length - 1; i++) {
      final currentEnd = fieldConfigs[i].position.dx + fieldConfigs[i].width;
      final nextStart = fieldConfigs[i + 1].position.dx;
      final gapSize = nextStart - currentEnd;
      
      if (gapSize > 0.05) { // Only consider significant gaps (>5%)
        gaps.add((position: currentEnd, size: gapSize));
      }
    }
    
    // Check gap at the end
    if (fieldConfigs.isNotEmpty) {
      final lastEnd = fieldConfigs.last.position.dx + fieldConfigs.last.width;
      if (lastEnd < 0.95) { // If not at the very end
        gaps.add((position: lastEnd, size: 1.0 - lastEnd));
      }
    }
    
    return gaps;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return GestureDetector(
      onTap: _isCustomizationMode ? _deselectField : null,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: _theme.scaffoldBackgroundColor,
        appBar: widget.showAppBar ? _buildAppBar() : null,
        body: Stack(children: [_buildMainContent()]),
        bottomSheet:
            _isCustomizationMode
                ? _buildAdditionalFieldsContainer()
                : widget.cartSummaryButton?.call(context, _formData),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _theme.appBarTheme.backgroundColor,
      elevation: 0.5,
      centerTitle: true,
      title: Text(widget.appBarTitle, style: _theme.appBarTheme.titleTextStyle),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(
            _isCustomizationMode ? Icons.done : Icons.tune,
            size: 24,
            color: _theme.colorScheme.onSurface,
          ),
          onPressed: () {
            setState(() {
              _isCustomizationMode = !_isCustomizationMode;
              if (!_isCustomizationMode) {
                _saveFieldConfigurations();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = _isCustomizationMode ? 120.0 : 90.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _theme.scaffoldBackgroundColor),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: screenWidth - 32,
                  height:
                      _isCustomizationMode
                          ? max(screenHeight - 200, 840)
                          : screenHeight - 150,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (_isCustomizationMode) _buildSnapGuides(),

                      // Preview target indicator
                      if (_isCustomizationMode) _buildPreviewIndicator(),

                      ..._fieldConfigs.keys.map((fieldId) {
                        final matchingField = widget.availableFields.where(
                          (f) => f.id == fieldId,
                        );
                        if (matchingField.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return _buildMagneticField(
                          fieldId,
                          matchingField.first.builder(
                            context,
                            _isCustomizationMode,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(height: bottomPadding),
              ],
            ),
            // Auto-resize feedback message
            if (_autoResizeMessage != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _theme.colorScheme.onSurface.withValues(
                          alpha: 0.2,
                        ),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _autoResizeMessage!,
                    style: TextStyle(
                      color: _theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapGuides() {
    final containerWidth = _containerWidth;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Stack(
        children: [
          for (int row = 0; row < MagneticCardSystem.maxRows; row++)
            Positioned(
              left: 0,
              right: 0,
              top: row * MagneticCardSystem.cardHeight - 2,
              child: Container(
                height: MagneticCardSystem.cardHeight + 4,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  color: _theme.colorScheme.onSurface.withValues(alpha: 0.02),
                ),
              ),
            ),

          for (int col = 1; col < 6; col++)
            Positioned(
              left: (containerWidth / 6) * col - 1,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  color: _theme.colorScheme.onSurface.withValues(
                    alpha: col % 2 == 0 ? 0.1 : 0.06,
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMagneticField(String fieldId, Widget field) {
    final config = _fieldConfigs[fieldId];
    if (config == null) return const SizedBox.shrink();

    // Only render fields that are actually visible
    if (!config.isVisible) {
      return const SizedBox.shrink();
    }

    final isSelected = _selectedFieldId == fieldId;
    final isDragged = _draggedFieldId == fieldId;
    final isInPreview =
        _previewState.isActive && fieldId != _previewState.draggedFieldId;
    final containerWidth = _containerWidth;

    final fieldWidth = config.width * containerWidth;
    final leftPosition = config.position.dx * containerWidth;

    return Positioned(
      left: leftPosition,
      top: config.position.dy + 8,
      child: Stack(
        children: [
          GestureDetector(
            onTap: _isCustomizationMode ? () => _selectField(fieldId) : null,
            onLongPressStart:
                _isCustomizationMode
                    ? (details) => _startFieldDrag(fieldId, details)
                    : null,
            onLongPressMoveUpdate:
                _isCustomizationMode && _draggedFieldId == fieldId
                    ? (details) => _onFieldDrag(fieldId, details)
                    : null,
            onLongPressEnd:
                _isCustomizationMode && _draggedFieldId == fieldId
                    ? (details) => _onFieldDragEnd(fieldId, details)
                    : null,
            behavior: HitTestBehavior.opaque,
            child: AbsorbPointer(
              absorbing: _isCustomizationMode,
              child: Container(
                width:
                    fieldWidth -
                    (config.position.dx > 0 ? MagneticCardSystem.fieldGap : 0),
                margin: EdgeInsets.only(
                  left:
                      config.position.dx > 0 ? MagneticCardSystem.fieldGap : 0,
                ),
                decoration:
                    isDragged
                        ? BoxDecoration(
                          border: Border.all(
                            color: _theme.colorScheme.primary,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: _theme.colorScheme.primary.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                        : isInPreview
                        ? BoxDecoration(
                          border: Border.all(
                            color: _theme.colorScheme.secondary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: _theme.colorScheme.secondary.withValues(
                            alpha: 0.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _theme.colorScheme.secondary.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                        : _isCustomizationMode && isSelected
                        ? BoxDecoration(
                          border: Border.all(
                            color: _theme.colorScheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: _theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                        : _isCustomizationMode
                        ? BoxDecoration(
                          border: Border.all(
                            color: _theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        )
                        : null,
                child: field,
              ),
            ),
          ),
          if (_isCustomizationMode && isSelected) ...[
            // Resize handles
            FieldResizeHandler.buildResizeHandle(
              direction: ResizeDirection.left,
              fieldId: fieldId,
              theme: _theme,
              onResize: _onResizeField,
              onResizeStart: _onResizeFieldStart,
              onResizeEnd: _onResizeFieldEnd,
            ),
            FieldResizeHandler.buildResizeHandle(
              direction: ResizeDirection.right,
              fieldId: fieldId,
              theme: _theme,
              onResize: _onResizeField,
              onResizeStart: _onResizeFieldStart,
              onResizeEnd: _onResizeFieldEnd,
            ),
          ],
        ],
      ),
    );
  }

  void _startFieldDrag(String fieldId, LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    final config = _fieldConfigs[fieldId]!;

    setState(() {
      _draggedFieldId = fieldId;
      _selectedFieldId = fieldId; // Also select the field
      _dragStartPosition = details.globalPosition;
      _dragStartFieldPosition = config.position;
      _hasMovedBeyondThreshold = false; // Reset threshold flag

      // Initialize preview state
      _previewState = PreviewState.initial();

      // Store original positions of all fields at drag start
      _originalPositions.clear();
      _temporarilyMovedFields.clear();
      for (final entry in _fieldConfigs.entries) {
        _originalPositions[entry.key] = entry.value.position;
      }
    });
  }

  void _onFieldDrag(String fieldId, LongPressMoveUpdateDetails details) {
    if (_dragStartPosition == null || _dragStartFieldPosition == null) return;

    final containerWidth = _containerWidth;
    final config = _fieldConfigs[fieldId]!;

    // Calculate distance moved from start position
    final distanceMoved =
        (details.globalPosition - _dragStartPosition!).distance;

    // Check if we've moved beyond the threshold
    if (!_hasMovedBeyondThreshold && distanceMoved > hoverThreshold) {
      _hasMovedBeyondThreshold = true;
    }

    // Calculate delta from start position
    final deltaX =
        (details.globalPosition.dx - _dragStartPosition!.dx) / containerWidth;
    final deltaY = details.globalPosition.dy - _dragStartPosition!.dy;

    // Calculate new position for visual feedback (dragged field follows cursor)
    final newX = (_dragStartFieldPosition!.dx + deltaX).clamp(
      0.0,
      1.0 - config.width,
    );
    final newY = (_dragStartFieldPosition!.dy + deltaY).clamp(
      0.0,
      MagneticCardSystem.maxRows * MagneticCardSystem.cardHeight,
    );

    final newPosition = Offset(newX, newY);

    // Get hovered column and row
    final gridPosition = MagneticCardSystem.getGridPosition(
      newPosition,
      containerWidth,
    );
    final hoveredColumn = gridPosition.column;
    final hoveredRow = gridPosition.row;

    // Update dragged field position for visual feedback
    setState(() {
      final currentWidth = _fieldConfigs[fieldId]!.width;
      _fieldConfigs[fieldId] = config.copyWith(
        position: newPosition,
        width: currentWidth,
      );
      _hoveredColumn = hoveredColumn;
      _hoveredRow = hoveredRow;
    });

    // Handle preview logic if we've moved beyond threshold
    if (_hasMovedBeyondThreshold) {
      _handlePreviewLogic(fieldId, hoveredRow);
    }
  }

  // Handle preview logic for hover effects
  void _handlePreviewLogic(String fieldId, int hoveredRow) {
    // Throttle preview updates to prevent excessive calls
    final now = DateTime.now();
    if (_lastRearrangementTime != null &&
        now.difference(_lastRearrangementTime!).inMilliseconds < 100) {
      return;
    }
    _lastRearrangementTime = now;

    // Check if we're hovering over a new row
    if (_previewState.targetRow != hoveredRow) {
      // Always show preview - either direct placement or push down
      _showPreview(fieldId, hoveredRow);
    }
  }

  // Show preview positions
  void _showPreview(String fieldId, int targetRow) {
    print('\n🎯 DRAG PREVIEW: Field $fieldId targeting row $targetRow');
    print('Current field configs before preview:');
    for (final entry in _fieldConfigs.entries) {
      final config = entry.value;
      final row = MagneticCardSystem.getRowFromPosition(config.position.dy);
      final startCol = MagneticCardSystem.getColumnFromPosition(config.position.dx, _containerWidth);
      final span = MagneticCardSystem.getColumnsFromWidth(config.width);
      print('  ${entry.key}: Row $row, Columns $startCol-${startCol + span - 1}, Width ${(config.width * 100).toInt()}%');
    }
    
    final originalConfigs =
        _previewState.originalConfigs.isNotEmpty
            ? _previewState.originalConfigs
            : Map<String, FieldConfig>.from(_fieldConfigs);

    print('Calling FieldPreviewSystem.calculatePreviewPositions...');
    final previewConfigs = FieldPreviewSystem.calculatePreviewPositions(
      targetRow: targetRow,
      draggedFieldId: fieldId,
      currentConfigs: originalConfigs,
      containerWidth: _containerWidth,
    );

    print('Calling FieldPreviewSystem.getPreviewInfo...');
    final previewInfo = FieldPreviewSystem.getPreviewInfo(
      targetRow: targetRow,
      draggedFieldId: fieldId,
      currentConfigs: originalConfigs,
      containerWidth: _containerWidth,
    );
    
    print('Preview result: ${previewInfo.message}');
    print('Preview configs returned:');
    for (final entry in previewConfigs.entries) {
      final config = entry.value;
      final row = MagneticCardSystem.getRowFromPosition(config.position.dy);
      final startCol = MagneticCardSystem.getColumnFromPosition(config.position.dx, _containerWidth);
      final span = MagneticCardSystem.getColumnsFromWidth(config.width);
      print('  ${entry.key}: Row $row, Columns $startCol-${startCol + span - 1}, Width ${(config.width * 100).toInt()}%');
    }

    // Update preview state
    _previewState = PreviewState.active(
      draggedFieldId: fieldId,
      targetRow: targetRow,
      previewConfigs: previewConfigs,
      originalConfigs: originalConfigs,
      previewInfo: previewInfo,
    );

    // Animate to preview positions (excluding the dragged field which follows cursor)
    final animationConfigs = Map<String, FieldConfig>.from(previewConfigs);
    animationConfigs[fieldId] =
        _fieldConfigs[fieldId]!; // Keep dragged field at cursor position

    FieldPreviewSystem.animateToPreview(
      vsync: this,
      fromConfigs: _fieldConfigs,
      toConfigs: animationConfigs,
      onUpdate: (configs) {
        setState(() {
          _fieldConfigs = configs;
        });
      },
    );

    // Show preview feedback
    _showAutoResizeMessage(previewInfo.message);
  }

  // Build preview target indicator
  Widget _buildPreviewIndicator() {
    if (!_previewState.isActive ||
        _previewState.previewInfo?.targetPosition == null ||
        _previewState.previewInfo?.hasSpace != true) {
      return const SizedBox.shrink();
    }

    final targetPosition = _previewState.previewInfo!.targetPosition!;
    final containerWidth = _containerWidth;
    final draggedField = _fieldConfigs[_previewState.draggedFieldId!]!;

    final fieldWidth = draggedField.width * containerWidth;
    final leftPosition = targetPosition.dx * containerWidth;

    return Positioned(
      left: leftPosition,
      top: targetPosition.dy + 8,
      child: Container(
        width:
            fieldWidth -
            (targetPosition.dx > 0 ? MagneticCardSystem.fieldGap : 0),
        height: MagneticCardSystem.cardHeight,
        margin: EdgeInsets.only(
          left: targetPosition.dx > 0 ? MagneticCardSystem.fieldGap : 0,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: _theme.colorScheme.primary.withValues(alpha: 0.6),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        child: Center(
          child: Icon(
            Icons.place,
            color: _theme.colorScheme.primary.withValues(alpha: 0.7),
            size: 24,
          ),
        ),
      ),
    );
  }

  void _onFieldDragEnd(String fieldId, LongPressEndDetails details) {
    if (_previewState.isActive && _previewState.previewInfo?.hasSpace == true) {
      // Commit preview positions
      _commitPreview(fieldId);
    } else {
      // No preview or no space - use standard snap logic
      _handleStandardDragEnd(fieldId);
    }

    // Clean up drag state
    setState(() {
      _draggedFieldId = null;
      _dragStartPosition = null;
      _dragStartFieldPosition = null;
      _hoveredColumn = null;
      _hoveredRow = null;
      _hasMovedBeyondThreshold = false;
      _originalPositions.clear();
      _temporarilyMovedFields.clear();
    });

    _previewState = PreviewState.initial();
  }

  // Commit preview positions with animation
  void _commitPreview(String fieldId) {
    print('\n✅ COMMIT PREVIEW: Field $fieldId');
    if (!_previewState.isActive ||
        _previewState.previewInfo?.targetPosition == null) {
      print('No active preview, using standard drag end');
      _handleStandardDragEnd(fieldId);
      return;
    }

    print('Committing preview positions...');
    print('Preview info: ${_previewState.previewInfo!.message}');
    
    // Create final configs with the dragged field at the preview position
    final finalConfigs = Map<String, FieldConfig>.from(
      _previewState.previewConfigs,
    );
    
    // Check if the preview included a width change for the dragged field
    final previewDraggedField = _previewState.previewConfigs[fieldId];
    if (previewDraggedField != null) {
      print('Using preview config for $fieldId: width ${(previewDraggedField.width * 100).toInt()}%, position ${previewDraggedField.position}');
      finalConfigs[fieldId] = previewDraggedField;
    } else {
      print('No preview config found, using target position only');
      finalConfigs[fieldId] = _fieldConfigs[fieldId]!.copyWith(
        position: _previewState.previewInfo!.targetPosition!,
      );
    }
    
    print('Final configs to commit:');
    for (final entry in finalConfigs.entries) {
      final config = entry.value;
      final row = MagneticCardSystem.getRowFromPosition(config.position.dy);
      final startCol = MagneticCardSystem.getColumnFromPosition(config.position.dx, _containerWidth);
      final span = MagneticCardSystem.getColumnsFromWidth(config.width);
      print('  ${entry.key}: Row $row, Columns $startCol-${startCol + span - 1}, Width ${(config.width * 100).toInt()}%');
    }

    // Animate to final positions
    FieldPreviewSystem.animateToCommit(
      vsync: this,
      fromConfigs: _fieldConfigs,
      toConfigs: finalConfigs,
      onUpdate: (configs) {
        setState(() {
          _fieldConfigs = configs;
        });
      },
      onComplete: () {
        _pullUpFieldsToFillGaps();
        // Auto-expand fields to fill remaining gaps
        _autoExpandToFillGaps();
        _saveFieldConfigurations();
      },
    );
  }

  // Handle standard drag end without preview
  void _handleStandardDragEnd(String fieldId) {
    final containerWidth = _containerWidth;
    final config = _fieldConfigs[fieldId]!;

    // Snap dragged field to grid
    final snappedPosition = MagneticCardSystem.getMagneticSnapPosition(
      config.position,
      containerWidth,
    );

    // Check if snapped position would cause overlap
    final wouldOverlap = MagneticCardSystem.wouldOverlap(
      snappedPosition,
      config.width,
      containerWidth,
      _fieldConfigs,
      fieldId,
    );

    // If overlap detected, find nearest valid position
    final finalPosition =
        wouldOverlap
            ? MagneticCardSystem.findNextAvailablePosition(
              config.width,
              containerWidth,
              _fieldConfigs,
              fieldId,
            )
            : snappedPosition;

    setState(() {
      _fieldConfigs[fieldId] = _fieldConfigs[fieldId]!.copyWith(
        position: finalPosition,
      );
    });

    _pullUpFieldsToFillGaps();
    _saveFieldConfigurations();
  }

  void _onResizeField(
    String fieldId,
    DragUpdateDetails details,
    ResizeDirection direction,
  ) {
    FieldResizeHandler.handleResize(
      fieldId: fieldId,
      details: details,
      direction: direction,
      fieldConfigs: _fieldConfigs,
      containerWidth: _containerWidth,
      accumulatedDrag: _accumulatedDrag,
      vsync: this,
      onFieldUpdate: (id, config) {
        setState(() {
          _fieldConfigs[id] = config;
        });
      },
      onAccumulatedDragUpdate: (value) {
        _accumulatedDrag = value;
      },
      onSave: _saveFieldConfigurations,
    );
  }

  void _onResizeFieldStart(String fieldId, ResizeDirection direction) {
    FieldResizeHandler.handleResizeStart(
      fieldId: fieldId,
      fieldConfigs: _fieldConfigs,
    );
  }

  void _onResizeFieldEnd(String fieldId, ResizeDirection direction) {
    FieldResizeHandler.handleResizeEnd(
      fieldId: fieldId,
      fieldConfigs: _fieldConfigs,
      containerWidth: _containerWidth,
      vsync: this,
      onFieldUpdate: (id, config) {
        setState(() {
          _fieldConfigs[id] = config;
        });
      },
      onSave: _saveFieldConfigurations,
    );
  }

  Widget _buildAdditionalFieldsContainer() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: _theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: _theme.colorScheme.onSurface.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: _theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _theme.colorScheme.onSurface.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: _theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 16,
                  color: _theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'All Entry Fields',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap to add/remove →',
                  style: TextStyle(
                    fontSize: 12,
                    color: _theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children:
                    widget.availableFields.map((field) {
                      final config = _fieldConfigs[field.id];
                      final isOnPage = config != null && config.isVisible;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _toggleAdditionalField(field.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isOnPage
                                      ? _theme.colorScheme.primary
                                      : _theme.colorScheme.surface,
                              border: Border.all(
                                color:
                                    isOnPage
                                        ? _theme.colorScheme.primary
                                        : _theme.colorScheme.onSurface
                                            .withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOnPage ? Icons.check_circle : field.icon,
                                  size: 14,
                                  color:
                                      isOnPage
                                          ? _theme.colorScheme.onPrimary
                                          : _theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  field.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isOnPage
                                            ? _theme.colorScheme.onPrimary
                                            : _theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                    fontWeight:
                                        isOnPage
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                  ),
                                ),
                                if (isOnPage) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.close,
                                    size: 12,
                                    color: _theme.colorScheme.onPrimary,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectField(String fieldId) {
    setState(() {
      _selectedFieldId = fieldId;
    });
  }

  void _deselectField() {
    if (_selectedFieldId != null) {
      setState(() {
        _selectedFieldId = null;
      });
    }
  }

  void _showAutoResizeMessage(String message) {
    setState(() {
      _autoResizeMessage = message;
      _autoResizeTime = DateTime.now();
    });

    // Clear the message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted &&
          _autoResizeTime != null &&
          DateTime.now().difference(_autoResizeTime!).inSeconds >= 3) {
        setState(() {
          _autoResizeMessage = null;
          _autoResizeTime = null;
        });
      }
    });
  }

  void _toggleAdditionalField(String fieldId) {
    setState(() {
      final config = _fieldConfigs[fieldId];
      final isCurrentlyVisible = config != null && config.isVisible;

      if (isCurrentlyVisible) {
        // Hide the field by setting width to 0 and moving to negative position
        _fieldConfigs[fieldId] = FieldConfig(
          id: fieldId,
          width: 0,
          position: const Offset(-100, -100),
        );
        if (_selectedFieldId == fieldId) {
          _selectedFieldId = null;
        }

        _pullUpFieldsToFillGaps();
      } else {
        // Show the field by adding it to the form
        _addFieldToSingleColumn(fieldId);
      }
    });
    _saveFieldConfigurations();
  }

  void _addFieldToSingleColumn(String fieldId) {
    int nextRow = 0;
    for (var config in _fieldConfigs.values) {
      if (config.position.dx == 0) {
        int currentRow = MagneticCardSystem.getRowFromPosition(
          config.position.dy,
        );
        if (currentRow >= nextRow) {
          nextRow = currentRow + 1;
        }
      }
    }

    _fieldConfigs[fieldId] = FieldConfig(
      id: fieldId,
      position: Offset(0, nextRow * 70.0),
      width: 1.0,
    );
  }
}
