import 'package:flutter/material.dart';
import '../design/colors.dart';

/// A 3x4 phone-style number pad sized for illiterate users on low-cost phones.
/// Keys are ≥72dp; backspace and submit are visual icons, not text.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onSubmit,
    this.submitEnabled = false,
  });

  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onSubmit;
  final bool submitEnabled;

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in keys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final k in row) _DigitKey(label: k, onTap: () => onDigit(k))],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _IconKey(icon: Icons.backspace_outlined, onTap: onBackspace, color: GasColors.out),
              _DigitKey(label: '0', onTap: () => onDigit('0')),
              _IconKey(
                icon: Icons.check,
                onTap: submitEnabled ? onSubmit : null,
                color: submitEnabled ? GasColors.available : GasColors.divider,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 72,
      child: Material(
        color: GasColors.card,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: GasColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconKey extends StatelessWidget {
  const _IconKey({required this.icon, required this.onTap, required this.color});

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 72,
      child: Material(
        color: GasColors.card,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(child: Icon(icon, size: 32, color: color)),
        ),
      ),
    );
  }
}
