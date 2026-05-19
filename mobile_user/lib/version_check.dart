import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_flutter/shared_flutter.dart';

/// Outcome of the cold-start version check.
enum VersionCheckOutcome {
  ok,
  flexibleStarted,
  immediateHandled,
  upgradeRequired,
  unknown,
}

class VersionCheckService {
  VersionCheckService({required this.versionApi, required this.appName, required this.currentVersion});

  final VersionApi versionApi;
  final String appName;
  final int currentVersion;

  AppVersionResponse? lastPolicy;

  Future<VersionCheckOutcome> runColdStartCheck() async {
    final policy = await _safelyFetchPolicy();
    lastPolicy = policy;
    if (policy == null) return VersionCheckOutcome.unknown;

    final needsImmediate = policy.critical || policy.isBelowMinimum(currentVersion);
    if (needsImmediate) {
      return await _tryImmediate(policy);
    }

    if (policy.isBelowRecommended(currentVersion)) {
      return await _tryFlexible(policy);
    }

    return VersionCheckOutcome.ok;
  }

  Future<VersionCheckOutcome> handleUpgradeRequired(AppVersionResponse policy) async {
    lastPolicy = policy;
    return _tryImmediate(policy);
  }

  Future<AppVersionResponse?> _safelyFetchPolicy() async {
    try {
      return await versionApi.getPolicy(appName);
    } catch (e) {
      debugPrint('Version policy fetch failed: $e');
      return null;
    }
  }

  Future<VersionCheckOutcome> _tryImmediate(AppVersionResponse policy) async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
        return VersionCheckOutcome.immediateHandled;
      }
    } catch (e) {
      debugPrint('Immediate update flow failed: $e');
    }
    return VersionCheckOutcome.upgradeRequired;
  }

  Future<VersionCheckOutcome> _tryFlexible(AppVersionResponse policy) async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        return VersionCheckOutcome.flexibleStarted;
      }
    } catch (e) {
      debugPrint('Flexible update flow failed: $e');
    }
    return VersionCheckOutcome.ok;
  }
}
