import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_retailer/main.dart';
import 'package:mobile_retailer/stock/outbox_store.dart';
import 'package:shared_flutter/shared_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Retailer app boots to welcome when not authenticated', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final policy = ValueNotifier<AppVersionResponse?>(null);
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      appName: 'retailer',
      appVersionCode: 1,
    );
    final session = AuthSession(apiClient: apiClient, storage: AuthStorage());
    final stockApi = StockApi(apiClient);
    final outbox = OutboxStore(stockApi: stockApi);
    await outbox.init();

    await tester.pumpWidget(GasFinderRetailerApp(
      upgradePolicy: policy,
      session: session,
      authApi: AuthApi(apiClient),
      brandsApi: BrandsApi(apiClient),
      stockApi: stockApi,
      outbox: outbox,
    ));
    expect(find.text('Gas Finder'), findsOneWidget);
    expect(find.text('Connexion'), findsOneWidget);
  });
}
