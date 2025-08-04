import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageService {
  static const String _userPreferencesKey = 'user_preferences';
  static const String _appSettingsKey = 'app_settings';
  static const String _cacheKey = 'cache_data';
  static const String _securitySettingsKey = 'security_settings';

  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // User preferences
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await _initPrefs();
      final jsonString = json.encode(preferences);
      await _prefs!.setString(_userPreferencesKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save user preferences: $e');
    }
  }

  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      await _initPrefs();
      final jsonString = _prefs!.getString(_userPreferencesKey);
      if (jsonString != null) {
        return Map<String, dynamic>.from(json.decode(jsonString));
      }
      return {};
    } catch (e) {
      throw Exception('Failed to get user preferences: $e');
    }
  }

  // App settings
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      await _initPrefs();
      final jsonString = json.encode(settings);
      await _prefs!.setString(_appSettingsKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save app settings: $e');
    }
  }

  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      await _initPrefs();
      final jsonString = _prefs!.getString(_appSettingsKey);
      if (jsonString != null) {
        return Map<String, dynamic>.from(json.decode(jsonString));
      }
      return {};
    } catch (e) {
      throw Exception('Failed to get app settings: $e');
    }
  }

  // Security settings
  Future<void> saveSecuritySettings(Map<String, dynamic> settings) async {
    try {
      await _initPrefs();
      final jsonString = json.encode(settings);
      await _prefs!.setString(_securitySettingsKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save security settings: $e');
    }
  }

  Future<Map<String, dynamic>> getSecuritySettings() async {
    try {
      await _initPrefs();
      final jsonString = _prefs!.getString(_securitySettingsKey);
      if (jsonString != null) {
        return Map<String, dynamic>.from(json.decode(jsonString));
      }
      return {};
    } catch (e) {
      throw Exception('Failed to get security settings: $e');
    }
  }

  // Cache management
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    try {
      await _initPrefs();
      final cacheData = await getCacheData();
      cacheData[key] = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      final jsonString = json.encode(cacheData);
      await _prefs!.setString(_cacheKey, jsonString);
    } catch (e) {
      throw Exception('Failed to cache data: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedData(String key, {Duration? maxAge}) async {
    try {
      await _initPrefs();
      final cacheData = await getCacheData();
      final cachedItem = cacheData[key];
      
      if (cachedItem != null) {
        final timestamp = DateTime.parse(cachedItem['timestamp']);
        final age = DateTime.now().difference(timestamp);
        
        if (maxAge == null || age <= maxAge) {
          return Map<String, dynamic>.from(cachedItem['data']);
        } else {
          // Remove expired cache
          await removeCachedData(key);
        }
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get cached data: $e');
    }
  }

  Future<Map<String, dynamic>> getCacheData() async {
    try {
      await _initPrefs();
      final jsonString = _prefs!.getString(_cacheKey);
      if (jsonString != null) {
        return Map<String, dynamic>.from(json.decode(jsonString));
      }
      return {};
    } catch (e) {
      throw Exception('Failed to get cache data: $e');
    }
  }

  Future<void> removeCachedData(String key) async {
    try {
      await _initPrefs();
      final cacheData = await getCacheData();
      cacheData.remove(key);
      final jsonString = json.encode(cacheData);
      await _prefs!.setString(_cacheKey, jsonString);
    } catch (e) {
      throw Exception('Failed to remove cached data: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      await _initPrefs();
      await _prefs!.remove(_cacheKey);
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  // Theme settings
  Future<void> saveThemeMode(String themeMode) async {
    try {
      await _initPrefs();
      await _prefs!.setString('theme_mode', themeMode);
    } catch (e) {
      throw Exception('Failed to save theme mode: $e');
    }
  }

  Future<String?> getThemeMode() async {
    try {
      await _initPrefs();
      return _prefs!.getString('theme_mode');
    } catch (e) {
      throw Exception('Failed to get theme mode: $e');
    }
  }

  // Biometric settings
  Future<void> saveBiometricEnabled(bool enabled) async {
    try {
      await _initPrefs();
      await _prefs!.setBool('biometric_enabled', enabled);
    } catch (e) {
      throw Exception('Failed to save biometric setting: $e');
    }
  }

  Future<bool> getBiometricEnabled() async {
    try {
      await _initPrefs();
      return _prefs!.getBool('biometric_enabled') ?? false;
    } catch (e) {
      throw Exception('Failed to get biometric setting: $e');
    }
  }

  // Notification settings
  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    try {
      await _initPrefs();
      for (final entry in settings.entries) {
        await _prefs!.setBool('notification_${entry.key}', entry.value);
      }
    } catch (e) {
      throw Exception('Failed to save notification settings: $e');
    }
  }

  Future<Map<String, bool>> getNotificationSettings() async {
    try {
      await _initPrefs();
      final keys = _prefs!.getKeys().where((key) => key.startsWith('notification_'));
      final settings = <String, bool>{};
      
      for (final key in keys) {
        final settingKey = key.replaceFirst('notification_', '');
        settings[settingKey] = _prefs!.getBool(key) ?? true;
      }
      
      return settings;
    } catch (e) {
      throw Exception('Failed to get notification settings: $e');
    }
  }

  // PIN/Password storage (encrypted in production)
  Future<void> savePIN(String pin) async {
    try {
      await _initPrefs();
      // In production, this should be encrypted
      await _prefs!.setString('user_pin', pin);
    } catch (e) {
      throw Exception('Failed to save PIN: $e');
    }
  }

  Future<String?> getPIN() async {
    try {
      await _initPrefs();
      return _prefs!.getString('user_pin');
    } catch (e) {
      throw Exception('Failed to get PIN: $e');
    }
  }

  Future<void> removePIN() async {
    try {
      await _initPrefs();
      await _prefs!.remove('user_pin');
    } catch (e) {
      throw Exception('Failed to remove PIN: $e');
    }
  }

  // Last login tracking
  Future<void> saveLastLogin(DateTime dateTime) async {
    try {
      await _initPrefs();
      await _prefs!.setString('last_login', dateTime.toIso8601String());
    } catch (e) {
      throw Exception('Failed to save last login: $e');
    }
  }

  Future<DateTime?> getLastLogin() async {
    try {
      await _initPrefs();
      final dateString = _prefs!.getString('last_login');
      return dateString != null ? DateTime.parse(dateString) : null;
    } catch (e) {
      throw Exception('Failed to get last login: $e');
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      await _initPrefs();
      await _prefs!.clear();
    } catch (e) {
      throw Exception('Failed to clear all data: $e');
    }
  }

  // Check if first time user
  Future<bool> isFirstTimeUser() async {
    try {
      await _initPrefs();
      return _prefs!.getBool('first_time_user') ?? true;
    } catch (e) {
      throw Exception('Failed to check first time user: $e');
    }
  }

  Future<void> setFirstTimeUser(bool isFirstTime) async {
    try {
      await _initPrefs();
      await _prefs!.setBool('first_time_user', isFirstTime);
    } catch (e) {
      throw Exception('Failed to set first time user: $e');
    }
  }

  // App version tracking
  Future<void> saveAppVersion(String version) async {
    try {
      await _initPrefs();
      await _prefs!.setString('app_version', version);
    } catch (e) {
      throw Exception('Failed to save app version: $e');
    }
  }

  Future<String?> getAppVersion() async {
    try {
      await _initPrefs();
      return _prefs!.getString('app_version');
    } catch (e) {
      throw Exception('Failed to get app version: $e');
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
