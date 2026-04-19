# Testing Documentation

## Test Structure

```
test/
├── calculator_logic_test.dart   # Unit tests for math functions & expression parser
└── integration_test.dart        # Provider-level integration tests (button sequences)
```

---

## Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/calculator_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Unit Tests — `calculator_logic_test.dart`

### CalculatorLogic
| Test | Description |
|---|---|
| `formatResult` integer | Whole numbers show without decimals |
| `formatResult` trailing zeros | `3.14000` → `3.14` |
| `formatResult` NaN/Infinity | Returns `Error` / `∞` / `-∞` |
| `factorial(5)` | Returns `120` |
| `factorial(-1)` | Throws `ArgumentError` |
| `sin(90°)` | Returns `1.0` |
| `cos(0°)` | Returns `1.0` |
| `tan(45°)` | Returns `1.0` |
| `log10(100)` | Returns `2.0` |
| `ln(e)` | Returns `1.0` |
| `sqrt(9)` | Returns `3.0` |
| `cbrt(27)` | Returns `3.0` |
| `pow(2, 10)` | Returns `1024.0` |
| `bitwiseAnd(0xFF, 0x0F)` | Returns `0x0F` |
| `bitwiseOr(0xF0, 0x0F)` | Returns `0xFF` |
| `bitwiseXor(0xFF, 0x0F)` | Returns `0xF0` |
| `shiftLeft(1, 3)` | Returns `8` |
| `shiftRight(8, 3)` | Returns `1` |
| `toBinary(10)` | Returns `"1010"` |
| `toHex(255)` | Returns `"FF"` |
| `fromHex("FF")` | Returns `255` |

### ExpressionParser
| Expression | Expected |
|---|---|
| `2+3` | `5` |
| `5+3*2` | `11` |
| `(5+3)*2-4/2` | `14` |
| `((2+3)*(4-1))/5` | `3` |
| `sin(45)+cos(45)` | `≈ 1.414` |
| `-5+3` | `-2` |
| `5/0` | `Error` |
| `2^10` | `1024` |
| `sqrt(9)` | `3` |
| `log(100)` | `2` |
| `0.1+0.2` | `≈ 0.3` |

---

## Integration Tests — `integration_test.dart`

| Scenario | Steps | Expected |
|---|---|---|
| Simple add | `5 + 3 =` | `8` |
| Chain calc | `5+3= +2= +1=` | `11` |
| Mode switch resets | Type `55`, switch mode | display = `0` |
| Memory M+/MR | `5 M+`, `3 M+`, `MR` | `8` |
| Memory MC | `9 M+`, `MC` | `memoryHasValue = false` |
| Toggle sign | `5`, `±` | expression starts with `-` |
| Percentage | `200`, `%` | `2` |
| Clear entry | `123`, `CE` | expression = `12` |
| History save | `7+3=` | history has entry with result `10` |

---

## Coverage Goal: ≥ 80%

Core files targeted:
- `calculator_logic.dart` — 100%
- `expression_parser.dart` — ~90%
- `calculator_provider.dart` — ~80%
- `history_provider.dart` — ~85%
- `storage_service.dart` — mocked in unit tests
