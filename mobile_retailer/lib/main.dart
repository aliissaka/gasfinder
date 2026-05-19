import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_flutter/shared_flutter.dart';

import 'home_screen.dart';
import 'register/register_flow.dart';
import 'stock/outbox_store.dart';
import 'version_check.dart';
import 'welcome_screen.dart';

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5180',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final pkg = await PackageInfo.fromPlatform();
  final versionCode = int.tryParse(pkg.buildNumber) ?? 0;

  final upgradePolicy = ValueNotifier<AppVersionResponse?>(null);

  final apiClient = ApiClient(
    baseUrl: kApiBaseUrl,
    appName: 'retailer',
    appVersionCode: versionCode,
    onUpgradeRequired: (policy) => upgradePolicy.value = policy,
  );

  final versionApi = VersionApi(apiClient);
  final authApi = AuthApi(apiClient);
  final brandsApi = BrandsApi(apiClient);
  final stockApi = StockApi(apiClient);

  final authStorage = AuthStorage();
  final session = AuthSession(apiClient: apiClient, storage: authStorage);
  await session.restore();

  final outbox = OutboxStore(stockApi: stockApi);
  await outbox.init();
  // Best-effort flush of anything that survived the last session.
  if (session.isAuthenticated) {
    outbox.flush();
  }

  final versionCheck = VersionCheckService(
    versionApi: versionApi,
    appName: 'retailer',
    currentVersion: versionCode,
  );
  versionCheck.runColdStartCheck().then((outcome) {
    if (outcome == VersionCheckOutcome.upgradeRequired &&
        versionCheck.lastPolicy != null) {
      upgradePolicy.value = versionCheck.lastPolicy;
    }
  });

  runApp(GasFinderRetailerApp(
    upgradePolicy: upgradePolicy,
    session: session,
    authApi: authApi,
    brandsApi: brandsApi,
    stockApi: stockApi,
    outbox: outbox,
  ));
}

class GasFinderRetailerApp extends StatelessWidget {
  const GasFinderRetailerApp({
    super.key,
    required this.upgradePolicy,
    required this.session,
    required this.authApi,
    required this.brandsApi,
    required this.stockApi,
    required this.outbox,
  });

  final ValueNotifier<AppVersionResponse?> upgradePolicy;
  final AuthSession session;
  final AuthApi authApi;
  final BrandsApi brandsApi;
  final StockApi stockApi;
  final OutboxStore outbox;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gas Finder Retailer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: GasColors.primary),
        scaffoldBackgroundColor: GasColors.surface,
        useMaterial3: true,
      ),
      home: ValueListenableBuilder<AppVersionResponse?>(
        valueListenable: upgradePolicy,
        builder: (_, policy, __) {
          if (policy != null) {
            return UpgradeRequiredScreen(
              message: policy.message,
              onOpenStore: () {
                debugPrint('Open Play Store: ${policy.playStoreUrl}');
              },
            );
          }
          return _AuthGate(
            session: session,
            authApi: authApi,
            brandsApi: brandsApi,
            stockApi: stockApi,
            outbox: outbox,
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({
    required this.session,
    required this.authApi,
    required this.brandsApi,
    required this.stockApi,
    required this.outbox,
  });

  final AuthSession session;
  final AuthApi authApi;
  final BrandsApi brandsApi;
  final StockApi stockApi;
  final OutboxStore outbox;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

enum _AuthScreen { welcome, login, register }

class _AuthGateState extends State<_AuthGate> {
  _AuthScreen _screen = _AuthScreen.welcome;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    setState(() => _screen = _AuthScreen.welcome);
    // A fresh login may have queued outbox writes earlier; flush once authenticated.
    if (widget.session.isAuthenticated) {
      widget.outbox.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.isAuthenticated) {
      return HomeScreen(
        session: widget.session,
        brandsApi: widget.brandsApi,
        stockApi: widget.stockApi,
        outbox: widget.outbox,
      );
    }

    switch (_screen) {
      case _AuthScreen.login:
        return LoginFlow(
          authApi: widget.authApi,
          onSuccess: (auth) => widget.session.setAuth(auth),
        );
      case _AuthScreen.register:
        return RegisterFlow(
          authApi: widget.authApi,
          onSuccess: (auth) => widget.session.setAuth(auth),
          onCancel: () => setState(() => _screen = _AuthScreen.welcome),
        );
      case _AuthScreen.welcome:
        return WelcomeScreen(
          onLogin: () => setState(() => _screen = _AuthScreen.login),
          onRegister: () => setState(() => _screen = _AuthScreen.register),
        );
    }
  }
}
