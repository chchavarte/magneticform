# 🧲 Magnetic Form Builder

![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Desktop-lightgrey.svg)
![Version](https://img.shields.io/badge/Version-1.0.1-brightgreen.svg)

A sophisticated Flutter package for building **drag-and-drop forms** with magnetic grid positioning, intelligent field placement, and smooth animations.

> **🏆 Production-Ready** - Clean logging and professional error handling  
> **🚀 v1.0.1** - Optimized for production builds

## ✨ Features

- 🎯 **Drag & Drop Interface** - Users can customize form layouts by dragging fields
- 🧲 **Magnetic Grid System** - 6-column responsive grid with intelligent snapping
- 🔄 **Real-time Preview** - See field placement before dropping
- 🤖 **Auto-resize & Collision Detection** - Fields automatically adjust to fit available space
- 📱 **Responsive Design** - Works on mobile, tablet, and desktop
- 🎨 **Customizable Themes** - Full Material Design integration
- ⚡ **Smooth Animations** - 60fps performance with optimized animations
- 🧹 **Production-Ready Logging** - Clean console output with professional error reporting

## 🚀 Quick Start

### 1. Add to pubspec.yaml
```yaml
dependencies:
  magnetic_form_builder:
    git:
      url: https://github.com/chchavarte/magneticform.git
      ref: v1.0.1
```

### 2. Import the package
```dart
import 'package:field_collision_test/features/customizable_form/presentation/screens/customizable_form_screen.dart';
```

### 3. Create your first magnetic form
```dart
import 'package:flutter/material.dart';
import 'package:field_collision_test/features/customizable_form/presentation/screens/customizable_form_screen.dart';
import 'package:field_collision_test/features/customizable_form/data/models/field_config.dart';

class MyFormScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomizableFormScreen(
      defaultFieldConfigs: {
        // Set initial positions and sizes
        'field1': FieldConfig(
          id: 'field1',
          type: 'text',
          label: 'Full Name',
          position: Offset(0, 0),    // Top-left corner
          width: 1.0,               // Full width (100%)
        ),
        'field2': FieldConfig(
          id: 'field2',
          type: 'email',
          label: 'Email',
          position: Offset(0, 70),   // Second row
          width: 0.5,               // Half width (50%)
        ),
      },
      storageKey: 'my_form_layout',
    );
  }
}
```

That's it! 🎉 You now have a fully functional drag-and-drop form builder.

## 🎯 Common Layout Patterns

### Side-by-Side Fields (50/50)
```dart
defaultFieldConfigs: {
  'firstName': FieldConfig(id: 'firstName', position: Offset(0, 0), width: 0.5),
  'lastName': FieldConfig(id: 'lastName', position: Offset(0.5, 0), width: 0.5),
}
```

### Three Columns (33/33/33)
```dart
defaultFieldConfigs: {
  'day': FieldConfig(id: 'day', position: Offset(0, 0), width: 0.33),
  'month': FieldConfig(id: 'month', position: Offset(0.33, 0), width: 0.33),
  'year': FieldConfig(id: 'year', position: Offset(0.66, 0), width: 0.33),
}
```

### Full Width Header + Two Columns
```dart
defaultFieldConfigs: {
  'title': FieldConfig(id: 'title', position: Offset(0, 0), width: 1.0),
  'address1': FieldConfig(id: 'address1', position: Offset(0, 70), width: 0.5),
  'address2': FieldConfig(id: 'address2', position: Offset(0.5, 70), width: 0.5),
}
```

## 📐 Understanding the Grid System

The Magnetic Form Builder uses a 6-column responsive grid:

**Position:** `Offset(x, y)` where:
- `x`: Horizontal position (0.0 = left edge, 1.0 = right edge)
- `y`: Vertical position (0 = top, increments by row height ~70px)

**Width:** Percentage of container width (0.0 to 1.0)
- `1.0` = Full width (100%)
- `0.5` = Half width (50%)
- `0.33` = One third (33%)

### Visual Grid Reference
```
┌─────────────────────────────────────────┐
│ 0.0    0.17   0.33   0.5    0.67   0.83 │ 1.0
├─────────────────────────────────────────┤
│ [    Field 1 (width: 1.0)             ] │ Row 0 (y: 0)
├─────────────────────────────────────────┤
│ [ Field 2 ] │ [ Field 3 ] │ [ Field 4 ] │ Row 1 (y: 70)
│ (width:0.33)│ (width:0.33)│ (width:0.33)│
├─────────────────────────────────────────┤
│ [    Field 5 (width: 0.5)  ] │ Field 6 │ Row 2 (y: 140)
│                              │(w: 0.5) │
└─────────────────────────────────────────┘
```

## 🔧 Configuration

### Debug Logging (Optional)
By default, debug logging is disabled for clean production builds. To enable debug output during development:

```dart
import 'package:field_collision_test/core/utils/logger.dart';

void main() {
  // Enable debug logging for development
  Logger.setDebugMode(true);
  runApp(MyApp());
}
```

### Production Benefits
The package is optimized for production with:
- ✅ No debug console output by default
- ✅ Clean error reporting via `Logger.error()`
- ✅ Optimized performance without debug overhead

## � Migration from v1.0.0

### Changes in v1.0.1

Version 1.0.1 focuses on production readiness:

#### Clean Console Output
```dart
// v1.0.0: Debug logging was enabled by default (lots of console output)
// v1.0.1: Debug logging is disabled by default (clean production builds)

// If you want debug output during development, add this to your main():
Logger.setDebugMode(true);
```

#### Internal Code Cleanup
- Removed debug print statements from production code
- Streamlined internal implementation

**✅ Public APIs remain unchanged** - all widget interfaces, controllers, and data models work exactly the same.

## 🎯 Use Cases

**Perfect For:**
- Admin Dashboards - Let users customize data entry forms
- Survey Builders - Drag-and-drop survey creation
- CRM Systems - Customizable contact forms
- Report Builders - Dynamic form layouts
- Settings Screens - User-configurable interfaces

**Not Ideal For:**
- Simple static forms (use regular Flutter forms)
- Forms that never need layout changes
- Performance-critical applications with 100+ fields

## 🚀 Performance Tips

- **Limit Field Count**: Best performance with < 50 fields
- **Use RepaintBoundary**: Wrap expensive field widgets
- **Disable Animations**: Set `AnimationConstants.previewDuration = Duration.zero` for testing
- **Optimize Builders**: Keep field builders lightweight

## 📚 API Reference

### CustomizableFormScreen

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `defaultFieldConfigs` | `Map<String, FieldConfig>` | ✅ | Initial positions and sizes |
| `storageKey` | `String?` | ❌ | Key for persisting layout changes |

### FieldConfig

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | `String` | ✅ | Unique identifier for the field |
| `type` | `String` | ✅ | Field type (text, email, etc.) |
| `label` | `String` | ✅ | Display name for the field |
| `position` | `Offset` | ✅ | Position on grid (x: 0.0-1.0, y: 0+) |
| `width` | `double` | ✅ | Width as percentage (0.0-1.0) |
| `isVisible` | `bool` | ❌ | Whether field is shown (default: true) |

## 🏛️ Architecture

The package follows Clean Architecture principles with feature-based organization:

```
lib/
├── core/                     # Core functionality
│   ├── constants/           # Animation, app, field, and grid constants
│   ├── theme/              # App theming and styling
│   └── utils/              # Utilities (logger, decorations)
├── features/
│   └── customizable_form/  # Main form builder feature
│       ├── data/           # Models and repositories
│       └── presentation/   # UI components, handlers, and systems
└── demo/                   # Demo data and test builders
```

## 🧪 Testing

Run tests with:
```bash
flutter test
```

The package includes comprehensive tests for:
- Field preview system logic
- Collision detection algorithms
- Animation state management
- Grid positioning calculations

## 📱 Supported Platforms

- ✅ iOS
- ✅ Android
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📚 Documentation

- **[API Compatibility](API_COMPATIBILITY.md)** - Version compatibility matrix
- **[Migration Guide](MIGRATION_GUIDE.md)** - Upgrade instructions between versions
- **[Changelog](CHANGELOG.md)** - Version history

## 🆘 Support

If you have any questions or need help, please:
- 🐛 [Open an issue](https://github.com/chchavarte/magneticform/issues) for bugs
- 💡 [Start a discussion](https://github.com/chchavarte/magneticform/discussions) for questions
- 📖 Check the comprehensive documentation

## ⭐ Show Your Support

If this project helped you, please consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs or suggesting features
- 🤝 Contributing to the codebase
- 📢 Sharing with the Flutter community

---

**Built with ❤️ using Flutter** | **v1.0.1 - Production Ready** 🚀