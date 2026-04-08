import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/blocked_apps_provider.dart';
import '../../core/providers/app_balance_provider.dart';
import '../../shared/theme/color_tokens.dart';
import '../app_registry/app_registry_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../games/game_router.dart';

import '../challenge_overlay/challenge_overlay_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: IndexedStack(
        index: _currentTab,
        children: const [_DashboardTab(), AppRegistryScreen(), HistoryScreen()],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: kDivider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (index) => setState(() => _currentTab = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield),
              label: 'Shield',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apps_outlined),
              activeIcon: Icon(Icons.apps),
              label: 'Apps',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAppsAsync = ref.watch(blockedAppsProvider);
    final balanceState = ref.watch(appBalanceProvider);

    // Calculate total balance minutes across all apps
    int calculateTotalBalanceMinutes() {
      int totalSeconds = 0;
      for (final seconds in balanceState.balancesSeconds.values) {
        totalSeconds += seconds;
      }
      return totalSeconds ~/ 60;
    }

    String formatDuration(int seconds) {
      final clamped = seconds < 0 ? 0 : seconds;
      final min = clamped ~/ 60;
      final sec = clamped % 60;
      return '${min}m ${sec.toString().padLeft(2, '0')}s';
    }

    Color statusColor(String status) {
      switch (status) {
        case 'active':
          return kAccentGreen;
        case 'saved':
          return kAccentAmber;
        default:
          return kAccentRed;
      }
    }

    String statusLabel(String status) {
      switch (status) {
        case 'active':
          return 'ACTIVE';
        case 'saved':
          return 'BALANCE SAVED';
        default:
          return 'BLOCKED';
      }
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEUROGATE',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                              letterSpacing: 3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your cognitive shield',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 12,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Focus Points Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          kAccentCyan.withValues(alpha: 0.15),
                          kSurfaceAlt,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: kAccentCyan.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kAccentCyan.withValues(alpha: 0.08),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL BALANCE MINUTES',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 11,
                            color: kTextSecondary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${calculateTotalBalanceMinutes()}',
                          style: const TextStyle(
                            fontFamily: 'FiraCode',
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: kAccentCyan,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: kAccentAmber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Keep going!',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 12,
                                color: kAccentAmber,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Section title
                  const Row(
                    children: [
                      Icon(Icons.block, color: kAccentRed, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'BLOCKED APPS',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kTextSecondary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          // Blocked apps list
          blockedAppsAsync.when(
            data: (apps) {
              if (apps.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: kSurfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kDivider),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 64,
                          color: kTextSecondary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No apps blocked yet',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add apps to start training\nyour focus muscles',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 12,
                            color: kTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Switch to apps tab - parent handles this via state
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('ADD APPS TO BLOCK'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final app = apps[index];
                  final balanceSeconds = balanceState.balanceFor(
                    app.packageName,
                  );
                  final status = ref
                      .read(appBalanceProvider.notifier)
                      .statusFor(app.packageName);
                  final color = statusColor(status);

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kSurfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kDivider),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: kAccentCyan.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.apps,
                          color: kAccentCyan,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        app.appName,
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      subtitle: Text(
                        formatDuration(balanceSeconds),
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 12,
                          color: balanceSeconds > 0
                              ? kTextPrimary
                              : kTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: SizedBox(
                        width: 128,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                statusLabel(status),
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  backgroundColor: kSurface,
                                  builder: (_) => _TopUpSheet(
                                    appName: app.appName,
                                    packageName: app.packageName,
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  'EARN MORE TIME',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 9,
                                    color: kAccentCyan,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }, childCount: apps.length),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: kAccentCyan),
                ),
              ),
            ),
            error: (_, __) => const SliverToBoxAdapter(
              child: Center(
                child: Text(
                  'Error loading apps',
                  style: TextStyle(color: kAccentRed),
                ),
              ),
            ),
          ),
          // Debug Game Menu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Divider(color: kDivider),
                  const SizedBox(height: 12),
                  const Text(
                    'DEBUG / TEST GAMES',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 11,
                      color: kTextSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _DebugGameButton(
                        icon: Icons.palette,
                        label: 'Stroop',
                        color: kAccentRed,
                        gameType: GameType.stroop,
                      ),
                      const SizedBox(width: 8),
                      _DebugGameButton(
                        icon: Icons.grid_on,
                        label: 'Schulte',
                        color: kAccentCyan,
                        gameType: GameType.schulte,
                      ),
                      const SizedBox(width: 8),
                      _DebugGameButton(
                        icon: Icons.calculate,
                        label: 'Math',
                        color: kAccentGreen,
                        gameType: GameType.mentalMath,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final gameType = GameRouterService.selectRandom();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChallengeOverlayScreen(
                              packageName: 'com.test.app',
                              appName: 'Test App',
                              gameType: gameType,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shuffle, size: 18),
                      label: const Text('RANDOM CHALLENGE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopUpSheet extends StatelessWidget {
  final String appName;
  final String packageName;

  const _TopUpSheet({required this.appName, required this.packageName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top up $appName',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pick a game. Win to add minutes instantly for this app.',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 12,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            ...GameType.values.map(
              (game) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: kSurfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kDivider),
                ),
                child: ListTile(
                  leading: Icon(game.icon, color: kAccentCyan),
                  title: Text(
                    game.displayName,
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 13,
                      color: kTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Reward: +${game.rewardMinutes} minutes',
                    style: const TextStyle(
                      fontFamily: 'FiraCode',
                      fontSize: 11,
                      color: kAccentGreen,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: kTextSecondary,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChallengeOverlayScreen(
                          packageName: packageName,
                          appName: appName,
                          gameType: game,
                          fromDashboardTopUp: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugGameButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final GameType gameType;

  const _DebugGameButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.gameType,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChallengeOverlayScreen(
                  packageName: 'com.test.app',
                  appName: 'Test App',
                  gameType: gameType,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
