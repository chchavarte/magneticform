import '../models/field_models.dart';

/// Abstract interface for form storage operations
abstract class FormStorageRepository {
  /// Load field configurations from storage
  Future<Map<String, FieldConfig>> loadConfigurations(String key);
  
  /// Save field configurations to storage
  Future<void> saveConfigurations(String key, Map<String, FieldConfig> configs);
  
  /// Check if configurations exist for a given key
  Future<bool> hasConfigurations(String key);
  
  /// Clear all configurations for a given key
  Future<void> clearConfigurations(String key);
}

/// Local storage implementation using SharedPreferences
class LocalFormStorageRepository implements FormStorageRepository {
  // Note: This is a placeholder implementation
  // In a real app, this would use SharedPreferences or another storage mechanism
  
  final Map<String, Map<String, FieldConfig>> _storage = {};
  
  @override
  Future<Map<String, FieldConfig>> loadConfigurations(String key) async {
    return _storage[key] ?? {};
  }
  
  @override
  Future<void> saveConfigurations(String key, Map<String, FieldConfig> configs) async {
    _storage[key] = Map.from(configs);
  }
  
  @override
  Future<bool> hasConfigurations(String key) async {
    return _storage.containsKey(key) && _storage[key]!.isNotEmpty;
  }
  
  @override
  Future<void> clearConfigurations(String key) async {
    _storage.remove(key);
  }
}