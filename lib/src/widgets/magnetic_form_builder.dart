import 'package:flutter/material.dart';
import 'dart:math';

import '../utils/magnetic_utils.dart';
import '../handlers/interaction_handler.dart';
import '../systems/magnetic_system.dart';
import '../components/form_ui_builder.dart';
import '../models/field_models.dart';
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
  // Core state management - consolidated
  late Map<String, FieldConfig> _fieldConfigs;
  late final FormStorageRepository _repository;
  bool _isLoading = true;

  // UI state management - consolidated
  bool _isCustomizationMode = false;
  String? _selectedFieldId;

  // Interaction state management - consolidated
  DragState? _dragState;
  double _accumulatedDrag = 0;
  DateTime? _lastRearrangementTime;

  // Preview system state - consolidated
  PreviewState _previewState = PreviewState.initial();
  final Map<String, Offset> _originalPositions = {};
  final Set<String> _temporarilyMovedFields = {};

  // Form data management - consolidated
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};

  // Computed properties for better organization
  double get _containerWidth => MediaQuery.of(context).size.width - 32;
  ThemeData get _theme => widget.theme ?? MagneticTheme.lightTheme;
  double get _bottomPadding => _isCustomizationMode ? 120.0 : 90.0;
  double get _contentHeight =>
      _isCustomizationMode
          ? max(MediaQuery.of(context).size.height - 200, 840)
          : MediaQuery.of(context).size.height - 150;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  // Consolidated initialization helper
  void _initializeState() {
    _repository = LocalFormStorageRepository();
    _initializeFormControllers();
    _loadFieldConfigurations();
  }

  // Extracted form controller initialization
  void _initializeFormControllers() {
    for (var field in widget.availableFields) {
      final controller = TextEditingController(text: field.defaultValue);
      controller.addListener(
        () => _handleFormDataChange(field.id, controller.text),
      );
      _controllers[field.id] = controller;
    }
  }

  // Extracted form data change handler
  void _handleFormDataChange(String fieldId, String? value) {
    _formData[fieldId] = value;
    widget.onFormDataChanged?.call(Map.from(_formData));
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Consolidated configuration management
  Future<void> _loadFieldConfigurations() async {
    try {
      final savedConfigs = await _repository.loadConfigurations(
        widget.storageKey,
      );
      _updateFieldConfigs(
        savedConfigs.isNotEmpty ? savedConfigs : widget.defaultFieldConfigs,
      );
    } catch (e) {
      _updateFieldConfigs(widget.defaultFieldConfigs);
    }
  }

  Future<void> _saveFieldConfigurations() async {
    try {
      await _repository.saveConfigurations(widget.storageKey, _fieldConfigs);
      _notifyFieldConfigChange();
    } catch (e) {
      MagneticUtils.error('Error saving field configurations: $e');
    }
  }

  // Helper for updating field configs with state management
  void _updateFieldConfigs(Map<String, FieldConfig> configs) {
    setState(() {
      _fieldConfigs = Map.from(configs);
      _isLoading = false;
    });
    _notifyFieldConfigChange();
  }

  // Helper for notifying field config changes
  void _notifyFieldConfigChange() {
    widget.onFieldConfigChanged?.call(Map.from(_fieldConfigs));
  }

  // Consolidated field layout optimization
  void _optimizeFieldLayout() {
    _pullUpFieldsToFillGaps();
    _autoExpandToFillGaps();
  }

  // Pull up fields to fill gaps after drag operations
  void _pullUpFieldsToFillGaps() {
    final fieldsByRow = MagneticSystem.groupFieldsByRow(_fieldConfigs);
    final occupiedRows = fieldsByRow.keys.toList()..sort();

    final updatedConfigs = <String, FieldConfig>{};
    int targetRow = 0;

    for (int sourceRow in occupiedRows) {
      if (sourceRow != targetRow) {
        for (String fieldId in fieldsByRow[sourceRow]!) {
          final currentConfig = _fieldConfigs[fieldId]!;
          final newY = targetRow * MagneticCardSystem.cardHeight;
          updatedConfigs[fieldId] = currentConfig.copyWith(
            position: Offset(currentConfig.position.dx, newY),
          );
        }
      }
      targetRow++;
    }

    if (updatedConfigs.isNotEmpty) {
      setState(() {
        _fieldConfigs.addAll(updatedConfigs);
      });
    }
  }

  // Auto-expand fields to fill remaining gaps after drag operations
  void _autoExpandToFillGaps() {
    InteractionHandler.autoExpandToFillGaps(
      fieldConfigs: _fieldConfigs,
      vsync: this,
      onUpdate: (configs) => setState(() => _fieldConfigs = configs),
      onComplete: () {}, // Auto-expansion complete
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();

    return _buildMainWidget();
  }

  // Extracted loading state builder
  Widget _buildLoadingState() {
    return Theme(
      data: _theme,
      child: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  // Consolidated main widget builder
  Widget _buildMainWidget() {
    return Theme(
      data: _theme,
      child: GestureDetector(
        onTap: _isCustomizationMode ? _deselectField : null,
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: _theme.scaffoldBackgroundColor,
          appBar: widget.showAppBar ? _buildAppBar() : null,
          body: Stack(children: [_buildMainContent()]),
          bottomSheet: _buildBottomContent(),
        ),
      ),
    );
  }

  // Consolidated bottom content builder
  Widget? _buildBottomContent() {
    return _isCustomizationMode
        ? _buildAdditionalFieldsContainer()
        : widget.bottomWidget?.call(context, _formData);
  }

  PreferredSizeWidget _buildAppBar() {
    return FormUIBuilder.buildAppBar(
      context: context,
      title: widget.appBarTitle,
      isCustomizationMode: _isCustomizationMode,
      onToggleMode: _toggleCustomizationMode,
    );
  }

  // Streamlined main content builder
  Widget _buildMainContent() {
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
                _buildFieldContainer(),
                SizedBox(height: _bottomPadding),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Extracted field container builder
  Widget _buildFieldContainer() {
    return SizedBox(
      width: _containerWidth,
      height: _contentHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [..._buildCustomizationOverlays(), ..._buildFieldWidgets()],
      ),
    );
  }

  // Helper for customization overlays
  List<Widget> _buildCustomizationOverlays() {
    if (!_isCustomizationMode) return [];

    return [_buildSnapGuides(), _buildPreviewIndicator()];
  }

  // Helper for field widgets
  List<Widget> _buildFieldWidgets() {
    return _fieldConfigs.keys
        .map(_buildFieldWidget)
        .where((widget) => widget != null)
        .cast<Widget>()
        .toList();
  }

  // Helper for individual field widget
  Widget? _buildFieldWidget(String fieldId) {
    final matchingField = widget.availableFields.where((f) => f.id == fieldId);
    if (matchingField.isEmpty) return null;

    return _buildMagneticField(
      fieldId,
      matchingField.first.builder(context, _isCustomizationMode),
    );
  }

  Widget _buildSnapGuides() {
    return FormUIBuilder.buildSnapGuides(
      context: context,
      containerWidth: _containerWidth,
    );
  }

  // Streamlined magnetic field builder
  Widget _buildMagneticField(String fieldId, Widget field) {
    final config = _fieldConfigs[fieldId];
    if (config == null) return const SizedBox.shrink();

    return FormUIBuilder.buildMagneticField(
      context: context,
      fieldId: fieldId,
      field: field,
      config: config,
      isCustomizationMode: _isCustomizationMode,
      isSelected: _selectedFieldId == fieldId,
      isDragged: _dragState?.draggedFieldId == fieldId,
      isInPreview:
          _previewState.isActive && fieldId != _previewState.draggedFieldId,
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

  // Unified drag interaction handling
  void _startFieldDrag(String fieldId, LongPressStartDetails details) {
    _dragState = InteractionHandler.startFieldDrag(
      fieldId: fieldId,
      details: details,
      fieldConfigs: _fieldConfigs,
    );

    _initializeDragState(fieldId);
  }

  void _onFieldDrag(String fieldId, LongPressMoveUpdateDetails details) {
    if (_dragState == null) return;

    final result = InteractionHandler.handleFieldDrag(
      fieldId: fieldId,
      details: details,
      dragState: _dragState!,
      fieldConfigs: _fieldConfigs,
      containerWidth: _containerWidth,
    );

    _updateDragState(fieldId, result);

    if (result.shouldShowPreview) {
      _handlePreviewLogic(fieldId, result.hoveredRow);
    }
  }

  // Helper for drag state initialization
  void _initializeDragState(String fieldId) {
    setState(() {
      _selectedFieldId = fieldId;
      _previewState = PreviewState.initial();
    });

    _originalPositions.clear();
    _temporarilyMovedFields.clear();
    for (final entry in _fieldConfigs.entries) {
      _originalPositions[entry.key] = entry.value.position;
    }
  }

  // Helper for drag state updates
  void _updateDragState(String fieldId, dynamic result) {
    _dragState = _dragState!.copyWith(
      hasMovedBeyondThreshold: result.hasMovedBeyondThreshold,
    );

    setState(() {
      _fieldConfigs[fieldId] = _fieldConfigs[fieldId]!.copyWith(
        position: result.newPosition,
        width: _fieldConfigs[fieldId]!.width,
      );
    });
  }

  // Unified preview logic handling
  void _handlePreviewLogic(String fieldId, int hoveredRow) {
    if (!_shouldUpdatePreview(hoveredRow)) return;

    _lastRearrangementTime = DateTime.now();
    if (_previewState.targetRow != hoveredRow) {
      _showPreview(fieldId, hoveredRow);
    }
  }

  // Helper for preview throttling
  bool _shouldUpdatePreview(int hoveredRow) {
    final now = DateTime.now();
    return _lastRearrangementTime == null ||
        now.difference(_lastRearrangementTime!).inMilliseconds >= 100;
  }

  // Consolidated preview display logic
  void _showPreview(String fieldId, int targetRow) {
    MagneticUtils.preview('Field $fieldId targeting row $targetRow');

    final originalConfigs =
        _previewState.originalConfigs.isNotEmpty
            ? _previewState.originalConfigs
            : Map<String, FieldConfig>.from(_fieldConfigs);

    final previewConfigs = MagneticSystem.calculatePreviewPositions(
      targetRow: targetRow,
      draggedFieldId: fieldId,
      currentConfigs: originalConfigs,
      containerWidth: _containerWidth,
    );

    final previewInfo = MagneticSystem.getPreviewInfo(
      targetRow: targetRow,
      draggedFieldId: fieldId,
      currentConfigs: originalConfigs,
      containerWidth: _containerWidth,
    );

    _updatePreviewState(
      fieldId,
      targetRow,
      previewConfigs,
      originalConfigs,
      previewInfo,
    );
    _animateToPreview(fieldId, previewConfigs);
  }

  // Helper for updating preview state
  void _updatePreviewState(
    String fieldId,
    int targetRow,
    Map<String, FieldConfig> previewConfigs,
    Map<String, FieldConfig> originalConfigs,
    dynamic previewInfo,
  ) {
    _previewState = PreviewState.active(
      draggedFieldId: fieldId,
      targetRow: targetRow,
      previewConfigs: previewConfigs,
      originalConfigs: originalConfigs,
      previewInfo: previewInfo,
    );
  }

  // Helper for preview animation
  void _animateToPreview(
    String fieldId,
    Map<String, FieldConfig> previewConfigs,
  ) {
    final animationConfigs = Map<String, FieldConfig>.from(previewConfigs);
    animationConfigs[fieldId] =
        _fieldConfigs[fieldId]!; // Keep dragged field at cursor position

    MagneticSystem.animateToPreview(
      vsync: this,
      fromConfigs: _fieldConfigs,
      toConfigs: animationConfigs,
      onUpdate: (configs) => setState(() => _fieldConfigs = configs),
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

    final result = InteractionHandler.handleFieldDragEnd(
      fieldId: fieldId,
      fieldConfigs: _fieldConfigs,
      containerWidth: _containerWidth,
      previewState: _previewState,
    );

    _finalizeDragOperation(fieldId, result);
    _cleanupDragState();
  }

  // Helper for finalizing drag operations
  void _finalizeDragOperation(String fieldId, dynamic result) {
    if (result.shouldCommitPreview) {
      _commitPreview(fieldId);
    } else {
      _handleStandardDragEnd(fieldId, result.finalPosition);
    }
  }

  // Helper for cleaning up drag state
  void _cleanupDragState() {
    setState(() => _dragState = null);
    _originalPositions.clear();
    _temporarilyMovedFields.clear();
    _previewState = PreviewState.initial();
  }

  // Unified preview commit handling
  void _commitPreview(String fieldId) {
    MagneticUtils.success('COMMIT PREVIEW: Field $fieldId');

    if (!_canCommitPreview()) {
      _handleStandardDragEnd(fieldId, _fieldConfigs[fieldId]!.position);
      return;
    }

    final finalConfigs = _buildFinalConfigs(fieldId);
    _animateToFinalPosition(finalConfigs);
  }

  // Helper for preview commit validation
  bool _canCommitPreview() {
    return _previewState.isActive &&
        _previewState.previewInfo?.targetPosition != null;
  }

  // Helper for building final configurations
  Map<String, FieldConfig> _buildFinalConfigs(String fieldId) {
    final finalConfigs = Map<String, FieldConfig>.from(
      _previewState.previewConfigs,
    );

    final previewDraggedField = _previewState.previewConfigs[fieldId];
    if (previewDraggedField != null) {
      finalConfigs[fieldId] = previewDraggedField;
    } else {
      finalConfigs[fieldId] = _fieldConfigs[fieldId]!.copyWith(
        position: _previewState.previewInfo!.targetPosition!,
      );
    }

    return finalConfigs;
  }

  // Helper for final position animation
  void _animateToFinalPosition(Map<String, FieldConfig> finalConfigs) {
    MagneticSystem.animateToCommit(
      vsync: this,
      fromConfigs: _fieldConfigs,
      toConfigs: finalConfigs,
      onUpdate: (configs) => setState(() => _fieldConfigs = configs),
      onComplete: () {
        _optimizeFieldLayout();
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
    _optimizeFieldLayout();
    _saveFieldConfigurations();
  }

  // Unified resize interaction handling
  void _onResizeField(
    String fieldId,
    DragUpdateDetails details,
    ResizeDirection direction,
  ) {
    InteractionHandler.handleResize(
      fieldId: fieldId,
      details: details,
      direction: direction,
      fieldConfigs: _fieldConfigs,
      containerWidth: _containerWidth,
      accumulatedDrag: _accumulatedDrag,
      vsync: this,
      onFieldUpdate: _updateFieldConfig,
      onAccumulatedDragUpdate: (value) => _accumulatedDrag = value,
      onSave: _saveFieldConfigurations,
    );
  }

  void _onResizeFieldStart(String fieldId, ResizeDirection direction) {
    InteractionHandler.handleResizeStart(
      fieldId: fieldId,
      fieldConfigs: _fieldConfigs,
    );
  }

  void _onResizeFieldEnd(String fieldId, ResizeDirection direction) {
    InteractionHandler.handleResizeEnd(
      fieldId: fieldId,
      fieldConfigs: _fieldConfigs,
      containerWidth: _containerWidth,
      vsync: this,
      onFieldUpdate: _updateFieldConfig,
      onSave: _saveFieldConfigurations,
    );
  }

  // Unified field config update helper
  void _updateFieldConfig(String fieldId, FieldConfig config) {
    setState(() => _fieldConfigs[fieldId] = config);
  }

  Widget _buildAdditionalFieldsContainer() {
    return FormUIBuilder.buildAdditionalFieldsContainer(
      context: context,
      availableFields: widget.availableFields,
      fieldConfigs: _fieldConfigs,
      onToggleField: _toggleAdditionalField,
    );
  }

  // Consolidated field selection management
  void _selectField(String fieldId) {
    if (_selectedFieldId != fieldId) {
      setState(() => _selectedFieldId = fieldId);
    }
  }

  void _deselectField() {
    if (_selectedFieldId != null) {
      setState(() => _selectedFieldId = null);
    }
  }

  // Consolidated mode management
  void _toggleCustomizationMode() {
    setState(() {
      _isCustomizationMode = !_isCustomizationMode;
      if (!_isCustomizationMode) {
        _saveFieldConfigurations();
      }
    });
  }

  // Consolidated field toggle handling
  void _toggleAdditionalField(String fieldId) {
    final config = _fieldConfigs[fieldId];
    final isCurrentlyVisible = config != null && config.isVisible;

    setState(() {
      if (isCurrentlyVisible) {
        _hideField(fieldId);
      } else {
        _showField(fieldId);
      }
    });

    _saveFieldConfigurations();
  }

  // Helper for hiding fields
  void _hideField(String fieldId) {
    _fieldConfigs[fieldId] = FieldConfig(
      id: fieldId,
      width: 0,
      position: const Offset(-100, -100),
    );

    if (_selectedFieldId == fieldId) {
      _selectedFieldId = null;
    }

    _optimizeFieldLayout();
  }

  // Helper for showing fields
  void _showField(String fieldId) {
    final nextRow = _findNextAvailableRow();
    _fieldConfigs[fieldId] = FieldConfig(
      id: fieldId,
      position: Offset(0, nextRow * MagneticCardSystem.cardHeight),
      width: 1.0,
    );
  }

  // Helper for finding next available row
  int _findNextAvailableRow() {
    int nextRow = 0;
    for (var config in _fieldConfigs.values) {
      if (config.position.dx == 0) {
        final currentRow = FieldConfig.getRowFromPosition(config.position.dy);
        if (currentRow >= nextRow) {
          nextRow = currentRow + 1;
        }
      }
    }
    return nextRow;
  }
}
