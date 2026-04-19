// test/integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:advanced_calculator/main.dart';
import 'package:advanced_calculator/services/storage_service.dart';
import 'package:advanced_calculator/providers/calculator_provider.dart';
import 'package:advanced_calculator/providers/theme_provider.dart';
import 'package:advanced_calculator/providers/history_provider.dart';
import 'package:advanced_calculator/models/calculator_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget buildTestApp(StorageService storage) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider(storage)..loadTheme()),
      ChangeNotifierProvider(create: (_) => HistoryProvider(storage)..loadHistory()),
      ChangeNotifierProvider(create: (_) => CalculatorProvider(storage)..initialize()),
    ],
    child: MaterialApp(
      home: Builder(builder: (context) => const Scaffold(body: Text('Test'))),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  group('CalculatorProvider Integration', () {
    late StorageService storage;
    late CalculatorProvider calc;
    late HistoryProvider history;

    setUp(() async {
      storage = StorageService();
      calc = CalculatorProvider(storage);
      history = HistoryProvider(storage);
      await calc.initialize();
    });

    test('Button press sequence: 5 + 3 = 8', () {
      calc.inputDigit('5');
      calc.inputOperator('+');
      calc.inputDigit('3');
      calc.evaluate((expr, result) => history.addEntry(expr, result));
      expect(calc.display, '8');
    });

    test('Chain calculations: 5 + 3 = + 2 = + 1 = 11', () {
      calc.inputDigit('5');
      calc.inputOperator('+');
      calc.inputDigit('3');
      calc.evaluate((expr, result) {});
      // display = 8, now + 2
      calc.inputOperator('+');
      calc.inputDigit('2');
      calc.evaluate((expr, result) {});
      // display = 10, now + 1
      calc.inputOperator('+');
      calc.inputDigit('1');
      calc.evaluate((expr, result) {});
      expect(calc.display, '11');
    });

    test('Mode switching resets expression', () {
      calc.inputDigit('5');
      calc.inputDigit('5');
      expect(calc.display, '55');
      calc.setMode(calc.mode == CalculatorMode.basic
          ? CalculatorMode.scientific
          : CalculatorMode.basic);
      expect(calc.display, '0');
    });

    test('Memory: M+ 5, M+ 3, MR = 8', () {
      // Input 5, M+
      calc.inputDigit('5');
      calc.memoryAdd();
      calc.clear();

      // Input 3, M+
      calc.inputDigit('3');
      calc.memoryAdd();
      calc.clear();

      // MR
      calc.memoryRecall();
      expect(calc.display, '8');
    });

    test('Memory: MC clears memory', () {
      calc.inputDigit('9');
      calc.memoryAdd();
      calc.memoryClear();
      expect(calc.memoryHasValue, false);
    });

    test('Toggle sign: +5 -> -5', () {
      calc.inputDigit('5');
      calc.toggleSign();
      expect(calc.expression.startsWith('-'), true);
    });

    test('Percentage: 200 % = 2', () {
      calc.inputDigit('2');
      calc.inputDigit('0');
      calc.inputDigit('0');
      calc.percentage();
      expect(calc.display, '2');
    });

    test('Clear entry removes last char', () {
      calc.inputDigit('1');
      calc.inputDigit('2');
      calc.inputDigit('3');
      calc.clearEntry();
      expect(calc.expression, '12');
    });

    test('History saves entry after evaluation', () async {
      calc.inputDigit('7');
      calc.inputOperator('+');
      calc.inputDigit('3');
      calc.evaluate((expr, result) => history.addEntry(expr, result));
      expect(history.history.isNotEmpty, true);
      expect(history.history.first.result, '10');
    });
  });
}

// Import required for mode enum

