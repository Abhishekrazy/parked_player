
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum ViewMode { grid, list }

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  
  ViewMode _viewMode = ViewMode.grid;
  ViewMode get viewMode => _viewMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  bool _isIncognito = false;
  bool get isIncognito => _isIncognito;

  bool _isDesktopMode = false;
  bool get isDesktopMode => _isDesktopMode;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('themeMode');
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeString,
        orElse: () => ThemeMode.system,
      );
    }
    
    final viewModeString = prefs.getString('viewMode');
    if (viewModeString != null) {
      _viewMode = ViewMode.values.firstWhere(
        (e) => e.toString() == viewModeString,
        orElse: () => ViewMode.grid,
      );
    }

    _isDesktopMode = prefs.getBool('isDesktopMode') ?? false;
    
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString());
    notifyListeners();
  }
  
  Future<void> updateViewMode(ViewMode mode) async {
    _viewMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('viewMode', mode.toString());
    notifyListeners();
  }

  void toggleIncognito() {
    _isIncognito = !_isIncognito;
    notifyListeners();
  }

  Future<void> toggleDesktopMode(bool value) async {
    _isDesktopMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDesktopMode', value);
    notifyListeners();
  }
}
