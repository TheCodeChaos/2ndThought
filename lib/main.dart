import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/database/db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0F),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize database
  await DbHelper.instance.database;

  // Check onboarding status
  final onboardingComplete =
      await DbHelper.instance.getSetting('onboarding_complete');
  final showOnboarding = onboardingComplete != 'true';

  // Clean up expired sessions
  await DbHelper.instance.deleteExpiredSessions();

  runApp(
    ProviderScope(
      child: NeuroGateApp(showOnboarding: showOnboarding),
    ),
  );
}
