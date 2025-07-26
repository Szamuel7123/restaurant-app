import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  static const String _isDarkModeKey = 'is_dark_mode';

  // Get theme mode from preferences
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);

    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeString;

    switch (themeMode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }

    await prefs.setString(_themeKey, themeString);
  }

  // Get is dark mode preference
  Future<bool> getIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isDarkModeKey) ?? false;
  }

  // Set is dark mode preference
  Future<void> setIsDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, isDarkMode);
  }

  // Load theme preference
  Future<void> loadThemePreference() async {
    // This method can be used to load any additional theme preferences
    // For now, we just ensure the preferences are initialized
    await getThemeMode();
    await getIsDarkMode();
  }

  // Toggle between light and dark mode
  Future<ThemeMode> toggleTheme() async {
    final currentMode = await getThemeMode();
    ThemeMode newMode;

    switch (currentMode) {
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.light;
        break;
      case ThemeMode.system:
        // If system mode, switch to light
        newMode = ThemeMode.light;
        break;
    }

    await setThemeMode(newMode);
    return newMode;
  }

  // Check if system is in dark mode
  bool isSystemDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  // Get effective theme mode (considering system preference)
  ThemeMode getEffectiveThemeMode(ThemeMode themeMode, BuildContext context) {
    if (themeMode == ThemeMode.system) {
      return isSystemDarkMode(context) ? ThemeMode.dark : ThemeMode.light;
    }
    return themeMode;
  }
}
