import 'package:flutter/material.dart';
import 'package:shared_flutter/shared_flutter.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GasColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.storefront, size: 120, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Gas Finder',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Espace détaillant',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const Spacer(),
              BigButton(
                icon: Icons.login,
                label: 'Connexion',
                color: Colors.white,
                foreground: GasColors.primary,
                onPressed: onLogin,
              ),
              const SizedBox(height: 12),
              BigButton(
                icon: Icons.person_add,
                label: 'Créer un compte',
                color: GasColors.accent,
                onPressed: onRegister,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
