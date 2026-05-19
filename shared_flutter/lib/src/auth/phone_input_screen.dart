import 'package:flutter/material.dart';
import '../design/colors.dart';
import 'number_pad.dart';

/// Country dial codes for West African French-speaking markets.
const Map<String, String> westAfricaDialCodes = {
  'SN': '+221',
  'CI': '+225',
  'ML': '+223',
  'BF': '+226',
  'NE': '+227',
  'TG': '+228',
  'BJ': '+229',
};

/// Phone-number entry. Country prefix is fixed (default Senegal +221).
/// Calls [onSubmitted] with the full E.164 number when the user confirms.
class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({
    super.key,
    required this.onSubmitted,
    this.dialCode = '+221',
    this.title = 'Numéro de téléphone',
    this.subtitle,
  });

  final void Function(String phoneE164) onSubmitted;
  final String dialCode;
  final String title;
  final String? subtitle;

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  static const int _minDigits = 8;
  static const int _maxDigits = 10;

  String _digits = '';

  void _onDigit(String d) {
    if (_digits.length >= _maxDigits) return;
    setState(() => _digits = '$_digits$d');
  }

  void _onBackspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _onSubmit() => widget.onSubmitted('${widget.dialCode}$_digits');

  @override
  Widget build(BuildContext context) {
    final canSubmit = _digits.length >= _minDigits;

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
              _PhoneDisplay(dialCode: widget.dialCode, digits: _digits),
              const Spacer(),
              NumberPad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                onSubmit: _onSubmit,
                submitEnabled: canSubmit,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneDisplay extends StatelessWidget {
  const _PhoneDisplay({required this.dialCode, required this.digits});

  final String dialCode;
  final String digits;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: GasColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GasColors.divider),
      ),
      child: Row(
        children: [
          Text(dialCode,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w600, color: GasColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              digits.isEmpty ? '—' : digits,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: GasColors.textPrimary,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
