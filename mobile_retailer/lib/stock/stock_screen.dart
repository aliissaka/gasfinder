import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_flutter/shared_flutter.dart';
import 'package:uuid/uuid.dart';

import 'outbox_store.dart';

/// Lists all gas brands with a 3-state (Available / Low / Out) toggle row for
/// the logged-in retailer. Optimistic local updates feed an outbox that
/// flushes to the server.
class StockScreen extends StatefulWidget {
  const StockScreen({
    super.key,
    required this.brandsApi,
    required this.stockApi,
    required this.outbox,
  });

  final BrandsApi brandsApi;
  final StockApi stockApi;
  final OutboxStore outbox;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  static const _statuses = ['Available', 'Low', 'Out'];

  final _uuid = const Uuid();
  bool _loading = true;
  String? _error;
  List<BrandDto> _brands = const [];
  final Map<String, String> _status = {}; // brandId -> current status

  @override
  void initState() {
    super.initState();
    widget.outbox.addListener(_onOutboxChanged);
    _load();
  }

  @override
  void dispose() {
    widget.outbox.removeListener(_onOutboxChanged);
    super.dispose();
  }

  void _onOutboxChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.brandsApi.list(),
        widget.stockApi.getMine(),
      ]);
      final brands = results[0] as List<BrandDto>;
      final stock = results[1] as List<StockItemDto>;

      _status.clear();
      for (final s in stock) {
        _status[s.brandId] = s.status;
      }
      // Brands without server-side stock default to Out until the retailer says
      // otherwise — safer for consumers than guessing "Available".
      for (final b in brands) {
        _status.putIfAbsent(b.id, () => 'Out');
      }

      if (!mounted) return;
      setState(() {
        _brands = brands;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les produits. Vérifiez votre connexion.';
      });
    }
  }

  Future<void> _setStatus(BrandDto brand, String newStatus) async {
    if (_status[brand.id] == newStatus) return;
    setState(() => _status[brand.id] = newStatus);

    await widget.outbox.enqueue(StockUpdateRequest(
      clientOutboxId: _uuid.v4(),
      brandId: brand.id,
      status: newStatus,
      reportedAt: DateTime.now().toUtc(),
    ));
    // Fire-and-forget; the outbox notifier already updated the UI.
    unawaited(widget.outbox.flush());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon stock'),
        backgroundColor: GasColors.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          _SyncBadge(outbox: widget.outbox, onRetry: () => widget.outbox.flush()),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: GasColors.primary));
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: GasColors.out),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            BigButton(icon: Icons.refresh, label: 'Réessayer', onPressed: _load),
          ],
        ),
      );
    }
    if (_brands.isEmpty) {
      return const Center(child: Text('Aucune marque disponible'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _brands.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: GasColors.divider),
        itemBuilder: (_, i) {
          final b = _brands[i];
          return _BrandRow(
            brand: b,
            currentStatus: _status[b.id]!,
            onSelect: (s) => _setStatus(b, s),
            statuses: _statuses,
          );
        },
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({
    required this.brand,
    required this.currentStatus,
    required this.onSelect,
    required this.statuses,
  });

  final BrandDto brand;
  final String currentStatus;
  final void Function(String status) onSelect;
  final List<String> statuses;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          BrandLogo(logoUrl: brand.logoUrl, name: brand.name, size: 64),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                for (final s in statuses)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _StatusChip(
                        status: s,
                        selected: currentStatus == s,
                        onTap: () => onSelect(s),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.selected, required this.onTap});

  final String status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      'Available' => (GasColors.available, Icons.check_circle, 'Dispo'),
      'Low'       => (GasColors.low,       Icons.warning,      'Peu'),
      'Out'       => (GasColors.out,       Icons.cancel,       'Vide'),
      _           => (GasColors.divider,   Icons.help,         status),
    };

    return Material(
      color: selected ? color : color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? Colors.white : color, size: 26),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.outbox, required this.onRetry});

  final OutboxStore outbox;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: outbox,
      builder: (_, __) {
        final pending = outbox.pendingCount;
        final flushing = outbox.flushing;
        final error = outbox.lastError != null;

        final (icon, color) = flushing
            ? (Icons.sync, Colors.white70)
            : error
                ? (Icons.sync_problem, GasColors.low)
                : pending > 0
                    ? (Icons.cloud_upload, GasColors.low)
                    : (Icons.cloud_done, GasColors.available);

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: flushing
                ? 'Synchronisation…'
                : error
                    ? outbox.lastError
                    : pending > 0
                        ? '$pending en attente'
                        : 'Tout est synchronisé',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 28),
                if (pending > 0 && !flushing)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: const BoxDecoration(
                        color: GasColors.out,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$pending',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: flushing ? null : onRetry,
          ),
        );
      },
    );
  }
}

