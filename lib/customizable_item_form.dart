import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

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

// Magnetic card system for snapping fields
class MagneticCardSystem {
  static const double cardHeight = 70.0;
  static const int maxRows = 12;
  static const double snapThreshold = 30.0;
  static const double fieldGap = 4.0;

  // Base widths starting from 1/3 as minimum
  static const List<double> cardWidths = [
    1 / 3, // One third - minimum usable width
    2 / 3, // Two thirds
    1.0, // Full width
  ];

  static Offset getMagneticSnapPosition(
    Offset currentPos,
    double containerWidth,
  ) {
    final targetRow = (currentPos.dy / cardHeight).round().clamp(
      0,
      maxRows - 1,
    );
    final snappedY = targetRow * cardHeight;

    // Snap to grid positions based on sixths for 6-column grid
    final columnWidth = containerWidth / 6; // Divide container into 6 columns
    final targetSlot = (currentPos.dx / columnWidth).round();
    final snappedX = (targetSlot * columnWidth).clamp(
      0.0,
      containerWidth * 0.85,
    );

    return Offset(snappedX, snappedY);
  }

  static double getMagneticWidth(double currentWidth) {
    double closestWidth = cardWidths.first;
    double minDifference = (currentWidth - closestWidth).abs();

    for (final cardWidth in cardWidths) {
      final difference = (currentWidth - cardWidth).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestWidth = cardWidth;
      }
    }

    return closestWidth;
  }

  static bool isInMagneticRange(Offset current, Offset target) {
    return (current - target).distance <= snapThreshold;
  }

  // Column-aware overlap detection
  static int getColumnFromPosition(double xPosition, double containerWidth) {
    // 6-column grid: proper boundary detection
    // Column boundaries: 0-0.167, 0.167-0.333, 0.333-0.5, 0.5-0.667, 0.667-0.833, 0.833-1.0
    final column = (xPosition * 6).floor().clamp(0, 5);
    debugPrint(
      '🔢 Position ${xPosition.toStringAsFixed(3)} → Column $column (${xPosition * 6})',
    );
    return column;
  }

  static int getColumnsFromWidth(double width) {
    // Width to column span mapping for 6-column grid
    if (width <= 1 / 3 + 0.01) return 2; // 1/3 width = 2 columns (2/6)
    if (width <= 1 / 2 + 0.01) return 3; // 1/2 width = 3 columns (3/6)
    if (width <= 2 / 3 + 0.01) return 4; // 2/3 width = 4 columns (4/6)
    return 6; // 1.0 width = 6 columns (full row)
  }

  // Get the actual column span based on width and starting position
  static int getActualColumnSpan(double width, int startColumn) {
    final baseSpan = getColumnsFromWidth(width);
    // Ensure we don't exceed the grid (6 columns max)
    return (startColumn + baseSpan <= 6) ? baseSpan : (6 - startColumn);
  }

  static int getRowFromPosition(double yPosition) {
    return (yPosition / cardHeight).round();
  }

  // Check if a field placement would cause overlap
  static bool wouldOverlap(
    Offset newPosition,
    double newWidth,
    double containerWidth,
    Map<String, FieldConfig> existingFields,
    String excludeFieldId,
  ) {
    final newRow = getRowFromPosition(newPosition.dy);
    final newStartColumn = getColumnFromPosition(
      newPosition.dx,
      containerWidth,
    );
    final newColumnSpan = getActualColumnSpan(newWidth, newStartColumn);
    final newEndColumn = newStartColumn + newColumnSpan - 1;

    debugPrint('🔍 OVERLAP CHECK:');
    debugPrint(
      '  Testing position: (${newPosition.dx.toStringAsFixed(2)}, ${newPosition.dy.toStringAsFixed(0)})',
    );
    debugPrint('  New field width: ${newWidth.toStringAsFixed(2)}');
    debugPrint(
      '  New field: row $newRow, cols $newStartColumn-$newEndColumn (span: $newColumnSpan)',
    );

    // Check against all existing fields in the same row
    for (final entry in existingFields.entries) {
      if (entry.key == excludeFieldId) continue; // Skip the field being moved

      final config = entry.value;
      // Skip hidden fields
      if (config.width <= 0 || config.position.dx < 0 || config.position.dy < 0)
        continue;

      final existingRow = getRowFromPosition(config.position.dy);
      if (existingRow != newRow) continue; // Different row, no conflict

      final existingStartColumn = getColumnFromPosition(
        config.position.dx,
        containerWidth,
      );
      final existingColumnSpan = getActualColumnSpan(
        config.width,
        existingStartColumn,
      );
      final existingEndColumn = existingStartColumn + existingColumnSpan - 1;

      debugPrint(
        '  Checking against ${entry.key}: row $existingRow, cols $existingStartColumn-$existingEndColumn (span: $existingColumnSpan, width: ${config.width.toStringAsFixed(2)})',
      );
      debugPrint(
        '    Position: (${config.position.dx.toStringAsFixed(2)}, ${config.position.dy.toStringAsFixed(0)})',
      );

      // Check for column overlap
      final wouldOverlapResult =
          !(newEndColumn < existingStartColumn ||
              newStartColumn > existingEndColumn);

      debugPrint(
        '    Overlap check: !($newEndColumn < $existingStartColumn || $newStartColumn > $existingEndColumn) = $wouldOverlapResult',
      );

      if (wouldOverlapResult) {
        debugPrint('❌ OVERLAP DETECTED:');
        debugPrint(
          '  New field: cols $newStartColumn-$newEndColumn (width: $newWidth)',
        );
        debugPrint(
          '  Existing ${entry.key}: cols $existingStartColumn-$existingEndColumn (width: ${config.width})',
        );
        return true; // Overlap detected
      }
    }

    debugPrint('✅ NO OVERLAP DETECTED');
    return false; // No overlap
  }

  // Find the next available position for a field
  static Offset findNextAvailablePosition(
    double fieldWidth,
    double containerWidth,
    Map<String, FieldConfig> existingFields,
    String excludeFieldId, {
    int startFromRow = 0,
  }) {
    final columnSpan = getColumnsFromWidth(fieldWidth);

    for (int row = startFromRow; row < maxRows; row++) {
      // Try each possible starting column in this row
      for (int startCol = 0; startCol <= 3 - columnSpan; startCol++) {
        final testPosition = Offset(
          (startCol * containerWidth / 3) / containerWidth, // Normalize to 0-1
          row * cardHeight,
        );

        if (!wouldOverlap(
          testPosition,
          fieldWidth,
          containerWidth,
          existingFields,
          excludeFieldId,
        )) {
          return testPosition;
        }
      }
    }

    // If no space found, place at bottom
    final bottomRow =
        existingFields.values
            .where(
              (config) =>
                  config.width > 0 &&
                  config.position.dx >= 0 &&
                  config.position.dy >= 0,
            )
            .map((config) => getRowFromPosition(config.position.dy))
            .fold(0, (max, row) => row > max ? row : max) +
        1;

    return Offset(0, bottomRow * cardHeight);
  }

  // Get row occupancy information for visualization
  static Map<int, List<Map<String, dynamic>>> getRowOccupancy(
    Map<String, FieldConfig> fields,
    double containerWidth,
  ) {
    final Map<int, List<Map<String, dynamic>>> occupancy = {};

    for (final entry in fields.entries) {
      final config = entry.value;
      if (config.width <= 0 || config.position.dx < 0 || config.position.dy < 0)
        continue;

      final row = getRowFromPosition(config.position.dy);
      final startColumn = getColumnFromPosition(
        config.position.dx,
        containerWidth,
      );
      final columnSpan = getActualColumnSpan(config.width, startColumn);

      occupancy[row] ??= [];
      occupancy[row]!.add({
        'fieldId': entry.key,
        'startColumn': startColumn,
        'columnSpan': columnSpan,
        'endColumn': startColumn + columnSpan - 1,
      });
    }

    return occupancy;
  }

  // Calculate effective width accounting for gaps
  static double getEffectiveWidth(
    double containerWidth,
    double widthPercentage,
    double positionX,
  ) {
    final baseWidth = widthPercentage * containerWidth;
    // Subtract gap if not in first column
    return positionX > 0 ? baseWidth - fieldGap : baseWidth;
  }

  // Calculate available space accounting for gaps between fields
  static double getAvailableSpaceWithGaps(
    double containerWidth,
    List<FieldConfig> fieldsInRow,
  ) {
    if (fieldsInRow.isEmpty) return 1.0;

    double totalOccupied = 0.0;
    int gapCount = 0;

    for (final field in fieldsInRow) {
      totalOccupied += field.width;
      if (field.position.dx > 0)
        gapCount++; // Count gaps for non-first-column fields
    }

    // Account for gap space in percentage terms
    final gapSpacePercentage = (gapCount * fieldGap) / containerWidth;
    return (1.0 - totalOccupied - gapSpacePercentage).clamp(0.0, 1.0);
  }
}

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

class CustomizableFormState extends State<CustomizableForm> {
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

  // Auto-resize feedback
  String? _autoResizeMessage;
  DateTime? _autoResizeTime;

  // Magnetic timeline: Store original positions for restoration
  final Map<String, Offset> _originalPositions = {};
  final Set<String> _temporarilyMovedFields = {};

  // Hover threshold to prevent accidental triggering
  static const double hoverThreshold = 40.0; // pixels
  bool _hasMovedBeyondThreshold = false;

  // Form data storage
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fieldConfigs = Map.from(widget.defaultFieldConfigs);

    // Debug initial state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('\n🚀 INITIAL FIELD CONFIGURATION:');
      _debugRowStatus();
    });
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
    debugPrint('Saving field configurations: ${_fieldConfigs.length} fields');
  }

  void _debugRowStatus() {
    final containerWidth = MediaQuery.of(context).size.width - 32;
    final occupancy = MagneticCardSystem.getRowOccupancy(
      _fieldConfigs,
      containerWidth,
    );

    debugPrint('\n=== ROW STATUS DEBUG ===');

    // Show all rows with fields
    for (int row = 0; row < MagneticCardSystem.maxRows; row++) {
      final fieldsInRow = occupancy[row];
      if (fieldsInRow == null || fieldsInRow.isEmpty) {
        if (row < 5) debugPrint('Row $row: EMPTY');
        continue;
      }

      // Sort fields by start column
      fieldsInRow.sort((a, b) => a['startColumn'].compareTo(b['startColumn']));

      String rowInfo = 'Row $row: ';
      for (var fieldInfo in fieldsInRow) {
        final fieldId = fieldInfo['fieldId'];
        final startCol = fieldInfo['startColumn'];
        final span = fieldInfo['columnSpan'];
        final endCol = fieldInfo['endColumn'];
        final config = _fieldConfigs[fieldId]!;

        rowInfo +=
            '[$fieldId: cols $startCol-$endCol (span:$span, width:${config.width.toStringAsFixed(2)})] ';
      }
      debugPrint(rowInfo);
    }

    // Show individual field details
    debugPrint('\n=== FIELD DETAILS ===');
    for (var entry in _fieldConfigs.entries) {
      final config = entry.value;
      if (config.width <= 0 ||
          config.position.dx < 0 ||
          config.position.dy < 0) {
        debugPrint('${entry.key}: HIDDEN');
        continue;
      }

      final row = MagneticCardSystem.getRowFromPosition(config.position.dy);
      final startCol = MagneticCardSystem.getColumnFromPosition(
        config.position.dx,
        containerWidth,
      );
      final span = MagneticCardSystem.getActualColumnSpan(
        config.width,
        startCol,
      );

      debugPrint(
        '${entry.key}: Row $row, Start Col $startCol, Span $span columns, Width ${config.width.toStringAsFixed(2)}, Pos (${config.position.dx.toStringAsFixed(2)}, ${config.position.dy.toStringAsFixed(0)})',
      );
    }
    debugPrint('========================\n');
  }

  // Restore original positions of temporarily moved fields
  void _restoreOriginalPositions() {
    debugPrint('\n=== RESTORE ORIGINAL POSITIONS ===');
    debugPrint('Fields to restore: $_temporarilyMovedFields');

    // Restore all temporarily moved fields to their original positions
    for (final fieldId in _temporarilyMovedFields) {
      if (_originalPositions.containsKey(fieldId)) {
        final currentPos = _fieldConfigs[fieldId]!.position;
        final originalPos = _originalPositions[fieldId]!;

        debugPrint(
          '$fieldId: ${currentPos.dx.toStringAsFixed(2)},${currentPos.dy.toStringAsFixed(0)} → ${originalPos.dx.toStringAsFixed(2)},${originalPos.dy.toStringAsFixed(0)}',
        );

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
    debugPrint('=== RESTORE COMPLETE ===\n');
  }

  // Check if there's space available in a row for a field
  bool _hasSpaceInRow(int targetRow, String excludeFieldId, double fieldWidth) {
    final containerWidth = MediaQuery.of(context).size.width - 32;

    // Try different positions in the row to see if the field fits (6-column grid)
    for (int col = 0; col < 6; col++) {
      final testX =
          (col * containerWidth / 6) / containerWidth; // Normalize to 0-1
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
    debugPrint('\n=== PUSH DOWN FOR ROW $targetRow ===');
    debugPrint('Excluding: $excludeFieldId');

    // First, restore any previously moved fields
    _restoreOriginalPositions();

    final currentWidth = _fieldConfigs[excludeFieldId]!.width;

    // Check if there's space available in the target row
    if (_hasSpaceInRow(targetRow, excludeFieldId, currentWidth)) {
      // There's space - find the exact position in the target row
      final containerWidth = MediaQuery.of(context).size.width - 32;
      final columnSpan = MagneticCardSystem.getColumnsFromWidth(currentWidth);

      Offset? foundPosition;

      // Try each possible starting column in the target row only (6-column grid)
      for (int startCol = 0; startCol <= 6 - columnSpan; startCol++) {
        final testPosition = Offset(
          startCol / 6.0, // Direct normalization to 0-1
          targetRow * MagneticCardSystem.cardHeight,
        );

        if (!MagneticCardSystem.wouldOverlap(
          testPosition,
          currentWidth,
          containerWidth,
          _fieldConfigs,
          excludeFieldId,
        )) {
          foundPosition = testPosition;
          break; // Use the first available position
        }
      }

      if (foundPosition != null) {
        debugPrint('Auto-fitting field $excludeFieldId to available position');
        debugPrint(
          '  New position: (${foundPosition.dx.toStringAsFixed(2)}, ${foundPosition.dy.toStringAsFixed(0)})',
        );

        setState(() {
          _fieldConfigs[excludeFieldId] = _fieldConfigs[excludeFieldId]!
              .copyWith(position: foundPosition);
          _temporarilyMovedFields.add(excludeFieldId);

          // End drag after auto-fit to prevent position drift
          if (_draggedFieldId == excludeFieldId) {
            _draggedFieldId = null;
            _dragStartPosition = null;
            _dragStartFieldPosition = null;
            _hoveredColumn = null;
            _hoveredRow = null;
          }
        });

        // Show auto-fit feedback
        _showAutoResizeMessage(
          'Auto-fitted $excludeFieldId to available position (${(currentWidth * 100).toInt()}% width)',
        );
      } else {
        // This shouldn't happen if _hasSpaceInRow returned true, but fallback to rearrange
        debugPrint(
          '❌ Unexpected: _hasSpaceInRow said true but no position found. Using rearrange logic.',
        );
        _rearrangeFieldsWithPullUp(targetRow, excludeFieldId);
      }
    } else {
      // No space - use rearrangement logic
      debugPrint('❌ No space available. Using rearrange logic with pull-up.');
      _rearrangeFieldsWithPullUp(targetRow, excludeFieldId);
    }
  }

  void _rearrangeFieldsWithPullUp(int targetRow, String excludeFieldId) {
    final draggedFieldOriginalRow = MagneticCardSystem.getRowFromPosition(
      _originalPositions[excludeFieldId]!.dy,
    );

    debugPrint(
      'Dragged field original row: $draggedFieldOriginalRow, target row: $targetRow',
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
    debugPrint('Compacting fields with pull-up logic:');
    int nextAvailableRow = 0;

    for (final originalRow in sortedRows) {
      final fieldsInRow = fieldsByRow[originalRow]!;

      // Skip the target row - reserve it for the dragged field
      if (nextAvailableRow == targetRow) {
        debugPrint(
          '  Skipping row $nextAvailableRow (reserved for dragged field)',
        );
        nextAvailableRow++;
      }

      debugPrint('  Row $originalRow → Row $nextAvailableRow:');

      for (final entry in fieldsInRow) {
        final fieldId = entry.key;
        final originalPosition = entry.value;

        final newPosition = Offset(
          originalPosition.dx,
          nextAvailableRow * MagneticCardSystem.cardHeight,
        );

        debugPrint(
          '    $fieldId: pos(${originalPosition.dx.toStringAsFixed(2)},${originalPosition.dy.toStringAsFixed(0)}) → (${newPosition.dx.toStringAsFixed(2)},${newPosition.dy.toStringAsFixed(0)})',
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
    debugPrint('=== REARRANGE COMPLETE ===\n');
  }

  // Pull up fields to fill gaps after drag operations
  void _pullUpFieldsToFillGaps() {
    debugPrint('\n=== PULL UP FIELDS TO FILL GAPS ===');

    // Find all rows that have fields
    Map<int, List<String>> fieldsByRow = {};
    for (final entry in _fieldConfigs.entries) {
      final fieldId = entry.key;
      final config = entry.value;
      if (config.width <= 0 || config.position.dx < 0 || config.position.dy < 0)
        continue;

      final position = config.position;
      final row = MagneticCardSystem.getRowFromPosition(position.dy);

      if (!fieldsByRow.containsKey(row)) {
        fieldsByRow[row] = [];
      }
      fieldsByRow[row]!.add(fieldId);
    }

    // Get all rows with fields, sorted
    List<int> occupiedRows = fieldsByRow.keys.toList()..sort();
    debugPrint('Occupied rows: $occupiedRows');

    // Calculate all position changes in one pass (no setState yet)
    Map<String, FieldConfig> updatedConfigs = {};
    bool hasChanges = false;

    // Simple single-pass algorithm: assign consecutive row numbers
    int targetRow = 0;
    for (int sourceRow in occupiedRows) {
      if (sourceRow != targetRow) {
        // This row needs to be moved up
        List<String> fieldsInRow = fieldsByRow[sourceRow]!;
        debugPrint('  Pulling up row $sourceRow → row $targetRow:');

        for (String fieldId in fieldsInRow) {
          final currentConfig = _fieldConfigs[fieldId]!;
          final newY = targetRow * MagneticCardSystem.cardHeight;
          final newPosition = Offset(currentConfig.position.dx, newY);

          updatedConfigs[fieldId] = currentConfig.copyWith(
            position: newPosition,
          );
          debugPrint('    $fieldId: row $sourceRow → row $targetRow');
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
      debugPrint('=== PULL UP COMPLETE ===\n');
    } else {
      debugPrint('No gaps found, no pull-up needed');
      debugPrint('=== PULL UP COMPLETE ===\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _isCustomizationMode ? _deselectField : null,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
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
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0.5,
      centerTitle: true,
      title: Text(widget.appBarTitle, style: theme.appBarTheme.titleTextStyle),
      automaticallyImplyLeading: false,
      actions: [
        if (_isCustomizationMode)
          IconButton(
            icon: Icon(
              Icons.bug_report,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              debugPrint('\n🐛 MANUAL DEBUG TRIGGER:');
              _debugRowStatus();
            },
          ),
        IconButton(
          icon: Icon(
            _isCustomizationMode ? Icons.done : Icons.tune,
            size: 24,
            color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
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
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.onSurface.withValues(
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
                      color: theme.colorScheme.onPrimary,
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
    final containerWidth = MediaQuery.of(context).size.width - 32;
    final theme = Theme.of(context);

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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
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
                  color: theme.colorScheme.onSurface.withValues(
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

    // Only render fields that are actually visible (width > 0 and positive position)
    if (config.width <= 0 || config.position.dx < 0 || config.position.dy < 0) {
      return const SizedBox.shrink();
    }

    final isSelected = _selectedFieldId == fieldId;
    final isDragged = _draggedFieldId == fieldId;
    final containerWidth = MediaQuery.of(context).size.width - 32;
    final theme = Theme.of(context);

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
                            color: theme.colorScheme.primary,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                        : _isCustomizationMode && isSelected
                        ? BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
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
                            color: theme.colorScheme.onSurface.withValues(
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
            // Left resize handle
            Positioned(
              left: -12,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate:
                    (details) =>
                        _onResizeField(fieldId, details, ResizeDirection.left),
                child: Container(
                  width: 24,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.drag_indicator,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Right resize handle
            Positioned(
              right: -12,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate:
                    (details) =>
                        _onResizeField(fieldId, details, ResizeDirection.right),
                child: Container(
                  width: 24,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      right: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.drag_indicator,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _startFieldDrag(String fieldId, LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    final config = _fieldConfigs[fieldId]!;

    debugPrint('\n🚀 DRAG START: $fieldId');
    debugPrint('Start position: ${details.globalPosition}');
    debugPrint('Field position: ${config.position}');

    setState(() {
      _draggedFieldId = fieldId;
      _selectedFieldId = fieldId; // Also select the field
      _dragStartPosition = details.globalPosition;
      _dragStartFieldPosition = config.position;
      _hasMovedBeyondThreshold = false; // Reset threshold flag

      // Store original positions of all fields at drag start
      _originalPositions.clear();
      _temporarilyMovedFields.clear();
      for (final entry in _fieldConfigs.entries) {
        _originalPositions[entry.key] = entry.value.position;
      }
    });

    debugPrint('Original positions stored:');
    final containerWidth = MediaQuery.of(context).size.width - 32;
    for (final entry in _originalPositions.entries) {
      final pos = entry.value;
      final col = MagneticCardSystem.getColumnFromPosition(
        pos.dx,
        containerWidth,
      );
      final row = MagneticCardSystem.getRowFromPosition(pos.dy);
      debugPrint(
        '  ${entry.key}: (${pos.dx.toStringAsFixed(2)},${pos.dy.toStringAsFixed(0)}) → col:$col, row:$row',
      );
    }
    debugPrint('🚀 DRAG START COMPLETE\n');
  }

  void _onFieldDrag(String fieldId, LongPressMoveUpdateDetails details) {
    if (_dragStartPosition == null || _dragStartFieldPosition == null) return;

    final containerWidth = MediaQuery.of(context).size.width - 32;
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

    // Calculate new position
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
    final hoveredColumn = MagneticCardSystem.getColumnFromPosition(
      newPosition.dx,
      containerWidth,
    );
    final hoveredRow = MagneticCardSystem.getRowFromPosition(newPosition.dy);

    bool needsRearrangement = false;

    // Only trigger hover effects if we've moved beyond the threshold
    if (_hasMovedBeyondThreshold) {
      // Check if hovered ROW changed (ignore column changes)
      if (_hoveredRow != hoveredRow) {
        _hoveredColumn = hoveredColumn;
        _hoveredRow = hoveredRow;
        needsRearrangement = true;
      } else {
        // Just update column for display
        _hoveredColumn = hoveredColumn;
      }
    }

    // Single setState with all updates
    setState(() {
      // Update dragged field position (preserve any width changes from auto-resize)
      final currentWidth = _fieldConfigs[fieldId]!.width;
      _fieldConfigs[fieldId] = config.copyWith(
        position: newPosition,
        width: currentWidth, // Preserve width changes from auto-resize
      );
    });

    // Trigger rearrangement after setState to avoid nested setState calls
    if (needsRearrangement) {
      // Use post-frame callback to avoid performance issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pushDownAllFieldsAtRow(hoveredRow, fieldId);
        }
      });
    }
  }

  void _onFieldDragEnd(String fieldId, LongPressEndDetails details) {
    final containerWidth = MediaQuery.of(context).size.width - 32;
    final config = _fieldConfigs[fieldId]!;

    // Snap dragged field to grid
    final snappedPosition = MagneticCardSystem.getMagneticSnapPosition(
      config.position,
      containerWidth,
    );

    setState(() {
      _fieldConfigs[fieldId] = _fieldConfigs[fieldId]!.copyWith(
        position: snappedPosition,
      );
      _draggedFieldId = null;
      _dragStartPosition = null;
      _dragStartFieldPosition = null;
      _hoveredColumn = null;
      _hoveredRow = null;
      _hasMovedBeyondThreshold = false; // Reset threshold flag
      _originalPositions.clear();
      // Don't clear _temporarilyMovedFields - let hover positions become permanent
      _temporarilyMovedFields.clear();
    });

    // After positioning the field, check for empty rows and pull up fields to fill gaps
    _pullUpFieldsToFillGaps();
    _saveFieldConfigurations();
  }

  void _onResizeField(
    String fieldId,
    DragUpdateDetails details,
    ResizeDirection direction,
  ) {
    final config = _fieldConfigs[fieldId]!;
    final containerWidth = MediaQuery.of(context).size.width - 32;

    _accumulatedDrag += details.primaryDelta ?? 0;
    if (_accumulatedDrag.abs() < containerWidth * 0.1) return;

    // Determine new width based on drag direction and amount
    double newWidth = config.width;
    double newX = config.position.dx;
    final currentIndex = MagneticCardSystem.cardWidths.indexOf(config.width);

    if (direction == ResizeDirection.right) {
      // Right resize: Only change width
      if (_accumulatedDrag > 0 &&
          currentIndex < MagneticCardSystem.cardWidths.length - 1) {
        newWidth = MagneticCardSystem.cardWidths[currentIndex + 1];
      } else if (_accumulatedDrag < 0 && currentIndex > 0) {
        newWidth = MagneticCardSystem.cardWidths[currentIndex - 1];
      }
    } else {
      // Left resize: Change both width and x position
      if (_accumulatedDrag < 0 &&
          currentIndex < MagneticCardSystem.cardWidths.length - 1) {
        // Expanding left
        if (newX > 0) {
          // Only if there's space to expand left
          newWidth = MagneticCardSystem.cardWidths[currentIndex + 1];
          newX = max(0, newX - (newWidth - config.width));
        }
      } else if (_accumulatedDrag > 0 && currentIndex > 0) {
        // Shrinking from left
        newWidth = MagneticCardSystem.cardWidths[currentIndex - 1];
        newX = newX + (config.width - newWidth);
      }
    }

    _accumulatedDrag = 0; // Reset after processing

    // Only update if width or position changed
    if (newWidth != config.width || newX != config.position.dx) {
      setState(() {
        _fieldConfigs[fieldId] = config.copyWith(
          width: newWidth,
          position: Offset(newX, config.position.dy),
        );
      });
      _saveFieldConfigurations();
      HapticFeedback.mediumImpact();
    }
  }

  Widget _buildAdditionalFieldsContainer() {
    final theme = Theme.of(context);

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'All Entry Fields',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap to add/remove →',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
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
                      final isOnPage =
                          config != null &&
                          config.width > 0 &&
                          config.position.dx >= 0 &&
                          config.position.dy >= 0;
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
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surface,
                              border: Border.all(
                                color:
                                    isOnPage
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
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
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  field.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isOnPage
                                            ? theme.colorScheme.onPrimary
                                            : theme
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
                                    color: theme.colorScheme.onPrimary,
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
      final isCurrentlyVisible =
          config != null &&
          config.width > 0 &&
          config.position.dx >= 0 &&
          config.position.dy >= 0;

      if (isCurrentlyVisible) {
        debugPrint('\n🗑️ REMOVING FIELD: $fieldId');
        // Hide the field by setting width to 0 and moving to negative position
        _fieldConfigs[fieldId] = FieldConfig(
          id: fieldId,
          width: 0,
          position: const Offset(-100, -100),
        );
        if (_selectedFieldId == fieldId) {
          _selectedFieldId = null;
        }

        debugPrint('📊 BEFORE REFLOW (after removal):');
        _debugRowStatus();

        _pullUpFieldsToFillGaps();

        debugPrint('📊 AFTER REFLOW (after removal):');
        _debugRowStatus();
      } else {
        debugPrint('\n➕ ADDING FIELD: $fieldId');
        // Show the field by adding it to the form
        _addFieldToSingleColumn(fieldId);

        debugPrint('📊 AFTER ADDING FIELD:');
        _debugRowStatus();
      }
    });
    _saveFieldConfigurations();
  }

  void _addFieldToSingleColumn(String fieldId) {
    int nextRow = 0;
    for (var config in _fieldConfigs.values) {
      if (config.position.dx == 0) {
        int currentRow = (config.position.dy / 70).round();
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
