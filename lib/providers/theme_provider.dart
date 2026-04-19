// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  String _themeMode = 'system';
  final StorageService _storage;

  ThemeProvider(this._storage);

  String get themeMode => _themeMode;

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  Future<void> loadTheme() async {
    _themeMode = await _storage.loadThemeMode();
    notifyListeners();
  }

  Future<void> setTheme(String mode) async {
    _themeMode = mode;
    await _storage.saveThemeMode(mode);
    notifyListeners();
  }
}
