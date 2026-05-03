
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => CalcProvider()..init(),
      child: const AdvancedCalculatorApp(),
    ),
  );
}

enum CalcMode { basic, scientific, programmer }

enum AngleMode { deg, rad }

class HistoryItem {
  final String expression;
  final String result;
  final DateTime time;
  HistoryItem(this.expression, this.result, this.time);

  Map<String, dynamic> toJson() => {
    'e': expression,
    'r': result,
    't': time.toIso8601String(),
  };
  factory HistoryItem.fromJson(Map<String, dynamic> j) =>
      HistoryItem(j['e'], j['r'], DateTime.parse(j['t']));
}

class CalcLogic {
  static String evaluate(String expr, {bool isDeg = true}) {
    try {
      if (expr.trim().isEmpty) return '0';
      String e = expr
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '${math.pi}')
          .replaceAllMapped(RegExp(r'(\d)([\(])'), (m) => '${m[1]}*${m[2]}');

      if (isDeg) {
        for (final fn in ['sin', 'cos', 'tan']) {
          e = e.replaceAllMapped(
            RegExp('$fn\\(([^)]+)\\)'),
                (m) => '$fn((${m[1]})*${math.pi}/180)',
          );
        }
      }
      Parser p = Parser();
      Expression exp = p.parse(e);
      double res = exp.evaluate(EvaluationType.REAL, ContextModel());
      if (res.isNaN) return 'Error: Invalid';
      if (res.isInfinite) return 'Error: Div/0';
      return _fmt(res);
    } catch (_) {
      return 'Error: Invalid';
    }
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e15) return v.toInt().toString();
    String s = v.toStringAsFixed(10);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  static String sin(double v, bool isDeg) {
    double r = isDeg ? v * math.pi / 180 : v;
    return _fmt(math.sin(r));
  }

  static String cos(double v, bool isDeg) {
    double r = isDeg ? v * math.pi / 180 : v;
    return _fmt(math.cos(r));
  }

  static String tan(double v, bool isDeg) {
    double r = isDeg ? v * math.pi / 180 : v;
    double res = math.tan(r);
    if (res.abs() > 1e10) return 'Error: Undefined';
    return _fmt(res);
  }

  static String asin(double v, bool isDeg) {
    if (v < -1 || v > 1) return 'Error: Domain';
    double r = math.asin(v);
    return _fmt(isDeg ? r * 180 / math.pi : r);
  }

  static String acos(double v, bool isDeg) {
    if (v < -1 || v > 1) return 'Error: Domain';
    double r = math.acos(v);
    return _fmt(isDeg ? r * 180 / math.pi : r);
  }

  static String atan(double v, bool isDeg) {
    double r = math.atan(v);
    return _fmt(isDeg ? r * 180 / math.pi : r);
  }

  static String ln(double v) =>
      v <= 0 ? 'Error: Domain' : _fmt(math.log(v));

  static String log10(double v) =>
      v <= 0 ? 'Error: Domain' : _fmt(math.log(v) / math.ln10);

  static String sqrt(double v) =>
      v < 0 ? 'Error: Domain' : _fmt(math.sqrt(v));

  static String cbrt(double v) {
    double s = v < 0 ? -1 : 1;
    return _fmt(s * math.pow(v.abs(), 1 / 3));
  }

  static String square(double v) => _fmt(v * v);
  static String cube(double v) => _fmt(v * v * v);
  static String recip(double v) =>
      v == 0 ? 'Error: Div/0' : _fmt(1 / v);

  static String fact(int n) {
    if (n < 0) return 'Error: Domain';
    if (n > 20) return 'Error: Overflow';
    int r = 1;
    for (int i = 2; i <= n; i++) r *= i;
    return r.toString();
  }
  static String toHex(int v) => '0x${v.toRadixString(16).toUpperCase()}';
  static String toBin(int v) => '0b${v.toRadixString(2)}';
  static String toOct(int v) => '0o${v.toRadixString(8)}';
  static String band(int a, int b) => (a & b).toString();
  static String bor(int a, int b) => (a | b).toString();
  static String bxor(int a, int b) => (a ^ b).toString();
  static String bnot(int a) => (~a).toString();
  static String shl(int a, int n) => (a << n).toString();
  static String shr(int a, int n) => (a >> n).toString();

  static int openParens(String e) {
    int c = 0;
    for (var ch in e.runes) {
      if (String.fromCharCode(ch) == '(') c++;
      if (String.fromCharCode(ch) == ')') c--;
    }
    return c;
  }
}

class CalcProvider extends ChangeNotifier {
  String _expr = '';
  String _display = '0';
  String _prevExpr = '';
  List<HistoryItem> _history = [];
  CalcMode _mode = CalcMode.basic;
  AngleMode _angle = AngleMode.deg;
  double? _memory;
  bool _newInput = false;
  bool _show2nd = false;
  bool _haptic = true;
  int _histSize = 50;
  bool _isDark = true;

  // getters
  String get display => _display;
  String get prevExpr => _prevExpr;
  List<HistoryItem> get history => _history;
  CalcMode get mode => _mode;
  AngleMode get angle => _angle;
  bool get isDeg => _angle == AngleMode.deg;
  double? get memory => _memory;
  bool get hasMemory => _memory != null;
  bool get show2nd => _show2nd;
  bool get isDark => _isDark;
  int get histSize => _histSize;
  bool get hapticOn => _haptic;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _isDark = p.getBool('dark') ?? true;
    _mode = CalcMode.values[p.getInt('mode') ?? 0];
    _angle = AngleMode.values[p.getInt('angle') ?? 0];
    _haptic = p.getBool('haptic') ?? true;
    _histSize = p.getInt('histSize') ?? 50;
    _memory = p.getDouble('mem');
    final raw = p.getString('history');
    if (raw != null) {
      final List list = json.decode(raw);
      _history = list.map((e) => HistoryItem.fromJson(e)).toList();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark', _isDark);
    await p.setInt('mode', _mode.index);
    await p.setInt('angle', _angle.index);
    await p.setBool('haptic', _haptic);
    await p.setInt('histSize', _histSize);
    if (_memory != null) await p.setDouble('mem', _memory!);
    else await p.remove('mem');
    await p.setString('history',
        json.encode(_history.map((h) => h.toJson()).toList()));
  }

  void _vibrate() {
    if (_haptic) HapticFeedback.lightImpact();
  }

  void digit(String d) {
    _vibrate();
    if (_newInput) {
      _expr = d;
      _newInput = false;
    } else {
      _expr = (_display == '0' && d != '.') ? d : _expr + d;
    }
    _display = _expr;
    notifyListeners();
  }

  void op(String o) {
    _vibrate();
    if (_expr.isEmpty) return;
    final last = _expr[_expr.length - 1];
    if ('+-×÷'.contains(last)) {
      _expr = _expr.substring(0, _expr.length - 1) + o;
    } else {
      _expr += o;
    }
    _newInput = false;
    _display = _expr;
    notifyListeners();
  }

  void dot() {
    _vibrate();
    if (_newInput) { _expr = '0.'; _newInput = false; _display = _expr; notifyListeners(); return; }
    final parts = _expr.split(RegExp(r'[+\-×÷]'));
    if (!parts.last.contains('.')) { _expr += '.'; _display = _expr; notifyListeners(); }
  }

  void paren() {
    _vibrate();
    final open = CalcLogic.openParens(_expr);
    if (_expr.isEmpty || '(+−×÷'.contains(_expr[_expr.length - 1])) {
      _expr += '(';
    } else if (open > 0) {
      _expr += ')';
    } else {
      _expr += '(';
    }
    _display = _expr;
    notifyListeners();
  }

  void calc() {
    _vibrate();
    if (_expr.isEmpty) return;
    final open = CalcLogic.openParens(_expr);
    _expr += ')' * open;
    final res = CalcLogic.evaluate(_expr, isDeg: isDeg);
    if (!res.startsWith('Error')) _addHistory(_expr, res);
    _prevExpr = _expr;
    _display = res;
    _expr = res.startsWith('Error') ? '' : res;
    _newInput = true;
    notifyListeners();
    _save();
  }

  void clear() { _vibrate(); _expr = ''; _display = '0'; _prevExpr = ''; _newInput = false; notifyListeners(); }
  void clearEntry() { _vibrate(); _expr = ''; _display = '0'; notifyListeners(); }
  void backspace() {
    _vibrate();
    if (_expr.isNotEmpty) {
      _expr = _expr.substring(0, _expr.length - 1);
      _display = _expr.isEmpty ? '0' : _expr;
      notifyListeners();
    }
  }

  void toggleSign() {
    _vibrate();
    try {
      final v = double.parse(_display) * -1;
      _display = _fmtVal(v);
      _expr = _display;
      notifyListeners();
    } catch (_) {}
  }

  void percent() {
    _vibrate();
    try {
      final v = double.parse(_expr.isNotEmpty ? _expr : _display) / 100;
      _display = _fmtVal(v);
      _expr = _display;
      notifyListeners();
    } catch (_) {}
  }

  void scientific(String fn) {
    _vibrate();
    try {
      final v = double.parse(_display);
      String res;
      switch (fn) {
        case 'sin': res = _show2nd ? CalcLogic.asin(v, isDeg) : CalcLogic.sin(v, isDeg); break;
        case 'cos': res = _show2nd ? CalcLogic.acos(v, isDeg) : CalcLogic.cos(v, isDeg); break;
        case 'tan': res = _show2nd ? CalcLogic.atan(v, isDeg) : CalcLogic.tan(v, isDeg); break;
        case 'ln':  res = CalcLogic.ln(v); break;
        case 'log': res = CalcLogic.log10(v); break;
        case 'x²':  res = CalcLogic.square(v); break;
        case '√':   res = _show2nd ? CalcLogic.square(v) : CalcLogic.sqrt(v); break;
        case '∛':   res = CalcLogic.cbrt(v); break;
        case '1/x': res = CalcLogic.recip(v); break;
        case 'n!':  res = CalcLogic.fact(v.toInt()); break;
        default: return;
      }
      _addHistory('$fn($v)', res);
      _display = res;
      _expr = res.startsWith('Error') ? '' : res;
      _newInput = true;
      notifyListeners();
      _save();
    } catch (_) {}
  }

  void pi() {
    _vibrate();
    const p = '3.14159265358979';
    _expr = _newInput || _expr.isEmpty ? p : '$_expr*$p';
    _display = _expr;
    _newInput = false;
    notifyListeners();
  }

  void eConst() {
    _vibrate();
    const e = '2.71828182845905';
    _expr = _newInput || _expr.isEmpty ? e : '$_expr*$e';
    _display = _expr;
    _newInput = false;
    notifyListeners();
  }

  void power() { _vibrate(); _expr += '^'; _display = _expr; _newInput = false; notifyListeners(); }
  void toggle2nd() { _show2nd = !_show2nd; notifyListeners(); }
  void toggleAngle() { _vibrate(); _angle = isDeg ? AngleMode.rad : AngleMode.deg; _save(); notifyListeners(); }

  void mStore()  { _vibrate(); try { _memory = double.parse(_display); _save(); notifyListeners(); } catch (_) {} }
  void mRecall() { _vibrate(); if (_memory != null) { _display = _fmtVal(_memory!); _expr = _display; _newInput = true; notifyListeners(); } }
  void mClear()  { _vibrate(); _memory = null; _save(); notifyListeners(); }
  void mAdd()    { _vibrate(); try { _memory = (_memory ?? 0) + double.parse(_display); _save(); notifyListeners(); } catch (_) {} }
  void mSub()    { _vibrate(); try { _memory = (_memory ?? 0) - double.parse(_display); _save(); notifyListeners(); } catch (_) {} }


  String get programmerInfo {
    try {
      final v = int.parse(_display);
      return 'DEC: $v    HEX: ${CalcLogic.toHex(v)}\nOCT: ${CalcLogic.toOct(v)}    BIN: ${CalcLogic.toBin(v)}';
    } catch (_) { return ''; }
  }

  void bitwise(String o) { _vibrate(); _expr += ' $o '; _display = _expr; _newInput = false; notifyListeners(); }
  void bitwiseNot() {
    _vibrate();
    try { final v = int.parse(_display); _display = CalcLogic.bnot(v); _expr = _display; _newInput = true; notifyListeners(); }
    catch (_) {}
  }

  void _addHistory(String e, String r) {
    if (r.startsWith('Error')) return;
    _history.insert(0, HistoryItem(e, r, DateTime.now()));
    if (_history.length > _histSize) _history = _history.take(_histSize).toList();
  }

  void useHistory(HistoryItem item) {
    _display = item.result; _expr = item.result; _newInput = true; notifyListeners();
  }

  void clearHistory() { _history.clear(); _save(); notifyListeners(); }

  void setMode(CalcMode m) { _mode = m; _save(); notifyListeners(); }
  void toggleTheme() { _isDark = !_isDark; _save(); notifyListeners(); }
  void setHistSize(int s) { _histSize = s; _save(); notifyListeners(); }
  void setHaptic(bool v) { _haptic = v; notifyListeners(); }

  String _fmtVal(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e15) return v.toInt().toString();
    String s = v.toStringAsFixed(10);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s;
  }
}

class AppTheme {
  static const _accent_light = Color(0xFFFF6B6B);
  static const _accent_dark  = Color(0xFF4ECDC4);

  static ThemeData light() => ThemeData(
    useMaterial3: true, brightness: Brightness.light,
    colorScheme: const ColorScheme.light(primary: _accent_light, secondary: Color(0xFF424242)),
    scaffoldBackgroundColor: const Color(0xFFF0F0F0),
    fontFamily: 'Roboto',
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true, brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(primary: _accent_dark, secondary: Color(0xFF2C2C2C)),
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    fontFamily: 'Roboto',
  );
}

class AdvancedCalculatorApp extends StatelessWidget {
  const AdvancedCalculatorApp({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<CalcProvider>().isDark;
    return MaterialApp(
      title: 'Advanced Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<CalcProvider>();
    final isDark = calc.isDark;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Advanced Calculator',
            style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E1E1E),
            )),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => calc.toggleTheme(),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
                        value: calc, child: const HistoryScreen()))),
              ),
              if (calc.history.isNotEmpty)
                Positioned(right: 8, top: 8,
                    child: Container(width: 8, height: 8,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle))),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
                    value: calc, child: const SettingsScreen()))),
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) < -500) {
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                    value: calc, child: const HistoryScreen())));
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                const ModeSelector(),
                const SizedBox(height: 10),
                const DisplayArea(),
                const SizedBox(height: 8),
                if (calc.mode == CalcMode.scientific) ...[
                  GestureDetector(
                    onTap: () => calc.toggleAngle(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: accent.withOpacity(0.6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(calc.isDeg ? 'DEG' : 'RAD',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (calc.history.isNotEmpty) ...[
                  SizedBox(
                    height: 26,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: calc.history.take(3).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final item = calc.history[i];
                        return GestureDetector(
                          onTap: () => calc.useHistory(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${item.expression}=${item.result}',
                                style: TextStyle(fontSize: 11,
                                    color: isDark ? Colors.white54 : Colors.black54)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Expanded(child: const ButtonGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key});

  static const _labels = ['Basic', 'Scientific', 'Programmer'];

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<CalcProvider>();
    final isDark = calc.isDark;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: CalcMode.values.asMap().entries.map((e) {
          final selected = calc.mode == e.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => calc.setMode(e.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected ? [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 6, offset: const Offset(0,2))] : null,
                ),
                child: Text(_labels[e.key],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white54 : Colors.black54),
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DisplayArea extends StatelessWidget {
  const DisplayArea({super.key});

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<CalcProvider>();
    final isDark = calc.isDark;
    final accent = Theme.of(context).colorScheme.primary;
    final bg = isDark ? const Color(0xFF0F3460) : const Color(0xFFEEEEEE);
    final fg = isDark ? Colors.white : const Color(0xFF1E1E1E);

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 300) calc.backspace();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0,2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (calc.hasMemory)
                  _Chip(label: 'M', color: accent)
                else
                  const SizedBox(),
                Row(
                  children: [
                    _Chip(label: calc.isDeg ? 'DEG' : 'RAD', color: accent),
                    if (calc.mode == CalcMode.scientific) ...[
                      const SizedBox(width: 6),
                      _Chip(label: calc.show2nd ? '2nd ON' : '2nd', color: calc.show2nd ? Colors.orange : accent),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (calc.prevExpr.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(calc.prevExpr,
                    style: TextStyle(fontSize: 14, color: fg.withOpacity(0.4), fontWeight: FontWeight.w300)),
              ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: SingleChildScrollView(
                key: ValueKey(calc.display),
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  calc.display,
                  style: TextStyle(
                    fontSize: _fs(calc.display),
                    fontWeight: FontWeight.w500,
                    color: calc.display.startsWith('Error') ? Colors.redAccent : fg,
                  ),
                ),
              ),
            ),
            if (calc.mode == CalcMode.programmer && calc.programmerInfo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(calc.programmerInfo,
                    style: TextStyle(fontSize: 11, color: fg.withOpacity(0.5)),
                    textAlign: TextAlign.right),
              ),
          ],
        ),
      ),
    );
  }

  double _fs(String d) {
    if (d.length > 14) return 22;
    if (d.length > 9) return 30;
    return 40;
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}

enum BtnType { num, op, fn, eq, mem }

class CBtn extends StatefulWidget {
  final String label;
  final String? sub;
  final VoidCallback onTap;
  final BtnType type;
  final Color? bg;
  final Color? fg;
  final double? fs;

  const CBtn(this.label, this.type, this.onTap, {super.key, this.sub, this.bg, this.fg, this.fs});

  @override
  State<CBtn> createState() => _CBtnState();
}

class _CBtnState extends State<CBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      duration: const Duration(milliseconds: 130), vsync: this);
  late final Animation<double> _sc = Tween(begin: 1.0, end: 0.88)
      .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut));

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  Color _bg(BuildContext ctx) {
    if (widget.bg != null) return widget.bg!;
    final dark = Theme.of(ctx).brightness == Brightness.dark;
    switch (widget.type) {
      case BtnType.num: return dark ? const Color(0xFF2C2C2C) : Colors.white;
      case BtnType.op:  return Theme.of(ctx).colorScheme.primary;
      case BtnType.fn:  return dark ? const Color(0xFF1E1E1E) : const Color(0xFFE0E0E0);
      case BtnType.eq:  return Theme.of(ctx).colorScheme.primary;
      case BtnType.mem: return dark ? const Color(0xFF16213E) : const Color(0xFFD0D0D0);
    }
  }

  Color _fg(BuildContext ctx) {
    if (widget.fg != null) return widget.fg!;
    final dark = Theme.of(ctx).brightness == Brightness.dark;
    switch (widget.type) {
      case BtnType.op:
      case BtnType.eq:
        return dark ? Colors.black : Colors.white;
      default:
        return dark ? Colors.white : const Color(0xFF1E1E1E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ac.forward(),
      onTapUp: (_) { _ac.reverse(); widget.onTap(); },
      onTapCancel: () => _ac.reverse(),
      child: ScaleTransition(
        scale: _sc,
        child: Container(
          decoration: BoxDecoration(
            color: _bg(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0,2))],
          ),
          child: Center(
            child: widget.sub != null
                ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.sub!, style: TextStyle(fontSize: 9, color: _fg(context).withOpacity(0.55))),
                Text(widget.label, style: TextStyle(fontSize: widget.fs ?? 17, fontWeight: FontWeight.w600, color: _fg(context))),
              ],
            )
                : Text(widget.label,
                style: TextStyle(fontSize: widget.fs ?? 17, fontWeight: FontWeight.w600, color: _fg(context))),
          ),
        ),
      ),
    );
  }
}

class ButtonGrid extends StatelessWidget {
  const ButtonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<CalcProvider>().mode;
    switch (mode) {
      case CalcMode.basic:       return const _BasicGrid();
      case CalcMode.scientific:  return const _SciGrid();
      case CalcMode.programmer:  return const _ProgGrid();
    }
  }
}

Widget _grid(List<Widget> children, int cols, {double ratio = 1.1}) =>
    GridView.count(
      crossAxisCount: cols,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: ratio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );

class _BasicGrid extends StatelessWidget {
  const _BasicGrid();
  @override
  Widget build(BuildContext context) {
    final c = context.read<CalcProvider>();
    return _grid([
      CBtn('C',  BtnType.fn, () => c.clear()),
      CBtn('CE', BtnType.fn, () => c.clearEntry(), fs: 15),
      CBtn('%',  BtnType.fn, () => c.percent()),
      CBtn('÷',  BtnType.op, () => c.op('÷')),
      CBtn('7',  BtnType.num, () => c.digit('7')),
      CBtn('8',  BtnType.num, () => c.digit('8')),
      CBtn('9',  BtnType.num, () => c.digit('9')),
      CBtn('×',  BtnType.op, () => c.op('×')),
      CBtn('4',  BtnType.num, () => c.digit('4')),
      CBtn('5',  BtnType.num, () => c.digit('5')),
      CBtn('6',  BtnType.num, () => c.digit('6')),
      CBtn('−',  BtnType.op, () => c.op('-')),
      CBtn('1',  BtnType.num, () => c.digit('1')),
      CBtn('2',  BtnType.num, () => c.digit('2')),
      CBtn('3',  BtnType.num, () => c.digit('3')),
      CBtn('+',  BtnType.op, () => c.op('+')),
      CBtn('±',  BtnType.fn, () => c.toggleSign()),
      CBtn('0',  BtnType.num, () => c.digit('0')),
      CBtn('.',  BtnType.num, () => c.dot()),
      CBtn('=',  BtnType.eq, () => c.calc()),
    ], 4);
  }
}

class _SciGrid extends StatelessWidget {
  const _SciGrid();
  @override
  Widget build(BuildContext context) {
    final c = context.watch<CalcProvider>();
    final s2 = c.show2nd;
    final accent = Theme.of(context).colorScheme.primary;
    return _grid([
      CBtn('2nd', BtnType.fn, () => c.toggle2nd(), fs: 13,
          bg: s2 ? accent : null, fg: s2 ? Colors.white : null),
      CBtn(s2 ? 'asin' : 'sin', BtnType.fn, () => c.scientific('sin'), fs: 13),
      CBtn(s2 ? 'acos' : 'cos', BtnType.fn, () => c.scientific('cos'), fs: 13),
      CBtn(s2 ? 'atan' : 'tan', BtnType.fn, () => c.scientific('tan'), fs: 13),
      CBtn('ln',  BtnType.fn, () => c.scientific('ln'),  fs: 13),
      CBtn('log', BtnType.fn, () => c.scientific('log'), fs: 13),
      CBtn('x²',  BtnType.fn, () => c.scientific('x²'), fs: 14),
      CBtn(s2 ? 'x²' : '√', BtnType.fn, () => c.scientific(s2 ? 'x²' : '√'), fs: 15),
      CBtn('xʸ',  BtnType.fn, () => c.power(), fs: 14),
      CBtn('(',   BtnType.fn, () => c.paren()),
      CBtn(')',   BtnType.fn, () => c.paren()),
      CBtn('÷',   BtnType.op, () => c.op('÷')),
      CBtn('MC', BtnType.mem, () => c.mClear(), fs: 13),
      CBtn('7',  BtnType.num, () => c.digit('7')),
      CBtn('8',  BtnType.num, () => c.digit('8')),
      CBtn('9',  BtnType.num, () => c.digit('9')),
      CBtn('C',  BtnType.fn,  () => c.clear()),
      CBtn('×',  BtnType.op,  () => c.op('×')),
      CBtn('MR', BtnType.mem, () => c.mRecall(), fs: 13),
      CBtn('4',  BtnType.num, () => c.digit('4')),
      CBtn('5',  BtnType.num, () => c.digit('5')),
      CBtn('6',  BtnType.num, () => c.digit('6')),
      CBtn('CE', BtnType.fn,  () => c.clearEntry(), fs: 13),
      CBtn('−',  BtnType.op,  () => c.op('-')),
      CBtn('M+', BtnType.mem, () => c.mAdd(), fs: 13),
      CBtn('1',  BtnType.num, () => c.digit('1')),
      CBtn('2',  BtnType.num, () => c.digit('2')),
      CBtn('3',  BtnType.num, () => c.digit('3')),
      CBtn('%',  BtnType.fn,  () => c.percent()),
      CBtn('+',  BtnType.op,  () => c.op('+')),
      CBtn('M−', BtnType.mem, () => c.mSub(), fs: 13),
      CBtn('±',  BtnType.fn,  () => c.toggleSign()),
      CBtn('0',  BtnType.num, () => c.digit('0')),
      CBtn('.',  BtnType.num, () => c.dot()),
      CBtn('π',  BtnType.fn,  () => c.pi(), fs: 18),
      CBtn('=',  BtnType.eq,  () => c.calc()),
    ], 6, ratio: 1.0);
  }
}

class _ProgGrid extends StatelessWidget {
  const _ProgGrid();
  @override
  Widget build(BuildContext context) {
    final c = context.read<CalcProvider>();
    return _grid([
      CBtn('C',   BtnType.fn, () => c.clear()),
      CBtn('CE',  BtnType.fn, () => c.clearEntry(), fs: 14),
      CBtn('<<',  BtnType.fn, () => c.bitwise('<<'), fs: 14),
      CBtn('>>',  BtnType.fn, () => c.bitwise('>>'), fs: 14),
      CBtn('AND', BtnType.op, () => c.bitwise('AND'), fs: 13),
      CBtn('OR',  BtnType.op, () => c.bitwise('OR'),  fs: 13),
      CBtn('XOR', BtnType.op, () => c.bitwise('XOR'), fs: 13),
      CBtn('NOT', BtnType.fn, () => c.bitwiseNot(),   fs: 13),
      CBtn('7',   BtnType.num, () => c.digit('7')),
      CBtn('8',   BtnType.num, () => c.digit('8')),
      CBtn('9',   BtnType.num, () => c.digit('9')),
      CBtn('÷',   BtnType.op, () => c.op('÷')),
      CBtn('4',   BtnType.num, () => c.digit('4')),
      CBtn('5',   BtnType.num, () => c.digit('5')),
      CBtn('6',   BtnType.num, () => c.digit('6')),
      CBtn('×',   BtnType.op, () => c.op('×')),
      CBtn('1',   BtnType.num, () => c.digit('1')),
      CBtn('2',   BtnType.num, () => c.digit('2')),
      CBtn('3',   BtnType.num, () => c.digit('3')),
      CBtn('−',   BtnType.op, () => c.op('-')),
      CBtn('±',   BtnType.fn, () => c.toggleSign()),
      CBtn('0',   BtnType.num, () => c.digit('0')),
      CBtn('⌫',   BtnType.fn, () => c.backspace()),
      CBtn('=',   BtnType.eq, () => c.calc()),
    ], 4);
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<CalcProvider>();
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = calc.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (calc.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear History'),
                  content: const Text('Delete all calculations?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () { calc.clearHistory(); Navigator.pop(ctx); },
                      child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: calc.history.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 72, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 16),
            Text('No calculations yet',
                style: TextStyle(fontSize: 16, color: isDark ? Colors.white38 : Colors.black38)),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: calc.history.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final item = calc.history[i];
          return InkWell(
            onTap: () { calc.useHistory(item); Navigator.pop(context); },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.expression,
                            style: TextStyle(fontSize: 14,
                                color: isDark ? Colors.white60 : Colors.black54)),
                        const SizedBox(height: 4),
                        Text('= ${item.result}',
                            style: TextStyle(fontSize: 22,
                                fontWeight: FontWeight.w600, color: accent)),
                      ],
                    ),
                  ),
                  Text(_timeAgo(item.time),
                      style: TextStyle(fontSize: 11,
                          color: isDark ? Colors.white30 : Colors.black26)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<CalcProvider>();
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _section('Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Theme'),
            value: calc.isDark,
            activeColor: accent,
            onChanged: (_) => calc.toggleTheme(),
          ),
          _section('Calculation'),
          ListTile(
            leading: const Icon(Icons.rotate_right),
            title: const Text('Angle Mode'),
            subtitle: Text(calc.isDeg ? 'Degrees' : 'Radians'),
            trailing: Switch(
              value: calc.isDeg,
              activeColor: accent,
              onChanged: (_) => calc.toggleAngle(),
            ),
          ),
          _section('History'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History Size'),
            subtitle: Text('${calc.histSize} calculations'),
            trailing: DropdownButton<int>(
              value: calc.histSize,
              underline: const SizedBox(),
              items: [25, 50, 100].map((n) =>
                  DropdownMenuItem(value: n, child: Text('$n'))).toList(),
              onChanged: (v) => v != null ? calc.setHistSize(v) : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
            title: const Text('Clear All History'),
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Clear History'),
                content: const Text('This cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      calc.clearHistory();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('History cleared')));
                    },
                    child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ),
          _section('Feedback'),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Haptic Feedback'),
            value: calc.hapticOn,
            activeColor: accent,
            onChanged: (v) => calc.setHaptic(v),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Advanced Calculator — Chapter 3',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white30 : Colors.black38)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.grey)),
  );
}
