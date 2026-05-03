import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../providers/history_provider.dart';
import '../models/calculator_mode.dart';
import '../utils/constants.dart';
import 'calculator_button.dart';

class ButtonGrid extends StatelessWidget {
  const ButtonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<CalculatorProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSwitcher(
      duration: AppDimensions.modeSwitchAnimDuration,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: KeyedSubtree(
        key: ValueKey(calc.mode),
        child: switch (calc.mode) {
          CalculatorMode.basic => _BasicGrid(isDark: isDark),
          CalculatorMode.scientific => _ScientificGrid(isDark: isDark),
          CalculatorMode.programmer => _ProgrammerGrid(isDark: isDark),
        },
      ),
    );
  }
}
void _evaluate(BuildContext context) {
  final calc = context.read<CalculatorProvider>();
  final history = context.read<HistoryProvider>();
  calc.evaluate((expr, result) => history.addEntry(expr, result));
}
class _BasicGrid extends StatelessWidget {
  final bool isDark;
  const _BasicGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final calc = context.read<CalculatorProvider>();
    final spacing = AppDimensions.buttonSpacing;

    final buttons = [
      _Btn('C', ButtonType.special, () => calc.clear()),
      _Btn('CE', ButtonType.special, () => calc.clearEntry()),
      _Btn('%', ButtonType.special, () => calc.percentage()),
      _Btn('÷', ButtonType.operator, () => calc.inputOperator('/')),
      _Btn('7', ButtonType.number, () => calc.inputDigit('7')),
      _Btn('8', ButtonType.number, () => calc.inputDigit('8')),
      _Btn('9', ButtonType.number, () => calc.inputDigit('9')),
      _Btn('×', ButtonType.operator, () => calc.inputOperator('*')),
      _Btn('4', ButtonType.number, () => calc.inputDigit('4')),
      _Btn('5', ButtonType.number, () => calc.inputDigit('5')),
      _Btn('6', ButtonType.number, () => calc.inputDigit('6')),
      _Btn('-', ButtonType.operator, () => calc.inputOperator('-')),
      _Btn('1', ButtonType.number, () => calc.inputDigit('1')),
      _Btn('2', ButtonType.number, () => calc.inputDigit('2')),
      _Btn('3', ButtonType.number, () => calc.inputDigit('3')),
      _Btn('+', ButtonType.operator, () => calc.inputOperator('+')),
      _Btn('±', ButtonType.special, () => calc.toggleSign()),
      _Btn('0', ButtonType.number, () => calc.inputDigit('0')),
      _Btn('.', ButtonType.number, () => calc.inputDecimal()),
      _Btn('=', ButtonType.equals, () => _evaluate(context)),
    ];

    return _buildGrid(buttons, 4, spacing, isDark);
  }
}
class _ScientificGrid extends StatelessWidget {
  final bool isDark;
  const _ScientificGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<CalculatorProvider>();
    final spacing = AppDimensions.buttonSpacing;
    final is2nd = calc.isSecondFunction;

    final buttons = [
      _Btn(is2nd ? '2nd' : '2nd', ButtonType.special, () => calc.toggleSecondFunction(),
          color: is2nd ? (isDark ? AppColors.darkAccent : AppColors.lightAccent) : null),
      _Btn(is2nd ? 'asin' : 'sin', ButtonType.special,
          () => calc.inputFunction(is2nd ? 'asin' : 'sin')),
      _Btn(is2nd ? 'acos' : 'cos', ButtonType.special,
          () => calc.inputFunction(is2nd ? 'acos' : 'cos')),
      _Btn(is2nd ? 'atan' : 'tan', ButtonType.special,
          () => calc.inputFunction(is2nd ? 'atan' : 'tan')),
      _Btn(is2nd ? 'log₂' : 'Ln', ButtonType.special,
          () => calc.inputFunction(is2nd ? 'log2' : 'ln')),
      _Btn('log', ButtonType.special, () => calc.inputFunction('log')),
      _Btn('x²', ButtonType.special, () => calc.inputOperator('^2')),
      _Btn(is2nd ? '∛' : '√', ButtonType.special,
          () => calc.inputFunction(is2nd ? 'cbrt' : 'sqrt')),
      _Btn('xʸ', ButtonType.special, () => calc.inputOperator('^')),
      _Btn('(', ButtonType.special, () => calc.inputParenthesis('(')),
      _Btn(')', ButtonType.special, () => calc.inputParenthesis(')')),
      _Btn('÷', ButtonType.operator, () => calc.inputOperator('/')),
      _Btn('MC', ButtonType.memory, () => calc.memoryClear()),
      _Btn('7', ButtonType.number, () => calc.inputDigit('7')),
      _Btn('8', ButtonType.number, () => calc.inputDigit('8')),
      _Btn('9', ButtonType.number, () => calc.inputDigit('9')),
      _Btn('C', ButtonType.special, () => calc.clear()),
      _Btn('×', ButtonType.operator, () => calc.inputOperator('*')),
      _Btn('MR', ButtonType.memory, () => calc.memoryRecall()),
      _Btn('4', ButtonType.number, () => calc.inputDigit('4')),
      _Btn('5', ButtonType.number, () => calc.inputDigit('5')),
      _Btn('6', ButtonType.number, () => calc.inputDigit('6')),
      _Btn('CE', ButtonType.special, () => calc.clearEntry()),
      _Btn('-', ButtonType.operator, () => calc.inputOperator('-')),
      _Btn('M+', ButtonType.memory, () => calc.memoryAdd()),
      _Btn('1', ButtonType.number, () => calc.inputDigit('1')),
      _Btn('2', ButtonType.number, () => calc.inputDigit('2')),
      _Btn('3', ButtonType.number, () => calc.inputDigit('3')),
      _Btn('%', ButtonType.special, () => calc.percentage()),
      _Btn('+', ButtonType.operator, () => calc.inputOperator('+')),
      _Btn('M-', ButtonType.memory, () => calc.memorySubtract()),
      _Btn('±', ButtonType.special, () => calc.toggleSign()),
      _Btn('0', ButtonType.number, () => calc.inputDigit('0')),
      _Btn('.', ButtonType.number, () => calc.inputDecimal()),
      _Btn('π', ButtonType.special, () => calc.inputConstant('π')),
      _Btn('=', ButtonType.equals, () => _evaluate(context)),
    ];

    return _buildGrid(buttons, 6, spacing, isDark);
  }
}
class _ProgrammerGrid extends StatelessWidget {
  final bool isDark;
  const _ProgrammerGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final calc = context.read<CalculatorProvider>();
    final spacing = AppDimensions.buttonSpacing;

    return Column(
      children: [
        Row(
          children: ['BIN', 'OCT', 'DEC', 'HEX'].asMap().entries.map((e) {
            final bases = [2, 8, 10, 16];
            final base = bases[e.key];
            final selected = calc.programmerBase == base;
            return Expanded(
              child: GestureDetector(
                onTap: () => calc.setProgrammerBase(base),
                child: Container(
                  margin: EdgeInsets.all(spacing / 2),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                        : (isDark ? AppColors.darkSecondary : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildBtn('AND', ButtonType.special, () => calc.bitwiseOperation('AND'), isDark),
              _buildBtn('OR', ButtonType.special, () => calc.bitwiseOperation('OR'), isDark),
              _buildBtn('XOR', ButtonType.special, () => calc.bitwiseOperation('XOR'), isDark),
              _buildBtn('NOT', ButtonType.special, () => calc.bitwiseOperation('NOT'), isDark),
              _buildBtn('<<', ButtonType.special, () => calc.bitwiseOperation('<<'), isDark),
              _buildBtn('>>', ButtonType.special, () => calc.bitwiseOperation('>>'), isDark),
              _buildBtn('C', ButtonType.special, () => calc.clear(), isDark),
              _buildBtn('÷', ButtonType.operator, () => calc.inputOperator('/'), isDark),
              _buildBtn('7', ButtonType.number, () => calc.inputDigit('7'), isDark),
              _buildBtn('8', ButtonType.number, () => calc.inputDigit('8'), isDark),
              _buildBtn('9', ButtonType.number, () => calc.inputDigit('9'), isDark),
              _buildBtn('×', ButtonType.operator, () => calc.inputOperator('*'), isDark),
              _buildBtn('4', ButtonType.number, () => calc.inputDigit('4'), isDark),
              _buildBtn('5', ButtonType.number, () => calc.inputDigit('5'), isDark),
              _buildBtn('6', ButtonType.number, () => calc.inputDigit('6'), isDark),
              _buildBtn('-', ButtonType.operator, () => calc.inputOperator('-'), isDark),
              _buildBtn('1', ButtonType.number, () => calc.inputDigit('1'), isDark),
              _buildBtn('2', ButtonType.number, () => calc.inputDigit('2'), isDark),
              _buildBtn('3', ButtonType.number, () => calc.inputDigit('3'), isDark),
              _buildBtn('+', ButtonType.operator, () => calc.inputOperator('+'), isDark),
              _buildBtn('±', ButtonType.special, () => calc.toggleSign(), isDark),
              _buildBtn('0', ButtonType.number, () => calc.inputDigit('0'), isDark),
              _buildBtn('CE', ButtonType.special, () => calc.clearEntry(), isDark),
              _buildBtn('=', ButtonType.equals, () => _evaluate(context), isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBtn(String label, ButtonType type, VoidCallback cb, bool isDark) {
    return CalculatorButton(label: label, type: type, onPressed: cb, isDark: isDark);
  }
}
class _Btn {
  final String label;
  final ButtonType type;
  final VoidCallback callback;
  final Color? color;
  _Btn(this.label, this.type, this.callback, {this.color});
}

Widget _buildGrid(List<_Btn> buttons, int cols, double spacing, bool isDark) {
  return GridView.count(
    crossAxisCount: cols,
    mainAxisSpacing: spacing,
    crossAxisSpacing: spacing,
    physics: const NeverScrollableScrollPhysics(),
    children: buttons.map((b) => CalculatorButton(
      label: b.label,
      type: b.type,
      onPressed: b.callback,
      isDark: isDark,
      customColor: b.color,
      fontSize: cols == 6 ? 13 : 16,
    )).toList(),
  );
}
