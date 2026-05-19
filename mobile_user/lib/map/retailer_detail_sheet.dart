import 'package:flutter/material.dart';
import 'package:shared_flutter/shared_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom sheet shown when a retailer pin is tapped. Loads full details
/// (with per-brand stock) from the server lazily so the map markers stay light.
class RetailerDetailSheet extends StatefulWidget {
  const RetailerDetailSheet({
    super.key,
    required this.retailerId,
    required this.retailersApi,
  });

  final String retailerId;
  final RetailersApi retailersApi;

  @override
  State<RetailerDetailSheet> createState() => _RetailerDetailSheetState();
}

class _RetailerDetailSheetState extends State<RetailerDetailSheet> {
  RetailerDetail? _detail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await widget.retailersApi.get(widget.retailerId);
      if (!mounted) return;
      setState(() => _detail = d);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de charger les détails');
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _directions(double lat, double lon, String label) async {
    final geo = Uri.parse('geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(label)})');
    if (await canLaunchUrl(geo)) {
      await launchUrl(geo);
      return;
    }
    final web = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    await launchUrl(web, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GasColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (d == null && _error == null)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: GasColors.primary)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(_error!, style: const TextStyle(color: GasColors.out)),
                ),
              )
            else ...[
              Text(d!.shopName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (d.address != null) ...[
                const SizedBox(height: 4),
                Text(d.address!,
                    style: const TextStyle(color: GasColors.textSecondary, fontSize: 14)),
              ],
              const SizedBox(height: 8),
              _LastUpdatedChip(updatedAt: d.updatedAt),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BigButton(
                      icon: Icons.phone,
                      label: 'Appeler',
                      color: GasColors.available,
                      onPressed: () => _call(d.phone),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BigButton(
                      icon: Icons.directions,
                      label: 'Itinéraire',
                      onPressed: () => _directions(d.latitude, d.longitude, d.shopName),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Disponibilité',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: d.stock.length,
                  itemBuilder: (_, i) {
                    final s = d.stock[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: BrandLogo(
                        logoUrl: s.logoUrl,
                        name: s.brandName,
                        size: 72,
                        statusColor: _statusColor(s.status),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Available':
        return GasColors.available;
      case 'Low':
        return GasColors.low;
      default:
        return GasColors.out;
    }
  }
}

class _LastUpdatedChip extends StatelessWidget {
  const _LastUpdatedChip({required this.updatedAt});
  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    final delta = DateTime.now().toUtc().difference(updatedAt.toUtc());
    final (color, text) = _formatAge(delta);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  (Color, String) _formatAge(Duration d) {
    if (d.inMinutes < 60) return (GasColors.available, 'Mis à jour il y a ${d.inMinutes} min');
    if (d.inHours < 6) return (GasColors.low, 'Mis à jour il y a ${d.inHours} h');
    if (d.inDays < 1) return (GasColors.out, 'Mis à jour il y a ${d.inHours} h');
    return (GasColors.out, 'Mis à jour il y a ${d.inDays} j');
  }
}
