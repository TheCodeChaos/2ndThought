import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../services/native_bridge_service.dart';

class BlockedAppsNotifier extends AsyncNotifier<List<BlockedApp>> {
  @override
  Future<List<BlockedApp>> build() async {
    return DbHelper.instance.getBlockedApps();
  }

  Future<void> add(BlockedApp app) async {
    await DbHelper.instance.insertBlockedApp(app);
    state = AsyncData(await DbHelper.instance.getBlockedApps());
    _syncToNative();
  }

  Future<void> remove(String packageName) async {
    await DbHelper.instance.removeBlockedApp(packageName);
    state = AsyncData(await DbHelper.instance.getBlockedApps());
    _syncToNative();
  }

  Future<void> toggle(String packageName, bool active) async {
    await DbHelper.instance.toggleAppActive(packageName, active);
    state = AsyncData(await DbHelper.instance.getBlockedApps());
    _syncToNative();
  }

  Future<void> refresh() async {
    state = AsyncData(await DbHelper.instance.getBlockedApps());
  }

  void _syncToNative() {
    final apps = state.valueOrNull ?? [];
    final activePackages = apps
        .where((a) => a.isActive)
        .map((a) => a.packageName)
        .toList();
    try {
      NativeBridgeService.instance.syncBlockedApps(activePackages);
    } catch (e) {
      debugPrint('Failed to sync to native: $e');
    }
  }
}

final blockedAppsProvider =
    AsyncNotifierProvider<BlockedAppsNotifier, List<BlockedApp>>(() {
  return BlockedAppsNotifier();
});
