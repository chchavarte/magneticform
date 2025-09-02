# Implementation Plan

- [-] 1. Phase 1: Core Infrastructure Migration with Integration Testing

  - Migrate core utilities, theme files, and constants with immediate testing after each step
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 1.1 Create core directory structure and migrate constants files

  - Create lib/core/constants/ directory structure
  - Copy animation_constants.dart, app_constants.dart, field_constants.dart, and grid_constants.dart to lib/core/constants/
  - Update all import statements in files that reference constants (field_builders.dart, field_resize_handler.dart, form_ui_builder.dart, decoration_utils.dart, auto_expand_handler.dart, drag_handler.dart)
  - Test app compilation and run basic functionality tests
  - _Requirements: 1.1, 4.1, 4.2, 6.6_

- [x] 1.2 Migrate and restructure theme system with testing

  - Create lib/core/theme/ directory
  - Move app_theme.dart to lib/core/theme/app_theme.dart
  - Extract FieldThemeExtension from app_theme.dart to lib/core/theme/field_theme_extension.dart
  - Update import in main.dart and any other files using AppTheme
  - Test app startup, theme switching, and field styling to ensure no visual regressions
  - _Requirements: 1.2, 4.1, 4.2, 6.5, 6.6_

- [x] 1.3 Migrate core utilities and implement proper logging

  - Create lib/core/utils/ directory
  - Move logger.dart and decoration_utils.dart to lib/core/utils/
  - Update logger.dart to replace print statements with proper logging framework
  - Update all import statements referencing these utilities
  - Test logging functionality and decoration utilities across the app
  - _Requirements: 1.3, 4.1, 4.2, 6.6_

- [x] 1.4 Clean up old constants directory and validate Phase 1

  - Remove lib/constants/ directory after confirming all imports are updated
  - Run comprehensive app testing including form building, field positioning, drag/drop, and theme switching
  - Verify no compilation errors and all existing functionality works identically
  - _Requirements: 1.5, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 2. Phase 2: Model Layer Restructuring with Integration Testing

  - Split form_models.dart and create repository layer with thorough testing of data operations
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 2.1 Create feature data structure and extract FieldConfig model

  - Create lib/features/customizable_form/data/models/ directory structure
  - Extract FieldConfig class from form_models.dart to lib/features/customizable_form/data/models/field_config.dart
  - Include ResizeDirection enum in field_config.dart
  - Update imports in all files that use FieldConfig
  - Test field configuration functionality including position management, width calculations, and serialization
  - _Requirements: 2.1, 2.4, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 2.2 Extract CustomFormField model and test field definitions

  - Extract CustomFormField class from form_models.dart to lib/features/customizable_form/data/models/form_field.dart
  - Update imports in all files that use CustomFormField
  - Test field creation, field builders, and form field functionality
  - Verify all field types (Name, Email, Phone, Address, Notes) work correctly
  - _Requirements: 2.2, 2.4, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 2.3 Extract MagneticCardSystem and test grid functionality

  - Extract MagneticCardSystem class from form_models.dart to lib/features/customizable_form/data/models/magnetic_card_system.dart
  - Update imports in all files that use MagneticCardSystem
  - Test comprehensive grid functionality including magnetic snapping, overlap detection, position calculations, and 6-column grid system
  - Test field positioning, resizing, and collision detection thoroughly
  - _Requirements: 2.3, 2.4, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 2.4 Create repository layer and test data persistence

  - Create lib/features/customizable_form/data/repositories/ directory
  - Implement form_storage_repository.dart with abstract interface and concrete implementation
  - Extract storage logic from existing form widgets into repository
  - Test field configuration saving and loading functionality
  - Verify data persistence works correctly across app sessions
  - _Requirements: 2.5, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 2.5 Remove old form_models.dart and validate Phase 2

  - Delete lib/form_models.dart after confirming all classes are extracted and imports updated
  - Run comprehensive testing of all model functionality including field creation, positioning, grid calculations, and data persistence
  - Test complex scenarios like field overlapping, magnetic snapping, and form state management
  - _Requirements: 2.6, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 3. Phase 3: Presentation Layer Organization with UI Testing

  - Reorganize UI components, handlers, and systems with extensive user interface testing
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 3.1 Create presentation structure and migrate handler files

  - Create lib/features/customizable_form/presentation/handlers/ directory
  - Move field_resize_handler.dart to lib/features/customizable_form/presentation/handlers/resize_handler.dart
  - Move utils/drag_handler.dart to lib/features/customizable_form/presentation/handlers/drag_handler.dart
  - Move utils/auto_expand_handler.dart to lib/features/customizable_form/presentation/handlers/auto_expand_handler.dart
  - Update all import statements referencing these handlers
  - Test drag and drop functionality, field resizing, and auto-expansion features thoroughly
  - _Requirements: 3.1, 3.6, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 3.2 Migrate system files and test complex UI systems

  - Create lib/features/customizable_form/presentation/systems/ directory
  - Move field_animations.dart to lib/features/customizable_form/presentation/systems/field_animations.dart
  - Move field_preview_system.dart to lib/features/customizable_form/presentation/systems/field_preview_system.dart
  - Move grid_utils.dart to lib/features/customizable_form/presentation/systems/grid_utils.dart
  - Update all import statements referencing these systems
  - Test field animations, preview functionality, and grid utility calculations
  - _Requirements: 3.2, 3.6, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 3.3 Migrate component files and test UI building

  - Create lib/features/customizable_form/presentation/components/ directory
  - Move widgets/form_ui_builder.dart to lib/features/customizable_form/presentation/components/form_ui_builder.dart
  - Move widgets/field_builders.dart to lib/features/customizable_form/presentation/components/field_builders.dart
  - Update all import statements referencing these components
  - Test form UI construction, field widget building, and component rendering
  - _Requirements: 3.3, 3.6, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 3.4 Migrate screen files and test main application screens

  - Create lib/features/customizable_form/presentation/screens/ directory
  - Move customizable_item_form.dart to lib/features/customizable_form/presentation/screens/customizable_form_screen.dart
  - Move preview_demo.dart to lib/features/customizable_form/presentation/screens/form_demo_screen.dart
  - Rename classes to follow screen naming conventions (CustomizableFormScreen, FormDemoScreen)
  - Update main.dart imports to reference new screen locations
  - Test complete application flow including screen navigation and main form functionality
  - _Requirements: 3.4, 3.6, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 3.5 Clean up old presentation files and validate Phase 3

  - Remove lib/widgets/ directory after confirming all components are migrated
  - Remove old individual files (field_resize_handler.dart, field_animations.dart, field_preview_system.dart, grid_utils.dart, customizable_item_form.dart, preview_demo.dart)
  - Run comprehensive UI testing including all user interactions, visual elements, and screen functionality
  - Test complete user workflows from form creation to field customization
  - _Requirements: 3.5, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 4. Phase 4: Import Management and Optimization with Compilation Testing

  - Optimize import structure and create barrel exports with thorough compilation validation
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 4.1 Implement consistent import patterns across codebase

  - Review all import statements and convert to consistent patterns (relative within features, absolute for cross-feature)
  - Update import statements to follow the established patterns from design document
  - Test compilation and ensure no import errors exist
  - _Requirements: 4.1, 4.2, 4.5, 6.6_

- [x] 4.2 Create barrel export files for easier imports

  - Create lib/core/core.dart with exports for all core functionality (constants, theme, utils)
  - Create lib/features/customizable_form/customizable_form.dart with exports for feature components
  - Update relevant files to use barrel imports where appropriate
  - Test that barrel exports work correctly and don't introduce circular dependencies
  - _Requirements: 4.4, 4.6, 6.6_

- [x] 4.3 Final import cleanup and remove empty directories

  - Remove any remaining empty directories (lib/models/, lib/themes/, lib/utils/ if empty)
  - Perform final cleanup of unused import statements
  - Ensure all imports are optimized and follow consistent patterns
  - Run full compilation test and fix any remaining import issues
  - _Requirements: 4.3, 4.5, 4.6, 6.6_

- [ ] 5. Phase 5: Demo Structure and Final Validation with End-to-End Testing

  - Organize demo files and perform comprehensive end-to-end testing
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 5.1 Organize demo files and test demo functionality

  - Ensure lib/demo/demo_data.dart and lib/demo/test_field_builder.dart are properly organized
  - Extract any remaining demo/test data from existing files into centralized demo structure
  - Update main.dart to use proper demo structure if needed
  - Test demo functionality and ensure all test fields and configurations work correctly
  - _Requirements: 5.1, 5.3, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 5.2 Update test files and validate test structure

  - Update test/field_preview_system_test.dart and test/widget_test.dart to match new file structure
  - Update all test imports to reference new file locations
  - Create feature-specific test directories if needed
  - Run all tests and ensure they pass with new structure
  - _Requirements: 5.2, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 5.3 Comprehensive end-to-end testing and validation
  - Perform complete application testing including all user workflows
  - Test form building, field customization, drag and drop, resizing, magnetic snapping, and data persistence
  - Test theme switching, animations, and visual consistency
  - Verify performance is maintained and no regressions exist
  - Test app on different screen sizes and orientations
  - Validate that all original functionality works identically to pre-migration state
  - _Requirements: 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_
