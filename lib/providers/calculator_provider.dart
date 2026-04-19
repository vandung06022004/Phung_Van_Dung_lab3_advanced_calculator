// lib/providers/calculator_provider.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/calculator_mode.dart';
import '../models/calculator_settings.dart';
import '../services/storage_service.dart';
import '../utils/calculator_logic.dart';
import '../utils/expression_parser.dart';

class CalculatorProvider extends ChangeNotifier {
  String _expression = '';
  String _display = '0';
  String _previousResult = '';
  bool _hasError = false;
  bool _justEvaluated = false;

  CalculatorMode _mode = CalculatorMode.basic;
  AngleMode _angleMode = AngleMode.degrees;
  double _memory = 0.0;
  bool _memoryHasValue = false;
  bool _isSecondFunction = false;

  // Programmer mode
  int _programmerBase = 10; // 2, 8, 10, 16

  CalculatorSettings _settings = CalculatorSettings();
  final StorageService _storage;

  CalculatorProvider(this._storage);

  String get expression => _expression;
  String get display => _display;
  String get previousResult => _previousResult;
  bool get hasError => _hasError;
  CalculatorMode get mode => _mode;
  AngleMode get angleMode => _angleMode;
  bool get memoryHasValue => _memoryHasValue;
  bool get isSecondFunction => _isSecondFunction;
  int get programmerBase => _programmerBase;
  CalculatorSettings get settings => _settings;

  Future<void> initialize() async {
    _settings = await _storage.loadSettings();
    _mode = await _storage.loadCalculatorMode();
    _memory = await _storage.loadMemory();
    _memoryHasValue = _memory != 0.0;
    _angleMode = _settings.angleMode;
    notifyListeners();
  }

  void setMode(CalculatorMode mode) {
    _mode = mode;
    clear();
    _storage.saveCalculatorMode(mode);
    notifyListeners();
  }

  void toggleAngleMode() {
    _angleMode = _angleMode == AngleMode.degrees ? AngleMode.radians : AngleMode.degrees;
    notifyListeners();
  }

  void toggleSecondFunction() {
    _isSecondFunction = !_isSecondFunction;
    notifyListeners();
  }

  void setProgrammerBase(int base) {
    _programmerBase = base;
    notifyListeners();
  }

  void inputDigit(String digit) {
    _hasError = false;
    if (_justEvaluated) {
      // Start fresh expression after evaluation, unless it's an operator
      _expression = digit;
      _display = digit;
      _justEvaluated = false;
    } else {
      if (_display == '0' && digit != '.') {
        _expression = _expression.isEmpty ? digit : _expression.substring(0, _expression.length - 1) + digit;
        _display = digit;
      } else {
        _expression += digit;
        _display += digit;
      }
    }
    notifyListeners();
  }

  void inputDecimal() {
    if (_justEvaluated) {
      _expression = '0.';
      _display = '0.';
      _justEvaluated = false;
      notifyListeners();
      return;
    }
    // Only add if current number doesn't already have a decimal
    final lastNumber = _expression.split(RegExp(r'[+\-*/()]')).last;
    if (!lastNumber.contains('.')) {
      if (_display.isEmpty || _display == '0') {
        _expression = _expression.isEmpty ? '0.' : _expression + '0.';
        _display = '0.';
      } else {
        _expression += '.';
        _display += '.';
      }
      notifyListeners();
    }
  }

  void inputOperator(String op) {
    _hasError = false;
    _justEvaluated = false;

    if (_expression.isEmpty) {
      if (op == '-') {
        _expression = '-';
        _display = '-';
      }
      notifyListeners();
      return;
    }

    // Replace last operator if expression ends with one
    if (_expression.isNotEmpty && '+-*/'.contains(_expression[_expression.length - 1])) {
      _expression = _expression.substring(0, _expression.length - 1) + op;
    } else {
      _expression += op;
    }
    _display = _expression;
    notifyListeners();
  }

  void inputFunction(String fn) {
    _hasError = false;
    if (_justEvaluated && _previousResult.isNotEmpty) {
      // Apply function to current result
      _expression = '$fn($_previousResult)';
    } else {
      _expression += '$fn(';
    }
    _display = _expression;
    _justEvaluated = false;
    notifyListeners();
  }

  void inputConstant(String constant) {
    _hasError = false;
    double value = constant == 'π' ? math.pi : math.e;
    String strVal = CalculatorLogic.formatResult(value, _settings.decimalPrecision);
    if (_justEvaluated) {
      _expression = strVal;
      _display = constant;
      _justEvaluated = false;
    } else {
      _expression += strVal;
      _display += constant;
    }
    notifyListeners();
  }

  void inputParenthesis(String paren) {
    _hasError = false;
    _justEvaluated = false;
    _expression += paren;
    _display = _expression;
    notifyListeners();
  }

  void evaluate(HistoryCallback? onHistory) {
    if (_expression.isEmpty) return;

    final parser = ExpressionParser(
      angleMode: _angleMode,
      precision: _settings.decimalPrecision,
    );

    // Auto-close unclosed parentheses
    int openCount = _expression.split('(').length - 1;
    int closeCount = _expression.split(')').length - 1;
    String evalExpr = _expression + ')' * (openCount - closeCount);

    String result = parser.evaluate(evalExpr);

    if (result == 'Error') {
      _hasError = true;
      _display = 'Error';
    } else {
      onHistory?.call(_expression, result);
      _previousResult = result;
      _display = result;
      _expression = result;
      _justEvaluated = true;
    }
    notifyListeners();
  }

  void clear() {
    _expression = '';
    _display = '0';
    _previousResult = '';
    _hasError = false;
    _justEvaluated = false;
    notifyListeners();
  }

  void clearEntry() {
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
      _display = _expression.isEmpty ? '0' : _expression;
    }
    _hasError = false;
    _justEvaluated = false;
    notifyListeners();
  }

  void percentage() {
    if (_expression.isEmpty) return;
    final parser = ExpressionParser(angleMode: _angleMode, precision: _settings.decimalPrecision);
    String result = parser.evaluate(_expression);
    if (result != 'Error') {
      double val = double.tryParse(result) ?? 0;
      String pct = CalculatorLogic.formatResult(val / 100, _settings.decimalPrecision);
      _expression = pct;
      _display = pct;
      notifyListeners();
    }
  }

  void toggleSign() {
    if (_expression.startsWith('-')) {
      _expression = _expression.substring(1);
    } else if (_expression.isNotEmpty) {
      _expression = '-$_expression';
    }
    _display = _expression.isEmpty ? '0' : _expression;
    notifyListeners();
  }

  void factorial() {
    final parser = ExpressionParser(angleMode: _angleMode, precision: _settings.decimalPrecision);
    String result = parser.evaluate(_expression);
    if (result != 'Error') {
      double val = double.tryParse(result) ?? 0;
      if (val >= 0 && val == val.truncateToDouble() && val <= 170) {
        double fact = CalculatorLogic.factorial(val.toInt());
        String factStr = CalculatorLogic.formatResult(fact, _settings.decimalPrecision);
        _previousResult = factStr;
        _display = factStr;
        _expression = factStr;
        _justEvaluated = true;
        notifyListeners();
      }
    }
  }

  // Memory functions
  void memoryAdd() {
    final parser = ExpressionParser(angleMode: _angleMode, precision: _settings.decimalPrecision);
    String result = parser.evaluate(_expression);
    double? val = double.tryParse(result);
    if (val != null) {
      _memory += val;
      _memoryHasValue = true;
      _storage.saveMemory(_memory);
      notifyListeners();
    }
  }

  void memorySubtract() {
    final parser = ExpressionParser(angleMode: _angleMode, precision: _settings.decimalPrecision);
    String result = parser.evaluate(_expression);
    double? val = double.tryParse(result);
    if (val != null) {
      _memory -= val;
      _memoryHasValue = _memory != 0.0;
      _storage.saveMemory(_memory);
      notifyListeners();
    }
  }

  void memoryRecall() {
    String memStr = CalculatorLogic.formatResult(_memory, _settings.decimalPrecision);
    _expression = memStr;
    _display = memStr;
    _justEvaluated = false;
    notifyListeners();
  }

  void memoryClear() {
    _memory = 0.0;
    _memoryHasValue = false;
    _storage.saveMemory(0.0);
    notifyListeners();
  }

  // Programmer mode bitwise operations
  void bitwiseOperation(String op) {
    final parser = ExpressionParser(angleMode: _angleMode, precision: _settings.decimalPrecision);
    String result = parser.evaluate(_expression);
    double? val = double.tryParse(result);
    if (val != null) {
      int intVal = val.toInt();
      _expression += ' $op ';
      _display = _expression;
      _justEvaluated = false;
      notifyListeners();
    }
  }

  void updateSettings(CalculatorSettings settings) {
    _settings = settings;
    _angleMode = settings.angleMode;
    _storage.saveSettings(settings);
    notifyListeners();
  }

  void deleteLastChar() {
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
      _display = _expression.isEmpty ? '0' : _expression;
      _hasError = false;
      _justEvaluated = false;
      notifyListeners();
    }
  }

  void useHistoryResult(String result) {
    _expression = result;
    _display = result;
    _justEvaluated = true;
    notifyListeners();
  }
}

typedef HistoryCallback = void Function(String expression, String result);
