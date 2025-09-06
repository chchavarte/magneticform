import 'package:flutter/material.dart';
import 'dart:math';
import '../constants/animation_constants.dart';
import '../utils/logger.dart';
import '../handlers/resize_handler.dart';
import '../handlers/drag_handler.dart';
import '../handlers/auto_expand_handler.dart';
import '../systems/field_preview_system.dart';
import '../systems/grid_utils.dart';
import '../components/form_ui_builder.dart';
import '../models/field_config.dart';
import '../models/form_field.dart';
import '../models/magnetic_card_system.dart';
import '../storage/form_storage_repository.dart';
import '../theme/magnetic_theme.dart';

/// A sophisticated form builder widget with magnetic grid positioning and drag-and-drop capabilities.
///
/// Creates a customizable form interface where users can drag and drop fields to create
/// their preferred layout. The widget uses a 6-column responsive grid system with
/// intelligent field placement, collision detection, and smooth animations.
///
/// ## Quick Start
///
/// ```dart
/// MagneticFormBuilder(
///   availableFields: [
///     MagneticFormField(
///       id: 'name',
///       label: 'Full Name',
///       icon: Icons.person,
///       builder: (context, isCustomizationMode) => TextField(
///         decoration: InputDecoration(labelText: 'Full Name'),
///         enabled: !isCustomizationMode, // Important: disable during layout editing
///       ),
///     ),
///   ],
///   defaultFieldConfigs: {
///     'name': FieldConfig(
///       id: 'name',
///       position: Offset(0, 0),    // Top-left corner
///       width: 1.0,               // Full width (100%)
///     ),
///   },
///   appBarTitle: 'My Custom Form',
///   onFormDataChanged: (data) => print('Form data: $data'),
/// )
/// ```
///
/// ## Grid System
///
/// - **6-Column Grid**: Fields snap to a responsive 6-column layout
/// - **Position**: `Offset(x, y)` where x is 0.0-1.0 (left to right), y is row number * 70
/// - **Width**: Percentage of container width (0.0 to 1.0)
/// - **Auto-resize**: Fields automatically adjust to fit available space
///
/// ## Advanced Features (Automatic)
///
/// - ✅ Real-time preview during drag operations
/// - ✅ Intelligent field placement with collision detection
/// - ✅ Auto-resize to fit available space
/// - ✅ Push up/pull down logic for optimal layouts
/// - ✅ Smooth 60fps animations for all interactions
/// - ✅ Form data persistence with customizable storage keys
///
/// ## Common Layout Patterns
///
/// ```dart
/// // Side-by-side fields (50/50)
/// 'firstName': FieldConfig(id: 'firstName', position: Offset(0, 0), width: 0.5),
/// 'lastName': FieldConfig(id: 'lastName', position: Offset(0.5, 0), width: 0.5),
///
/// // Three columns (33/33/33)
/// 'day': FieldConfig(id: 'day', position: Offset(0, 0), width: 0.33),
/// 'month': FieldConfig(id: 'month', position: Offset(0.33, 0), width: 0.33),
/// 'year': FieldConfig(id: 'year', position: Offset(0.66, 0), width: 0.33),
///
/// // Full width header + two columns
/// 'title': FieldConfig(id: 'title', position: Offset(0, 0), width: 1.0),
/// 'address1': FieldConfig(id: 'address1', position: Offset(0, 70), width: 0.5),
/// 'address2': FieldConfig(id: 'address2', position: Offset(0.5, 70), width: 0.5),
/// ```
class MagneticFormBuilder extends StatefulWidget {
  /// List of form fields that can be placed on the magnetic grid.
  ///
  /// Each field must have a unique [MagneticFormField.id] and provide a
  /// [MagneticFormField.builder] function that creates the field widget.
  ///
  /// **Important**: In the builder function, always disable field interaction
  /// during customization mode by checking `isCustomizationMode`.
  ///
  /// Example:
  /// ```dart
  /// availableFields: [
  ///   MagneticFormField(
  ///     id: 'email',
  ///     label: 'Email Address',
  ///     icon: Icons.email,
  ///     builder: (context, isCustomizationMode) => TextField(
  ///       decoration: InputDecoration(labelText: 'Email'),
  ///       enabled: !isCustomizationMode, // Disable during layout editing
  ///       keyboardType: TextInputType.emailAddress,
  ///     ),
  ///   ),
  /// ]
  /// ```
  final List<MagneticFormField> availableFields;

  /// Initial positions and sizes for fields on the grid.
  ///
  /// Map keys must match [MagneticFormField.id] values. Each [FieldConfig]
  /// defines where the field appears initially and how much space it occupies.
  ///
  /// ## Position System
  /// - `position.dx`: Horizontal position (0.0 = left edge, 1.0 = right edge)
  /// - `position.dy`: Vertical position (0 = top, increments by ~70px per row)
  /// - `width`: Field width as percentage (0.0-1.0)
  ///
  /// ## Common Patterns
  /// ```dart
  /// defaultFieldConfigs: {
  ///   // Full width field at top
  ///   'name': FieldConfig(id: 'name', position: Offset(0, 0), width: 1.0),
  ///   
  ///   // Two half-width fields side by side
  ///   'firstName': FieldConfig(id: 'firstName', position: Offset(0, 70), width: 0.5),
  ///   'lastName': FieldConfig(id: 'lastName', position: Offset(0.5, 70), width: 0.5),
  ///   
  ///   // Three equal columns
  ///   'day': FieldConfig(id: 'day', position: Offset(0, 140), width: 0.33),
  ///   'month': FieldConfig(id: 'month', position: Offset(0.33, 140), width: 0.33),
  ///   'year': FieldConfig(id: 'year', position: Offset(0.66, 140), width: 0.33),
  /// }
  /// ```
  final Map<String, FieldConfig> defaultFieldConfigs;

  /// Custom theme data for styling the form builder.
  ///
  /// If not provided, automatically inherits from your app's theme. For custom
  /// themes, wrap with [MagneticTheme.withFieldExtensions] to ensure proper
  /// field-specific styling.
  ///
  /// ## Theme Options
  /// ```dart
  /// // Option 1: Use built-in themes
  /// theme: MagneticTheme.lightTheme,  // or MagneticTheme.darkTheme
  ///
  /// // Option 2: Custom theme
  /// theme: MagneticTheme.withFieldExtensions(
  ///   ThemeData(
  ///     colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
  ///     useMaterial3: true,
  ///   ),
  /// ),
  ///
  /// // Option 3: No theme (inherits from app)
  /// // theme: null, // Default behavior
  /// ```
  final ThemeData? theme;

  /// Builder function for custom content below the form grid.
  ///
  /// Receives the current [BuildContext] and a map of form data containing
  /// the current values of all fields. Perfect for submit buttons, form
  /// summaries, or validation messages.
  ///
  /// Example:
  /// ```dart
  /// formDataBuilder: (context, formData) => Column(
  ///   children: [
  ///     ElevatedButton(
  ///       onPressed: () => submitForm(formData),
  ///       child: Text('Submit Form'),
  ///     ),
  ///     Text('Fields filled: ${formData.length}'),
  ///   ],
  /// ),
  /// ```
  ///   onPressed: () => submitForm(formData),
  ///   child: Text('Submit Form'),
  /// )
  /// ```
  final Widget Function(BuildContext context, Map<String, dynamic> formData)?
  bottomWidget;

  /// Whether to show the app bar at the top of the form.
  ///
  /// Defaults to `true`. Set to `false` if you want to embed the form
  /// builder within your own scaffold or custom layout.
  final bool showAppBar;

  /// Title displayed in the app bar.
  ///
  /// Only used when [showAppBar] is `true`. Defaults to 'Custom Form'.
  final String appBarTitle;

  /// Unique key for persisting field configurations.
  ///
  /// Field positions and sizes are automatically saved using this key
  /// and restored when the widget is recreated. Use different keys for
  /// different forms to prevent configuration conflicts.
  ///
  /// Defaults to 'magnetic_form_field_configs'.
  final String storageKey;

  /// Callback invoked when form field values change.
  ///
  /// The callback receives a map where keys are field IDs and values are
  /// the current field values. Called whenever a user interacts with any
  /// form field.
  ///
  /// Example:
  /// ```dart
  /// onFormDataChanged: (data) {
  ///   print('Name: ${data['name']}');
  ///   print('Email: ${data['email']}');
  /// }
  /// ```
  final Function(Map<String, dynamic>)? onFormDataChanged;

  /// Callback invoked when field configurations change.
  ///
  /// The callback receives a map of [FieldConfig] objects representing
  /// the current positions and sizes of all fields. Called when fields
  /// are moved, resized, or their layout changes.
  ///
  /// Example:
  /// ```dart
  /// onFieldConfigChanged: (configs) {
  ///   // Save layout preferences
  ///   saveUserLayout(configs);
  /// }
  /// ```
  final Function(Map<String, FieldConfig>)? onFieldConfigChanged;

  /// Creates a magnetic form builder widget.
  ///
  /// The [availableFields] and [defaultFieldConfigs] parameters are required.
  /// All other parameters are optional and have sensible defaults.
  ///
  /// Example:
  /// ```dart
  /// MagneticFormBuilder(
  ///   availableFields: myFields,
  ///   defaultFieldConfigs: myConfigs,
  ///   appBarTitle: 'User Registration',
  ///   storageKey: 'registration_form',
  ///   onFormDataChanged: handleFormChange,
  /// )
  /// ```
  const MagneticFormBuilder({
    super.key,
    required this.availableFields,
    required this.defaultFieldConfigs,
    this.theme,
    this.bottomWidget,
    this.showAppBar = true,
    this.appBarTitle = 'Custom Form',
    this.storageKey = 'magnetic_form_field_configs',
    this.onFormDataChanged,
    this.onFieldConfigChanged,
  });

  @override
  MagneticFormBuilderState createState() => MagneticFormBuilderState();
}

class MagneticFormBuilderState extends State<MagneticFormBuilder>
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

  // Throttling for rearrangement to prevent excessive calls
  DateTime? _lastRearrangementTime;

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
  ThemeData get _theme => widget.theme ?? MagneticTheme.lightTheme;

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
        // Call callback when form data changes
        widget.onFormDataChanged?.call(Map.from(_formData));
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

  Future<void> _loadFieldConfigurations() async {
    try {
      final savedConfigs = await _repository.loadConfigurations(
        widget.storageKey,
      );
      setState(() {
        if (savedConfigs.isNotEmpty) {
          _fieldConfigs = savedConfigs;
        } else {
          _fieldConfigs = Map.from(widget.defaultFieldConfigs);
        }
        _isLoading = false;
      });
      // Call callback when field configs are loaded
      widget.onFieldConfigChanged?.call(Map.from(_fieldConfigs));
    } catch (e) {
      // If loading fails, use default configurations
      setState(() {
        _fieldConfigs = Map.from(widget.defaultFieldConfigs);
        _isLoading = false;
      });
      widget.onFieldConfigChanged?.call(Map.from(_fieldConfigs));
    }
  }

  Future<void> _saveFieldConfigurations() async {
    try {
      await _repository.saveConfigurations(widget.storageKey, _fieldConfigs);
      // Call callback when field configs are saved
      widget.onFieldConfigChanged?.call(Map.from(_fieldConfigs));
    } catch (e) {
      // Handle save error if needed
      Logger.error('Error saving field configurations: $e');
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
      return Theme(
        data: _theme,
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return Theme(
      data: _theme,
      child: GestureDetector(
        onTap: _isCustomizationMode ? _deselectField : null,
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: _theme.scaffoldBackgroundColor,
          appBar: widget.showAppBar ? _buildAppBar() : null,
          body: Stack(children: [_buildMainContent()]),
          bottomSheet:
              _isCustomizationMode
                  ? _buildAdditionalFieldsContainer()
                  : widget.bottomWidget?.call(context, _formData),
        ),
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
      isDragged: isDragged,
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
    });

    // Handle preview logic if we've moved beyond threshold
    if (result.shouldShowPreview) {
      _handlePreviewLogic(fieldId, result.hoveredRow);
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
    setState(() {
      _dragState = null;

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
