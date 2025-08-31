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
  
  FieldConfig copyWith({
    String? id,
    double? width,
    Offset? position,
  }) {
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
    1/3,  // One third - minimum usable width
    1/2,  // Half
    2/3,  // Two thirds
    1.0   // Full width
  ];
  
  static Offset getMagneticSnapPosition(Offset currentPos, double containerWidth) {
    final targetRow = (currentPos.dy / cardHeight).round().clamp(0, maxRows - 1);
    final snappedY = targetRow * cardHeight;
    
    // Snap to grid positions based on thirds instead of sixths
    final columnWidth = containerWidth / 3;  // Divide container into 3 columns
    final targetSlot = (currentPos.dx / columnWidth).round();
    final snappedX = (targetSlot * columnWidth).clamp(0.0, containerWidth * 0.85);
    
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
  final Widget Function(BuildContext context, Map<String, dynamic> formData)? cartSummaryButton;
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: _isCustomizationMode ? _deselectField : null,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: widget.showAppBar ? _buildAppBar() : null,
        body: Stack(
          children: [
            _buildMainContent(),
          ],
        ),
        bottomSheet: _isCustomizationMode 
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
      title: Text(
        widget.appBarTitle,
        style: theme.appBarTheme.titleTextStyle,
      ),
      automaticallyImplyLeading: false,
      actions: [
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
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: screenWidth - 32,
                  height: _isCustomizationMode 
                      ? max(screenHeight - 200, 840)
                      : screenHeight - 150,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (_isCustomizationMode)
                        _buildSnapGuides(),
                      
                      ..._fieldConfigs.keys.map((fieldId) {
                        final matchingField = widget.availableFields.where((f) => f.id == fieldId);
                        if (matchingField.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        return _buildMagneticField(
                          fieldId,
                          matchingField.first.builder(context, _isCustomizationMode),
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
                  color: theme.colorScheme.onSurface.withValues(alpha: col % 2 == 0 ? 0.1 : 0.06),
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
            onLongPressStart: _isCustomizationMode ? (details) => _startFieldDrag(fieldId) : null,
            onLongPressMoveUpdate: _isCustomizationMode && isSelected ? (details) => _onFieldDrag(fieldId, details) : null,
            onLongPressEnd: _isCustomizationMode && isSelected ? (details) => _onFieldDragEnd(fieldId) : null,
            behavior: HitTestBehavior.opaque,
            child: AbsorbPointer(
              absorbing: _isCustomizationMode,
              child: Container(
                width: fieldWidth - (config.position.dx > 0 ? MagneticCardSystem.fieldGap : 0),
                margin: EdgeInsets.only(
                  left: config.position.dx > 0 ? MagneticCardSystem.fieldGap : 0,
                ),
                decoration: _isCustomizationMode && isSelected
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
                    : _isCustomizationMode
                        ? BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
                onHorizontalDragUpdate: (details) => _onResizeField(fieldId, details, ResizeDirection.left),
                child: Container(
                  width: 24,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      left: BorderSide(color: theme.colorScheme.primary, width: 2),
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
                onHorizontalDragUpdate: (details) => _onResizeField(fieldId, details, ResizeDirection.right),
                child: Container(
                  width: 24,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      right: BorderSide(color: theme.colorScheme.primary, width: 2),
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

  void _onResizeField(String fieldId, DragUpdateDetails details, ResizeDirection direction) {
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
      if (_accumulatedDrag > 0 && currentIndex < MagneticCardSystem.cardWidths.length - 1) {
        newWidth = MagneticCardSystem.cardWidths[currentIndex + 1];
      } else if (_accumulatedDrag < 0 && currentIndex > 0) {
        newWidth = MagneticCardSystem.cardWidths[currentIndex - 1];
      }
    } else {
      // Left resize: Change both width and x position
      if (_accumulatedDrag < 0 && currentIndex < MagneticCardSystem.cardWidths.length - 1) {
        // Expanding left
        if (newX > 0) { // Only if there's space to expand left
          newWidth = MagneticCardSystem.cardWidths[currentIndex + 1];
          newX = max(0, newX - (newWidth - config.width));
        }
      } else if (_accumulatedDrag > 0 && currentIndex > 0) {
        // Shrinking from left
        newWidth = MagneticCardSystem.cardWidths[currentIndex - 1];
        newX = newX + (config.width - newWidth);
      }
    }
    
    _accumulatedDrag = 0;  // Reset after processing
    
    // Only update if width or position changed
    if (newWidth != config.width || newX != config.position.dx) {
      setState(() {
        _fieldConfigs[fieldId] = config.copyWith(
          width: newWidth,
          position: Offset(newX, config.position.dy)
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
          top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, size: 16, color: theme.colorScheme.onSurfaceVariant),
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
                children: widget.availableFields.map((field) {
                  final config = _fieldConfigs[field.id];
                  final isOnPage = config != null && config.width > 0 && config.position.dx >= 0 && config.position.dy >= 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _toggleAdditionalField(field.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOnPage ? theme.colorScheme.primary : theme.colorScheme.surface,
                          border: Border.all(
                            color: isOnPage ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOnPage ? Icons.check_circle : field.icon,
                              size: 14,
                              color: isOnPage ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              field.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: isOnPage ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                                fontWeight: isOnPage ? FontWeight.w500 : FontWeight.normal,
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

  void _toggleAdditionalField(String fieldId) {
    setState(() {
      final config = _fieldConfigs[fieldId];
      final isCurrentlyVisible = config != null && config.width > 0 && config.position.dx >= 0 && config.position.dy >= 0;
      
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
        _reflowFieldsUpward();
      } else {
        // Show the field by adding it to the form
        _addFieldToSingleColumn(fieldId);
      }
    });
    _saveFieldConfigurations();
  }

  void _reflowFieldsUpward() {
    var sortedFields = _fieldConfigs.entries.toList()
      ..sort((a, b) => a.value.position.dy.compareTo(b.value.position.dy));
    
    double currentY = 0;
    for (var entry in sortedFields) {
      if (entry.value.position.dx == 0) {
        _fieldConfigs[entry.key] = entry.value.copyWith(
          position: Offset(0, currentY)
        );
        currentY += MagneticCardSystem.cardHeight;
      }
    }
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

  void _startFieldDrag(String fieldId) {
    HapticFeedback.mediumImpact();
    final config = _fieldConfigs[fieldId]!;
    setState(() {
      _selectedFieldId = fieldId;
      _dragStartPosition = null;
      _dragStartFieldPosition = config.position;
    });
  }

  void _onFieldDrag(String fieldId, LongPressMoveUpdateDetails details) {
    final config = _fieldConfigs[fieldId]!;
    final containerWidth = MediaQuery.of(context).size.width - 32;
    
    // Initialize drag start position if not set
    _dragStartPosition ??= details.globalPosition;
    
    // Calculate the delta from the start position
    final deltaX = (details.globalPosition.dx - _dragStartPosition!.dx) / containerWidth;
    final deltaY = details.globalPosition.dy - _dragStartPosition!.dy;
    
    // Calculate new position
    final newX = (_dragStartFieldPosition!.dx + deltaX).clamp(0.0, 1.0 - config.width);
    final newY = (_dragStartFieldPosition!.dy + deltaY).clamp(0.0, MagneticCardSystem.maxRows * MagneticCardSystem.cardHeight);
    
    // Update position based on the initial field position plus delta
    setState(() {
      _fieldConfigs[fieldId] = config.copyWith(
        position: Offset(newX, newY),
      );
    });
  }

  void _onFieldDragEnd(String fieldId) {
    final config = _fieldConfigs[fieldId]!;
    final containerWidth = MediaQuery.of(context).size.width - 32;
    
    // Reset drag tracking
    _dragStartPosition = null;
    _dragStartFieldPosition = null;
    
    // Calculate final magnetic position
    final currentPos = Offset(
      config.position.dx * containerWidth,
      config.position.dy,
    );
    
    final magneticPos = MagneticCardSystem.getMagneticSnapPosition(currentPos, containerWidth);
    
    // Ensure the magnetic position doesn't push the field off the right edge
    final maxX = (containerWidth - (config.width * containerWidth)) / containerWidth;
    final snappedX = (magneticPos.dx / containerWidth).clamp(0.0, maxX);
    
    setState(() {
      _fieldConfigs[fieldId] = config.copyWith(
        position: Offset(
          snappedX,
          magneticPos.dy.clamp(0.0, MagneticCardSystem.maxRows * MagneticCardSystem.cardHeight),
        ),
      );
      
      // After updating the dragged field's position, reflow all fields to fill gaps
      _reflowFieldsUpward();
    });
    
    _saveFieldConfigurations();
  }


}