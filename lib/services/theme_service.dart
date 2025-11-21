import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { light, modern, beautifulDark, succulentBlue }

class ThemeService {
  static const String _themeKey = 'app_theme';
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setTheme(AppTheme theme) async {
    await _prefs.setString(_themeKey, theme.toString());
  }

  static AppTheme getTheme() {
    final theme = _prefs.getString(_themeKey) ?? AppTheme.light.toString();
    return AppTheme.values.firstWhere(
      (e) => e.toString() == theme,
      orElse: () => AppTheme.light,
    );
  }

  static ThemeData getThemeData(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return _lightTheme();
      case AppTheme.modern:
        return _modernTheme();
      case AppTheme.beautifulDark:
        return _beautifulDarkTheme();
      case AppTheme.succulentBlue:
        return _succulentBlueTheme();
    }
  }

  static ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.pink,
      primaryColor: Colors.pinkAccent,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData _modernTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF6A5ACD),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF6A5ACD),
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6A5ACD),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData _beautifulDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF1A1A2E),
      scaffoldBackgroundColor: const Color(0xFF0F3460),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE94560),
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFE94560),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF16213E),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData _succulentBlueTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF1B3A57),
      scaffoldBackgroundColor: const Color(0xFF0D1F2D),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B3A57),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00B4D8),
          foregroundColor: Colors.black,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF00B4D8),
        foregroundColor: Colors.black,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E4A68),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x3300B4D8),
        selectedColor: const Color(0xFF00B4D8),
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
