import 'package:flutter/material.dart';
import 'package:shared_flutter/shared_flutter.dart';

import 'location_pick_screen.dart';
import 'shop_info_screen.dart';

/// 5-step retailer registration flow.
///
///  1. Phone        (reuses PhoneInputScreen)
///  2. Create PIN   (reuses PinInputScreen)
///  3. Confirm PIN  (reuses PinInputScreen; mismatch sends user back to step 2)
///  4. Shop info    (typed: shop name + optional owner name + optional address)
///  5. Location     (GPS auto-detect + flutter_map fine-tune)
///
/// On final submit, calls AuthApi.registerRetailer and propagates the resulting
/// AuthResponse via [onSuccess]; the app's AuthGate then transitions to Home.
class RegisterFlow extends StatefulWidget {
  const RegisterFlow({
    super.key,
    required this.authApi,
    required this.onSuccess,
    required this.onCancel,
    this.dialCode = '+221',
  });

  final AuthApi authApi;
  final void Function(AuthResponse auth) onSuccess;
  final VoidCallback onCancel;
  final String dialCode;

  @override
  State<RegisterFlow> createState() => _RegisterFlowState();
}

class _RegisterFlowState extends State<RegisterFlow> {
  final PageController _controller = PageController();
  static const _stepCount = 5;

  String? _phone;
  String? _pin;
  String? _shopName;
  String? _ownerName;
  String? _address;

  String? _pinError;
  String? _submitError;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) => _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

  Future<void> _onPhoneSubmitted(String phone) async {
    setState(() => _phone = phone);
    _go(1);
  }

  void _onPinCreated(String pin) {
    setState(() {
      _pin = pin;
      _pinError = null;
    });
    _go(2);
  }

  void _onPinConfirmed(String pin) {
    if (pin != _pin) {
      setState(() {
        _pinError = 'Les codes ne correspondent pas. Recommencez.';
        _pin = null;
      });
      _go(1);
      return;
    }
    _go(3);
  }

  void _onShopInfoSubmitted({
    required String shopName,
    String? ownerName,
    String? address,
  }) {
    setState(() {
      _shopName = shopName;
      _ownerName = ownerName;
      _address = address;
    });
    _go(4);
  }

  Future<void> _onLocationConfirmed(double lat, double lon) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final auth = await widget.authApi.registerRetailer(RegisterRetailerRequest(
        ownerPhone: _phone!,
        pin: _pin!,
        ownerName: _ownerName,
        shopName: _shopName!,
        shopPhone: _phone!,
        shopLatitude: lat,
        shopLongitude: lon,
        shopAddress: _address,
      ));
      if (!mounted) return;
      widget.onSuccess(auth);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = _humanize(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = 'Inscription impossible. Réessayez.';
      });
    }
  }

  String _humanize(ApiException e) {
    switch (e.code) {
      case 'phone_already_registered':
        return 'Ce numéro est déjà utilisé.';
      case 'validation_failed':
        return 'Informations invalides. Vérifiez et réessayez.';
      case 'too_many_attempts':
        return 'Trop de tentatives. Patientez une minute.';
      default:
        return 'Inscription impossible. Réessayez.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GasColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _ProgressHeader(controller: _controller, total: _stepCount, onClose: widget.onCancel),
            Expanded(
              child: Stack(
                children: [
                  PageView(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      PhoneInputScreen(
                        dialCode: widget.dialCode,
                        title: 'Créer un compte',
                        subtitle: 'Votre numéro de téléphone',
                        onSubmitted: _onPhoneSubmitted,
                      ),
                      PinInputScreen(
                        title: 'Créer un code secret',
                        subtitle: 'Choisissez 4 chiffres faciles à retenir',
                        errorMessage: _pinError,
                        onSubmitted: _onPinCreated,
                      ),
                      PinInputScreen(
                        key: ValueKey('confirm-${_pin ?? "empty"}'),
                        title: 'Confirmez votre code',
                        subtitle: 'Tapez à nouveau les 4 chiffres',
                        onSubmitted: _onPinConfirmed,
                      ),
                      ShopInfoScreen(
                        initialShopName: _shopName,
                        initialOwnerName: _ownerName,
                        initialAddress: _address,
                        onSubmitted: _onShopInfoSubmitted,
                      ),
                      LocationPickScreen(onConfirmed: _onLocationConfirmed),
                    ],
                  ),
                  if (_submitError != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 96,
                      child: Material(
                        color: GasColors.out,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_submitError!,
                              style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                      ),
                    ),
                  if (_submitting)
                    const ColoredBox(
                      color: Color(0x66000000),
                      child: Center(
                        child: CircularProgressIndicator(color: GasColors.primary),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.controller,
    required this.total,
    required this.onClose,
  });

  final PageController controller;
  final int total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final page = (controller.hasClients ? (controller.page ?? 0) : 0).round();
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                tooltip: 'Annuler',
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: (page + 1) / total,
                  minHeight: 6,
                  backgroundColor: GasColors.divider,
                  valueColor: const AlwaysStoppedAnimation(GasColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Text('${page + 1} / $total',
                  style: const TextStyle(fontSize: 14, color: GasColors.textSecondary)),
              const SizedBox(width: 4),
            ],
          ),
        );
      },
    );
  }
}
