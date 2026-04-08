import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/db_helper.dart';
import '../../core/services/native_bridge_service.dart';
import '../../shared/theme/color_tokens.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _permissionGranted = false;
  bool _permissionChecked = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    if (_permissionChecked) return;
    _permissionChecked = true;
    bool granted;
    try {
      if (Platform.isAndroid) {
        granted = await NativeBridgeService.instance.checkAccessibilityEnabled();
      } else {
        granted = await NativeBridgeService.instance.checkAuthorizationStatus();
      }
    } catch (_) {
      granted = false;
    }
    if (mounted) {
      setState(() => _permissionGranted = granted);
    }
  }

  Future<void> _requestPermission() async {
    try {
      if (Platform.isAndroid) {
        await NativeBridgeService.instance.openAccessibilitySettings();
      } else {
        await NativeBridgeService.instance.requestAuthorization();
      }
    } catch (_) {
      // Silently fail on simulator
    }
    await Future.delayed(const Duration(seconds: 1));
    _permissionChecked = false; // Allow re-check after request
    await _checkPermission();
  }

  Future<void> _completeOnboarding() async {
    await DbHelper.instance.setSetting('onboarding_complete', 'true');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                  if (page == 2) _checkPermission();
                },
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),
            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? kAccentCyan
                          : kDivider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('BACK',
                          style: TextStyle(color: kTextSecondary)),
                    )
                  else
                    const SizedBox(width: 80),
                  if (_currentPage < 2)
                    ElevatedButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('NEXT'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _permissionGranted ? kAccentCyan : kAccentAmber,
                      ),
                      child: Text(
                        _permissionGranted ? 'GET STARTED' : 'SKIP FOR NOW',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kAccentCyan.withValues(alpha: 0.3),
                  kAccentCyan.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: kAccentCyan.withValues(alpha: 0.5), width: 2),
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 56,
              color: kAccentCyan,
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Break the Loop',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'NeuroGate intercepts distracting apps and makes you solve a brain challenge before you can open them.\n\nNo more mindless scrolling.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 14,
              color: kTextSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'The Science',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your brain has two thinking systems:\n\n'
            '• System 1: Fast, automatic, habitual\n'
            '• System 2: Slow, deliberate, focused\n\n'
            'NeuroGate forces System 2 activation before you can access distracting apps.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 13,
              color: kTextSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _gameTypeIcon(Icons.palette, 'Stroop', kAccentRed),
              _gameTypeIcon(Icons.grid_on, 'Schulte', kAccentCyan),
              _gameTypeIcon(Icons.calculate, 'Math', kAccentGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gameTypeIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 12,
            color: kTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kAccentGreen.withValues(alpha: 0.3),
                  kAccentGreen.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: kAccentGreen.withValues(alpha: 0.5), width: 2),
            ),
            child: Icon(
              _permissionGranted ? Icons.check : Icons.lock_open,
              size: 56,
              color: kAccentGreen,
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Permissions',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            Platform.isAndroid
                ? 'NeuroGate needs Accessibility Service permission to detect when blocked apps open.'
                : 'NeuroGate needs Screen Time permission to block selected apps.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 13,
              color: kTextSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          if (!_permissionGranted)
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: Icon(
                Platform.isAndroid
                    ? Icons.accessibility_new
                    : Icons.screen_lock_portrait,
              ),
              label: Text(
                Platform.isAndroid
                    ? 'ENABLE ACCESSIBILITY'
                    : 'AUTHORIZE SCREEN TIME',
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: kAccentGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: kAccentGreen),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: kAccentGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Permission Granted',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kAccentGreen,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
