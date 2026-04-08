import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/db_helper.dart';
import '../../core/providers/app_balance_provider.dart';
import '../../core/providers/stats_provider.dart';
import '../../core/services/native_bridge_service.dart';
import '../../shared/theme/color_tokens.dart';
import '../games/game_router.dart';
import '../games/stroop/stroop_models.dart';

class ChallengeOverlayScreen extends ConsumerStatefulWidget {
  final String packageName;
  final String appName;
  final GameType? gameType;
  final bool fromDashboardTopUp;

  const ChallengeOverlayScreen({
    super.key,
    required this.packageName,
    required this.appName,
    this.gameType,
    this.fromDashboardTopUp = false,
  });

  @override
  ConsumerState<ChallengeOverlayScreen> createState() =>
      _ChallengeOverlayScreenState();
}

class _ChallengeOverlayScreenState
    extends ConsumerState<ChallengeOverlayScreen> {
  late GameType _selectedGame;
  late final Stopwatch _gameStopwatch;
  bool _roundCompleted = false;
  int _roundKey = 0;

  @override
  void initState() {
    super.initState();
    _selectedGame = widget.gameType ?? _pickRandomGame();
    _gameStopwatch = Stopwatch()..start();
  }

  GameType _pickRandomGame() {
    return GameRouterService.selectRandom();
  }

  void _startNextRound({bool forceRandom = false}) {
    setState(() {
      _roundCompleted = false;
      _roundKey++;
      if (forceRandom || widget.gameType == null) {
        _selectedGame = _pickRandomGame();
      }
      _gameStopwatch
        ..reset()
        ..start();
    });
  }

  Future<void> _onGameResult(GameResult result) async {
    if (_roundCompleted) return;
    _roundCompleted = true;
    _gameStopwatch.stop();

    final durationMs = _gameStopwatch.elapsedMilliseconds;
    final isSuccess = result == GameResult.success;
    final focusPoints = isSuccess ? _selectedGame.successPoints : 0;

    // Save to history
    await DbHelper.instance.insertChallengeHistory(
      ChallengeHistoryEntry(
        packageName: widget.packageName,
        appName: widget.appName,
        gameType: _selectedGame.dbKey,
        outcome: isSuccess ? 'success' : 'failure',
        durationMs: durationMs,
        focusPoints: focusPoints,
        playedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    // Invalidate stats providers
    ref.invalidate(totalFocusPointsProvider);
    ref.invalidate(totalWinsProvider);
    ref.invalidate(streakProvider);
    ref.invalidate(challengeHistoryProvider);

    if (isSuccess) {
      final earnedMinutes = _selectedGame.rewardMinutes;
      await ref
          .read(appBalanceProvider.notifier)
          .addMinutes(widget.packageName, earnedMinutes);

      if (mounted) {
        await _showSuccessOverlay(earnedMinutes);
      }
    } else {
      _showFailureBanner();
      _startNextRound(forceRandom: !widget.fromDashboardTopUp);
    }
  }

  Future<void> _showSuccessOverlay(int earnedMinutes) async {
    final totalSeconds = ref
        .read(appBalanceProvider.notifier)
        .remainingDuration(widget.packageName)
        .inSeconds;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kAccentGreen.withValues(alpha: 0.18), kSurface],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kAccentGreen.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAccentGreen.withValues(alpha: 0.2),
                  ),
                  child: const Icon(Icons.check, color: kAccentGreen, size: 42),
                ),
                const SizedBox(height: 16),
                const Text(
                  'YOU WON',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kAccentGreen,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You earned $earnedMinutes minutes!\n${widget.appName} balance is now ${_formatDuration(totalSeconds)}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 13,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+${_selectedGame.successPoints} Focus Points',
                  style: const TextStyle(
                    fontFamily: 'FiraCode',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kAccentCyan,
                  ),
                ),
                const SizedBox(height: 18),
                if (!widget.fromDashboardTopUp)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _openAppNow();
                      },
                      icon: const Icon(Icons.lock_open),
                      label: Text('OPEN ${widget.appName.toUpperCase()}'),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _startNextRound(forceRandom: !widget.fromDashboardTopUp);
                    },
                    icon: const Icon(Icons.sports_esports),
                    label: Text(
                      widget.fromDashboardTopUp
                          ? 'PLAY AGAIN'
                          : 'PLAY ANOTHER GAME',
                    ),
                  ),
                ),
                if (widget.fromDashboardTopUp)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Text('DONE'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAppNow() async {
    final started = await ref
        .read(appBalanceProvider.notifier)
        .startUsing(widget.packageName);
    if (!started) {
      _showFailureBanner(
        customText: 'No balance available yet. Win a game first.',
      );
      return;
    }

    final seconds = ref
        .read(appBalanceProvider.notifier)
        .remainingDuration(widget.packageName)
        .inSeconds;
    final minutesForNative = (seconds / 60).ceil().clamp(1, 180);

    try {
      await NativeBridgeService.instance.grantSession(
        widget.packageName,
        minutesForNative,
      );
      // Wait a moment for native side to process the grant
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Failed to grant session: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(int seconds) {
    final clamped = seconds < 0 ? 0 : seconds;
    final minutes = clamped ~/ 60;
    final secs = clamped % 60;
    return '${minutes}m ${secs.toString().padLeft(2, '0')}s';
  }

  void _showFailureBanner({String? customText}) {
    final text =
        customText ??
        'No minutes earned this round. Try again with a new challenge.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: kAccentRed));
  }

  @override
  Widget build(BuildContext context) {
    final currentBalanceSeconds = ref.watch(
      appBalanceProvider.select(
        (state) => state.balanceFor(widget.packageName),
      ),
    );

    return PopScope(
      canPop: widget.fromDashboardTopUp,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !widget.fromDashboardTopUp) {
          try {
            NativeBridgeService.instance.goToLauncher();
          } catch (_) {}
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: kAccentRed.withValues(alpha: 0.15),
                        border: Border.all(
                          color: kAccentRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: kAccentRed,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${widget.appName} is blocked',
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Balance: ${_formatDuration(currentBalanceSeconds)}',
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.fromDashboardTopUp
                          ? 'Play ${_selectedGame.displayName} to top up ${widget.appName}'
                          : 'Complete a random challenge to earn minutes',
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: kDivider),
              if (!widget.fromDashboardTopUp && currentBalanceSeconds > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openAppNow,
                      icon: const Icon(Icons.lock_open),
                      label: Text(
                        'USE BALANCE TO OPEN ${widget.appName.toUpperCase()}',
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // Game widget
              Expanded(
                child: GameRouterService.buildGame(
                  _selectedGame,
                  key: ValueKey<int>(_roundKey),
                  onResult: _onGameResult,
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(
                  widget.fromDashboardTopUp
                      ? 'Win to add minutes for this app. Lose and try again.'
                      : 'Win to add minutes. Lose and a new random game appears.',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    color: kTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
