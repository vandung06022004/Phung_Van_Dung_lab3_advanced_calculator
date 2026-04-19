// lib/widgets/display_area.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../providers/history_provider.dart';
import '../models/calculator_mode.dart';
import '../utils/constants.dart';

class DisplayArea extends StatefulWidget {
  const DisplayArea({super.key});

  @override
  State<DisplayArea> createState() => _DisplayAreaState();
}

class _DisplayAreaState extends State<DisplayArea>
    with SingleTickerProviderStateMixin {
  late AnimationController _errorController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _errorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(_errorController);
  }

  @override
  void dispose() {
    _errorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<CalculatorProvider>();
    final history = context.watch<HistoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (calc.hasError && !_errorController.isAnimating) {
      _errorController.forward(from: 0);
    }

    final bgColor = isDark ? AppColors.darkSecondary : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightPrimary;
    final dimColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.displayRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mode & angle mode indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _chip(calc.mode.label, isDark),
                  if (calc.mode == CalculatorMode.scientific) ...[
                    const SizedBox(width: 8),
                    _chip(
                      calc.angleMode == AngleMode.degrees ? 'DEG' : 'RAD',
                      isDark,
                      color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    ),
                  ],
                  if (calc.memoryHasValue) ...[
                    const SizedBox(width: 8),
                    _chip('M', isDark,
                        color: isDark ? Colors.amber : Colors.orange),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // History preview (last 3)
          if (history.recentThree.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                reverse: true,
                shrinkWrap: true,
                itemCount: history.recentThree.length,
                itemBuilder: (ctx, i) {
                  final entry = history.recentThree[i];
                  return GestureDetector(
                    onTap: () {
                      context.read<CalculatorProvider>().useHistoryResult(entry.result);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entry.expression} = ${entry.result}',
                        style: AppTextStyles.historyStyle.copyWith(
                          color: dimColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Expression line
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              calc.expression.isEmpty ? '' : calc.expression,
              style: AppTextStyles.expressionStyle.copyWith(color: dimColor),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 4),

          // Main display with shake on error
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              );
            },
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTextStyles.displayStyle.copyWith(
                  color: calc.hasError ? Colors.red : textColor,
                  fontSize: calc.display.length > 12 ? 24 : 32,
                ),
                child: Text(
                  calc.display,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),

          // Programmer mode conversions
          if (calc.mode == CalculatorMode.programmer) ...[
            const SizedBox(height: 8),
            _programmerDisplay(calc.display, dimColor),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, bool isDark, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? (isDark ? Colors.white24 : Colors.black12)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color != null
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black54),
        ),
      ),
    );
  }

  Widget _programmerDisplay(String display, Color dimColor) {
    int? value = int.tryParse(display);
    if (value == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('HEX: ${value.toRadixString(16).toUpperCase()}',
            style: TextStyle(fontSize: 12, color: dimColor)),
        Text('OCT: ${value.toRadixString(8)}',
            style: TextStyle(fontSize: 12, color: dimColor)),
        Text('BIN: ${value.toRadixString(2)}',
            style: TextStyle(fontSize: 12, color: dimColor)),
      ],
    );
  }
}
