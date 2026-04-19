// lib/utils/calculator_logic.dart
import 'dart:math' as math;
import '../models/calculator_mode.dart';

class CalculatorLogic {
  static double factorial(int n) {
    if (n < 0) throw ArgumentError('Factorial of negative number');
    if (n == 0 || n == 1) return 1;
    double result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  static double toDegrees(double radians) => radians * 180 / math.pi;
  static double toRadians(double degrees) => degrees * math.pi / 180;

  static double sin(double value, AngleMode mode) {
    final rad = mode == AngleMode.degrees ? toRadians(value) : value;
    return math.sin(rad);
  }

  static double cos(double value, AngleMode mode) {
    final rad = mode == AngleMode.degrees ? toRadians(value) : value;
    return math.cos(rad);
  }

  static double tan(double value, AngleMode mode) {
    final rad = mode == AngleMode.degrees ? toRadians(value) : value;
    return math.tan(rad);
  }

  static double asin(double value, AngleMode mode) {
    final result = math.asin(value);
    return mode == AngleMode.degrees ? toDegrees(result) : result;
  }

  static double acos(double value, AngleMode mode) {
    final result = math.acos(value);
    return mode == AngleMode.degrees ? toDegrees(result) : result;
  }

  static double atan(double value, AngleMode mode) {
    final result = math.atan(value);
    return mode == AngleMode.degrees ? toDegrees(result) : result;
  }

  static double log10(double value) => math.log(value) / math.ln10;
  static double log2(double value) => math.log(value) / math.ln2;
  static double ln(double value) => math.log(value);

  static double sqrt(double value) => math.sqrt(value);
  static double cbrt(double value) => math.pow(value, 1 / 3).toDouble();
  static double pow(double base, double exp) => math.pow(base, exp).toDouble();

  static String formatResult(double value, int precision) {
    if (value.isNaN) return 'Error';
    if (value.isInfinite) return value > 0 ? '∞' : '-∞';

    // If integer, don't show decimals
    if (value == value.truncateToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }

    // Use scientific notation for very large/small numbers
    if (value.abs() >= 1e15 || (value.abs() < 1e-6 && value != 0)) {
      return value.toStringAsExponential(precision);
    }

    // Format with precision
    String formatted = value.toStringAsFixed(precision);
    // Remove trailing zeros
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }
    return formatted;
  }

  // Programmer mode operations
  static int bitwiseAnd(int a, int b) => a & b;
  static int bitwiseOr(int a, int b) => a | b;
  static int bitwiseXor(int a, int b) => a ^ b;
  static int bitwiseNot(int a) => ~a;
  static int shiftLeft(int a, int b) => a << b;
  static int shiftRight(int a, int b) => a >> b;

  static String toBinary(int value) => value.toRadixString(2);
  static String toOctal(int value) => value.toRadixString(8);
  static String toHex(int value) => value.toRadixString(16).toUpperCase();
  static int fromBinary(String s) => int.parse(s, radix: 2);
  static int fromOctal(String s) => int.parse(s, radix: 8);
  static int fromHex(String s) => int.parse(s, radix: 16);
}
