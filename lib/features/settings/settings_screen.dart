import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/db_helper.dart';
import '../../core/services/native_bridge_service.dart';
import '../../shared/theme/color_tokens.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _sessionDuration = 10;
  int _dailyGoal = 5;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final durationStr =
        await DbHelper.instance.getSetting('session_duration_minutes');
    final goalStr = await DbHelper.instance.getSetting('daily_focus_goal');

    bool permGranted;
    try {
      if (Platform.isAndroid) {
        permGranted =
            await NativeBridgeService.instance.checkAccessibilityEnabled();
      } else {
        permGranted =
            await NativeBridgeService.instance.checkAuthorizationStatus();
      }
    } catch (_) {
      permGranted = false;
    }

    if (mounted) {
      setState(() {
        _sessionDuration =
            double.tryParse(durationStr ?? '10') ?? 10;
        _dailyGoal = int.tryParse(goalStr ?? '5') ?? 5;
        _permissionGranted = permGranted;
      });
    }
  }

  Future<void> _saveSessionDuration(double value) async {
    setState(() => _sessionDuration = value);
    await DbHelper.instance
        .setSetting('session_duration_minutes', value.round().toString());
  }

  Future<void> _saveDailyGoal(int value) async {
    setState(() => _dailyGoal = value);
    await DbHelper.instance
        .setSetting('daily_focus_goal', value.toString());
  }

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will delete all blocked apps, session history, '
          'and reset all settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentRed,
            ),
            child: const Text('RESET'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DbHelper.instance.resetAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data has been reset')),
        );
        _loadSettings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('SETTINGS'),
        titleTextStyle: const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
          letterSpacing: 2,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Session Duration
          _SettingsSection(
            title: 'SESSION DURATION',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Minutes after passing challenge',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: kAccentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_sessionDuration.round()} min',
                        style: const TextStyle(
                          fontFamily: 'FiraCode',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kAccentCyan,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _sessionDuration,
                  min: 5,
                  max: 60,
                  divisions: 11,
                  onChanged: _saveSessionDuration,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Daily Focus Goal
          _SettingsSection(
            title: 'DAILY FOCUS GOAL',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Target challenges per day',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 12,
                    color: kTextSecondary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed:
                          _dailyGoal > 1 ? () => _saveDailyGoal(_dailyGoal - 1) : null,
                      icon: const Icon(Icons.remove_circle_outline,
                          color: kTextSecondary),
                      iconSize: 20,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: kAccentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_dailyGoal',
                        style: const TextStyle(
                          fontFamily: 'FiraCode',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kAccentCyan,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _saveDailyGoal(_dailyGoal + 1),
                      icon: const Icon(Icons.add_circle_outline,
                          color: kAccentCyan),
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Permission Status
          _SettingsSection(
            title: 'PERMISSION STATUS',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _permissionGranted
                          ? Icons.check_circle
                          : Icons.warning,
                      color: _permissionGranted ? kAccentGreen : kAccentAmber,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _permissionGranted ? 'Enabled' : 'Disabled',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 14,
                        color: _permissionGranted
                            ? kAccentGreen
                            : kAccentAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!_permissionGranted)
                  TextButton(
                    onPressed: () async {
                      if (Platform.isAndroid) {
                        await NativeBridgeService.instance
                            .openAccessibilitySettings();
                      } else {
                        await NativeBridgeService.instance
                            .requestAuthorization();
                      }
                      await Future.delayed(const Duration(seconds: 1));
                      _loadSettings();
                    },
                    child: const Text('FIX'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Reset All Data
          Container(
            decoration: BoxDecoration(
              color: kAccentRed.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kAccentRed.withValues(alpha: 0.2)),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: kAccentRed),
              title: const Text(
                'Reset All Data',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: kAccentRed,
                ),
              ),
              subtitle: const Text(
                'Delete all data and reset settings',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                  color: kTextSecondary,
                ),
              ),
              onTap: _resetAllData,
            ),
          ),
          const SizedBox(height: 32),
          // Version info
          Center(
            child: Text(
              'NeuroGate v1.0.0\n100% Offline',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                color: kTextSecondary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 11,
              color: kTextSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
