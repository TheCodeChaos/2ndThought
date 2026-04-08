import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/providers/stats_provider.dart';

import '../../shared/theme/color_tokens.dart';

import 'widgets/focus_win_card.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(challengeHistoryProvider(_selectedFilter));
    final totalPointsAsync = ref.watch(totalFocusPointsProvider);
    final totalWinsAsync = ref.watch(totalWinsProvider);
    final streakAsync = ref.watch(streakProvider);
    final weeklyAsync = ref.watch(weeklyFocusPointsProvider);

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FOCUS LOG',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Stats Row
                    Row(
                      children: [
                        _StatCard(
                          label: 'Wins',
                          value: totalWinsAsync.when(
                            data: (v) => '$v',
                            loading: () => '...',
                            error: (_, __) => '0',
                          ),
                          icon: Icons.emoji_events,
                          color: kAccentAmber,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: 'Points',
                          value: totalPointsAsync.when(
                            data: (v) => '$v',
                            loading: () => '...',
                            error: (_, __) => '0',
                          ),
                          icon: Icons.stars,
                          color: kAccentCyan,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: 'Streak',
                          value: streakAsync.when(
                            data: (v) => '${v}d',
                            loading: () => '...',
                            error: (_, __) => '0d',
                          ),
                          icon: Icons.local_fire_department,
                          color: kAccentRed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Weekly chart
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kSurfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kDivider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WEEKLY FOCUS',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 11,
                              color: kTextSecondary,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: weeklyAsync.when(
                              data: (data) => _buildWeeklyChart(data),
                              loading: () => const Center(
                                child: CircularProgressIndicator(
                                    color: kAccentCyan),
                              ),
                              error: (_, __) => const Center(
                                child: Text('No data',
                                    style: TextStyle(color: kTextSecondary)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: _selectedFilter == null,
                            onTap: () =>
                                setState(() => _selectedFilter = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Stroop',
                            selected: _selectedFilter == 'stroop',
                            onTap: () =>
                                setState(() => _selectedFilter = 'stroop'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Schulte',
                            selected: _selectedFilter == 'schulte',
                            onTap: () =>
                                setState(() => _selectedFilter = 'schulte'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Math',
                            selected: _selectedFilter == 'mental_math',
                            onTap: () => setState(
                                () => _selectedFilter = 'mental_math'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            // History list
            historyAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: kTextSecondary.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No challenge history yet',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 14,
                                color: kTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Complete a challenge to see\nyour progress here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 12,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = entries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        child: FocusWinCard(entry: entry),
                      );
                    },
                    childCount: entries.length,
                  ),
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
                    'Error loading history',
                    style: TextStyle(color: kAccentRed),
                  ),
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(Map<String, int> data) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DateFormat('yyyy-MM-dd').format(date);
    });

    final maxY = data.values.fold<int>(0, (a, b) => a > b ? a : b);
    final adjustedMaxY = maxY == 0 ? 100.0 : maxY * 1.3;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: adjustedMaxY,
        barGroups: days.asMap().entries.map((entry) {
          final points = data[entry.value]?.toDouble() ?? 0;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: points,
                color: kAccentCyan,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: adjustedMaxY,
                  color: kDivider.withValues(alpha: 0.3),
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= days.length) {
                  return const SizedBox.shrink();
                }
                final date =
                    DateTime.parse(days[idx]);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('E').format(date).substring(0, 2),
                    style: const TextStyle(
                      fontFamily: 'FiraCode',
                      fontSize: 10,
                      color: kTextSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} pts',
                const TextStyle(
                  fontFamily: 'FiraCode',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kAccentCyan,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'FiraCode',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kAccentCyan.withValues(alpha: 0.15) : kSurfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kAccentCyan : kDivider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? kAccentCyan : kTextSecondary,
          ),
        ),
      ),
    );
  }
}
