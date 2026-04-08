import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeBridgeService {
  static const _channel = MethodChannel('com.neurogate.app/blocker');
  static const _eventChannel =
      EventChannel('com.neurogate.app/blocker_events');

  static NativeBridgeService? _instance;
  StreamController<String>? _blockedAppController;
  bool _eventChannelInitialized = false;

  NativeBridgeService._();

  static NativeBridgeService get instance {
    _instance ??= NativeBridgeService._();
    return _instance!;
  }

  void _setupEventChannel() {
    if (_eventChannelInitialized) return;
    _eventChannelInitialized = true;
    _blockedAppController = StreamController<String>.broadcast();
    try {
      _eventChannel.receiveBroadcastStream().listen(
        (event) {
          if (event is String) {
            _blockedAppController?.add(event);
          }
        },
        onError: (error) {
          debugPrint('EventChannel error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to setup EventChannel: $e');
    }
  }

  Stream<String> get onBlockedAppDetected {
    _setupEventChannel();
    return _blockedAppController?.stream ?? const Stream.empty();
  }

  Future<void> syncBlockedApps(List<String> packageNames) async {
    try {
      await _channel.invokeMethod('syncBlockedApps', {
        'packageNames': packageNames,
      });
    } catch (e) {
      debugPrint('Failed to sync blocked apps: $e');
    }
  }

  Future<void> grantSession(String packageName, int durationMinutes) async {
    try {
      await _channel.invokeMethod('grantSession', {
        'packageName': packageName,
        'durationMinutes': durationMinutes,
      });
    } catch (e) {
      debugPrint('Failed to grant session: $e');
    }
  }

  Future<bool> checkAccessibilityEnabled() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('checkAccessibilityEnabled');
      return result ?? false;
    } catch (e) {
      debugPrint('Failed to check accessibility: $e');
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      debugPrint('Failed to open accessibility settings: $e');
    }
  }

  Future<bool> checkAuthorizationStatus() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('checkAuthorizationStatus');
      return result ?? false;
    } catch (e) {
      debugPrint('Failed to check auth status: $e');
      return false;
    }
  }

  Future<void> requestAuthorization() async {
    try {
      await _channel.invokeMethod('requestAuthorization');
    } catch (e) {
      debugPrint('Failed to request authorization: $e');
    }
  }

  Future<void> goToLauncher() async {
    try {
      await _channel.invokeMethod('goToLauncher');
    } catch (e) {
      debugPrint('Failed to go to launcher: $e');
    }
  }
}
