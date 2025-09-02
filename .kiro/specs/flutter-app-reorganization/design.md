# Design Document

## Overview

This design outlines the systematic reorganization of a Flutter application from a flat file structure to a feature-based clean architecture. The migration will transform the current scattered file organization into a structured hierarchy with clear separation of concerns, while preserving all existing functionality.

The current codebase contains approximately 25+ files spread across various directories (lib/constants, lib/utils, lib/widgets) without clear architectural boundaries. The target architecture follows clean architecture principles with core utilities, feature-based modules, and proper data/presentation layer separation.

## Architecture

### Target Architecture Pattern

The new structure follows a hybrid of Clean Architecture and Feature-First organization:

```
lib/
├── core/                    # Shared infrastructure
│   ├── constants/          # Application-wide constants
│   ├── theme/             # Theme and styling system
│   └── utils/             # Core utilities
├── features/              # Feature modules
│   └── customizable_form/ # Main feature
│       ├── data/          # Data layer
│       ├── domain/        # Business logic layer
│       └── presentation/  # UI layer
├── shared/                # Cross-feature shared code
└── demo/                  # Demo and testing utilities
```

### Migration Strategy

The migration follows a 5-phase approach to minimize risk and ensure functionality preservation:

1. **Core Infrastructure Migration** - Move shared utilities first
2. **Model Layer Restructuring** - Split and organize data models
3. **Presentation Layer Organization** - Restructure UI components
4. **Import Management** - Update all references and dependencies
5. **Cleanup and Optimization** - Remove old structure and optimize

## Components and Interfaces

### Core Module Components

#### Constants System
- **Location**: `lib/core/constants/`
- **Components**:
  - `animation_constants.dart` - Animation timing and curves
  - `app_constants.dart` - General application constants
  - `field_constants.dart` - Field-specific styling and behavior constants
  - `grid_constants.dart` - Grid system and magnetic snapping constants

**Migration Strategy**: Direct file moves with import path updates. The `FieldConstants` class contains critical styling values used throughout the UI, while `GridConstants` manages the 6-column grid system.

#### Theme System
- **Location**: `lib/core/theme/`
- **Components**:
  - `app_theme.dart` - Main theme configuration and color schemes
  - `field_theme_extension.dart` - Extracted field-specific theme extensions

**Extraction Strategy**: The current `app_theme.dart` contains both base theme and field-specific extensions. The `FieldThemeExtension` class will be extracted to a separate file for better organization.

#### Core Utilities
- **Location**: `lib/core/utils/`
- **Components**:
  - `logger.dart` - Logging utilities (addresses current print statement issues)
  - `decoration_utils.dart` - UI decoration helpers

### Feature Module Components

#### Data Layer
- **Location**: `lib/features/customizable_form/data/`
- **Models**:
  - `field_config.dart` - `FieldConfig` class with position and width management
  - `form_field.dart` - `CustomFormField` class for field definitions
  - `magnetic_card_system.dart` - `MagneticCardSystem` class with grid logic
- **Repositories**:
  - `form_storage_repository.dart` - Data persistence abstraction

**Splitting Strategy**: The current `form_models.dart` (300+ lines) contains three distinct classes that will be separated based on their responsibilities.

#### Presentation Layer
- **Location**: `lib/features/customizable_form/presentation/`
- **Handlers**: Event handling logic
  - `resize_handler.dart` - Field resizing logic
  - `drag_handler.dart` - Drag and drop functionality
  - `auto_expand_handler.dart` - Automatic field expansion
- **Systems**: Complex UI systems
  - `field_animations.dart` - Animation management
  - `field_preview_system.dart` - Field preview functionality
  - `grid_utils.dart` - Grid calculation utilities
- **Components**: Reusable UI components
  - `field_builders.dart` - Field widget builders
  - `form_ui_builder.dart` - Form UI construction
- **Screens**: Main application screens
  - `customizable_form_screen.dart` - Main form interface
  - `form_demo_screen.dart` - Demo screen

### Dependency Management

#### Import Strategy
- **Relative Imports**: Within same feature module
  ```dart
  import '../models/field_config.dart';
  import '../../data/models/form_field.dart';
  ```
- **Absolute Imports**: Cross-feature and core dependencies
  ```dart
  import 'package:field_collision_test/core/utils/logger.dart';
  import 'package:field_collision_test/core/theme/app_theme.dart';
  ```

#### Barrel Exports
- `lib/core/core.dart` - Export all core functionality
- `lib/features/customizable_form/customizable_form.dart` - Export feature components

## Data Models

### Current Model Analysis

The `form_models.dart` file contains three main classes:

1. **FieldConfig** (60 lines)
   - Manages field position, width, and visibility
   - Contains serialization methods (`toMap`, `fromMap`)
   - Critical for field state management

2. **MagneticCardSystem** (200+ lines)
   - Complex grid calculation logic
   - 6-column grid system implementation
   - Overlap detection and positioning algorithms

3. **CustomFormField** (15 lines)
   - Field definition and builder function
   - Simple data structure for field metadata

### Target Model Structure

```dart
// field_config.dart
class FieldConfig {
  final String id;
  final double width;
  final Offset position;
  // ... existing methods
}

// magnetic_card_system.dart
class MagneticCardSystem {
  // All grid calculation logic
  // Snap positioning algorithms
  // Overlap detection methods
}

// form_field.dart
class CustomFormField {
  final String id;
  final String label;
  final Widget Function(BuildContext, bool) builder;
  // ... existing properties
}
```

### Repository Pattern Implementation

```dart
// form_storage_repository.dart
abstract class FormStorageRepository {
  Future<Map<String, FieldConfig>> loadConfigurations(String key);
  Future<void> saveConfigurations(String key, Map<String, FieldConfig> configs);
}

class LocalFormStorageRepository implements FormStorageRepository {
  // SharedPreferences implementation
}
```

## Error Handling

### Migration Error Prevention

1. **Incremental Migration**: Each phase is independent and can be rolled back
2. **Import Validation**: Automated checking of import paths during migration
3. **Functionality Testing**: Each migrated component maintains identical behavior
4. **Backup Strategy**: Original files preserved until migration completion

### Runtime Error Handling

1. **Logging System**: Replace print statements with proper logging
2. **Null Safety**: Maintain existing null safety patterns
3. **State Management**: Preserve existing state management approach
4. **Error Boundaries**: Maintain existing error handling in UI components

## Testing Strategy

### Migration Testing Approach

1. **Pre-Migration Baseline**: Capture current functionality behavior
2. **Phase-by-Phase Testing**: Test each migration phase independently
3. **Integration Testing**: Verify cross-component functionality after each phase
4. **Regression Testing**: Ensure no functionality loss throughout migration

### Test Structure Updates

```
test/
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── features/
│   └── customizable_form/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── integration/
```

### Testing Priorities

1. **Critical Path Testing**: Form building, field positioning, drag/drop
2. **UI Consistency**: Theme application, styling preservation
3. **Data Integrity**: Field configuration persistence
4. **Performance**: Ensure no performance regression from restructuring

## Implementation Phases

### Phase 1: Core Infrastructure (Low Risk)
- Move constants files (4 files)
- Move theme files (1 file + extraction)
- Move core utilities (2 files)
- Update ~10 import statements

### Phase 2: Model Layer (Medium Risk)
- Split `form_models.dart` into 3 files
- Create repository interface
- Update ~15 files importing models

### Phase 3: Presentation Layer (Medium Risk)
- Move handler files (3 files)
- Move system files (3 files)
- Move component files (2 files)
- Move screen files (2 files)
- Update ~20 import statements

### Phase 4: Import Management (Low Risk)
- Systematic import path updates
- Create barrel exports
- Remove old directories

### Phase 5: Cleanup (Low Risk)
- Remove empty directories
- Update demo structure
- Final testing and validation

## Risk Mitigation

### High-Risk Areas
1. **MagneticCardSystem**: Complex grid logic with many dependencies
2. **Theme Extensions**: Custom theme system integration
3. **Cross-File Dependencies**: Handler and system interdependencies

### Mitigation Strategies
1. **Incremental Testing**: Test each file move individually
2. **Dependency Mapping**: Document all import relationships before migration
3. **Rollback Plan**: Maintain ability to revert each phase independently
4. **Automated Validation**: Use IDE and compiler to catch import errors immediately

## Success Criteria

### Functional Requirements
- All existing features work identically
- No performance degradation
- All tests pass
- No compilation errors

### Structural Requirements
- Clean separation of concerns
- Consistent import patterns
- Proper architectural boundaries
- Maintainable code organization

### Quality Requirements
- Improved code discoverability
- Better separation of responsibilities
- Enhanced maintainability
- Clearer architectural intent