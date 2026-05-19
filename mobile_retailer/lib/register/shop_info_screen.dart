import 'package:flutter/material.dart';
import 'package:shared_flutter/shared_flutter.dart';

/// Typed-input form for the parts of registration that can't be number-pad-only:
/// shop name (required), owner name (optional), shop address (optional).
class ShopInfoScreen extends StatefulWidget {
  const ShopInfoScreen({
    super.key,
    required this.onSubmitted,
    this.initialShopName,
    this.initialOwnerName,
    this.initialAddress,
  });

  final void Function({
    required String shopName,
    String? ownerName,
    String? address,
  }) onSubmitted;

  final String? initialShopName;
  final String? initialOwnerName;
  final String? initialAddress;

  @override
  State<ShopInfoScreen> createState() => _ShopInfoScreenState();
}

class _ShopInfoScreenState extends State<ShopInfoScreen> {
  late final TextEditingController _shopName =
      TextEditingController(text: widget.initialShopName);
  late final TextEditingController _ownerName =
      TextEditingController(text: widget.initialOwnerName);
  late final TextEditingController _address =
      TextEditingController(text: widget.initialAddress);

  String? _error;

  @override
  void dispose() {
    _shopName.dispose();
    _ownerName.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    final shopName = _shopName.text.trim();
    if (shopName.isEmpty) {
      setState(() => _error = 'Nom de la boutique requis');
      return;
    }

    setState(() => _error = null);
    widget.onSubmitted(
      shopName: shopName,
      ownerName: _ownerName.text.trim().isEmpty ? null : _ownerName.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GasColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text('Votre boutique',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Quelques informations pour vous identifier',
                style: TextStyle(fontSize: 14, color: GasColors.textSecondary),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _shopName,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Nom de la boutique *',
                  prefixIcon: Icon(Icons.storefront),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ownerName,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Votre nom (optionnel)',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _address,
                style: const TextStyle(fontSize: 18),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Adresse (optionnel)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: GasColors.out, fontSize: 16)),
              ],
              const Spacer(),
              BigButton(
                icon: Icons.arrow_forward,
                label: 'Suivant',
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
