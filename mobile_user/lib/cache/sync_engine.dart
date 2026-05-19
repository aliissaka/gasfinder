import 'package:flutter/foundation.dart';
import 'package:shared_flutter/shared_flutter.dart';

import 'cached_store.dart';

/// Drives the local cache by calling the delta-sync endpoints and merging the
/// results into [CachedStore]. The retailer sync needs a centre; the engine
/// remembers the last one so post-online wakeups can resume without UI input.
class SyncEngine extends ChangeNotifier {
  SyncEngine({required this.api, required this.store, this.radiusMeters = 10000});

  final SyncApi api;
  final CachedStore store;
  final int radiusMeters;

  double? _lastLat;
  double? _lastLon;

  bool _isSyncing = false;
  String? _lastError;

  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  bool get hasLocation => _lastLat != null && _lastLon != null;

  /// Records the latest known centre so subsequent retailer syncs (including
  /// ones triggered by the connectivity listener) reuse it.
  void rememberCenter(double lat, double lon) {
    _lastLat = lat;
    _lastLon = lon;
  }

  /// Full sync: brands first (small, cheap), then retailers around the centre.
  Future<void> syncAll({double? lat, double? lon}) async {
    if (lat != null && lon != null) rememberCenter(lat, lon);
    if (!hasLocation) return;
    await _run(() async {
      await _syncBrands();
      await _syncRetailers();
    });
  }

  Future<void> syncBrandsOnly() => _run(_syncBrands);

  Future<void> _syncBrands() async {
    final resp = await api.brands(cursor: store.brandsCursor);
    if (resp.changes.isEmpty && resp.deletes.isEmpty && resp.cursor == store.brandsCursor) {
      return;
    }
    await store.applyBrandSync(
      changes: resp.changes,
      deletes: resp.deletes,
      cursor: resp.cursor,
    );
  }

  Future<void> _syncRetailers() async {
    final resp = await api.retailers(
      lat: _lastLat!,
      lon: _lastLon!,
      radiusMeters: radiusMeters,
      cursor: store.retailersCursor,
    );
    if (resp.changes.isEmpty && resp.deletes.isEmpty && resp.cursor == store.retailersCursor) {
      return;
    }
    // resetExisting=false: keep previously-cached retailers from earlier centres
    // so the user still sees pins they've recently passed.
    await store.applyRetailerSync(
      changes: resp.changes,
      deletes: resp.deletes,
      cursor: resp.cursor,
      resetExisting: false,
    );
  }

  Future<void> _run(Future<void> Function() body) async {
    if (_isSyncing) return;
    _isSyncing = true;
    _lastError = null;
    notifyListeners();
    try {
      await body();
    } on ApiException catch (e) {
      _lastError = e.message;
      debugPrint('SyncEngine: $e');
    } catch (e) {
      _lastError = 'Synchronisation impossible';
      debugPrint('SyncEngine error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
