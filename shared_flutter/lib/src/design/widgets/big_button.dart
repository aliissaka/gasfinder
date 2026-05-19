import 'package:flutter/material.dart';
import '../colors.dart';

/// Large tap target with optional icon. Designed for illiterate users:
/// the icon carries the meaning; the label is supportive, not required.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.label,
    this.color = GasColors.primary,
    this.foreground = Colors.white,
  }) : assert(icon != null || label != null, 'Provide an icon, a label, or both');

  final VoidCallback? onPressed;
  final IconData? icon;
  final String? label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 32),
            if (icon != null && label != null) const SizedBox(width: 12),
            if (label != null) Text(label!),
          ],
        ),
      ),
    );
  }
}
