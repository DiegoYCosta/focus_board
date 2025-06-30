import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType { light, dark, green, grey }

class ThemeManager with ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.light;

  AppThemeType get current => _currentTheme;

  ThemeData get themeData {
    switch (_currentTheme) {
      case AppThemeType.dark:
        return _darkTheme;
      case AppThemeType.green:
        return _greenTheme;
      case AppThemeType.grey:
        return _greyTheme;
      case AppThemeType.light:
      default:
        return _lightTheme;
    }
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('theme') ?? 0;
    _currentTheme = AppThemeType.values[index];
    notifyListeners();
  }

  Future<void> setTheme(AppThemeType theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme', theme.index);
    notifyListeners();
  }

  bool get isDark => _currentTheme == AppThemeType.dark;
}

// === DEFINIÇÕES DE TEMAS ===

final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.indigo,
  scaffoldBackgroundColor: Colors.grey[100],
);

final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.grey[900],
  appBarTheme: AppBarTheme(backgroundColor: Colors.black),
);

final ThemeData _greenTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Color(0xFFEDF1E5),
  appBarTheme: AppBarTheme(backgroundColor: Color(0xFF7A8D63)),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF6B7C54),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF7A8D63)),
  ),
  cardColor: Color(0xFFD5D9C2),
);

final ThemeData _greyTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Color(0xFFE6E6E6),
  appBarTheme: AppBarTheme(backgroundColor: Colors.grey[700]),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.grey[800],
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
  ),
  cardColor: Colors.grey[300],
);
