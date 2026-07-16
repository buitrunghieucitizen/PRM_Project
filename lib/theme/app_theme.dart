import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _showDetailedAmount = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get showDetailedAmount => _showDetailedAmount;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  void toggleDetailedAmount(bool isOn) {
    _showDetailedAmount = isOn;
    _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _showDetailedAmount = prefs.getBool('showDetailedAmount') ?? false;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    await prefs.setBool('showDetailedAmount', _showDetailedAmount);
  }
}

class AppTheme {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Color(0xFF666666),
      surface: Colors.white,
      onSurface: Colors.black,
      error: Colors.black,
    ),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Color(0xFF333333)),
      bodySmall: TextStyle(color: Color(0xFF666666)),
    ),
    dividerColor: const Color(0xFFE5E5E5),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: const Color(0xFF111111),
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Color(0xFF999999),
      surface: Color(0xFF1A1A1A),
      onSurface: Colors.white,
      error: Colors.white,
    ),
    cardColor: const Color(0xFF1A1A1A),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Color(0xFFCCCCCC)),
      bodySmall: TextStyle(color: Color(0xFF999999)),
    ),
    dividerColor: const Color(0xFF333333),
  );
}
