import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/db_helper.dart';

const _balancesSettingKey = 'app_balances_json';
const _activeSettingKey = 'active_balance_state_json';

class AppBalanceState {
  final Map<String, int> balancesSeconds;
  final String? activePackageName;
  final int activeStartedAtMs;
  final int activeInitialSeconds;

  const AppBalanceState({
    this.balancesSeconds = const {},
    this.activePackageName,
    this.activeStartedAtMs = 0,
    this.activeInitialSeconds = 0,
  });

  AppBalanceState copyWith({
    Map<String, int>? balancesSeconds,
    String? activePackageName,
    int? activeStartedAtMs,
    int? activeInitialSeconds,
    bool clearActive = false,
  }) {
    return AppBalanceState(
      balancesSeconds: balancesSeconds ?? this.balancesSeconds,
      activePackageName: clearActive
          ? null
          : (activePackageName ?? this.activePackageName),
      activeStartedAtMs: clearActive
          ? 0
          : (activeStartedAtMs ?? this.activeStartedAtMs),
      activeInitialSeconds: clearActive
          ? 0
          : (activeInitialSeconds ?? this.activeInitialSeconds),
    );
  }

  int balanceFor(String packageName) => balancesSeconds[packageName] ?? 0;

  bool isActiveFor(String packageName) {
    return activePackageName == packageName && balanceFor(packageName) > 0;
  }
}

class AppBalanceNotifier extends Notifier<AppBalanceState> {
  Timer? _ticker;

  @override
  AppBalanceState build() {
    _loadState();
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const AppBalanceState();
  }

  Future<void> _loadState() async {
    try {
      final balancesJson = await DbHelper.instance.getSetting(
        _balancesSettingKey,
      );
      final activeJson = await DbHelper.instance.getSetting(_activeSettingKey);

      final balances = <String, int>{};
      if (balancesJson != null && balancesJson.isNotEmpty) {
        final decoded = jsonDecode(balancesJson);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final seconds = entry.value;
            if (seconds is int) {
              balances[entry.key] = seconds;
            } else if (seconds is num) {
              balances[entry.key] = seconds.toInt();
            }
          }
        }
      }

      AppBalanceState next = AppBalanceState(balancesSeconds: balances);

      if (activeJson != null && activeJson.isNotEmpty) {
        final decoded = jsonDecode(activeJson);
        if (decoded is Map<String, dynamic>) {
          final packageName = decoded['package_name'] as String?;
          final startedAt = (decoded['started_at_ms'] as num?)?.toInt() ?? 0;
          final initialSeconds =
              (decoded['initial_seconds'] as num?)?.toInt() ?? 0;

          if (packageName != null && initialSeconds > 0 && startedAt > 0) {
            next = next.copyWith(
              activePackageName: packageName,
              activeStartedAtMs: startedAt,
              activeInitialSeconds: initialSeconds,
            );
          }
        }
      }

      state = next;
      _recomputeActiveBalance();
      debugPrint(
        'AppBalance: Final state loaded - ${state.balancesSeconds.length} apps with balance',
      );
    } catch (e) {
      debugPrint('Failed to load app balance state: $e');
    }
  }

  Future<void> refreshBalance() async {
    await _loadState();
  }

  Future<void> addMinutes(String packageName, int minutes) async {
    final secondsToAdd = minutes * 60;
    await addSeconds(packageName, secondsToAdd);
  }

  Future<void> addSeconds(String packageName, int seconds) async {
    if (seconds <= 0) return;
    _recomputeActiveBalance();

    final nextBalances = Map<String, int>.from(state.balancesSeconds);
    final previousBalance = nextBalances[packageName] ?? 0;
    nextBalances[packageName] = previousBalance + seconds;

    debugPrint(
      'AppBalance: Adding $seconds seconds to $packageName (was $previousBalance, now ${nextBalances[packageName]})',
    );

    state = state.copyWith(balancesSeconds: nextBalances);
    await _persistState();

    debugPrint(
      'AppBalance: Persisted balance for $packageName: ${nextBalances[packageName]} seconds',
    );
  }

  Future<bool> startUsing(String packageName) async {
    _recomputeActiveBalance();

    final available = state.balanceFor(packageName);
    if (available <= 0) return false;

    final nextState = state.copyWith(
      activePackageName: packageName,
      activeStartedAtMs: DateTime.now().millisecondsSinceEpoch,
      activeInitialSeconds: available,
    );
    state = nextState;
    _ensureTicker();
    await _persistState();
    return true;
  }

  Future<void> stopUsing({bool keepBalance = true}) async {
    _recomputeActiveBalance();
    if (!keepBalance && state.activePackageName != null) {
      final packageName = state.activePackageName!;
      final nextBalances = Map<String, int>.from(state.balancesSeconds);
      nextBalances[packageName] = 0;
      state = state.copyWith(balancesSeconds: nextBalances, clearActive: true);
    } else {
      state = state.copyWith(clearActive: true);
    }

    _stopTickerIfIdle();
    await _persistState();
  }

  Duration remainingDuration(String packageName) {
    _recomputeActiveBalance();
    return Duration(seconds: state.balanceFor(packageName));
  }

  String statusFor(String packageName) {
    final seconds = state.balanceFor(packageName);
    if (state.isActiveFor(packageName)) {
      return 'active';
    }
    if (seconds <= 0) {
      return 'blocked';
    }
    return 'saved';
  }

  void _ensureTicker() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      final before = state;
      _recomputeActiveBalance();
      if (before != state) {
        await _persistState();
      }
      _stopTickerIfIdle();
    });
  }

  void _stopTickerIfIdle() {
    if (state.activePackageName != null) return;
    _ticker?.cancel();
    _ticker = null;
  }

  void _recomputeActiveBalance() {
    final activePackage = state.activePackageName;
    if (activePackage == null) return;

    final elapsedSeconds =
        ((DateTime.now().millisecondsSinceEpoch - state.activeStartedAtMs) ~/
                1000)
            .clamp(0, 1 << 30);

    final remaining = state.activeInitialSeconds - elapsedSeconds;
    final nextBalances = Map<String, int>.from(state.balancesSeconds);

    if (remaining <= 0) {
      nextBalances[activePackage] = 0;
      state = state.copyWith(balancesSeconds: nextBalances, clearActive: true);
      return;
    }

    if (nextBalances[activePackage] != remaining) {
      nextBalances[activePackage] = remaining;
      state = state.copyWith(balancesSeconds: nextBalances);
    }
  }

  Future<void> _persistState() async {
    try {
      await DbHelper.instance.setSetting(
        _balancesSettingKey,
        jsonEncode(state.balancesSeconds),
      );

      if (state.activePackageName == null) {
        await DbHelper.instance.setSetting(_activeSettingKey, '');
        return;
      }

      await DbHelper.instance.setSetting(
        _activeSettingKey,
        jsonEncode({
          'package_name': state.activePackageName,
          'started_at_ms': state.activeStartedAtMs,
          'initial_seconds': state.activeInitialSeconds,
        }),
      );
    } catch (e) {
      debugPrint('Failed to persist app balance state: $e');
    }
  }
}

final appBalanceProvider =
    NotifierProvider<AppBalanceNotifier, AppBalanceState>(() {
      return AppBalanceNotifier();
    });
