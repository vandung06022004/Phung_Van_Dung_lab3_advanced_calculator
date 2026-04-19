// lib/providers/history_provider.dart
import 'package:flutter/material.dart';
import '../models/calculation_history.dart';
import '../services/storage_service.dart';

class HistoryProvider extends ChangeNotifier {
  List<CalculationHistory> _history = [];
  final StorageService _storage;
  int _maxSize = 50;

  HistoryProvider(this._storage);

  List<CalculationHistory> get history => List.unmodifiable(_history);

  Future<void> loadHistory() async {
    _history = await _storage.loadHistory();
    notifyListeners();
  }

  Future<void> addEntry(String expression, String result) async {
    final entry = CalculationHistory(
      expression: expression,
      result: result,
      timestamp: DateTime.now(),
    );
    _history.insert(0, entry);
    if (_history.length > _maxSize) {
      _history = _history.take(_maxSize).toList();
    }
    await _storage.saveHistory(_history);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history = [];
    await _storage.clearHistory();
    notifyListeners();
  }

  void setMaxSize(int size) {
    _maxSize = size;
  }

  List<CalculationHistory> get recentThree => _history.take(3).toList();
}
