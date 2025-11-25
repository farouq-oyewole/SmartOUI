// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      state = ThemeMode.values[themeIndex];
    } catch (e) {
      state = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
      state = mode;
    } catch (e) {
      // ignore silently
    }
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  Future<void> setLightMode() async => setThemeMode(ThemeMode.light);
  Future<void> setDarkMode() async => setThemeMode(ThemeMode.dark);
  Future<void> setSystemMode() async => setThemeMode(ThemeMode.system);
}

// Convenience providers
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return themeMode == ThemeMode.dark;
});

final isLightModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return themeMode == ThemeMode.light;
});

final isSystemModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return themeMode == ThemeMode.system;
});

// ✅ Pure White Light Theme
final lightThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.grey,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black87,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Colors.black.withOpacity(0.1),
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(color: Colors.black87),
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: Colors.black87,
      secondary: Colors.grey,
      surface: Colors.white,
      background: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.black87, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
});

// Dark Theme (unchanged)
final darkThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.grey,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.grey[900],
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey[500],
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.grey[900],
      indicatorColor: Colors.white.withOpacity(0.1),
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(color: Colors.white),
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.white,
      brightness: Brightness.dark,
      primary: Colors.white,
      secondary: Colors.grey,
      surface: Colors.grey[850]!,
      background: Colors.grey[900]!,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[600]!),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[800],
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
});
