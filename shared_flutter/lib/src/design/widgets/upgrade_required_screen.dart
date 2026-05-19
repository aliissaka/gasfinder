import 'package:flutter/material.dart';
import '../colors.dart';
import 'big_button.dart';

/// Blocking full-screen UI shown when the app cannot proceed without an update.
/// Used as a fallback when the platform in-app-update flow is unavailable
/// (debug build, sideload, Play Store unreachable).
class UpgradeRequiredScreen extends StatelessWidget {
  const UpgradeRequiredScreen({
    super.key,
    required this.onOpenStore,
    this.message,
  });

  final VoidCallback onOpenStore;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: GasColors.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update, size: 120, color: Colors.white),
                const SizedBox(height: 32),
                Text(
                  message ?? 'Mise à jour requise',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Veuillez installer la dernière version pour continuer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 48),
                BigButton(
                  icon: Icons.download,
                  label: 'Mettre à jour',
                  color: Colors.white,
                  foreground: GasColors.primary,
                  onPressed: onOpenStore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
