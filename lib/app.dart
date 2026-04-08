import 'dart:async';
import 'package:flutter/material.dart';
import 'shared/theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/challenge_overlay/challenge_overlay_screen.dart';
import 'core/services/native_bridge_service.dart';
import 'core/database/db_helper.dart';

class NeuroGateApp extends StatefulWidget {
  final bool showOnboarding;

  const NeuroGateApp({super.key, required this.showOnboarding});

  @override
  State<NeuroGateApp> createState() => _NeuroGateAppState();
}

class _NeuroGateAppState extends State<NeuroGateApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<String>? _blockedAppSubscription;
  bool _isShowingChallenge = false;

  @override
  void initState() {
    super.initState();
    _listenForBlockedApps();
  }

  void _listenForBlockedApps() {
    _blockedAppSubscription =
        NativeBridgeService.instance.onBlockedAppDetected.listen(
      (packageName) {
        debugPrint('NeuroGate: Blocked app detected -> $packageName');
        _showChallengeOverlay(packageName);
      },
      onError: (error) {
        debugPrint('NeuroGate: Event stream error -> $error');
      },
    );
  }

  Future<void> _showChallengeOverlay(String packageName) async {
    // Don't stack multiple challenge overlays
    if (_isShowingChallenge) {
      debugPrint('NeuroGate: Already showing a challenge, ignoring');
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('NeuroGate: Navigator not ready');
      return;
    }

    // Look up the app name from the database
    String appName = packageName;
    try {
      final blockedApps = await DbHelper.instance.getBlockedApps();
      final match = blockedApps.where((a) => a.packageName == packageName);
      if (match.isNotEmpty) {
        appName = match.first.appName;
      }
    } catch (_) {
      // Use package name as fallback
    }

    _isShowingChallenge = true;
    debugPrint('NeuroGate: Navigating to challenge overlay for $appName');

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => ChallengeOverlayScreen(
          packageName: packageName,
          appName: appName,
        ),
      ),
    );

    _isShowingChallenge = false;
    debugPrint('NeuroGate: Challenge overlay dismissed');
  }

  @override
  void dispose() {
    _blockedAppSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroGate',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home:
          widget.showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
