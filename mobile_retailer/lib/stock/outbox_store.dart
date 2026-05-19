import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_flutter/shared_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists pending [StockUpdateRequest]s to SharedPreferences so they survive
/// app restarts and intermittent connectivity. Acts as the source of truth for
/// "I told the server about this change, but I haven't heard confirmation yet."
///
/// Server idempotency (unique index on retailerId+clientOutboxId) makes
/// repeated flushes safe.
class OutboxStore extends ChangeNotifier {
  OutboxStore({required this.stockApi, SharedPreferences? prefs}) : _prefs = prefs;

  static const _key = 'gasfinder.stock_outbox.v1';

  final StockApi stockApi;
  SharedPreferences? _prefs;
  final List<StockUpdateRequest> _pending = [];
  bool _flushing = false;
  String? _lastError;

  List<StockUpdateRequest> get pending => List.unmodifiable(_pending);
  int get pendingCount => _pending.length;
  bool get flushing => _flushing;
  String? get lastError => _lastError;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    _pending.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _pending.addAll(list.map((e) => StockUpdateRequest.fromJson(e as Map<String, dynamic>)));
      } catch (e) {
        debugPrint('OutboxStore: failed to parse persisted queue: $e');
        await _prefs!.remove(_key);
      }
    }
    notifyListeners();
  }

  Future<void> enqueue(StockUpdateRequest update) async {
    _pending.removeWhere((u) => u.brandId == update.brandId && u.clientOutboxId == update.clientOutboxId);
    _pending.add(update);
    await _persist();
    notifyListeners();
  }

  /// POSTs all pending updates as a single batch. Removes confirmed (accepted
  /// OR duplicate) entries on success. Rejected entries are dropped — they
  /// would never succeed on retry and would block the queue.
  Future<void> flush() async {
    if (_flushing || _pending.isEmpty) return;
    _flushing = true;
    _lastError = null;
    notifyListeners();

    try {
      final batch = StockUpdateBatchRequest(List.of(_pending));
      final resp = await stockApi.submit(batch);

      final clearable = resp.results.where((r) => r.clearable).map((r) => r.clientOutboxId).toSet();
      final rejected = resp.results.where((r) => r.isRejected).toList();

      _pending.removeWhere((u) => clearable.contains(u.clientOutboxId));
      _pending.removeWhere((u) => rejected.any((r) => r.clientOutboxId == u.clientOutboxId));
      await _persist();

      if (rejected.isNotEmpty) {
        _lastError = 'Certaines mises à jour ont été refusées (${rejected.first.message ?? 'non spécifié'})';
      }
    } catch (e) {
      _lastError = 'Synchronisation impossible. Réessayer plus tard.';
      debugPrint('OutboxStore.flush failed: $e');
    } finally {
      _flushing = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    final encoded = jsonEncode(_pending.map((u) => u.toJson()).toList());
    await _prefs!.setString(_key, encoded);
  }
}
