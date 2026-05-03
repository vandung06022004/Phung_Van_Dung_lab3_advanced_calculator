import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

enum ButtonType { number, operator, special, equals, memory }

class CalculatorButton extends StatefulWidget {
  final String label;
  final String? subLabel;
  final VoidCallback onPressed;
  final ButtonType type;
  final double? fontSize;
  final bool isDark;
  final Color? customColor;

  const CalculatorButton({
    super.key,
    required this.label,
    this.subLabel,
    required this.onPressed,
    this.type = ButtonType.number,
    this.fontSize,
    required this.isDark,
    this.customColor,
  });

  @override
  State<CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<CalculatorButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDimensions.buttonPressAnimDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getButtonColor() {
    if (widget.customColor != null) return widget.customColor!;
    if (widget.isDark) {
      switch (widget.type) {
        case ButtonType.number: return AppColors.numberBtnDark;
        case ButtonType.operator: return AppColors.operatorBtnDark;
        case ButtonType.special: return AppColors.specialBtnDark;
        case ButtonType.equals: return AppColors.equalsBtnDark;
        case ButtonType.memory: return const Color(0xFF1A3A3A);
      }
    } else {
      switch (widget.type) {
        case ButtonType.number: return AppColors.numberBtnLight;
        case ButtonType.operator: return AppColors.operatorBtnLight;
        case ButtonType.special: return AppColors.specialBtnLight;
        case ButtonType.equals: return AppColors.equalsBtnLight;
        case ButtonType.memory: return const Color(0xFFE8F5F5);
      }
    }
  }

  Color _getTextColor() {
    if (widget.isDark) {
      if (widget.type == ButtonType.equals) return Colors.black87;
      if (widget.type == ButtonType.operator) return AppColors.darkAccent;
      return Colors.white;
    } else {
      if (widget.type == ButtonType.equals) return Colors.white;
      if (widget.type == ButtonType.operator) return AppColors.lightAccent;
      return AppColors.lightPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: _getButtonColor(),
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.subLabel != null)
                Text(
                  widget.subLabel!,
                  style: TextStyle(
                    fontSize: 9,
                    color: _getTextColor().withOpacity(0.7),
                  ),
                ),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.fontSize ?? 16,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(),
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
