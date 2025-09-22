import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnetic_form_builder/magnetic_form_builder.dart';

/// Comprehensive API compatibility test suite.
/// 
/// Tests all public API methods, constructor parameters, and callback functions
/// to ensure the consolidated code maintains identical signatures and behavior.
/// 
/// This test validates:
/// - All constructor parameters work identically
/// - All public methods maintain identical signatures
/// - All callback functions receive identical data structures
/// - All exported classes and functions remain available
void main() {
  group('API Compatibility Tests', () {
    group('MagneticFormBuilder Constructor', () {
      testWidgets('accepts all required parameters', (tester) async {
        // Test that all required parameters are accepted
        final fields = TestFieldBuilder.createTestFields();
        final configs = TestFieldBuilder.createDefaultConfigs();
        
        final widget = MagneticFormBuilder(
          availableFields: fields,
          defaultFieldConfigs: configs,
        );
        
        expect(widget.availableFields, equals(fields));
        expect(widget.defaultFieldConfigs, equals(configs));
        expect(widget.showAppBar, isTrue); // Default value
        expect(widget.appBarTitle, equals('Custom Form')); // Default value
        expect(widget.storageKey, equals('magnetic_form_field_configs')); // Default value
      });

      testWidgets('accepts all optional parameters', (tester) async {
        final fields = TestFieldBuilder.createTestFields();
        final configs = TestFieldBuilder.createDefaultConfigs();
        final customTheme = MagneticTheme.lightTheme;
        
        var formDataCallbackCalled = false;
        var fieldConfigCallbackCalled = false;
        Map<String, dynamic>? receivedFormData;
        Map<String, FieldConfig>? receivedFieldConfigs;
        
        Widget? bottomWidgetResult;
        
        final widget = MagneticFormBuilder(
          availableFields: fields,
          defaultFieldConfigs: configs,
          theme: customTheme,
          bottomWidget: (context, formData) {
            bottomWidgetResult = const Text('Bottom Widget');
            return bottomWidgetResult!;
          },
          showAppBar: false,
          appBarTitle: 'Custom Title',
          storageKey: 'custom_storage_key',
          onFormDataChanged: (data) {
            formDataCallbackCalled = true;
            receivedFormData = data;
          },
          onFieldConfigChanged: (configs) {
            fieldConfigCallbackCalled = true;
            receivedFieldConfigs = configs;
          },
        );
        
        // Verify all parameters are set correctly
        expect(widget.availableFields, equals(fields));
        expect(widget.defaultFieldConfigs, equals(configs));
        expect(widget.theme, equals(customTheme));
        expect(widget.bottomWidget, isNotNull);
        expect(widget.showAppBar, isFalse);
        expect(widget.appBarTitle, equals('Custom Title'));
        expect(widget.storageKey, equals('custom_storage_key'));
        expect(widget.onFormDataChanged, isNotNull);
        expect(widget.onFieldConfigChanged, isNotNull);
        
        // Test that callbacks can be called (signature compatibility)
        widget.onFormDataChanged?.call({'test': 'value'});
        widget.onFieldConfigChanged?.call(configs);
        
        expect(formDataCallbackCalled, isTrue);
        expect(fieldConfigCallbackCalled, isTrue);
        expect(receivedFormData, equals({'test': 'value'}));
        expect(receivedFieldConfigs, equals(configs));
        
        // Test bottomWidget callback
        final context = MockBuildContext();
        final result = widget.bottomWidget?.call(context, {'test': 'data'});
        expect(result, equals(bottomWidgetResult));
      });
    });

    group('MagneticFormField Constructor', () {
      test('accepts all required parameters', () {
        final field = MagneticFormField(
          id: 'test_field',
          label: 'Test Field',
          icon: Icons.text_fields,
          builder: (context, isCustomizationMode) => const TextField(),
        );
        
        expect(field.id, equals('test_field'));
        expect(field.label, equals('Test Field'));
        expect(field.icon, equals(Icons.text_fields));
        expect(field.builder, isNotNull);
        expect(field.isMandatory, isFalse); // Default value
        expect(field.defaultValue, isNull); // Default value
      });

      test('accepts all optional parameters', () {
        final field = MagneticFormField(
          id: 'test_field',
          label: 'Test Field',
          icon: Icons.text_fields,
          builder: (context, isCustomizationMode) => const TextField(),
          isMandatory: true,
          defaultValue: 'default text',
        );
        
        expect(field.id, equals('test_field'));
        expect(field.label, equals('Test Field'));
        expect(field.icon, equals(Icons.text_fields));
        expect(field.builder, isNotNull);
        expect(field.isMandatory, isTrue);
        expect(field.defaultValue, equals('default text'));
      });

      test('builder function receives correct parameters', () {
        BuildContext? receivedContext;
        bool? receivedIsCustomizationMode;
        
        final field = MagneticFormField(
          id: 'test_field',
          label: 'Test Field',
          icon: Icons.text_fields,
          builder: (context, isCustomizationMode) {
            receivedContext = context;
            receivedIsCustomizationMode = isCustomizationMode;
            return const TextField();
          },
        );
        
        final context = MockBuildContext();
        final result = field.builder(context, true);
        
        expect(receivedContext, equals(context));
        expect(receivedIsCustomizationMode, isTrue);
        expect(result, isA<TextField>());
      });
    });

    group('FieldConfig Constructor and Methods', () {
      test('accepts all required parameters', () {
        final config = FieldConfig(id: 'test_field');
        
        expect(config.id, equals('test_field'));
        expect(config.width, equals(1.0)); // Default value
        expect(config.position, equals(Offset.zero)); // Default value
      });

      test('accepts all optional parameters', () {
        const position = Offset(0.5, 70.0);
        const width = 0.5;
        
        final config = FieldConfig(
          id: 'test_field',
          width: width,
          position: position,
        );
        
        expect(config.id, equals('test_field'));
        expect(config.width, equals(width));
        expect(config.position, equals(position));
      });

      test('copyWith method maintains identical signature', () {
        final original = FieldConfig(
          id: 'original',
          width: 0.5,
          position: const Offset(0.25, 70.0),
        );
        
        // Test copyWith with all parameters
        final copy1 = original.copyWith(
          id: 'new_id',
          width: 0.75,
          position: const Offset(0.5, 140.0),
        );
        
        expect(copy1.id, equals('new_id'));
        expect(copy1.width, equals(0.75));
        expect(copy1.position, equals(const Offset(0.5, 140.0)));
        
        // Test copyWith with partial parameters
        final copy2 = original.copyWith(width: 1.0);
        
        expect(copy2.id, equals('original'));
        expect(copy2.width, equals(1.0));
        expect(copy2.position, equals(const Offset(0.25, 70.0)));
        
        // Test copyWith with no parameters
        final copy3 = original.copyWith();
        
        expect(copy3.id, equals(original.id));
        expect(copy3.width, equals(original.width));
        expect(copy3.position, equals(original.position));
      });

      test('isVisible property works correctly', () {
        // Visible field
        final visibleConfig = FieldConfig(
          id: 'visible',
          width: 0.5,
          position: const Offset(0.0, 0.0),
        );
        expect(visibleConfig.isVisible, isTrue);
        
        // Invisible field (zero width)
        final invisibleConfig1 = FieldConfig(
          id: 'invisible1',
          width: 0.0,
          position: const Offset(0.0, 0.0),
        );
        expect(invisibleConfig1.isVisible, isFalse);
        
        // Invisible field (negative position)
        final invisibleConfig2 = FieldConfig(
          id: 'invisible2',
          width: 0.5,
          position: const Offset(-1.0, 0.0),
        );
        expect(invisibleConfig2.isVisible, isFalse);
      });

      test('toMap method returns correct structure', () {
        final config = FieldConfig(
          id: 'test_field',
          width: 0.5,
          position: const Offset(0.25, 70.0),
        );
        
        final map = config.toMap();
        
        expect(map, isA<Map<String, dynamic>>());
        expect(map['id'], equals('test_field'));
        expect(map['width'], equals(0.5));
        expect(map['positionX'], equals(0.25));
        expect(map['positionY'], equals(70.0));
        expect(map.keys.length, equals(4));
      });

      test('fromMap factory constructor works correctly', () {
        final map = {
          'id': 'test_field',
          'width': 0.5,
          'positionX': 0.25,
          'positionY': 70.0,
        };
        
        final config = FieldConfig.fromMap(map);
        
        expect(config.id, equals('test_field'));
        expect(config.width, equals(0.5));
        expect(config.position, equals(const Offset(0.25, 70.0)));
      });

      test('static utility methods maintain identical signatures', () {
        // Test getRowFromPosition
        expect(FieldConfig.getRowFromPosition(0.0), equals(0));
        expect(FieldConfig.getRowFromPosition(70.0), equals(1));
        expect(FieldConfig.getRowFromPosition(140.0), equals(2));
        
        // Test getColumnFromPosition
        expect(FieldConfig.getColumnFromPosition(0.0, 600.0), equals(0));
        expect(FieldConfig.getColumnFromPosition(0.5, 600.0), equals(3));
        expect(FieldConfig.getColumnFromPosition(1.0, 600.0), equals(5));
        
        // Test getColumnPositionNormalized
        expect(FieldConfig.getColumnPositionNormalized(0), equals(0.0));
        expect(FieldConfig.getColumnPositionNormalized(3), equals(0.5));
        expect(FieldConfig.getColumnPositionNormalized(6), equals(1.0));
        
        // Test getColumnsFromWidth
        expect(FieldConfig.getColumnsFromWidth(0.33), equals(2));
        expect(FieldConfig.getColumnsFromWidth(0.5), equals(3));
        expect(FieldConfig.getColumnsFromWidth(0.67), equals(6)); // 0.67 > 4/6, so returns 6
        expect(FieldConfig.getColumnsFromWidth(1.0), equals(6));
      });
    });

    group('MagneticTheme API', () {
      test('static theme getters work correctly', () {
        final lightTheme = MagneticTheme.lightTheme;
        final darkTheme = MagneticTheme.darkTheme;
        
        expect(lightTheme, isA<ThemeData>());
        expect(darkTheme, isA<ThemeData>());
        expect(lightTheme.brightness, equals(Brightness.light));
        expect(darkTheme.brightness, equals(Brightness.dark));
      });

      test('getTheme method maintains identical signature', () {
        // Test with no parameters
        final theme1 = MagneticTheme.getTheme();
        expect(theme1, isA<ThemeData>());
        
        // Test with custom theme
        final customTheme = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue));
        final theme2 = MagneticTheme.getTheme(customTheme: customTheme);
        expect(theme2, isA<ThemeData>());
        
        // Test with isDark parameter
        final theme3 = MagneticTheme.getTheme(isDark: true);
        expect(theme3, isA<ThemeData>());
        
        // Test with both parameters
        final theme4 = MagneticTheme.getTheme(customTheme: customTheme, isDark: true);
        expect(theme4, isA<ThemeData>());
      });

      test('withFieldExtensions method works correctly', () {
        final baseTheme = ThemeData();
        final enhancedTheme = MagneticTheme.withFieldExtensions(baseTheme);
        
        expect(enhancedTheme, isA<ThemeData>());
        expect(enhancedTheme.extensions, isNotEmpty);
        expect(enhancedTheme.extensions.values.first, isA<FieldThemeExtension>());
      });

      testWidgets('getFieldColor method maintains identical signature', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: MagneticTheme.lightTheme,
            home: Builder(
              builder: (context) {
                // Test various field IDs
                final color1 = MagneticTheme.getFieldColor(context, 'field1');
                final color2 = MagneticTheme.getFieldColor(context, 'field2');
                final color3 = MagneticTheme.getFieldColor(context, 'unknown_field');
                
                expect(color1, isA<Color>());
                expect(color2, isA<Color>());
                expect(color3, isA<Color>());
                
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('getFieldBorderColor method maintains identical signature', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: MagneticTheme.lightTheme,
            home: Builder(
              builder: (context) {
                // Test various field IDs
                final color1 = MagneticTheme.getFieldBorderColor(context, 'field1');
                final color2 = MagneticTheme.getFieldBorderColor(context, 'field2');
                final color3 = MagneticTheme.getFieldBorderColor(context, 'unknown_field');
                
                expect(color1, isA<Color>());
                expect(color2, isA<Color>());
                expect(color3, isA<Color>());
                
                return const SizedBox();
              },
            ),
          ),
        );
      });

      test('transparentColor getter works correctly', () {
        final transparentColor = MagneticTheme.transparentColor;
        expect(transparentColor, equals(Colors.transparent));
      });
    });

    group('FieldThemeExtension API', () {
      test('constructor accepts all required parameters', () {
        const extension = FieldThemeExtension(
          draggedFieldBorderColor: Colors.red,
          selectedFieldBorderColor: Colors.blue,
          previewFieldBackgroundColor: Colors.green,
          snapGuideColor: Colors.yellow,
          snapGuideBackgroundColor: Colors.purple,
        );
        
        expect(extension.draggedFieldBorderColor, equals(Colors.red));
        expect(extension.selectedFieldBorderColor, equals(Colors.blue));
        expect(extension.previewFieldBackgroundColor, equals(Colors.green));
        expect(extension.snapGuideColor, equals(Colors.yellow));
        expect(extension.snapGuideBackgroundColor, equals(Colors.purple));
      });

      test('copyWith method maintains identical signature', () {
        const original = FieldThemeExtension(
          draggedFieldBorderColor: Colors.red,
          selectedFieldBorderColor: Colors.blue,
          previewFieldBackgroundColor: Colors.green,
          snapGuideColor: Colors.yellow,
          snapGuideBackgroundColor: Colors.purple,
        );
        
        // Test copyWith with all parameters
        final copy1 = original.copyWith(
          draggedFieldBorderColor: Colors.orange,
          selectedFieldBorderColor: Colors.pink,
          previewFieldBackgroundColor: Colors.cyan,
          snapGuideColor: Colors.brown,
          snapGuideBackgroundColor: Colors.grey,
        );
        
        expect(copy1.draggedFieldBorderColor, equals(Colors.orange));
        expect(copy1.selectedFieldBorderColor, equals(Colors.pink));
        expect(copy1.previewFieldBackgroundColor, equals(Colors.cyan));
        expect(copy1.snapGuideColor, equals(Colors.brown));
        expect(copy1.snapGuideBackgroundColor, equals(Colors.grey));
        
        // Test copyWith with partial parameters
        final copy2 = original.copyWith(draggedFieldBorderColor: Colors.black);
        
        expect(copy2.draggedFieldBorderColor, equals(Colors.black));
        expect(copy2.selectedFieldBorderColor, equals(Colors.blue));
        expect(copy2.previewFieldBackgroundColor, equals(Colors.green));
        expect(copy2.snapGuideColor, equals(Colors.yellow));
        expect(copy2.snapGuideBackgroundColor, equals(Colors.purple));
      });

      test('lerp method maintains identical signature', () {
        const extension1 = FieldThemeExtension(
          draggedFieldBorderColor: Colors.red,
          selectedFieldBorderColor: Colors.blue,
          previewFieldBackgroundColor: Colors.green,
          snapGuideColor: Colors.yellow,
          snapGuideBackgroundColor: Colors.purple,
        );
        
        const extension2 = FieldThemeExtension(
          draggedFieldBorderColor: Colors.orange,
          selectedFieldBorderColor: Colors.pink,
          previewFieldBackgroundColor: Colors.cyan,
          snapGuideColor: Colors.brown,
          snapGuideBackgroundColor: Colors.grey,
        );
        
        final lerped = extension1.lerp(extension2, 0.5);
        
        expect(lerped, isA<FieldThemeExtension>());
        expect(lerped.draggedFieldBorderColor, isA<Color>());
        expect(lerped.selectedFieldBorderColor, isA<Color>());
        expect(lerped.previewFieldBackgroundColor, isA<Color>());
        expect(lerped.snapGuideColor, isA<Color>());
        expect(lerped.snapGuideBackgroundColor, isA<Color>());
        
        // Test lerp with null
        final lerpedWithNull = extension1.lerp(null, 0.5);
        expect(lerpedWithNull, equals(extension1));
      });
    });

    group('MagneticConstants API', () {
      test('all animation constants are accessible', () {
        expect(MagneticConstants.previewDuration, isA<Duration>());
        expect(MagneticConstants.commitDuration, isA<Duration>());
        expect(MagneticConstants.revertDuration, isA<Duration>());
        expect(MagneticConstants.defaultFieldAnimationDuration, isA<Duration>());
        expect(MagneticConstants.autoResizeMessageDuration, isA<Duration>());
        
        expect(MagneticConstants.previewCurve, isA<Curve>());
        expect(MagneticConstants.commitCurve, isA<Curve>());
        expect(MagneticConstants.revertCurve, isA<Curve>());
        expect(MagneticConstants.defaultFieldAnimationCurve, isA<Curve>());
      });

      test('all field constants are accessible', () {
        expect(MagneticConstants.fieldHeight, isA<double>());
        expect(MagneticConstants.fieldGap, isA<double>());
        expect(MagneticConstants.resizeHandleWidth, isA<double>());
        expect(MagneticConstants.resizeHandleHeight, isA<double>());
        expect(MagneticConstants.resizeHandleIconSize, isA<double>());
        expect(MagneticConstants.resizeHandleOffset, isA<double>());
        
        expect(MagneticConstants.fieldPadding, isA<EdgeInsets>());
        expect(MagneticConstants.fieldBorderRadius, isA<double>());
        expect(MagneticConstants.fieldBorderWidth, isA<double>());
        expect(MagneticConstants.fieldTextWeight, isA<FontWeight>());
        
        expect(MagneticConstants.fullWidth, equals(1.0));
        expect(MagneticConstants.halfWidth, equals(0.5));
        expect(MagneticConstants.thirdWidth, closeTo(0.333, 0.001));
        expect(MagneticConstants.quarterWidth, equals(0.25));
      });

      test('all grid constants are accessible', () {
        expect(MagneticConstants.cardHeight, isA<double>());
        expect(MagneticConstants.maxRows, isA<int>());
        expect(MagneticConstants.totalColumns, isA<int>());
        expect(MagneticConstants.snapThreshold, isA<double>());
        expect(MagneticConstants.cardWidths, isA<List<double>>());
        expect(MagneticConstants.columnWidth, isA<double>());
      });

      test('utility methods maintain identical signatures', () {
        expect(MagneticConstants.getRowY(0), equals(0.0));
        expect(MagneticConstants.getRowY(1), equals(70.0));
        expect(MagneticConstants.getRowY(2), equals(140.0));
        
        expect(MagneticConstants.getColumnX(0), equals(0.0));
        expect(MagneticConstants.getColumnX(3), closeTo(0.5, 0.001));
        expect(MagneticConstants.getColumnX(6), equals(1.0));
        
        expect(MagneticConstants.getColumnSpan(0.33), equals(2));
        expect(MagneticConstants.getColumnSpan(0.5), equals(3));
        expect(MagneticConstants.getColumnSpan(0.67), equals(6)); // 0.67 > 4/6, so returns 6
        expect(MagneticConstants.getColumnSpan(1.0), equals(6));
      });
    });

    group('TestFieldBuilder API', () {
      testWidgets('buildStandardTestField maintains identical signature', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: MagneticTheme.lightTheme,
            home: Builder(
              builder: (context) {
                final field = TestFieldBuilder.buildStandardTestField(
                  fieldId: 'test_field',
                  label: 'Test Label',
                  context: context,
                  isCustomizationMode: false,
                );
                
                expect(field, isA<Widget>());
                return field;
              },
            ),
          ),
        );
      });

      test('createTestFields returns correct structure', () {
        final fields = TestFieldBuilder.createTestFields();
        
        expect(fields, isA<List<MagneticFormField>>());
        expect(fields.length, equals(5));
        
        for (final field in fields) {
          expect(field.id, isA<String>());
          expect(field.label, isA<String>());
          expect(field.icon, isA<IconData>());
          expect(field.builder, isA<Function>());
        }
      });

      test('createDefaultConfigs returns correct structure', () {
        final configs = TestFieldBuilder.createDefaultConfigs();
        
        expect(configs, isA<Map<String, FieldConfig>>());
        expect(configs.length, equals(5));
        
        for (final entry in configs.entries) {
          expect(entry.key, isA<String>());
          expect(entry.value, isA<FieldConfig>());
          expect(entry.value.id, equals(entry.key));
        }
      });
    });

    group('Callback Function Data Structures', () {
      testWidgets('onFormDataChanged receives correct data structure', (tester) async {
        Map<String, dynamic>? receivedData;
        
        final widget = MagneticFormBuilder(
          availableFields: TestFieldBuilder.createTestFields(),
          defaultFieldConfigs: TestFieldBuilder.createDefaultConfigs(),
          onFormDataChanged: (data) {
            receivedData = data;
          },
        );
        
        // Simulate callback invocation
        widget.onFormDataChanged?.call({
          'field1': 'value1',
          'field2': 'value2',
          'field3': null,
        });
        
        expect(receivedData, isA<Map<String, dynamic>>());
        expect(receivedData?['field1'], equals('value1'));
        expect(receivedData?['field2'], equals('value2'));
        expect(receivedData?['field3'], isNull);
      });

      testWidgets('onFieldConfigChanged receives correct data structure', (tester) async {
        Map<String, FieldConfig>? receivedConfigs;
        
        final widget = MagneticFormBuilder(
          availableFields: TestFieldBuilder.createTestFields(),
          defaultFieldConfigs: TestFieldBuilder.createDefaultConfigs(),
          onFieldConfigChanged: (configs) {
            receivedConfigs = configs;
          },
        );
        
        final testConfigs = {
          'field1': FieldConfig(id: 'field1', width: 1.0, position: const Offset(0, 0)),
          'field2': FieldConfig(id: 'field2', width: 0.5, position: const Offset(0, 70)),
        };
        
        // Simulate callback invocation
        widget.onFieldConfigChanged?.call(testConfigs);
        
        expect(receivedConfigs, isA<Map<String, FieldConfig>>());
        expect(receivedConfigs?['field1'], isA<FieldConfig>());
        expect(receivedConfigs?['field2'], isA<FieldConfig>());
        expect(receivedConfigs?['field1']?.id, equals('field1'));
        expect(receivedConfigs?['field2']?.id, equals('field2'));
      });

      testWidgets('bottomWidget receives correct parameters', (tester) async {
        BuildContext? receivedContext;
        Map<String, dynamic>? receivedFormData;
        
        final widget = MagneticFormBuilder(
          availableFields: TestFieldBuilder.createTestFields(),
          defaultFieldConfigs: TestFieldBuilder.createDefaultConfigs(),
          bottomWidget: (context, formData) {
            receivedContext = context;
            receivedFormData = formData;
            return const Text('Bottom Widget');
          },
        );
        
        final context = MockBuildContext();
        final testFormData = {'field1': 'value1', 'field2': 'value2'};
        
        // Simulate callback invocation
        final result = widget.bottomWidget?.call(context, testFormData);
        
        expect(receivedContext, equals(context));
        expect(receivedFormData, equals(testFormData));
        expect(result, isA<Widget>());
      });
    });

    group('Export Validation', () {
      test('all expected classes are exported', () {
        // Test that all main classes are accessible
        expect(MagneticFormBuilder, isA<Type>());
        expect(MagneticFormField, isA<Type>());
        expect(FieldConfig, isA<Type>());
        expect(MagneticTheme, isA<Type>());
        expect(FieldThemeExtension, isA<Type>());
        expect(MagneticConstants, isA<Type>());
        expect(TestFieldBuilder, isA<Type>());
        
        // Test that enums are accessible
        expect(ResizeDirection, isA<Type>());
        expect(ResizeDirection.left, isA<ResizeDirection>());
        expect(ResizeDirection.right, isA<ResizeDirection>());
      });

      test('all expected constants are accessible', () {
        // Test that test data classes are accessible
        expect(TestFieldData, isA<Type>());
        expect(TestFieldConfig, isA<Type>());
        expect(TestFieldPosition, isA<Type>());
        
        // Test that test data is accessible
        expect(TestFieldData.testFields, isA<List<TestFieldConfig>>());
        expect(TestFieldData.defaultPositions, isA<Map<String, TestFieldPosition>>());
      });
    });
  });
}

/// Mock BuildContext for testing purposes
class MockBuildContext implements BuildContext {
  @override
  bool get debugDoingBuild => false;

  @override
  InheritedWidget dependOnInheritedElement(InheritedElement ancestor, {Object? aspect}) {
    throw UnimplementedError();
  }

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({Object? aspect}) => null;

  @override
  T? getInheritedWidgetOfExactType<T extends InheritedWidget>() => null;

  @override
  DiagnosticsNode describeElement(String name, {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty}) {
    throw UnimplementedError();
  }

  @override
  List<DiagnosticsNode> describeMissingAncestor({required Type expectedAncestorType}) {
    throw UnimplementedError();
  }

  @override
  DiagnosticsNode describeOwnershipChain(String name) {
    throw UnimplementedError();
  }

  @override
  DiagnosticsNode describeWidget(String name, {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty}) {
    throw UnimplementedError();
  }

  @override
  void dispatchNotification(Notification notification) {}

  @override
  T? findAncestorRenderObjectOfType<T extends RenderObject>() => null;

  @override
  T? findAncestorStateOfType<T extends State<StatefulWidget>>() => null;

  @override
  T? findAncestorWidgetOfExactType<T extends Widget>() => null;

  @override
  RenderObject? findRenderObject() => null;

  @override
  T? findRootAncestorStateOfType<T extends State<StatefulWidget>>() => null;

  @override
  InheritedElement? getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() => null;

  @override
  BuildOwner? get owner => null;

  @override
  Size? get size => null;

  @override
  void visitAncestorElements(bool Function(Element element) visitor) {}

  @override
  void visitChildElements(ElementVisitor visitor) {}

  @override
  Widget get widget => throw UnimplementedError();

  @override
  bool get mounted => true;
}