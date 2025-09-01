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
    1 / 2, // Half
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

    // Snap to grid positions based on thirds instead of sixths
    final columnWidth = containerWidth / 3; // Divide container into 3 columns
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
  bool _isCustomizationMode = false;
  String? _selectedFieldId;
  Offset? _dragStartPosition;
  Offset? _dragStartFieldPosition;
  double _accumulatedDrag = 0;

  // Form data storage
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};

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
    debugPrint('Saving field configurations: ${_fieldConfigs.length} fields');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isCustomizationMode ? _deselectField : null,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: widget.showAppBar ? _buildAppBar() : null,
        body: _buildMainContent(),
        bottomSheet:
            _isCustomizationMode
                ? _buildAdditionalFieldsContainer()
                : widget.cartSummaryButton?.call(context, _formData),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0.5,
      centerTitle: true,
      title: Text(widget.appBarTitle),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(_isCustomizationMode ? Icons.done : Icons.tune),
          onPressed: () {
            setState(() {
              _isCustomizationMode = !_isCustomizationMode;
              if (!_isCustomizationMode) _saveFieldConfigurations();
            });
          },
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    final size = MediaQuery.of(context).size;
    final containerWidth = size.width - 32;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: containerWidth,
        height:
            _isCustomizationMode
                ? max(size.height - 200, 840)
                : size.height - 150,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (_isCustomizationMode) _buildSnapGuides(),
            ..._buildVisibleFields(),
            SizedBox(height: _isCustomizationMode ? 120.0 : 90.0),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildVisibleFields() {
    return _fieldConfigs.entries
        .where((entry) => widget.availableFields.any((f) => f.id == entry.key))
        .map((entry) {
          final field = widget.availableFields.firstWhere(
            (f) => f.id == entry.key,
          );
          return _buildMagneticField(
            entry.key,
            field.builder(context, _isCustomizationMode),
          );
        })
        .toList();
  }

  Widget _buildSnapGuides() {
    final containerWidth = MediaQuery.of(context).size.width - 32;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Stack(
        children: [
          ...List.generate(
            MagneticCardSystem.maxRows,
            (row) => Positioned(
              left: 0,
              right: 0,
              top: row * MagneticCardSystem.cardHeight - 2,
              child: Container(
                height: MagneticCardSystem.cardHeight + 4,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  borderRadius: BorderRadius.circular(6),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
                ),
              ),
            ),
          ),
          ...List.generate(
            5,
            (col) => Positioned(
              left: (containerWidth / 6) * (col + 1) - 1,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: (col + 1) % 2 == 0 ? 0.1 : 0.06,
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagneticField(String fieldId, Widget field) {
    final config = _fieldConfigs[fieldId];
    if (config == null || !_isFieldVisible(config))
      return const SizedBox.shrink();

    final isSelected = _selectedFieldId == fieldId;
    final containerWidth = MediaQuery.of(context).size.width - 32;
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
                    ? (details) => _startFieldDrag(fieldId)
                    : null,
            onLongPressMoveUpdate:
                _isCustomizationMode && isSelected
                    ? (details) => _onFieldDrag(fieldId, details)
                    : null,
            onLongPressEnd:
                _isCustomizationMode && isSelected
                    ? (details) => _onFieldDragEnd(fieldId)
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
                decoration: _getFieldDecoration(isSelected),
                child: field,
              ),
            ),
          ),
          if (_isCustomizationMode && isSelected) ...[
            _buildResizeHandle(fieldId, ResizeDirection.left, -12),
            _buildResizeHandle(fieldId, ResizeDirection.right, null),
          ],
        ],
      ),
    );
  }

  bool _isFieldVisible(FieldConfig config) =>
      config.width > 0 && config.position.dx >= 0 && config.position.dy >= 0;

  BoxDecoration? _getFieldDecoration(bool isSelected) {
    if (!_isCustomizationMode) return null;
    final theme = Theme.of(context);

    return isSelected
        ? BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        )
        : BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        );
  }

  Widget _buildResizeHandle(
    String fieldId,
    ResizeDirection direction,
    double? left,
  ) {
    final theme = Theme.of(context);
    final isLeft = direction == ResizeDirection.left;

    return Positioned(
      left: left,
      right: isLeft ? null : -12,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          print('🎯 Handle drag: $direction, delta: ${details.delta.dx}');
          _onResizeField(fieldId, details, direction);
        },
        child: Container(
          width: 24,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              left:
                  isLeft
                      ? BorderSide(color: theme.colorScheme.primary, width: 2)
                      : BorderSide.none,
              right:
                  !isLeft
                      ? BorderSide(color: theme.colorScheme.primary, width: 2)
                      : BorderSide.none,
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
    );
  }

  void _onResizeField(
    String fieldId,
    DragUpdateDetails details,
    ResizeDirection direction,
  ) {
    print(
      '🔧 RESIZE DEBUG: $fieldId, direction: $direction, delta: ${details.primaryDelta}',
    );

    final config = _fieldConfigs[fieldId]!;
    final containerWidth = MediaQuery.of(context).size.width - 32;

    _accumulatedDrag += details.primaryDelta ?? 0;
    print(
      '   Accumulated drag: $_accumulatedDrag, threshold: ${containerWidth * 0.1}',
    );

    if (_accumulatedDrag.abs() < containerWidth * 0.1) return;

    final currentIndex = MagneticCardSystem.cardWidths.indexOf(config.width);
    final isExpanding =
        direction == ResizeDirection.left
            ? _accumulatedDrag <
                0 // Left handle: drag left to expand
            : _accumulatedDrag > 0; // Right handle: drag right to expand
    final canResize =
        isExpanding
            ? currentIndex < MagneticCardSystem.cardWidths.length - 1
            : currentIndex > 0;

    print(
      '   Current width: ${config.width}, index: $currentIndex, expanding: $isExpanding, canResize: $canResize',
    );

    if (!canResize) {
      print('   ❌ Cannot resize - at boundary');
      return;
    }

    final newWidth =
        MagneticCardSystem.cardWidths[currentIndex + (isExpanding ? 1 : -1)];

    // Calculate new position based on handle direction
    final newX =
        direction == ResizeDirection.left
            ? config.position.dx -
                (newWidth - config.width) // Left: expand left, keep right edge
            : config.position.dx; // Right: expand right, keep left edge

    print('   New width: $newWidth, position: $newX');

    // Check boundaries based on direction
    if (direction == ResizeDirection.left) {
      if (newX < 0) {
        print('   ❌ Left boundary exceeded: newX = $newX');
        return;
      }
    } else {
      // Right expansion: check if new right edge exceeds boundary
      double newRightEdge = config.position.dx + newWidth;
      if (newRightEdge > 1.0) {
        print('   ❌ Right boundary exceeded: newRightEdge = $newRightEdge');
        return;
      }
    }

    _accumulatedDrag = 0;

    if (newWidth != config.width || newX != config.position.dx) {
      print('   ✅ Applying resize: ${config.width} → $newWidth');
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
                    widget.availableFields
                        .map((field) => _buildFieldChip(field, theme))
                        .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldChip(CustomFormField field, ThemeData theme) {
    final config = _fieldConfigs[field.id];
    final isOnPage = config != null && _isFieldVisible(config);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _toggleAdditionalField(field.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                isOnPage
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
            border: Border.all(
              color:
                  isOnPage
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.2),
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
                          : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isOnPage ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              if (isOnPage) ...[
                const SizedBox(width: 4),
                Icon(Icons.close, size: 12, color: theme.colorScheme.onPrimary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _selectField(String fieldId) =>
      setState(() => _selectedFieldId = fieldId);

  void _deselectField() {
    if (_selectedFieldId != null) setState(() => _selectedFieldId = null);
  }

  void _toggleAdditionalField(String fieldId) {
    setState(() {
      final config = _fieldConfigs[fieldId];
      final isVisible = config != null && _isFieldVisible(config);

      if (isVisible) {
        _fieldConfigs[fieldId] = FieldConfig(
          id: fieldId,
          width: 0,
          position: const Offset(-100, -100),
        );
        if (_selectedFieldId == fieldId) _selectedFieldId = null;
        _reflowFieldsUpward();
      } else {
        _addFieldToSingleColumn(fieldId);
      }
    });
    _saveFieldConfigurations();
  }

  void _reflowFieldsUpward() {
    final sortedFields =
        _fieldConfigs.entries.toList()
          ..sort((a, b) => a.value.position.dy.compareTo(b.value.position.dy));

    double currentY = 0;
    for (final entry in sortedFields.where((e) => e.value.position.dx == 0)) {
      _fieldConfigs[entry.key] = entry.value.copyWith(
        position: Offset(0, currentY),
      );
      currentY += MagneticCardSystem.cardHeight;
    }
  }

  void _addFieldToSingleColumn(String fieldId) {
    final nextRow = _fieldConfigs.values
        .where((config) => config.position.dx == 0)
        .map((config) => (config.position.dy / 70).round())
        .fold(0, (max, row) => row >= max ? row + 1 : max);

    _fieldConfigs[fieldId] = FieldConfig(
      id: fieldId,
      position: Offset(0, nextRow * 70.0),
      width: 1.0,
    );
  }

  void _startFieldDrag(String fieldId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedFieldId = fieldId;
      _dragStartPosition = null;
      _dragStartFieldPosition = _fieldConfigs[fieldId]!.position;
    });
  }

  void _onFieldDrag(String fieldId, LongPressMoveUpdateDetails details) {
    final config = _fieldConfigs[fieldId]!;
    final containerWidth = MediaQuery.of(context).size.width - 32;

    _dragStartPosition ??= details.globalPosition;

    final deltaX =
        (details.globalPosition.dx - _dragStartPosition!.dx) / containerWidth;
    final deltaY = details.globalPosition.dy - _dragStartPosition!.dy;

    final newX = (_dragStartFieldPosition!.dx + deltaX).clamp(
      0.0,
      1.0 - config.width,
    );
    final newY = (_dragStartFieldPosition!.dy + deltaY).clamp(
      0.0,
      MagneticCardSystem.maxRows * MagneticCardSystem.cardHeight,
    );

    setState(() {
      _fieldConfigs[fieldId] = config.copyWith(position: Offset(newX, newY));
    });
  }

  void _onFieldDragEnd(String fieldId) {
    final config = _fieldConfigs[fieldId]!;
    final containerWidth = MediaQuery.of(context).size.width - 32;

    _dragStartPosition = null;
    _dragStartFieldPosition = null;

    final currentPos = Offset(
      config.position.dx * containerWidth,
      config.position.dy,
    );
    final magneticPos = MagneticCardSystem.getMagneticSnapPosition(
      currentPos,
      containerWidth,
    );
    final maxX =
        (containerWidth - (config.width * containerWidth)) / containerWidth;
    final snappedX = (magneticPos.dx / containerWidth).clamp(0.0, maxX);

    setState(() {
      _fieldConfigs[fieldId] = config.copyWith(
        position: Offset(
          snappedX,
          magneticPos.dy.clamp(
            0.0,
            MagneticCardSystem.maxRows * MagneticCardSystem.cardHeight,
          ),
        ),
      );
      _reflowFieldsUpward();
    });

    _saveFieldConfigurations();
  }
}
