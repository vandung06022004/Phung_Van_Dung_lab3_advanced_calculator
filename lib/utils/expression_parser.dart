// lib/utils/expression_parser.dart
import 'dart:math' as math;
import '../models/calculator_mode.dart';
import 'calculator_logic.dart';

class ExpressionParser {
  final AngleMode angleMode;
  final int precision;

  ExpressionParser({
    this.angleMode = AngleMode.degrees,
    this.precision = 6,
  });

  /// Parses and evaluates a mathematical expression string.
  String evaluate(String expression) {
    try {
      // Preprocess
      String expr = _preprocess(expression);
      double result = _parseExpression(expr, 0).value;
      return CalculatorLogic.formatResult(result, precision);
    } catch (e) {
      return 'Error';
    }
  }

  String _preprocess(String expr) {
    return expr
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('π', '${math.pi}')
        .replaceAll('e', '${math.e}')
        // Implicit multiplication: 2π -> 2*π, 2( -> 2*(
        .replaceAllMapped(RegExp(r'(\d)(\()'), (m) => '${m[1]}*(${m[2]}')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .trim();
  }

  _ParseResult _parseExpression(String expr, int pos) {
    return _parseAddSub(expr, pos);
  }

  _ParseResult _parseAddSub(String expr, int pos) {
    var left = _parseMulDiv(expr, pos);
    pos = left.pos;

    while (pos < expr.length && (expr[pos] == '+' || expr[pos] == '-')) {
      // Check it's not a unary minus
      String op = expr[pos];
      pos++;
      var right = _parseMulDiv(expr, pos);
      pos = right.pos;
      if (op == '+') {
        left = _ParseResult(left.value + right.value, pos);
      } else {
        left = _ParseResult(left.value - right.value, pos);
      }
    }
    return left;
  }

  _ParseResult _parseMulDiv(String expr, int pos) {
    var left = _parsePow(expr, pos);
    pos = left.pos;

    while (pos < expr.length && (expr[pos] == '*' || expr[pos] == '/')) {
      String op = expr[pos];
      pos++;
      var right = _parsePow(expr, pos);
      pos = right.pos;
      if (op == '*') {
        left = _ParseResult(left.value * right.value, pos);
      } else {
        if (right.value == 0) throw Exception('Division by zero');
        left = _ParseResult(left.value / right.value, pos);
      }
    }
    return left;
  }

  _ParseResult _parsePow(String expr, int pos) {
    var base = _parseUnary(expr, pos);
    pos = base.pos;

    if (pos < expr.length && expr[pos] == '^') {
      pos++;
      var exp = _parsePow(expr, pos); // right-associative
      return _ParseResult(math.pow(base.value, exp.value).toDouble(), exp.pos);
    }
    return base;
  }

  _ParseResult _parseUnary(String expr, int pos) {
    // Skip whitespace
    while (pos < expr.length && expr[pos] == ' ') pos++;

    if (pos < expr.length && expr[pos] == '-') {
      pos++;
      var val = _parseUnary(expr, pos);
      return _ParseResult(-val.value, val.pos);
    }
    if (pos < expr.length && expr[pos] == '+') {
      pos++;
      return _parseUnary(expr, pos);
    }

    return _parseAtom(expr, pos);
  }

  _ParseResult _parseAtom(String expr, int pos) {
    // Skip whitespace
    while (pos < expr.length && expr[pos] == ' ') pos++;

    // Parentheses
    if (pos < expr.length && expr[pos] == '(') {
      pos++;
      var val = _parseExpression(expr, pos);
      pos = val.pos;
      while (pos < expr.length && expr[pos] == ' ') pos++;
      if (pos < expr.length && expr[pos] == ')') pos++;
      return _ParseResult(val.value, pos);
    }

    // Functions
    final functions = ['sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'ln', 'log', 'sqrt', 'cbrt', 'abs'];
    for (String fn in functions) {
      if (expr.substring(pos).startsWith(fn)) {
        int fnEnd = pos + fn.length;
        // skip whitespace
        while (fnEnd < expr.length && expr[fnEnd] == ' ') fnEnd++;
        if (fnEnd < expr.length && expr[fnEnd] == '(') {
          fnEnd++;
          var arg = _parseExpression(expr, fnEnd);
          fnEnd = arg.pos;
          while (fnEnd < expr.length && expr[fnEnd] == ' ') fnEnd++;
          if (fnEnd < expr.length && expr[fnEnd] == ')') fnEnd++;
          double result = _applyFunction(fn, arg.value);
          return _ParseResult(result, fnEnd);
        }
      }
    }

    // Number
    int start = pos;
    if (pos < expr.length && expr[pos] == '.') {
      // number starting with decimal
    }
    while (pos < expr.length && (RegExp(r'[0-9.]').hasMatch(expr[pos]))) {
      pos++;
    }

    if (pos == start) throw Exception('Unexpected character at position $pos');

    double value = double.parse(expr.substring(start, pos));
    return _ParseResult(value, pos);
  }

  double _applyFunction(String fn, double arg) {
    switch (fn) {
      case 'sin': return CalculatorLogic.sin(arg, angleMode);
      case 'cos': return CalculatorLogic.cos(arg, angleMode);
      case 'tan': return CalculatorLogic.tan(arg, angleMode);
      case 'asin': return CalculatorLogic.asin(arg, angleMode);
      case 'acos': return CalculatorLogic.acos(arg, angleMode);
      case 'atan': return CalculatorLogic.atan(arg, angleMode);
      case 'ln': return CalculatorLogic.ln(arg);
      case 'log': return CalculatorLogic.log10(arg);
      case 'sqrt': return CalculatorLogic.sqrt(arg);
      case 'cbrt': return CalculatorLogic.cbrt(arg);
      case 'abs': return arg.abs();
      default: throw Exception('Unknown function: $fn');
    }
  }
}

class _ParseResult {
  final double value;
  final int pos;
  _ParseResult(this.value, this.pos);
}
