// lib/models/calculator_mode.dart
enum CalculatorMode { basic, scientific, programmer }

enum AngleMode { degrees, radians }

extension CalculatorModeExtension on CalculatorMode {
  String get label {
    switch (this) {
      case CalculatorMode.basic:
        return 'Basic';
      case CalculatorMode.scientific:
        return 'Scientific';
      case CalculatorMode.programmer:
        return 'Programmer';
    }
  }
}
