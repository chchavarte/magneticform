import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'field_resize_handler.dart';
import 'form_models.dart';
import 'field_animations.dart';

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
    final gridPosition = MagneticCardSystem.getGridPosition(
      newPosition,
      containerWidth,
    );
    final hoveredColumn = gridPosition.column;
    final hoveredRow = gridPosition.row;

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
      // Throttle rearrangement to prevent excessive calls (max once per 100ms)
      final now = DateTime.now();
      if (_lastRearrangementTime == null ||
          now.difference(_lastRearrangementTime!).inMilliseconds > 100) {
        _lastRearrangementTime = now;

        // Use post-frame callback to avoid performance issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _pushDownAllFieldsAtRow(hoveredRow, fieldId);
          }
        });
      }
    }
  }

  void _onFieldDragEnd(String fieldId, LongPressEndDetails details) {
    final containerWidth = _containerWidth;
    final config = _fieldConfigs[fieldId]!;

    print(
      'DEBUG DRAG END: Field $fieldId current position: ${config.position}',
    );

    // Snap dragged field to grid
    final snappedPosition = MagneticCardSystem.getMagneticSnapPosition(
      config.position,
      containerWidth,
    );

    print('DEBUG DRAG END: Snapped position: $snappedPosition');

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

    print(
      'DEBUG DRAG END: Final position: $finalPosition (overlap: $wouldOverlap)',
    );

    setState(() {
      _fieldConfigs[fieldId] = _fieldConfigs[fieldId]!.copyWith(
        position: finalPosition,
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
