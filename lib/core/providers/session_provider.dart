import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../services/native_bridge_service.dart';

class SessionNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() {
    _loadSessions();
    return {};
  }

  Future<void> _loadSessions() async {
    await DbHelper.instance.deleteExpiredSessions();
  }

  Future<void> grantSession(String packageName, int minutes) async {
    final now = DateTime.now();
    final expiry = now.add(Duration(minutes: minutes));

    final session = ActiveSession(
      packageName: packageName,
      grantedAt: now.millisecondsSinceEpoch,
      expiresAt: expiry.millisecondsSinceEpoch,
      gameType: 'session',
    );

    await DbHelper.instance.insertSession(session);

    try {
      await NativeBridgeService.instance.grantSession(packageName, minutes);
    } catch (e) {
      debugPrint('Failed to grant native session: $e');
    }

    state = {...state, packageName: expiry};
  }

  bool isSessionActive(String packageName) {
    final expiry = state[packageName];
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  Duration? remainingTime(String packageName) {
    final expiry = state[packageName];
    if (expiry == null) return null;
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) return null;
    return remaining;
  }
}

final sessionProvider =
    NotifierProvider<SessionNotifier, Map<String, DateTime>>(() {
  return SessionNotifier();
});
