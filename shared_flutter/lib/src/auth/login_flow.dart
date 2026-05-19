import 'package:flutter/material.dart';
import '../api/api_exception.dart';
import '../api/auth_api.dart';
import '../api/models/auth_response.dart';
import '../api/models/login_request.dart';
import '../design/colors.dart';
import 'phone_input_screen.dart';
import 'pin_input_screen.dart';

/// Phone-then-PIN login flow. Composed of two full-screen pages connected by a
/// PageView so transitions are smooth and back-navigation re-shows the phone.
class LoginFlow extends StatefulWidget {
  const LoginFlow({
    super.key,
    required this.authApi,
    required this.onSuccess,
    this.dialCode = '+221',
  });

  final AuthApi authApi;
  final void Function(AuthResponse auth) onSuccess;
  final String dialCode;

  @override
  State<LoginFlow> createState() => _LoginFlowState();
}

class _LoginFlowState extends State<LoginFlow> {
  final _controller = PageController();
  String? _phone;
  String? _errorMessage;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPhoneSubmitted(String phone) {
    setState(() {
      _phone = phone;
      _errorMessage = null;
    });
    _controller.animateToPage(1, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _onPinSubmitted(String pin) async {
    if (_submitting || _phone == null) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final auth = await widget.authApi.login(LoginRequest(phone: _phone!, pin: pin));
      if (!mounted) return;
      widget.onSuccess(auth);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _humanize(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Connexion impossible. Réessayez.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _humanize(ApiException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Numéro ou code secret incorrect.';
      case 'too_many_attempts':
        return 'Trop de tentatives. Patientez une minute.';
      default:
        return 'Connexion impossible. Réessayez.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            PhoneInputScreen(
              dialCode: widget.dialCode,
              title: 'Connexion',
              subtitle: 'Entrez votre numéro de téléphone',
              onSubmitted: _onPhoneSubmitted,
            ),
            PinInputScreen(
              title: 'Code secret',
              subtitle: 'Entrez votre code à 4 chiffres',
              errorMessage: _errorMessage,
              onSubmitted: _onPinSubmitted,
            ),
          ],
        ),
        if (_submitting)
          const ColoredBox(
            color: Color(0x66000000),
            child: Center(
              child: CircularProgressIndicator(color: GasColors.primary),
            ),
          ),
      ],
    );
  }
}
