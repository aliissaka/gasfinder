import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_user/cache/cached_store.dart';
import 'package:shared_flutter/shared_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

BrandDto _brand(String id, String name, {int order = 0}) => BrandDto(
      id: id,
      name: name,
      logoUrl: 'https://example.com/$id.png',
      displayOrder: order,
      updatedAt: DateTime.utc(2026, 1, 1),
    );

RetailerListItem _retailer(String id, {List<String>? brands}) =>
    RetailerListItem(
      id: id,
      shopName: 'Shop $id',
      latitude: 13.5,
      longitude: 2.1,
      phone: '+22790000000',
      photoUrl: null,
      updatedAt: DateTime.utc(2026, 1, 1),
      availableBrandIds: brands ?? const [],
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CachedStore brand sync', () {
    test('adds and updates brands, sorted by displayOrder then name', () async {
      final store = CachedStore();
      await store.init();

      await store.applyBrandSync(
        changes: [
          _brand('a', 'Total', order: 20),
          _brand('b', 'Oryx', order: 10),
        ],
        deletes: [],
        cursor: 'c1',
      );

      expect(store.brands.map((b) => b.id).toList(), ['b', 'a']);
      expect(store.brandsCursor, 'c1');
    });

    test('applies deletes', () async {
      final store = CachedStore();
      await store.init();

      await store.applyBrandSync(
        changes: [_brand('a', 'A'), _brand('b', 'B')],
        deletes: [],
        cursor: 'c1',
      );
      await store.applyBrandSync(
        changes: [],
        deletes: ['a'],
        cursor: 'c2',
      );

      expect(store.brands.map((b) => b.id).toList(), ['b']);
      expect(store.brandsCursor, 'c2');
    });
  });

  group('CachedStore retailer sync', () {
    test('replaces all when resetExisting is true', () async {
      final store = CachedStore();
      await store.init();

      await store.applyRetailerSync(
        changes: [_retailer('r1'), _retailer('r2')],
        deletes: [],
        cursor: 'c1',
        resetExisting: true,
      );
      expect(store.retailers.length, 2);

      await store.applyRetailerSync(
        changes: [_retailer('r3')],
        deletes: [],
        cursor: 'c2',
        resetExisting: true,
      );
      expect(store.retailers.map((r) => r.id).toList(), ['r3']);
    });

    test('merges deltas when resetExisting is false', () async {
      final store = CachedStore();
      await store.init();

      await store.applyRetailerSync(
        changes: [_retailer('r1'), _retailer('r2')],
        deletes: [],
        cursor: 'c1',
        resetExisting: true,
      );

      await store.applyRetailerSync(
        changes: [_retailer('r3')],
        deletes: ['r1'],
        cursor: 'c2',
        resetExisting: false,
      );

      final ids = store.retailers.map((r) => r.id).toSet();
      expect(ids, {'r2', 'r3'});
      expect(store.retailersCursor, 'c2');
    });
  });

  group('CachedStore persistence', () {
    test('reloads brands and retailers from SharedPreferences', () async {
      final s1 = CachedStore();
      await s1.init();
      await s1.applyBrandSync(
        changes: [_brand('a', 'A')],
        deletes: [],
        cursor: 'c1',
      );
      await s1.applyRetailerSync(
        changes: [_retailer('r1', brands: ['a'])],
        deletes: [],
        cursor: 'c1',
        resetExisting: true,
      );

      final s2 = CachedStore();
      await s2.init();

      expect(s2.brands.length, 1);
      expect(s2.brands.first.id, 'a');
      expect(s2.retailers.length, 1);
      expect(s2.retailers.first.id, 'r1');
      expect(s2.retailers.first.availableBrandIds, ['a']);
      expect(s2.brandsCursor, 'c1');
      expect(s2.retailersCursor, 'c1');
      expect(s2.lastSyncAt, isNotNull);
    });
  });

  test('clear wipes everything', () async {
    final store = CachedStore();
    await store.init();
    await store.applyBrandSync(
      changes: [_brand('a', 'A')],
      deletes: [],
      cursor: 'c1',
    );
    await store.applyRetailerSync(
      changes: [_retailer('r1')],
      deletes: [],
      cursor: 'c1',
      resetExisting: true,
    );

    await store.clear();

    expect(store.brands, isEmpty);
    expect(store.retailers, isEmpty);
    expect(store.brandsCursor, isNull);
    expect(store.retailersCursor, isNull);
    expect(store.lastSyncAt, isNull);
  });
}
