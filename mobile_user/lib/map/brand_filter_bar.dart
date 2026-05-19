import 'package:flutter/material.dart';
import 'package:shared_flutter/shared_flutter.dart';

/// Horizontal scrolling row of brand logos. Tapping a logo toggles it in/out
/// of the active filter set. Tapping the broom icon clears all filters.
class BrandFilterBar extends StatelessWidget {
  const BrandFilterBar({
    super.key,
    required this.brands,
    required this.selectedBrandIds,
    required this.onToggle,
    required this.onClear,
  });

  final List<BrandDto> brands;
  final Set<String> selectedBrandIds;
  final void Function(String brandId) onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      color: GasColors.card,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Effacer le filtre',
            onPressed: selectedBrandIds.isEmpty ? null : onClear,
            icon: Icon(
              Icons.filter_alt_off,
              size: 28,
              color: selectedBrandIds.isEmpty ? GasColors.divider : GasColors.primary,
            ),
          ),
          const VerticalDivider(width: 1, color: GasColors.divider),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: brands.length,
              itemBuilder: (_, i) {
                final b = brands[i];
                final selected = selectedBrandIds.contains(b.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    decoration: selected
                        ? BoxDecoration(
                            border: Border.all(color: GasColors.primary, width: 3),
                            borderRadius: BorderRadius.circular(14),
                          )
                        : null,
                    child: BrandLogo(
                      logoUrl: b.logoUrl,
                      name: b.name,
                      size: 56,
                      onTap: () => onToggle(b.id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
