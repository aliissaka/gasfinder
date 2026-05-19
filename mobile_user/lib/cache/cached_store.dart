import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_flutter/shared_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache for the end-user app. Persists brands and retailers as JSON to
/// SharedPreferences so the map renders instantly on cold start and works
/// offline. Sized for hundreds, not thousands, of retailers — if the dataset
/// grows beyond ~5k rows, migrate to sqflite/Isar.
///
/// Mutates from the sync engine; UI listens via [ChangeNotifier].
class CachedStore extends ChangeNotifier {
  CachedStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const _brandsKey = 'gasfinder.cache.brands.v1';
  static const _retailersKey = 'gasfinder.cache.retailers.v1';
  static const _brandsCursorKey = 'gasfinder.cache.brands_cursor.v1';
  static const _retailersCursorKey = 'gasfinder.cache.retailers_cursor.v1';
  static const _lastSyncAtKey = 'gasfinder.cache.last_sync_at.v1';

  SharedPreferences? _prefs;
  final Map<String, BrandDto> _brands = {};
  final Map<String, RetailerListItem> _retailers = {};
  String? _brandsCursor;
  String? _retailersCursor;
  DateTime? _lastSyncAt;

  List<BrandDto> get brands {
    final list = _brands.values.toList();
    list.sort((a, b) {
      final c = a.displayOrder.compareTo(b.displayOrder);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
    return list;
  }

  List<RetailerListItem> get retailers => _retailers.values.toList();

  String? get brandsCursor => _brandsCursor;
  String? get retailersCursor => _retailersCursor;
  DateTime? get lastSyncAt => _lastSyncAt;
  bool get hasData => _retailers.isNotEmpty || _brands.isNotEmpty;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _loadBrands();
    _loadRetailers();
    _brandsCursor = _prefs!.getString(_brandsCursorKey);
    _retailersCursor = _prefs!.getString(_retailersCursorKey);
    final ts = _prefs!.getString(_lastSyncAtKey);
    _lastSyncAt = ts != null ? DateTime.tryParse(ts) : null;
    notifyListeners();
  }

  Future<void> applyBrandSync({
    required List<BrandDto> changes,
    required List<String> deletes,
    required String cursor,
  }) async {
    for (final id in deletes) {
      _brands.remove(id);
    }
    for (final b in changes) {
      _brands[b.id] = b;
    }
    _brandsCursor = cursor;
    _lastSyncAt = DateTime.now().toUtc();
    await _persistBrands();
    notifyListeners();
  }

  Future<void> applyRetailerSync({
    required List<RetailerListItem> changes,
    required List<String> deletes,
    required String cursor,
    required bool resetExisting,
  }) async {
    if (resetExisting) _retailers.clear();
    for (final id in deletes) {
      _retailers.remove(id);
    }
    for (final r in changes) {
      _retailers[r.id] = r;
    }
    _retailersCursor = cursor;
    _lastSyncAt = DateTime.now().toUtc();
    await _persistRetailers();
    notifyListeners();
  }

  Future<void> clear() async {
    _brands.clear();
    _retailers.clear();
    _brandsCursor = null;
    _retailersCursor = null;
    _lastSyncAt = null;
    await _prefs?.remove(_brandsKey);
    await _prefs?.remove(_retailersKey);
    await _prefs?.remove(_brandsCursorKey);
    await _prefs?.remove(_retailersCursorKey);
    await _prefs?.remove(_lastSyncAtKey);
    notifyListeners();
  }

  void _loadBrands() {
    final raw = _prefs?.getString(_brandsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      for (final j in list) {
        final b = BrandDto.fromJson(j as Map<String, dynamic>);
        _brands[b.id] = b;
      }
    } catch (e) {
      debugPrint('CachedStore: brands parse failed: $e');
    }
  }

  void _loadRetailers() {
    final raw = _prefs?.getString(_retailersKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      for (final j in list) {
        final r = RetailerListItem.fromJson(j as Map<String, dynamic>);
        _retailers[r.id] = r;
      }
    } catch (e) {
      debugPrint('CachedStore: retailers parse failed: $e');
    }
  }

  Future<void> _persistBrands() async {
    final encoded = jsonEncode(_brands.values
        .map((b) => {
              'id': b.id,
              'name': b.name,
              'logoUrl': b.logoUrl,
              'displayOrder': b.displayOrder,
              'updatedAt': b.updatedAt.toIso8601String(),
            })
        .toList());
    await _prefs!.setString(_brandsKey, encoded);
    if (_brandsCursor != null) await _prefs!.setString(_brandsCursorKey, _brandsCursor!);
    if (_lastSyncAt != null) await _prefs!.setString(_lastSyncAtKey, _lastSyncAt!.toIso8601String());
  }

  Future<void> _persistRetailers() async {
    final encoded = jsonEncode(_retailers.values
        .map((r) => {
              'id': r.id,
              'shopName': r.shopName,
              'latitude': r.latitude,
              'longitude': r.longitude,
              'phone': r.phone,
              'photoUrl': r.photoUrl,
              'updatedAt': r.updatedAt.toIso8601String(),
              'availableBrandIds': r.availableBrandIds,
            })
        .toList());
    await _prefs!.setString(_retailersKey, encoded);
    if (_retailersCursor != null) await _prefs!.setString(_retailersCursorKey, _retailersCursor!);
    if (_lastSyncAt != null) await _prefs!.setString(_lastSyncAtKey, _lastSyncAt!.toIso8601String());
  }
}
