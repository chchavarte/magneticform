# API Documentation

This document provides detailed API documentation for the Flutter Magnetic Form Builder.

## Core Classes

### MagneticCardSystem

The core system for grid-based field positioning and collision detection.

#### Constants
```dart
static const double cardHeight = 70.0;        // Height of each grid row
static const int maxRows = 12;                // Maximum number of rows
static const double snapThreshold = 30.0;     // Snap sensitivity
static const double fieldGap = 4.0;           // Gap between fields
```

#### Field Widths
```dart
static const List<double> cardWidths = [
  2 / 6,  // 33% width (2 columns)
  3 / 6,  // 50% width (3 columns)  
  4 / 6,  // 67% width (4 columns)
  6 / 6,  // 100% width (6 columns)
];
```

#### Key Methods

##### `getMagneticSnapPosition(Offset currentPos, double containerWidth) → Offset`
Snaps a position to the nearest grid position.

**Parameters:**
- `currentPos`: Current field position (normalized 0-1 for x, absolute for y)
- `containerWidth`: Container width in pixels

**Returns:** Snapped position on the grid

##### `wouldOverlap(Offset newPosition, double newWidth, double containerWidth, Map<String, FieldConfig> existingFields, String excludeFieldId) → bool`
Checks if placing a field at the given position would cause overlap.

**Parameters:**
- `newPosition`: Proposed field position
- `newWidth`: Field width (normalized 0-1)
- `containerWidth`: Container width in pixels
- `existingFields`: Map of existing field configurations
- `excludeFieldId`: ID of field to exclude from overlap check

**Returns:** `true` if overlap would occur, `false` otherwise

##### `findNextAvailablePosition(double fieldWidth, double containerWidth, Map<String, FieldConfig> existingFields, String excludeFieldId, {int startFromRow = 0}) → Offset`
Finds the next available position for a field.

**Parameters:**
- `fieldWidth`: Width of field to place (normalized 0-1)
- `containerWidth`: Container width in pixels
- `existingFields`: Map of existing field configurations
- `excludeFieldId`: ID of field to exclude
- `startFromRow`: Row to start searching from (optional)

**Returns:** Available position for the field

---

### FieldPreviewSystem

Handles preview-on-hover functionality and intelligent field placement.

#### Key Methods

##### `calculatePreviewPositions({required int targetRow, required String draggedFieldId, required Map<String, FieldConfig> currentConfigs, required double containerWidth}) → Map<String, FieldConfig>`
Calculates preview positions for all fields when dragging to a target row.

**Parameters:**
- `targetRow`: Row being targeted for placement
- `draggedFieldId`: ID of the field being dragged
- `currentConfigs`: Current field configurations
- `containerWidth`: Container width in pixels

**Returns:** Map of field configurations showing preview positions

**Placement Strategy:**
1. **Auto-resize**: Try to resize field to fit available space
2. **Direct placement**: Place at current width if space available
3. **Push-down**: Rearrange other fields to make space

##### `hasSpaceInRow({required int targetRow, required String excludeFieldId, required double fieldWidth, required Map<String, FieldConfig> currentConfigs, required double containerWidth}) → bool`
Checks if there's space in a row for a field at its current width.

##### `getPreviewInfo({required int targetRow, required String draggedFieldId, required Map<String, FieldConfig> currentConfigs, required double containerWidth}) → PreviewInfo`
Gets information about the preview state for user feedback.

**Returns:** `PreviewInfo` object containing:
- `hasSpace`: Whether placement is possible
- `targetPosition`: Where field will be placed
- `targetColumns`: Column range (start, span)
- `message`: User-friendly description
- `isPushDown`: Whether push-down is required

#### Animation Methods

##### `animateToPreview({required TickerProvider vsync, required Map<String, FieldConfig> fromConfigs, required Map<String, FieldConfig> toConfigs, required Function(Map<String, FieldConfig>) onUpdate, VoidCallback? onComplete})`
Animates fields to preview positions (150ms duration).

##### `animateToCommit({required TickerProvider vsync, required Map<String, FieldConfig> fromConfigs, required Map<String, FieldConfig> toConfigs, required Function(Map<String, FieldConfig>) onUpdate, VoidCallback? onComplete})`
Animates fields to final positions (300ms duration).

##### `animateToRevert({required TickerProvider vsync, required Map<String, FieldConfig> fromConfigs, required Map<String, FieldConfig> toConfigs, required Function(Map<String, FieldConfig>) onUpdate, VoidCallback? onComplete})`
Animates fields back to original positions (200ms duration).

---

### DragHandler

Handles drag and drop operations for fields.

#### Key Methods

##### `startFieldDrag({required String fieldId, required LongPressStartDetails details, required Map<String, FieldConfig> fieldConfigs}) → DragState`
Initiates a drag operation.

**Returns:** `DragState` containing:
- `draggedFieldId`: ID of field being dragged
- `dragStartPosition`: Global position where drag started
- `dragStartFieldPosition`: Original field position
- `hasMovedBeyondThreshold`: Whether drag threshold exceeded
- `originalPositions`: Backup of original positions

##### `handleFieldDrag({required String fieldId, required LongPressMoveUpdateDetails details, required DragState dragState, required Map<String, FieldConfig> fieldConfigs, required double containerWidth}) → DragUpdateResult`
Handles drag movement updates.

**Returns:** `DragUpdateResult` containing:
- `newPosition`: Updated field position
- `hoveredColumn`: Column being hovered over
- `hoveredRow`: Row being hovered over
- `hasMovedBeyondThreshold`: Whether threshold exceeded
- `shouldShowPreview`: Whether to show preview

##### `handleFieldDragEnd({required String fieldId, required Map<String, FieldConfig> fieldConfigs, required double containerWidth, required PreviewState previewState}) → DragEndResult`
Handles end of drag operation.

**Returns:** `DragEndResult` containing:
- `shouldCommitPreview`: Whether to use preview positions
- `finalPosition`: Final position for dragged field
- `finalConfigs`: Final configurations for all affected fields

---

### FieldConfig

Data model representing a form field configuration.

#### Properties
```dart
final String id;                    // Unique field identifier
final String type;                  // Field type (text, email, etc.)
final String label;                 // Display label
final Offset position;              // Position (x: 0-1 normalized, y: absolute)
final double width;                 // Width (0-1 normalized)
final bool isVisible;               // Visibility state
final bool isRequired;              // Required field flag
final Map<String, dynamic> metadata; // Additional field data
```

#### Methods

##### `copyWith({...}) → FieldConfig`
Creates a copy with modified properties.

##### `toJson() → Map<String, dynamic>`
Serializes to JSON format.

##### `fromJson(Map<String, dynamic> json) → FieldConfig`
Deserializes from JSON format.

---

### GridUtils

Utility functions for grid calculations and field management.

#### Key Methods

##### `calculateRowAvailableSpace(int targetRow, Map<String, FieldConfig> currentConfigs, {String? excludeFieldId}) → double`
Calculates total available space in a row.

##### `wouldFieldOverlap(FieldConfig testField, Map<String, FieldConfig> existingFields, String excludeFieldId, double containerWidth) → bool`
Checks if a field configuration would cause overlap.

##### `getFieldsInRow(int row, Map<String, FieldConfig> fieldConfigs) → List<FieldConfig>`
Gets all fields in a specific row.

---

### Logger

Structured logging system with categories.

#### Methods

##### `Logger.preview(String message)`
Logs preview-related operations.

##### `Logger.drag(String message)`
Logs drag and drop operations.

##### `Logger.animation(String message)`
Logs animation-related events.

##### `Logger.collision(String message)`
Logs collision detection events.

##### `Logger.grid(String message)`
Logs grid calculation events.

---

## Usage Examples

### Basic Field Placement
```dart
// Check if field can be placed
final canPlace = MagneticCardSystem.wouldOverlap(
  newPosition,
  fieldWidth,
  containerWidth,
  existingFields,
  fieldId,
);

// Find available position
final position = MagneticCardSystem.findNextAvailablePosition(
  fieldWidth,
  containerWidth,
  existingFields,
  fieldId,
);
```

### Preview System
```dart
// Calculate preview positions
final previewConfigs = FieldPreviewSystem.calculatePreviewPositions(
  targetRow: hoveredRow,
  draggedFieldId: fieldId,
  currentConfigs: fieldConfigs,
  containerWidth: containerWidth,
);

// Get preview information
final previewInfo = FieldPreviewSystem.getPreviewInfo(
  targetRow: hoveredRow,
  draggedFieldId: fieldId,
  currentConfigs: fieldConfigs,
  containerWidth: containerWidth,
);
```

### Animation
```dart
// Animate to preview
FieldPreviewSystem.animateToPreview(
  vsync: this,
  fromConfigs: currentConfigs,
  toConfigs: previewConfigs,
  onUpdate: (configs) => setState(() => fieldConfigs = configs),
  onComplete: () => print('Preview animation complete'),
);
```

## Constants Reference

### Animation Constants
```dart
class AnimationConstants {
  static const Duration previewDuration = Duration(milliseconds: 150);
  static const Duration commitDuration = Duration(milliseconds: 300);
  static const Duration revertDuration = Duration(milliseconds: 200);
  
  static const Curve previewCurve = Curves.easeOut;
  static const Curve commitCurve = Curves.easeInOut;
  static const Curve revertCurve = Curves.easeIn;
}
```

### Field Constants
```dart
class FieldConstants {
  static const double hoverThreshold = 20.0;
  static const Duration hoverDelay = Duration(milliseconds: 100);
  static const double dragThreshold = 10.0;
}
```

### Grid Constants
```dart
class GridConstants {
  static const int totalColumns = 6;
  static const double minFieldWidth = 2 / 6;  // 33%
  static const double maxFieldWidth = 6 / 6;  // 100%
}
```