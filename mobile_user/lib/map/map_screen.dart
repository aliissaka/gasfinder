import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_flutter/shared_flutter.dart';

import '../cache/cached_store.dart';
import '../cache/sync_engine.dart';
import 'brand_filter_bar.dart';
import 'retailer_detail_sheet.dart';

/// Cache-first map. Renders retailer pins from [CachedStore] immediately, then
/// fires a background sync via [SyncEngine] to fetch deltas. Brand filtering
/// is client-side over the cache so it's instant and works offline.
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.retailersApi,
    required this.store,
    required this.syncEngine,
  });

  final RetailersApi retailersApi;
  final CachedStore store;
  final SyncEngine syncEngine;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _defaultCenter = LatLng(14.7167, -17.4677); // Dakar fallback

  final MapController _mapController = MapController();
  final Set<String> _selectedBrandIds = {};
  LatLng? _viewCenter;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onCacheChanged);
    widget.syncEngine.addListener(_onSyncChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    widget.store.removeListener(_onCacheChanged);
    widget.syncEngine.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onCacheChanged() {
    if (mounted) setState(() {});
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    final pos = await _tryGetPosition();
    if (!mounted) return;
    final start = pos != null ? LatLng(pos.latitude, pos.longitude) : _defaultCenter;
    setState(() => _viewCenter = start);
    _safeMove(start, 14);
    // Best-effort background sync. Failures keep the cached view intact.
    unawaited(widget.syncEngine.syncAll(lat: start.latitude, lon: start.longitude));
  }

  Future<Position?> _tryGetPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  void _toggleBrand(String brandId) {
    setState(() {
      if (_selectedBrandIds.contains(brandId)) {
        _selectedBrandIds.remove(brandId);
      } else {
        _selectedBrandIds.add(brandId);
      }
    });
  }

  void _clearFilters() {
    if (_selectedBrandIds.isEmpty) return;
    setState(() => _selectedBrandIds.clear());
  }

  void _searchHere() {
    final c = _mapController.camera.center;
    setState(() => _viewCenter = c);
    widget.syncEngine.syncAll(lat: c.latitude, lon: c.longitude);
  }

  Future<void> _recenter() async {
    final pos = await _tryGetPosition();
    if (pos == null || !mounted) return;
    final c = LatLng(pos.latitude, pos.longitude);
    _safeMove(c, 15);
    setState(() => _viewCenter = c);
    widget.syncEngine.syncAll(lat: c.latitude, lon: c.longitude);
  }

  void _safeMove(LatLng to, double zoom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(to, zoom);
      } catch (_) {}
    });
  }

  void _openRetailer(RetailerListItem r) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GasColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RetailerDetailSheet(
        retailerId: r.id,
        retailersApi: widget.retailersApi,
      ),
    );
  }

  List<RetailerListItem> get _filteredRetailers {
    final all = widget.store.retailers;
    if (_selectedBrandIds.isEmpty) return all;
    return all
        .where((r) => r.availableBrandIds.any(_selectedBrandIds.contains))
        .toList();
  }

  Color _pinColor(RetailerListItem r) {
    if (_selectedBrandIds.isEmpty) {
      return r.availableBrandIds.isEmpty ? GasColors.out : GasColors.available;
    }
    final matches = r.availableBrandIds.where(_selectedBrandIds.contains).isNotEmpty;
    return matches ? GasColors.available : GasColors.out;
  }

  @override
  Widget build(BuildContext context) {
    final center = _viewCenter ?? _defaultCenter;
    final retailers = _filteredRetailers;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              minZoom: 4,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gasfinder.mobile_user',
              ),
              MarkerLayer(
                markers: [
                  for (final r in retailers)
                    Marker(
                      point: LatLng(r.latitude, r.longitude),
                      width: 56,
                      height: 56,
                      child: GestureDetector(
                        onTap: () => _openRetailer(r),
                        child: Icon(
                          Icons.local_gas_station,
                          size: 48,
                          color: _pinColor(r),
                          shadows: const [Shadow(blurRadius: 4, color: Colors.black45)],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Column(
              children: [
                BrandFilterBar(
                  brands: widget.store.brands,
                  selectedBrandIds: _selectedBrandIds,
                  onToggle: _toggleBrand,
                  onClear: _clearFilters,
                ),
                _SyncStatusStrip(
                  syncing: widget.syncEngine.isSyncing,
                  error: widget.syncEngine.lastError,
                  lastSyncAt: widget.store.lastSyncAt,
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'recenter',
                  backgroundColor: GasColors.card,
                  foregroundColor: GasColors.primary,
                  onPressed: _recenter,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'search-here',
                  backgroundColor: GasColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: _searchHere,
                  icon: const Icon(Icons.search),
                  label: const Text('Chercher ici'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusStrip extends StatelessWidget {
  const _SyncStatusStrip({
    required this.syncing,
    required this.error,
    required this.lastSyncAt,
  });

  final bool syncing;
  final String? error;
  final DateTime? lastSyncAt;

  @override
  Widget build(BuildContext context) {
    if (syncing) {
      return Container(
        height: 22,
        color: GasColors.primary.withValues(alpha: 0.85),
        alignment: Alignment.center,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 8),
            Text('Mise à jour…',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (error != null) {
      return Container(
        height: 22,
        color: GasColors.out.withValues(alpha: 0.9),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(_lastSyncedText(lastSyncAt),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (lastSyncAt == null) return const SizedBox.shrink();
    return const SizedBox.shrink();
  }

  String _lastSyncedText(DateTime? at) {
    if (at == null) return 'Hors ligne';
    final delta = DateTime.now().toUtc().difference(at.toUtc());
    if (delta.inMinutes < 60) return 'Hors ligne — données il y a ${delta.inMinutes} min';
    if (delta.inHours < 24) return 'Hors ligne — données il y a ${delta.inHours} h';
    return 'Hors ligne — données il y a ${delta.inDays} j';
  }
}

