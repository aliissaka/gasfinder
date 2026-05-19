import 'package:flutter/material.dart';
import '../colors.dart';

/// Square brand-logo tile with optional stock-status badge.
/// The image dominates; the brand name appears small underneath as a
/// secondary cue for users who can read.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    required this.logoUrl,
    required this.name,
    this.statusColor,
    this.onTap,
    this.size = 96,
  });

  final String logoUrl;
  final String name;
  final Color? statusColor;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: GasColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GasColors.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    logoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.local_gas_station, size: 48, color: GasColors.textSecondary),
                  ),
                ),
                if (statusColor != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(fontSize: 12, color: GasColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
