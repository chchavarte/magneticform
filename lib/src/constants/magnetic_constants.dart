import 'package:flutter/material.dart';

/// Consolidated constants for the magnetic form builder.
/// 
/// Provides all configuration values, timing, and dimensions in a single location
/// for improved maintainability and consistency. All constants are organized by
/// functional area for easy navigation and usage.
/// 
/// ## Functional Areas
/// 
/// - **Animation**: Timing, curves, and animation-related constants
/// - **Field**: Dimensions, styling, and field-specific constants  
/// - **Grid**: Grid system, positioning, and layout constants
/// 
/// ## Usage
/// 
/// ```dart
/// AnimationController(
///   duration: MagneticConstants.previewDuration,
///   vsync: this,
/// )
/// 
/// Container(
///   height: MagneticConstants.fieldHeight,
///   padding: MagneticConstants.fieldPadding,
/// )
/// ```
class MagneticConstants {
  // Private constructor to prevent instantiation
  MagneticConstants._();

  // ============================================================================
  // ANIMATION CONSTANTS
  // ============================================================================

  /// Duration for field preview animations during drag operations.
  /// 
  /// Used for real-time preview feedback when hovering over grid positions.
  /// Fast timing (150ms) ensures responsive visual feedback without lag.
  static const Duration previewDuration = Duration(milliseconds: 150);

  /// Duration for field commit animations when placing fields.
  /// 
  /// Used when fields are successfully placed on the grid. Smooth timing
  /// (300ms) provides satisfying visual confirmation of the action.
  static const Duration commitDuration = Duration(milliseconds: 300);

  /// Duration for field revert animations when cancelling operations.
  /// 
  /// Used when drag operations are cancelled or fields return to original
  /// positions. Quick timing (200ms) provides immediate feedback.
  static const Duration revertDuration = Duration(milliseconds: 200);

  /// Default duration for general field animations.
  /// 
  /// Used for resize operations, field movements, and other general
  /// field-related animations that don't fall into specific categories.
  static const Duration defaultFieldAnimationDuration = Duration(milliseconds: 300);

  /// Duration for auto-resize feedback messages.
  /// 
  /// Controls how long auto-resize notifications are displayed to users
  /// after automatic field sizing operations.
  static const Duration autoResizeMessageDuration = Duration(seconds: 3);

  /// Animation curve for preview animations.
  /// 
  /// Provides fast, responsive easing for preview operations. The
  /// [Curves.easeOutQuart] curve starts fast and decelerates smoothly.
  static const Curve previewCurve = Curves.easeOutQuart;

  /// Animation curve for commit animations.
  /// 
  /// Provides smooth, natural easing for field placement operations.
  /// The [Curves.easeOutCubic] curve creates satisfying motion.
  static const Curve commitCurve = Curves.easeOutCubic;

  /// Animation curve for revert animations.
  /// 
  /// Provides balanced easing for cancelled operations. The
  /// [Curves.easeInOut] curve creates smooth bidirectional motion.
  static const Curve revertCurve = Curves.easeInOut;

  /// Default animation curve for general field operations.
  /// 
  /// Used for resize, movement, and other general field animations.
  /// Provides consistent motion feel across different operations.
  static const Curve defaultFieldAnimationCurve = Curves.easeOutCubic;

  // ============================================================================
  // FIELD CONSTANTS
  // ============================================================================

  // Field Dimensions
  static const double fieldHeight = 60.0;
  static const double fieldGap = 4.0;
  static const double resizeHandleWidth = 24.0;
  static const double resizeHandleHeight = 40.0;
  static const double resizeHandleIconSize = 16.0;
  static const double resizeHandleOffset = -12.0;

  // Field Styling
  static const EdgeInsets fieldPadding = EdgeInsets.all(8.0);
  static const double fieldBorderRadius = 8.0;
  static const double fieldBorderWidth = 1.0;
  static const FontWeight fieldTextWeight = FontWeight.bold;

  // Field Selection & Interaction
  static const double selectedFieldBorderWidth = 2.0;
  static const double draggedFieldBorderWidth = 3.0;
  static const double previewFieldBorderWidth = 2.0;

  // Field Positioning
  static const double fullWidth = 1.0;
  static const double halfWidth = 1.0 / 2.0;
  static const double thirdWidth = 1.0 / 3.0;
  static const double twoThirdsWidth = 2.0 / 3.0;
  static const double quarterWidth = 1.0 / 4.0;
  static const double threeQuartersWidth = 3.0 / 4.0;

  // Field Behavior Thresholds
  static const double hoverThreshold = 40.0; // pixels
  static const double accumulationThreshold = 0.1; // 10% of container width
  static const double significantGapThreshold = 0.05; // 5% for gap detection
  static const double widthChangeThreshold = 0.01; // 1% for width change detection

  // Container & Layout
  static const double containerPadding = 16.0;
  static const double containerMargin = 32.0; // Total horizontal margin
  static const double bottomPaddingCustomization = 120.0;
  static const double bottomPaddingNormal = 90.0;
  static const double screenHeightOffset = 200.0;
  static const double minScreenHeight = 840.0;
  static const double normalScreenHeightOffset = 150.0;

  // Auto-resize Message
  static const double autoResizeMessagePadding = 12.0;
  static const double autoResizeMessageTopOffset = 16.0;
  static const double autoResizeMessageHorizontalOffset = 16.0;
  static const double autoResizeMessageBorderRadius = 8.0;
  static const double autoResizeMessageBlurRadius = 4.0;
  static const Offset autoResizeMessageShadowOffset = Offset(0, 2);
  static const double autoResizeMessageShadowOpacity = 0.2;

  // Snap Guides
  static const double snapGuideBorderWidth = 1.0;
  static const double snapGuideHeight = 4.0; // Additional height for guides
  static const double snapGuideBorderRadius = 6.0;
  static const double snapGuideColumnWidth = 2.0;
  static const double snapGuideColumnBorderRadius = 1.0;
  static const double snapGuideOpacityPrimary = 0.08;
  static const double snapGuideOpacitySecondary = 0.06;
  static const double snapGuideBackgroundOpacity = 0.02;
  static const double snapGuideColumnOpacityEven = 0.1;
  static const double snapGuideColumnOpacityOdd = 0.06;

  // Shadow Effects
  static const double primaryShadowBlurRadius = 12.0;
  static const Offset primaryShadowOffset = Offset(0, 4);
  static const double primaryShadowOpacity = 0.4;
  static const double secondaryShadowBlurRadius = 6.0;
  static const Offset secondaryShadowOffset = Offset(0, 2);
  static const double secondaryShadowOpacity = 0.2;
  static const double selectedShadowOpacity = 0.3;

  // ============================================================================
  // GRID CONSTANTS
  // ============================================================================

  // Grid System
  static const double cardHeight = 70.0;
  static const int maxRows = 12;
  static const int totalColumns = 6;
  static const double snapThreshold = 30.0;

  // Magnetic Card Widths (based on 6-column grid)
  static const List<double> cardWidths = [
    2 / 6, // 2 columns (1/3 width)
    3 / 6, // 3 columns (1/2 width)
    4 / 6, // 4 columns (2/3 width)
    6 / 6, // 6 columns (full width)
  ];

  // Column calculations
  static const double columnWidth = 1.0 / totalColumns;

  // Row height calculations
  static double getRowY(int row) => row * cardHeight;

  // Column position calculations
  static double getColumnX(int column) => column * columnWidth;

  // Width to column span mapping
  static int getColumnSpan(double width) {
    if (width <= 2 / 6 + 0.001) return 2; // 2/6 width = 2 columns
    if (width <= 3 / 6 + 0.001) return 3; // 3/6 width = 3 columns
    if (width <= 4 / 6 + 0.001) return 4; // 4/6 width = 4 columns
    return 6; // 6/6 width = 6 columns (full row)
  }
}

/// Test field configuration data
class TestFieldData {
  // Private constructor to prevent instantiation
  TestFieldData._();

  /// Test field definitions
  static const List<TestFieldConfig> testFields = [
    TestFieldConfig('field1', 'Name', Icons.person),
    TestFieldConfig('field2', 'Email', Icons.email),
    TestFieldConfig('field3', 'Phone', Icons.phone),
    TestFieldConfig('field4', 'Address', Icons.location_on),
    TestFieldConfig('field5', 'Notes', Icons.note),
  ];

  /// Default field positions and widths
  static const Map<String, TestFieldPosition> defaultPositions = {
    'field1': TestFieldPosition(0.0, 0.0, MagneticConstants.fullWidth),
    'field2': TestFieldPosition(0.0, 70.0, MagneticConstants.halfWidth),
    'field3': TestFieldPosition(
      MagneticConstants.halfWidth,
      70.0,
      MagneticConstants.thirdWidth,
    ),
    'field4': TestFieldPosition(0.0, 140.0, MagneticConstants.twoThirdsWidth),
    'field5': TestFieldPosition(
      MagneticConstants.twoThirdsWidth,
      140.0,
      MagneticConstants.thirdWidth,
    ),
  };
}

/// Test field configuration model
class TestFieldConfig {
  final String id;
  final String label;
  final IconData icon;

  const TestFieldConfig(this.id, this.label, this.icon);
}

/// Test field position model
class TestFieldPosition {
  final double x;
  final double y;
  final double width;

  const TestFieldPosition(this.x, this.y, this.width);
}