// lib/services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_history.dart';
import '../models/calculator_mode.dart';
import '../models/calculator_settings.dart';

class StorageService {
  static const _historyKey = 'calculation_history';
  static const _themeModeKey = 'theme_mode';
  static const _calculatorModeKey = 'calculator_mode';
  static const _memoryKey = 'memory_value';
  static const _angleModeKey = 'angle_mode';
  static const _precisionKey = 'decimal_precision';
  static const _hapticKey = 'haptic_feedback';
  static const _soundKey = 'sound_effects';
  static const _historySizeKey = 'history_size';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> saveHistory(List<CalculationHistory> history) async {
    final prefs = await _prefs;
    await prefs.setString(_historyKey, CalculationHistory.encodeList(history));
  }

  Future<List<CalculationHistory>> loadHistory() async {
    final prefs = await _prefs;
    final data = prefs.getString(_historyKey);
    if (data == null) return [];
    try {
      return CalculationHistory.decodeList(data);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(_themeModeKey, mode);
  }

  Future<String> loadThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  Future<void> saveCalculatorMode(CalculatorMode mode) async {
    final prefs = await _prefs;
    await prefs.setInt(_calculatorModeKey, mode.index);
  }

  Future<CalculatorMode> loadCalculatorMode() async {
    final prefs = await _prefs;
    final index = prefs.getInt(_calculatorModeKey) ?? 0;
    return CalculatorMode.values[index];
  }

  Future<void> saveMemory(double value) async {
    final prefs = await _prefs;
    await prefs.setDouble(_memoryKey, value);
  }

  Future<double> loadMemory() async {
    final prefs = await _prefs;
    return prefs.getDouble(_memoryKey) ?? 0.0;
  }

  Future<void> saveSettings(CalculatorSettings settings) async {
    final prefs = await _prefs;
    await prefs.setString(_themeModeKey, settings.themeMode);
    await prefs.setInt(_angleModeKey, settings.angleMode.index);
    await prefs.setInt(_precisionKey, settings.decimalPrecision);
    await prefs.setBool(_hapticKey, settings.hapticFeedback);
    await prefs.setBool(_soundKey, settings.soundEffects);
    await prefs.setInt(_historySizeKey, settings.historySize);
  }

  Future<CalculatorSettings> loadSettings() async {
    final prefs = await _prefs;
    return CalculatorSettings(
      themeMode: prefs.getString(_themeModeKey) ?? 'system',
      angleMode: AngleMode.values[prefs.getInt(_angleModeKey) ?? 0],
      decimalPrecision: prefs.getInt(_precisionKey) ?? 6,
      hapticFeedback: prefs.getBool(_hapticKey) ?? true,
      soundEffects: prefs.getBool(_soundKey) ?? false,
      historySize: prefs.getInt(_historySizeKey) ?? 50,
    );
  }

  Future<void> clearHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_historyKey);
  }
}
