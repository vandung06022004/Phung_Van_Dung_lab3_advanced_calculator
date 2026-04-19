// test/calculator_test.dart
// Run: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_calculator/main.dart';

void main() {
  // ─── Basic Arithmetic ────────────────────────────────────────
  group('Basic Arithmetic', () {
    test('2 + 3 = 5', () => expect(CalcLogic.evaluate('2+3'), '5'));
    test('10 - 4 = 6', () => expect(CalcLogic.evaluate('10-4'), '6'));
    test('6 × 7 = 42', () => expect(CalcLogic.evaluate('6×7'), '42'));
    test('15 ÷ 3 = 5', () => expect(CalcLogic.evaluate('15÷3'), '5'));
    test('Divide by zero', () => expect(CalcLogic.evaluate('5÷0'), startsWith('Error')));
  });

  // ─── PEMDAS ──────────────────────────────────────────────────
  group('Operator Precedence (PEMDAS)', () {
    test('(5+3)×2-4÷2 = 14', () => expect(CalcLogic.evaluate('(5+3)×2-4÷2'), '14'));
    test('2+3×4 = 14', () => expect(CalcLogic.evaluate('2+3×4'), '14'));
    test('(2+3)×4 = 20', () => expect(CalcLogic.evaluate('(2+3)×4'), '20'));
    test('((2+3)×(4-1))÷5 = 3', () => expect(CalcLogic.evaluate('((2+3)×(4-1))÷5'), '3'));
  });

  // ─── Scientific Functions ─────────────────────────────────────
  group('Trigonometry (Degrees)', () {
    test('sin(45°) ≈ 0.7071', () {
      expect(double.parse(CalcLogic.sin(45, true)), closeTo(0.7071, 0.001));
    });
    test('cos(45°) ≈ 0.7071', () {
      expect(double.parse(CalcLogic.cos(45, true)), closeTo(0.7071, 0.001));
    });
    test('sin(45°) + cos(45°) ≈ 1.414', () {
      final s = double.parse(CalcLogic.sin(45, true));
      final c = double.parse(CalcLogic.cos(45, true));
      expect(s + c, closeTo(1.414, 0.001));
    });
    test('tan(45°) = 1', () {
      expect(double.parse(CalcLogic.tan(45, true)), closeTo(1.0, 0.001));
    });
    test('sin(90°) = 1', () {
      expect(double.parse(CalcLogic.sin(90, true)), closeTo(1.0, 0.001));
    });
  });

  group('Inverse Trig', () {
    test('asin(1) = 90°', () => expect(double.parse(CalcLogic.asin(1, true)), closeTo(90.0, 0.001)));
    test('acos(1) = 0°', () => expect(double.parse(CalcLogic.acos(1, true)), closeTo(0.0, 0.001)));
    test('atan(1) = 45°', () => expect(double.parse(CalcLogic.atan(1, true)), closeTo(45.0, 0.001)));
    test('asin domain error', () => expect(CalcLogic.asin(2, true), startsWith('Error')));
  });

  group('Logarithms', () {
    test('log(100) = 2', () => expect(double.parse(CalcLogic.log10(100)), closeTo(2.0, 0.001)));
    test('ln(e) = 1', () => expect(double.parse(CalcLogic.ln(2.71828182845905)), closeTo(1.0, 0.001)));
    test('log(0) = Error', () => expect(CalcLogic.log10(0), startsWith('Error')));
    test('ln(-1) = Error', () => expect(CalcLogic.ln(-1), startsWith('Error')));
  });

  group('Power & Root', () {
    test('sqrt(9) = 3', () => expect(CalcLogic.sqrt(9), '3'));
    test('sqrt(-1) = Error', () => expect(CalcLogic.sqrt(-1), startsWith('Error')));
    test('cbrt(27) = 3', () => expect(CalcLogic.cbrt(27), '3'));
    test('cbrt(-8) = -2', () => expect(CalcLogic.cbrt(-8), '-2'));
    test('square(5) = 25', () => expect(CalcLogic.square(5), '25'));
    test('recip(4) = 0.25', () => expect(CalcLogic.recip(4), '0.25'));
    test('recip(0) = Error', () => expect(CalcLogic.recip(0), startsWith('Error')));
  });

  group('Factorial', () {
    test('0! = 1', () => expect(CalcLogic.fact(0), '1'));
    test('5! = 120', () => expect(CalcLogic.fact(5), '120'));
    test('10! = 3628800', () => expect(CalcLogic.fact(10), '3628800'));
    test('-1! = Error', () => expect(CalcLogic.fact(-1), startsWith('Error')));
  });

  // ─── Programmer Mode ──────────────────────────────────────────
  group('Bitwise Operations', () {
    test('0xFF AND 0x0F = 15', () => expect(CalcLogic.band(0xFF, 0x0F), '15'));
    test('5 OR 3 = 7', () => expect(CalcLogic.bor(5, 3), '7'));
    test('5 XOR 3 = 6', () => expect(CalcLogic.bxor(5, 3), '6'));
    test('1 << 3 = 8', () => expect(CalcLogic.shl(1, 3), '8'));
    test('16 >> 2 = 4', () => expect(CalcLogic.shr(16, 2), '4'));
  });

  group('Number Conversions', () {
    test('255 → hex = 0xFF', () => expect(CalcLogic.toHex(255), '0xFF'));
    test('8 → binary = 0b1000', () => expect(CalcLogic.toBin(8), '0b1000'));
    test('8 → octal = 0o10', () => expect(CalcLogic.toOct(8), '0o10'));
  });

  // ─── Chain Calculations ───────────────────────────────────────
  group('Chain Calculations', () {
    test('5+3=8, +2=10, +1=11', () {
      var r = CalcLogic.evaluate('5+3');
      expect(r, '8');
      r = CalcLogic.evaluate('$r+2');
      expect(r, '10');
      r = CalcLogic.evaluate('$r+1');
      expect(r, '11');
    });
  });

  // ─── Edge Cases ───────────────────────────────────────────────
  group('Edge Cases', () {
    test('Empty expression = 0', () => expect(CalcLogic.evaluate(''), '0'));
    test('Invalid expression = Error', () => expect(CalcLogic.evaluate('++'), startsWith('Error')));
    test('Large number', () => expect(CalcLogic.evaluate('999999999+1'), '1000000000'));
    test('Decimal: 0.1+0.2 ≈ 0.3', () {
      expect(double.parse(CalcLogic.evaluate('0.1+0.2')), closeTo(0.3, 0.0001));
    });
  });

  // ─── Parentheses ──────────────────────────────────────────────
  group('Parentheses', () {
    test('openParens balanced = 0', () => expect(CalcLogic.openParens('(2+3)'), 0));
    test('openParens unbalanced = 2', () => expect(CalcLogic.openParens('(2+(3'), 2));
  });
}
