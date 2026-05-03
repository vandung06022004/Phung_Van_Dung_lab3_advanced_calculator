import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_mode.dart';
import '../providers/calculator_provider.dart';
import '../utils/constants.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<CalculatorProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return AnimatedSwitcher(
      duration: AppDimensions.modeSwitchAnimDuration,
      child: Container(
        key: ValueKey(calc.mode),
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSecondary : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: CalculatorMode.values.map((mode) {
            final isSelected = calc.mode == mode;
            return Expanded(
              child: GestureDetector(
                onTap: () => calc.setMode(mode),
                child: AnimatedContainer(
                  duration: AppDimensions.modeSwitchAnimDuration,
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      mode.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
