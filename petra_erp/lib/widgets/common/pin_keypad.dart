import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class PinKeypad extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final String? label;
  final bool error;

  const PinKeypad({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.label,
    this.error = false,
  });

  @override
  State<PinKeypad> createState() => PinKeypadState();
}

class PinKeypadState extends State<PinKeypad> with SingleTickerProviderStateMixin {
  final List<String> _digits = [];
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  String get currentPin => _digits.join();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void clear() {
    setState(() => _digits.clear());
  }

  void shake() {
    _shakeController.forward(from: 0);
    setState(() => _digits.clear());
  }

  void _addDigit(String digit) {
    if (_digits.length >= widget.length) return;
    setState(() => _digits.add(digit));

    if (_digits.length == widget.length) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) widget.onCompleted(currentPin);
      });
    }
  }

  void _deleteDigit() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTheme.jakarta(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
        ],
        _DotsRow(
          length: widget.length,
          filled: _digits.length,
          error: widget.error,
          shakeAnimation: _shakeAnimation,
        ),
        const SizedBox(height: 32),
        _KeypadGrid(
          onDigit: _addDigit,
          onDelete: _deleteDigit,
          isEmpty: _digits.isEmpty,
        ),
      ],
    );
  }
}

class _DotsRow extends StatelessWidget {
  final int length;
  final int filled;
  final bool error;
  final Animation<double> shakeAnimation;

  const _DotsRow({
    required this.length,
    required this.filled,
    required this.error,
    required this.shakeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        final offset =
            shakeAnimation.value > 0 ? 8 * (1 - shakeAnimation.value) * _sin(shakeAnimation.value * 8) : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(length, (i) {
          final isFilled = i < filled;
          final color = error
              ? AppColors.error
              : isFilled
                  ? AppColors.accent
                  : AppColors.border;
          return Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? color : Colors.transparent,
              border: Border.all(
                color: color,
                width: 2,
              ),
            ),
          );
        }),
      ),
    );
  }

  double _sin(double x) {
    double result = x;
    final x2 = x * x;
    result -= x2 * x / 6;
    result += x2 * x2 * x / 120;
    return result;
  }
}

class _KeypadGrid extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool isEmpty;

  const _KeypadGrid({
    required this.onDigit,
    required this.onDelete,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: row.map((d) => _KeyButton(digit: d, onTap: () => onDigit(d))).toList(),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 64, height: 56),
            _KeyButton(digit: '0', onTap: () => onDigit('0')),
            _KeyButton(
              digit: '',
              onTap: onDelete,
              isEmpty: isEmpty,
              child: const Icon(Icons.backspace_outlined, size: 24, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyButton extends StatefulWidget {
  final String digit;
  final VoidCallback onTap;
  final bool isEmpty;
  final Widget? child;

  const _KeyButton({
    required this.digit,
    required this.onTap,
    this.isEmpty = false,
    this.child,
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isEmpty ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 64,
          height: 56,
          decoration: BoxDecoration(
            color: _pressed ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: _pressed ? AppColors.accent : AppColors.border,
              width: _pressed ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: widget.child ??
              Text(
                widget.digit,
                style: AppTheme.numeric(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
        ),
      ),
    );
  }
}
