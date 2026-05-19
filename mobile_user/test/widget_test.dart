import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_user/cache/cached_store.dart';
import 'package:mobile_user/cache/sync_engine.dart';
import 'package:mobile_user/main.dart';
import 'package:shared_flutter/shared_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Shows UpgradeRequiredScreen when upgrade policy is set', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      appName: 'user',
      appVersionCode: 1,
    );
    final store = CachedStore();
    await store.init();
    final syncEngine = SyncEngine(api: SyncApi(apiClient), store: store);
    final policy = ValueNotifier<AppVersionResponse?>(AppVersionResponse(
      app: 'user',
      minimumVersion: 99,
      recommendedVersion: 99,
      critical: true,
      playStoreUrl: 'https://example.com',
      message: 'Mise à jour requise',
    ));

    await tester.pumpWidget(GasFinderUserApp(
      upgradePolicy: policy,
      retailersApi: RetailersApi(apiClient),
      store: store,
      syncEngine: syncEngine,
    ));

    expect(find.byType(UpgradeRequiredScreen), findsOneWidget);
    expect(find.text('Mise à jour requise'), findsOneWidget);
  });
}
