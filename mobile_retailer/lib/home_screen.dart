import 'package:flutter/material.dart';
import 'package:shared_flutter/shared_flutter.dart';

import 'stock/outbox_store.dart';
import 'stock/stock_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.session,
    required this.brandsApi,
    required this.stockApi,
    required this.outbox,
  });

  final AuthSession session;
  final BrandsApi brandsApi;
  final StockApi stockApi;
  final OutboxStore outbox;

  @override
  Widget build(BuildContext context) {
    final auth = session.current;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gas Finder - Détaillant'),
        backgroundColor: GasColors.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => session.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront, size: 96, color: GasColors.primary),
            const SizedBox(height: 16),
            if (auth?.retailerStatus == 'Pending')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GasColors.low.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GasColors.low),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_bottom, color: GasColors.low),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Compte en attente d\'approbation par l\'administrateur',
                        style: TextStyle(color: GasColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            BigButton(
              icon: Icons.inventory_2,
              label: 'Mettre à jour stock',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StockScreen(
                  brandsApi: brandsApi,
                  stockApi: stockApi,
                  outbox: outbox,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
