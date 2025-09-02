# Flutter Magnetic Form Builder

A sophisticated Flutter application featuring an advanced drag-and-drop form builder with magnetic grid positioning, intelligent field placement, and smooth animations.

## ✨ Features

### 🎯 Core Functionality
- **Magnetic Grid System**: 6-column responsive grid with precise field snapping
- **Preview-on-Hover**: Real-time preview of field placement while dragging
- **Intelligent Placement**: Auto-resize, push-down, and collision detection
- **Smooth Animations**: Fluid transitions for preview, commit, and revert operations
- **Haptic Feedback**: Enhanced user experience with tactile responses

### 🏗️ Advanced Systems
- **Field Collision Detection**: Prevents overlapping with smart positioning
- **Auto-Resize Logic**: Automatically adjusts field widths to fit available space
- **Push-Down Mechanism**: Rearranges fields when no space is available
- **Multi-Animation Support**: Different animation curves for different operations

### 🎨 User Experience
- **Real-time Visual Feedback**: See exactly where fields will be placed
- **Responsive Design**: Adapts to different screen sizes
- **Clean Architecture**: Feature-based organization for maintainability

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.7.2 or higher
- Dart SDK compatible with Flutter version

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/flutter-magnetic-form-builder.git
   cd flutter-magnetic-form-builder
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Running Tests
```bash
flutter test
```

## 🏛️ Architecture

The app follows Clean Architecture principles with feature-based organization:

```
lib/
├── core/                     # Core app functionality
│   ├── constants/           # Animation, app, field, and grid constants
│   ├── theme/              # App theming and styling
│   └── utils/              # Utilities (logger, decorations)
├── features/
│   └── customizable_form/  # Main form builder feature
│       ├── data/           # Models and repositories
│       ├── domain/         # Business logic (entities, use cases)
│       └── presentation/   # UI components, handlers, and systems
├── shared/                 # Shared widgets and extensions
└── demo/                   # Demo data and test builders
```

## 🔧 Key Components

### Magnetic Card System
- **Grid-based positioning** with 6-column layout
- **Automatic snapping** to grid positions
- **Collision detection** and avoidance
- **Multiple field widths**: 33%, 50%, 67%, 100%

### Field Preview System
- **Real-time preview** during drag operations
- **Three placement strategies**:
  1. Auto-resize to fit available space
  2. Direct placement at current width
  3. Push-down rearrangement

### Animation System
- **Preview animations** (150ms) for quick feedback
- **Commit animations** (300ms) for smooth transitions
- **Revert animations** (200ms) for quick cancellation

## 🎮 Usage

1. **Drag Fields**: Long press and drag any form field
2. **Preview Placement**: See real-time preview of where the field will be placed
3. **Auto-Resize**: Fields automatically resize to fit available space when possible
4. **Push-Down**: When no space is available, other fields are pushed down
5. **Smooth Animations**: All movements are animated for better UX

## 🧪 Testing

The app includes comprehensive tests for:
- Field preview system logic
- Collision detection algorithms
- Animation state management
- Grid positioning calculations

Run tests with:
```bash
flutter test test/field_preview_system_test.dart
```

## 📱 Supported Platforms

- ✅ iOS
- ✅ Android
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Community contributors for inspiration and feedback

## 📞 Support

If you have any questions or need help, please:
- Open an issue on GitHub
- Check the [documentation](FOLDER_STRUCTURE.md)
- Review the [preview system summary](PREVIEW_SYSTEM_SUMMARY.md)

---

**Built with ❤️ using Flutter**
