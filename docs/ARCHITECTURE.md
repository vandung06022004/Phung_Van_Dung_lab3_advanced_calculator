# Architecture Decision Records

## ADR-001: State Management — Provider

**Decision**: Use the `provider` package for state management.

**Reasoning**:
- Lightweight and officially recommended by the Flutter team
- No boilerplate compared to BLoC/Redux
- Easy to combine multiple providers with `MultiProvider`
- Straightforward to test with mock providers

**Alternatives Considered**: BLoC (too verbose for this scope), Riverpod (newer, but Provider is the course requirement), GetX (opinionated, less testable)

---

## ADR-002: Expression Parsing — Custom Recursive-Descent Parser

**Decision**: Implement a custom recursive-descent parser instead of relying solely on `math_expressions`.

**Reasoning**:
- Full control over operator precedence (PEMDAS)
- Native support for custom functions (sin, cos with DEG/RAD toggle)
- Better error messages and handling
- Implicit multiplication support (2π)
- Auto-close of unclosed parentheses

**Grammar**:
```
expression  = addSub
addSub      = mulDiv (('+' | '-') mulDiv)*
mulDiv      = pow (('*' | '/') pow)*
pow         = unary ('^' unary)*       (right-associative)
unary       = ('-' | '+')? atom
atom        = '(' expression ')' | function '(' expression ')' | number
function    = 'sin' | 'cos' | 'tan' | 'asin' | 'acos' | 'atan' | 'ln' | 'log' | 'sqrt' | 'cbrt' | 'abs'
```

---

## ADR-003: Persistence — SharedPreferences

**Decision**: Use `shared_preferences` for all persistent data.

**Reasoning**:
- Simple key-value store sufficient for this app's data model
- No need for a relational DB (SQLite) for a flat list of history entries
- History serialized as JSON string under a single key
- Fast reads on app startup

**Data stored**:
| Key | Type | Description |
|---|---|---|
| `calculation_history` | String (JSON) | List of history entries |
| `theme_mode` | String | `light` / `dark` / `system` |
| `calculator_mode` | int | Enum index |
| `memory_value` | double | Memory register |
| `angle_mode` | int | 0=DEG, 1=RAD |
| `decimal_precision` | int | 2–10 |
| `haptic_feedback` | bool | On/Off |
| `sound_effects` | bool | On/Off |
| `history_size` | int | 25/50/100 |

---

## ADR-004: Three-Mode Architecture

**Decision**: Each mode (`basic`, `scientific`, `programmer`) renders its own button grid, but shares a single `CalculatorProvider`.

**Reasoning**:
- Switching mode resets the expression to avoid confusion
- A single provider means memory and settings are shared across modes
- Independent `ButtonGrid` widgets enable `AnimatedSwitcher` fade transitions
- Clean separation of concerns; adding a 4th mode only requires a new widget + enum value
