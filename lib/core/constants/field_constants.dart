import 'package:flutter/material.dart';

/// Field-specific constants for styling, dimensions, and behavior
class FieldConstants {
  // Private constructor to prevent instantiation
  FieldConstants._();

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
  static const double widthChangeThreshold =
      0.01; // 1% for width change detection

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
    'field1': TestFieldPosition(0.0, 0.0, FieldConstants.fullWidth),
    'field2': TestFieldPosition(0.0, 70.0, FieldConstants.halfWidth),
    'field3': TestFieldPosition(
      FieldConstants.halfWidth,
      70.0,
      FieldConstants.thirdWidth,
    ),
    'field4': TestFieldPosition(0.0, 140.0, FieldConstants.twoThirdsWidth),
    'field5': TestFieldPosition(
      FieldConstants.twoThirdsWidth,
      140.0,
      FieldConstants.thirdWidth,
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