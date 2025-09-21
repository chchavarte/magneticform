import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:field_collision_test/core/constants/animation_constants.dart';
import 'package:field_collision_test/core/utils/logger.dart';
import '../handlers/resize_handler.dart';
import '../handlers/drag_handler.dart';
import '../handlers/auto_expand_handler.dart';
import '../systems/field_preview_system.dart';
import '../systems/grid_utils.dart';
import '../components/form_ui_builder.dart';
import '../../data/models/field_config.dart';
import '../../data/models/form_field.dart';
import '../../data/models/magnetic_card_system.dart';
import '../../data/repositories/form_storage_repository.dart';

// Main customizable form screen
class CustomizableFormScreen extends StatefulWidget {
  final List<CustomFormField> availableFields;
  final Map<String, FieldConfig> defaultFieldConfigs;
  final Widget Function(BuildContext context, Map<String, dynamic> formData)?
  cartSummaryButton;
  final bool showAppBar;
  final String appBarTitle;
  final String storageKey;

  const CustomizableFormScreen({
    super.key,
    required this.availableFields,
    required this.defaultFieldConfigs,
    this.cartSummaryButton,
    this.showAppBar = true,
    this.appBarTitle = 'Custom Form',
    this.storageKey = 'custom_form_field_configs',
  });

  @override
  CustomizableFormScreenState createState() => CustomizableFormScreenState();
}

class CustomizableFormScreenState extends State<CustomizableFormScreen>
    with TickerProviderStateMixin {
  late Map<String, FieldConfig> _fieldConfigs;
  bool _isLoading = true;
  late final FormStorageRepository _repository;
  bool _isCustomizationMode = false;
  String? _selectedFieldId;
  double _accumulatedDrag = 0;

  // Drag state
  DragState? _dragState;

  // Hover state for push down logic
  int? _hoveredColumn;
  int? _hoveredRow;

  // Hover timer for 0.3s delay
  Timer? _hoverTimer;
  int? _lastHoveredRow;

  // Auto-resize feedback
  String? _autoResizeMessage;
  DateTime? _autoResizeTime;

  // Preview system state
  PreviewState _previewState = PreviewState.initial();

  // Magnetic timeline: Store original positions for restoration
  final Map<String, Offset> _originalPositions = {};
  final Set<String> _temporarilyMovedFields = {};

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
    _repository = LocalFormStorageRepository();
    _initializeControllers();
    _loadFieldConfigurations();
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
    _hoverTimer?.cancel();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFieldConfigurations() async {
    try {
      final savedConfigs = await _repository.loadConfigurations(widget.storageKey);
      setState(() {
        if (savedConfigs.isNotEmpty) {
          _fieldConfigs = savedConfigs;
        } else {
          _fieldConfigs = Map.from(widget.defaultFieldConfigs);
        }
        _isLoading = false;
      });
    } catch (e) {
      // If loading fails, use default configurations
      setState(() {
        _fieldConfigs = Map.from(widget.defaultFieldConfigs);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFieldConfigurations() async {
    try {
      await _repository.saveConfigurations(widget.storageKey, _fieldConfigs);
    } catch (e) {
      // Handle save error if needed
      Logger.error('Error saving field configurations: $e');
    }
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
    return GridUtils.canFieldFitInRow(
      targetRow,
      fieldWidth,
      _fieldConfigs,
      _containerWidth,
      excludeFieldId: excludeFieldId,
    );
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
      Logger.debug(
        'Testing positions for field $excludeFieldId in row $targetRow, columnSpan: $columnSpan',
      );
      for (int startCol = 0; startCol <= 6 - columnSpan; startCol++) {
        final testPosition = Offset(
          MagneticCardSystem.getColumnPositionNormalized(startCol),
          targetRow * MagneticCardSystem.cardHeight,
        );

        Logger.debug('Testing column $startCol, position: ${testPosition.dx}');

        final hasOverlap = MagneticCardSystem.wouldOverlap(
          testPosition,
          currentWidth,
          containerWidth,
          _fieldConfigs,
          excludeFieldId,
        );

        Logger.debug('Column $startCol overlap: $hasOverlap');

        if (!hasOverlap) {
          foundPosition = testPosition;
          Logger.debug('Found position at column $startCol');
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
    // Find all rows that have fields using utility method
    final fieldsByRow = GridUtils.groupFieldsByRow(_fieldConfigs);

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
    AutoExpandHandler.autoExpandToFillGaps(
      fieldConfigs: _fieldConfigs,
      vsync: this,
      onUpdate: (configs) {
        setState(() {
          _fieldConfigs = configs;
        });
      },
      onComplete: () {
        // Auto-expansion complete
      },
    );
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
    return FormUIBuilder.buildAppBar(
      context: context,
      title: widget.appBarTitle,
      isCustomizationMode: _isCustomizationMode,
      onToggleMode: () {
        setState(() {
          _isCustomizationMode = !_isCustomizationMode;
          if (!_isCustomizationMode) {
            _saveFieldConfigurations();
          }
        });
      },
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
              FormUIBuilder.buildAutoResizeMessage(
                context: context,
                message: _autoResizeMessage!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapGuides() {
    return FormUIBuilder.buildSnapGuides(
      context: context,
      containerWidth: _containerWidth,
    );
  }

  Widget _buildMagneticField(String fieldId, Widget field) {
    final config = _fieldConfigs[fieldId];
    if (config == null) return const SizedBox.shrink();

    final isSelected = _selectedFieldId == fieldId;
    final isDragged = _dragState?.draggedFieldId == fieldId;
    final isInPreview =
        _previewState.isActive && fieldId != _previewState.draggedFieldId;

    return FormUIBuilder.buildMagneticField(
      context: context,
      fieldId: fieldId,
      field: field,
      config: config,
      isCustomizationMode: _isCustomizationMode,
      isSelected: isSelected,
      isDragged: isDragged ?? false,
      isInPreview: isInPreview,
      containerWidth: _containerWidth,
      onTap: _selectField,
      onLongPressStart: _startFieldDrag,
      onLongPressMoveUpdate: _onFieldDrag,
      onLongPressEnd: _onFieldDragEnd,
      onResize: _onResizeField,
      onResizeStart: _onResizeFieldStart,
      onResizeEnd: _onResizeFieldEnd,
    );
  }

  void _startFieldDrag(String fieldId, LongPressStartDetails details) {
    _dragState = DragHandler.startFieldDrag(
      fieldId: fieldId,
      details: details,
      fieldConfigs: _fieldConfigs,
    );

    setState(() {
      _selectedFieldId = fieldId; // Also select the field
      _previewState = PreviewState.initial();

      // Store original positions for restoration
      _originalPositions.clear();
      _temporarilyMovedFields.clear();
      for (final entry in _fieldConfigs.entries) {
        _originalPositions[entry.key] = entry.value.position;
      }
    });
  }

  void _onFieldDrag(String fieldId, LongPressMoveUpdateDetails details) {
    if (_dragState == null) return;

    final result = DragHandler.handleFieldDrag(
      fieldId: fieldId,
      details: details,
      dragState: _dragState!,
      fieldConfigs: _fieldConfigs,
      containerWidth: _containerWidth,
    );

    // Update drag state
    _dragState = _dragState!.copyWith(
      hasMovedBeyondThreshold: result.hasMovedBeyondThreshold,
    );

    // Update field position for visual feedback
    setState(() {
      final currentWidth = _fieldConfigs[fieldId]!.width;
      _fieldConfigs[fieldId] = _fieldConfigs[fieldId]!.copyWith(
        position: result.newPosition,
        width: currentWidth,
      );
      _hoveredColumn = result.hoveredColumn;
      _hoveredRow = result.hoveredRow;
    });

    // Handle preview logic if we've moved beyond threshold
    if (result.shouldShowPreview) {
      _handlePreviewLogic(fieldId, result.hoveredRow);
    }
  }

  // Handle preview logic for hover effects with 0.3s delay
  void _handlePreviewLogic(String fieldId, int hoveredRow) {
    // Check if we're hovering over a new row
    if (_lastHoveredRow != hoveredRow) {
      // Cancel existing timer
      _hoverTimer?.cancel();
      _lastHoveredRow = hoveredRow;
      
      // Start new timer for 0.3s delay
      _hoverTimer = Timer(const Duration(milliseconds: 300), () {
        // Show preview after delay - use existing preview logic
        _showPreview(fieldId, hoveredRow);
      });
    }
  }

  // Show preview positions
  void _showPreview(String fieldId, int targetRow) {
    Logger.preview('Field $fieldId targeting row $targetRow');
    GridUtils.printFieldConfigs(
      'Current field configs before preview:',
      _fieldConfigs,
      _containerWidth,
    );

    final originalConfigs =
        _previewState.originalConfigs.isNotEmpty
            ? _previewState.originalConfigs
            : Map<String, FieldConfig>.from(_fieldConfigs);

    Logger.debug('Calling FieldPreviewSystem.calculatePreviewPositions...');
    final previewConfigs = FieldPreviewSystem.calculatePreviewPositions(
      targetRow: targetRow,
      draggedFieldId: fieldId,
      currentConfigs: originalConfigs,
      containerWidth: _containerWidth,
    );

    Logger.debug('Calling FieldPreviewSystem.getPreviewInfo...');
    final previewInfo = FieldPreviewSystem.getPreviewInfo(
      targetRow: targetRow,
      draggedFieldId: fieldId,
      currentConfigs: originalConfigs,
      containerWidth: _containerWidth,
    );

    Logger.preview('Preview result: ${previewInfo.message}');
    GridUtils.printFieldConfigs(
      'Preview configs returned:',
      previewConfigs,
      _containerWidth,
    );

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
    return FormUIBuilder.buildPreviewIndicator(
      context: context,
      previewState: _previewState,
      containerWidth: _containerWidth,
      fieldConfigs: _fieldConfigs,
    );
  }

  void _onFieldDragEnd(String fieldId, LongPressEndDetails details) {
    if (_dragState == null) return;

    final result = DragHandler.handleFieldDragEnd(
      fieldId: fieldId,
      fieldConfigs: _fieldConfigs,
      containerWidth: _containerWidth,
      previewState: _previewState,
    );

    if (result.shouldCommitPreview) {
      _commitPreview(fieldId);
    } else {
      _handleStandardDragEnd(fieldId, result.finalPosition);
    }

    // Clean up drag state
    _hoverTimer?.cancel();
    setState(() {
      _dragState = null;
      _hoveredColumn = null;
      _hoveredRow = null;
      _lastHoveredRow = null;
      _originalPositions.clear();
      _temporarilyMovedFields.clear();
    });

    _previewState = PreviewState.initial();
  }

  // Commit preview positions with animation
  void _commitPreview(String fieldId) {
    Logger.success('COMMIT PREVIEW: Field $fieldId');
    if (!_previewState.isActive ||
        _previewState.previewInfo?.targetPosition == null) {
      Logger.info('No active preview, using standard drag end');
      _handleStandardDragEnd(fieldId, _fieldConfigs[fieldId]!.position);
      return;
    }

    Logger.info('Committing preview positions...');
    Logger.info('Preview info: ${_previewState.previewInfo!.message}');

    // Create final configs with the dragged field at the preview position
    final finalConfigs = Map<String, FieldConfig>.from(
      _previewState.previewConfigs,
    );

    // Check if the preview included a width change for the dragged field
    final previewDraggedField = _previewState.previewConfigs[fieldId];
    if (previewDraggedField != null) {
      Logger.info(
        'Using preview config for $fieldId: width ${(previewDraggedField.width * 100).toInt()}%, position ${previewDraggedField.position}',
      );
      finalConfigs[fieldId] = previewDraggedField;
    } else {
      Logger.info('No preview config found, using target position only');
      finalConfigs[fieldId] = _fieldConfigs[fieldId]!.copyWith(
        position: _previewState.previewInfo!.targetPosition!,
      );
    }

    GridUtils.printFieldConfigs(
      'Final configs to commit:',
      finalConfigs,
      _containerWidth,
    );

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
  void _handleStandardDragEnd(String fieldId, Offset finalPosition) {
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
    return FormUIBuilder.buildAdditionalFieldsContainer(
      context: context,
      availableFields: widget.availableFields,
      fieldConfigs: _fieldConfigs,
      onToggleField: _toggleAdditionalField,
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

    // Clear the message after the configured duration
    Future.delayed(AnimationConstants.autoResizeMessageDuration, () {
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
      position: Offset(0, nextRow * MagneticCardSystem.cardHeight),
      width: 1.0,
    );
  }
}