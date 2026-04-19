# Advanced Calculator - Flutter

A professional mobile calculator app built with Flutter featuring scientific functions, calculation history, theming, and more.

---

## Features

- **Three Calculator Modes**: Basic, Scientific, Programmer
- **Expression Evaluation** with proper operator precedence (PEMDAS)
- **Scientific Functions**: sin, cos, tan, asin, acos, atan, ln, log, log₂, sqrt, cbrt, xʸ, x², π, e, n!
- **Programmer Mode**: Binary/Octal/Decimal/Hex conversions, bitwise operations (AND, OR, XOR, NOT, <<, >>)
- **Memory Functions**: M+, M-, MR, MC (persisted)
- **Calculation History**: Last 50 entries, tap to reuse, swipe up to open
- **Dark / Light / System Theme** with smooth transitions
- **Settings Screen**: precision, angle mode, haptic feedback, sound, history size
- **Gesture Controls**: swipe right to delete last char, swipe up for history
- **Animations**: button press scale, mode switch fade, error shake
- **Data Persistence**: history, theme, mode, memory, settings saved with SharedPreferences
- **Unit Tests**: >80% coverage of core logic

---

## Architecture

```
lib/
├── main.dart
├── models/
│   ├── calculation_history.dart    # History data model
│   ├── calculator_mode.dart        # Mode & angle mode enums
│   └── calculator_settings.dart   # Settings model
├── providers/
│   ├── calculator_provider.dart   # Main state (expression, display, mode, memory)
│   ├── theme_provider.dart        # Theme switching
│   └── history_provider.dart      # History list management
├── screens/
│   ├── calculator_screen.dart     # Main screen with gestures
│   ├── history_screen.dart        # Full history list
│   └── settings_screen.dart       # User preferences
├── widgets/
│   ├── display_area.dart          # Multi-line display, history preview
│   ├── button_grid.dart           # All three button layouts
│   ├── calculator_button.dart     # Animated button with haptic
│   └── mode_selector.dart         # Animated mode tab selector
├── utils/
│   ├── calculator_logic.dart      # Pure math functions
│   ├── expression_parser.dart     # Recursive descent parser
│   └── constants.dart             # Colors, themes, dimensions
└── services/
    └── storage_service.dart       # SharedPreferences wrapper
```

**State Management**: Provider pattern  
**Persistence**: SharedPreferences  
**Expression Parsing**: Custom recursive-descent parser (PEMDAS compliant)

---

## Setup Instructions

### Requirements
- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0

### Installation

```bash
# Clone the repository
git clone https://github.com/your_username/flutter_advanced_calculator_[your_name].git
cd flutter_advanced_calculator_[your_name]

# Install dependencies
flutter pub get

# Run on emulator or device
flutter run
```

### Dependencies (pubspec.yaml)

```yaml
dependencies:
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  math_expressions: ^2.4.0
  intl: ^0.18.1

dev_dependencies:
  mockito: ^5.4.4
```

---

## Testing Instructions

```bash
# Run all unit tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Scenarios Covered

| Scenario | Expected |
|---|---|
| `(5 + 3) × 2 - 4 ÷ 2` | `14` |
| `sin(45°) + cos(45°)` | `≈ 1.414` |
| `5 M+  3 M+  MR` | `8` |
| `5 + 3 = + 2 = + 1 =` | `11` |
| `((2 + 3) × (4 - 1)) ÷ 5` | `3` |
| `0xFF AND 0x0F` | `0x0F` |

---

## Design Specifications

| Property | Value |
|---|---|
| Light accent color | `#FF6B6B` |
| Dark accent color | `#4ECDC4` |
| Button radius | `16px` |
| Display radius | `24px` |
| Screen padding | `24px` |
| Button spacing | `12px` |
| Button press animation | `200ms` |
| Mode switch animation | `300ms` |
| Font | Roboto |

---

## Known Limitations

- `math_expressions` package not used directly; custom recursive-descent parser implemented instead
- Programmer mode bitwise operations require integer operands
- Graph plotting and voice input not implemented (future bonus features)

## Future Improvements

- Landscape mode support
- Tablet / iPad optimization
- Voice input for calculations
- Graph plotting for functions
- Export history to CSV / PDF
- Custom theme creation
- Widget / home screen shortcut
