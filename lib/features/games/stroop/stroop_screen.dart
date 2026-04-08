import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'stroop_models.dart';
import 'stroop_controller.dart';
import '../../../shared/theme/color_tokens.dart';


class StroopScreen extends ConsumerStatefulWidget {
  final void Function(GameResult) onResult;

  const StroopScreen({super.key, required this.onResult});

  @override
  ConsumerState<StroopScreen> createState() => _StroopScreenState();
}

class _StroopScreenState extends ConsumerState<StroopScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late ConfettiController _confettiController;
  Timer? _timer;
  int _remainingSeconds = 20;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  void _startGame() {
    if (_started) return;
    _started = true;
    ref.read(stroopControllerProvider.notifier).start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          final elapsed =
              ref.read(stroopControllerProvider.notifier).elapsedMs;
          _remainingSeconds = 20 - (elapsed ~/ 1000);
          if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stroopControllerProvider);

    ref.listen(stroopControllerProvider, (prev, next) {
      if (next.status == GameStatus.failure) {
        _timer?.cancel();
        _shakeController.forward().then((_) {
          Future.delayed(const Duration(milliseconds: 400), () {
            widget.onResult(GameResult.failure);
          });
        });
      } else if (next.status == GameStatus.success) {
        _timer?.cancel();
        _confettiController.play();
        Future.delayed(const Duration(seconds: 2), () {
          widget.onResult(GameResult.success);
        });
      }
    });

    if (!_started && state.status == GameStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
    }

    final currentRound = state.currentRound;

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value * ((_shakeController.value * 10).toInt().isEven ? 1 : -1), 0),
              child: child,
            );
          },
          child: Container(
            color: kBackground,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Progress
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: kSurfaceAlt,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kDivider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: kAccentGreen, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${state.correctCount} / 15',
                                style: const TextStyle(
                                  fontFamily: 'FiraCode',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Timer
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _remainingSeconds <= 5
                                ? kAccentRedDim
                                : kSurfaceAlt,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _remainingSeconds <= 5
                                  ? kAccentRed
                                  : kDivider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer,
                                  color: _remainingSeconds <= 5
                                      ? kAccentRed
                                      : kAccentCyan,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${_remainingSeconds}s',
                                style: TextStyle(
                                  fontFamily: 'FiraCode',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _remainingSeconds <= 5
                                      ? kAccentRed
                                      : kAccentCyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: state.correctCount / 15,
                        backgroundColor: kDivider,
                        valueColor: const AlwaysStoppedAnimation(kAccentCyan),
                        minHeight: 4,
                      ),
                    ),
                    // Center - Word display
                    Expanded(
                      child: Center(
                        child: currentRound != null
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'TAP THE INK COLOR',
                                    style: TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 12,
                                      color: kTextSecondary,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 30),
                                    decoration: BoxDecoration(
                                      color: kSurfaceAlt,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: kDivider, width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: currentRound
                                              .inkColor.flutterColor
                                              .withValues(alpha: 0.15),
                                          blurRadius: 40,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      currentRound.word,
                                      style: TextStyle(
                                        fontFamily: 'FiraCode',
                                        fontSize: 72,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            currentRound.inkColor.flutterColor,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    // Bottom - Color buttons
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: StroopColor.values.map((color) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: state.status == GameStatus.running
                                      ? () => ref
                                          .read(stroopControllerProvider
                                              .notifier)
                                          .onTap(color)
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    decoration: BoxDecoration(
                                      color: color.flutterColor,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.flutterColor
                                              .withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      color.label,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'SpaceMono',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              kAccentCyan,
              kAccentGreen,
              kAccentAmber,
              Colors.white,
            ],
          ),
        ),
      ],
    );
  }
}
