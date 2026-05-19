import 'package:flutter/material.dart';
import '../design/colors.dart';
import 'number_pad.dart';

/// Masked-dot PIN entry. Auto-submits when [pinLength] digits are entered.
/// The user can also tap the check key any time after the minimum length.
class PinInputScreen extends StatefulWidget {
  const PinInputScreen({
    super.key,
    required this.onSubmitted,
    this.pinLength = 4,
    this.title = 'Code secret',
    this.subtitle,
    this.errorMessage,
  });

  final void Function(String pin) onSubmitted;
  final int pinLength;
  final String title;
  final String? subtitle;
  final String? errorMessage;

  @override
  State<PinInputScreen> createState() => _PinInputScreenState();
}

class _PinInputScreenState extends State<PinInputScreen> {
  String _pin = '';

  void _onDigit(String d) {
    if (_pin.length >= widget.pinLength) return;
    setState(() => _pin = '$_pin$d');
    if (_pin.length == widget.pinLength) {
      widget.onSubmitted(_pin);
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _onSubmit() {
    if (_pin.length >= widget.pinLength) widget.onSubmitted(_pin);
  }

  void clear() => setState(() => _pin = '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GasColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(widget.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(widget.subtitle!,
                    style: const TextStyle(fontSize: 14, color: GasColors.textSecondary)),
              ],
              const SizedBox(height: 24),
              _PinDots(filled: _pin.length, total: widget.pinLength),
              if (widget.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(widget.errorMessage!,
                    style: const TextStyle(color: GasColors.out, fontSize: 16)),
              ],
              const Spacer(),
              NumberPad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                onSubmit: _onSubmit,
                submitEnabled: _pin.length >= widget.pinLength,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? GasColors.primary : Colors.transparent,
                border: Border.all(color: GasColors.primary, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
