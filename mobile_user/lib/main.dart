import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_flutter/shared_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'cache/cached_store.dart';
import 'cache/sync_engine.dart';
import 'map/map_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'version_check.dart';

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
    appName: 'user',
    appVersionCode: versionCode,
    onUpgradeRequired: (policy) => upgradePolicy.value = policy,
  );

  final versionApi = VersionApi(apiClient);
  final retailersApi = RetailersApi(apiClient);
  final syncApi = SyncApi(apiClient);

  final store = CachedStore();
  await store.init();

  final syncEngine = SyncEngine(api: syncApi, store: store);

  // Trigger a sync when connectivity is restored. The engine remembers the
  // last centre, so this works even if the user moved the device while offline.
  Connectivity().onConnectivityChanged.listen((results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online && syncEngine.hasLocation && !syncEngine.isSyncing) {
      syncEngine.syncAll();
    }
  });

  final versionCheck = VersionCheckService(
    versionApi: versionApi,
    appName: 'user',
    currentVersion: versionCode,
  );
  versionCheck.runColdStartCheck().then((outcome) {
    if (outcome == VersionCheckOutcome.upgradeRequired &&
        versionCheck.lastPolicy != null) {
      upgradePolicy.value = versionCheck.lastPolicy;
    }
  });

  runApp(GasFinderUserApp(
    upgradePolicy: upgradePolicy,
    retailersApi: retailersApi,
    store: store,
    syncEngine: syncEngine,
  ));
}

class GasFinderUserApp extends StatefulWidget {
  const GasFinderUserApp({
    super.key,
    required this.upgradePolicy,
    required this.retailersApi,
    required this.store,
    required this.syncEngine,
  });

  final ValueNotifier<AppVersionResponse?> upgradePolicy;
  final RetailersApi retailersApi;
  final CachedStore store;
  final SyncEngine syncEngine;

  @override
  State<GasFinderUserApp> createState() => _GasFinderUserAppState();
}

class _GasFinderUserAppState extends State<GasFinderUserApp> {
  Future<bool>? _onboardingSeen;

  @override
  void initState() {
    super.initState();
    _onboardingSeen = OnboardingScreen.hasSeen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gas Finder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: GasColors.primary),
        scaffoldBackgroundColor: GasColors.surface,
        useMaterial3: true,
      ),
      home: ValueListenableBuilder<AppVersionResponse?>(
        valueListenable: widget.upgradePolicy,
        builder: (_, policy, __) {
          if (policy != null) {
            return UpgradeRequiredScreen(
              message: policy.message,
              onOpenStore: () async {
                final url = policy.playStoreUrl;
                if (url == null) return;
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            );
          }
          return FutureBuilder<bool>(
            future: _onboardingSeen,
            builder: (_, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.data!) {
                return OnboardingScreen(
                  onDone: () => setState(() {
                    _onboardingSeen = Future.value(true);
                  }),
                );
              }
              return MapScreen(
                retailersApi: widget.retailersApi,
                store: widget.store,
                syncEngine: widget.syncEngine,
              );
            },
          );
        },
      ),
    );
  }
}
