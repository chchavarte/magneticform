# Migration Guide

This guide helps you migrate between different versions of Flutter Magnetic Form Builder.

## Migrating from v1.0.0 to v1.0.1

### 🔧 Changes (Non-Breaking)

#### 1. Logger Default Behavior

**What Changed:**
- v1.0.0: Debug logging was **enabled by default** (`_debugMode = true`)
- v1.0.1: Debug logging is **disabled by default** (`_debugMode = false`)

**Impact:**
- Production builds now have clean console output
- Debug information is no longer shown unless explicitly enabled

**Migration:**
```dart
// If you need debug output during development, add this to your main():
import 'package:field_collision_test/core/utils/logger.dart';

void main() {
  // Enable debug logging for development
  Logger.setDebugMode(true);
  runApp(MyApp());
}
```

#### 2. Removed Internal APIs

**What Changed:**
The following internal methods and state variables were removed:

**Removed Methods:**
- `_restoreOriginalPositions()`
- `_hasSpaceInRow()`
- `_pushDownAllFieldsAtRow()`
- `_rearrangeFieldsWithPullUp()`

**Removed State Variables:**
- `int? _hoveredColumn`
- `int? _hoveredRow`

**Impact:**
- These were internal implementation details, not part of the public API
- If you were accessing these directly (not recommended), your code will break

**Migration:**
- ✅ **No action needed** if you were using the public API correctly
- ❌ If you were accessing internal methods, refactor to use public APIs

### ✅ What Remains Compatible

#### Public APIs (No Changes Required)
- **Widget APIs**: All public widgets work exactly the same
- **Data Models**: `FieldConfig`, `MagneticCardSystem`, etc. unchanged
- **Controllers**: `FormBuilderController` interface unchanged
- **Logger Methods**: All Logger methods (`debug()`, `info()`, `error()`, etc.) have the same interface

#### Example - These Still Work:
```dart
// ✅ All of these continue to work without changes:

// Widget usage
MagneticFormBuilder(
  availableFields: fields,
  onFieldsChanged: (configs) => handleChange(configs),
)

// Logger usage (interface unchanged, just default behavior)
Logger.debug('Debug message');  // Now requires setDebugMode(true)
Logger.error('Error message');  // Always works

// Data models
final config = FieldConfig(
  id: 'field1',
  type: 'text',
  label: 'Text Field',
  position: Offset(0.0, 0.0),
  width: 0.5,
);
```

### 🔧 Recommended Actions

#### For Development
```dart
void main() {
  // Add this for development builds to see debug output
  Logger.setDebugMode(true);
  runApp(MyApp());
}
```

#### For Production
```dart
void main() {
  // No changes needed - debug logging is off by default
  // Error logging still works via Logger.error()
  runApp(MyApp());
}
```

#### For CI/CD
```dart
void main() {
  // You can conditionally enable debug logging
  if (kDebugMode) {
    Logger.setDebugMode(true);
  }
  runApp(MyApp());
}
```

### 🎯 Benefits of v1.0.1

#### Production Benefits
- ✅ **Clean Console Output**: No debug spam in production
- ✅ **Better Performance**: Reduced debug overhead
- ✅ **Professional Logging**: Only errors and important messages

#### Development Benefits
- ✅ **Opt-in Debug Logging**: Enable when you need it
- ✅ **Cleaner Codebase**: Removed 414 lines of debug code
- ✅ **Same Functionality**: All features work identically

### 🧪 Testing Your Migration

#### 1. Check Debug Output
```dart
// Test that debug logging works when enabled
Logger.setDebugMode(true);
Logger.debug('This should appear');

Logger.setDebugMode(false);
Logger.debug('This should NOT appear');
```

#### 2. Verify Error Logging
```dart
// Test that error logging always works
Logger.error('This should ALWAYS appear');
```

#### 3. Test Your App
```bash
# Run your app and verify functionality
flutter run

# Test production build
flutter build web --release
flutter build apk --release
```

### 🆘 Troubleshooting

#### "I'm not seeing debug output anymore"
**Solution:** Add `Logger.setDebugMode(true);` to your main() function.

#### "My app is broken after upgrading"
**Likely Cause:** You were accessing internal methods that were removed.
**Solution:** Refactor to use public APIs only.

#### "Error logging isn't working"
**Check:** `Logger.error()` should always work. If not, check your import:
```dart
import 'package:field_collision_test/core/utils/logger.dart';
```

### 📞 Need Help?

If you encounter issues during migration:
1. 🐛 [Open an issue](https://github.com/yourusername/flutter-magnetic-form-builder/issues)
2. 💬 [Start a discussion](https://github.com/yourusername/flutter-magnetic-form-builder/discussions)
3. 📖 Check the [full changelog](CHANGELOG.md)

### 🎉 You're Done!

Once you've made these changes, you'll have:
- ✅ Clean production builds
- ✅ Professional logging
- ✅ Same great functionality
- ✅ Better performance

Welcome to v1.0.1! 🚀