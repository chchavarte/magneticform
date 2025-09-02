# 📁 New Folder Structure

## Overview
This document outlines the new organized folder structure for the customizable form project.

## Structure

```
lib/
├── 📁 core/                          # Core app functionality
│   ├── 📁 constants/                 # All constants (CREATED)
│   │   ├── animation_constants.dart  # ✅ CREATED
│   │   ├── app_constants.dart        # ✅ CREATED  
│   │   ├── field_constants.dart      # ✅ CREATED
│   │   └── grid_constants.dart       # ✅ CREATED
│   ├── 📁 theme/                     # Theme and styling (CREATED)
│   │   ├── app_theme.dart            # ✅ CREATED
│   │   └── field_theme_extension.dart # ✅ CREATED
│   └── 📁 utils/                     # Core utilities (CREATED)
│       ├── logger.dart               # ✅ CREATED
│       └── decoration_utils.dart     # ✅ CREATED
│
├── 📁 features/                      # Feature-based organization (CREATED)
│   └── 📁 customizable_form/         # Main feature (CREATED)
│       ├── 📁 data/                  # Data layer (CREATED)
│       │   ├── 📁 models/            # (CREATED)
│       │   │   ├── field_config.dart      # ✅ CREATED
│       │   │   ├── form_field.dart        # ✅ CREATED
│       │   │   └── magnetic_card_system.dart # ✅ CREATED
│       │   └── 📁 repositories/      # (CREATED)
│       │       └── form_storage_repository.dart # ✅ CREATED
│       ├── 📁 domain/                # Business logic (CREATED)
│       │   ├── 📁 entities/          # ✅ CREATED (.gitkeep)
│       │   └── 📁 usecases/          # ✅ CREATED (.gitkeep)
│       └── 📁 presentation/          # UI layer (CREATED)
│           ├── 📁 components/        # Reusable components (CREATED)
│           │   ├── field_builders.dart    # ✅ CREATED
│           │   └── form_ui_builder.dart   # ✅ CREATED
│           ├── 📁 handlers/          # Event handlers (CREATED)
│           │   ├── drag_handler.dart      # ✅ CREATED
│           │   ├── resize_handler.dart    # ✅ CREATED
│           │   └── auto_expand_handler.dart # ✅ CREATED
│           ├── 📁 systems/           # Complex systems (CREATED)
│           │   ├── field_animations.dart     # ✅ CREATED
│           │   ├── field_preview_system.dart # ✅ CREATED
│           │   └── grid_utils.dart           # ✅ CREATED
│           └── 📁 screens/           # Main screens (CREATED)
│               ├── customizable_form_screen.dart # ✅ CREATED
│               └── form_demo_screen.dart         # ✅ CREATED
│
├── 📁 shared/                        # Shared across features (CREATED)
│   ├── 📁 widgets/                   # Common widgets (✅ CREATED)
│   └── 📁 extensions/                # Dart extensions (✅ CREATED)
│
├── 📁 demo/                          # Demo and testing (CREATED)
│   ├── demo_data.dart                # ✅ CREATED
│   └── test_field_builder.dart       # ✅ CREATED
│
└── main.dart                         # App entry point (EXISTS)
```

## Status

### ✅ Created (Blank Files Ready for Migration)
- All new folder structure created
- All placeholder files created with basic comments
- Ready for step-by-step content migration

### 📋 Next Steps
1. **Phase 1**: Move core utilities and theme files
2. **Phase 2**: Split and move model files  
3. **Phase 3**: Move presentation layer components
4. **Phase 4**: Update imports and clean up old structure

### 🗂️ Files to be Moved/Split
- `lib/app_theme.dart` → `lib/core/theme/app_theme.dart`
- `lib/utils/logger.dart` → `lib/core/utils/logger.dart`
- `lib/utils/decoration_utils.dart` → `lib/core/utils/decoration_utils.dart`
- `lib/form_models.dart` → Split into multiple model files
- `lib/customizable_item_form.dart` → `lib/features/customizable_form/presentation/screens/`
- And more...

### 🧹 Files to be Removed
- Old `lib/constants/` (after moving to `lib/core/constants/`)
- Empty `.gitkeep` files in unused folders
- `lib/preview_demo.dart` (move to demo folder)