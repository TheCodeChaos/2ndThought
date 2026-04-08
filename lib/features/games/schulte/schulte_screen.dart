import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'schulte_controller.dart';
import '../stroop/stroop_models.dart';
import '../../../shared/theme/color_tokens.dart';

class SchulteScreen extends ConsumerStatefulWidget {
  final void Function(GameResult) onResult;

  const SchulteScreen({super.key, required this.onResult});

  @override
  ConsumerState<SchulteScreen> createState() => _SchulteScreenState();
}

class _SchulteScreenState extends ConsumerState<SchulteScreen> {
  Timer? _timer;
  int _remainingSeconds = 60;
  bool _started = false;

  @override
  void initState() {
    super.initState();
  }

  void _startGame() {
    if (_started) return;
    _started = true;
    ref.read(schulteControllerProvider.notifier).start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          final elapsed = ref
              .read(schulteControllerProvider.notifier)
              .elapsedMs;
          _remainingSeconds = 60 - (elapsed ~/ 1000);
          if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schulteControllerProvider);

    ref.listen(schulteControllerProvider, (prev, next) {
      if (next.status == GameStatus.failure) {
        _timer?.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onResult(GameResult.failure);
        });
      } else if (next.status == GameStatus.success) {
        _timer?.cancel();
        Future.delayed(const Duration(seconds: 1), () {
          widget.onResult(GameResult.success);
        });
      }
    });

    if (!_started && state.status == GameStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
    }

    return Container(
      color: kBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: kSurfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: kAccentCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: kAccentCyan, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Find: ${state.nextExpected <= 25 ? state.nextExpected : "✓"}',
                          style: const TextStyle(
                            fontFamily: 'FiraCode',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kAccentCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _remainingSeconds <= 8
                          ? kAccentRedDim
                          : kSurfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _remainingSeconds <= 8 ? kAccentRed : kDivider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: _remainingSeconds <= 8
                              ? kAccentRed
                              : kAccentCyan,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_remainingSeconds}s',
                          style: TextStyle(
                            fontFamily: 'FiraCode',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _remainingSeconds <= 8
                                ? kAccentRed
                                : kAccentCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (state.nextExpected - 1) / 25,
                  backgroundColor: kDivider,
                  valueColor: const AlwaysStoppedAnimation(kAccentCyan),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 20),
              // Grid
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                      itemCount: 25,
                      itemBuilder: (context, index) {
                        final cell = state.cells.isNotEmpty
                            ? state.cells[index]
                            : null;
                        if (cell == null) return const SizedBox.shrink();

                        final isWrong = state.wrongCellIndex == index;
                        final isTapped = cell.tapped;

                        return GestureDetector(
                          onTap:
                              (!isTapped && state.status == GameStatus.running)
                              ? () => ref
                                    .read(schulteControllerProvider.notifier)
                                    .onCellTap(cell.number)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isWrong
                                  ? kAccentRed.withValues(alpha: 0.6)
                                  : isTapped
                                  ? kAccentCyan.withValues(alpha: 0.15)
                                  : kSurfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isWrong
                                    ? kAccentRed
                                    : isTapped
                                    ? kAccentCyan.withValues(alpha: 0.4)
                                    : kDivider,
                                width: isWrong ? 2 : 1,
                              ),
                              boxShadow: isTapped
                                  ? [
                                      BoxShadow(
                                        color: kAccentCyan.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${cell.number}',
                                style: TextStyle(
                                  fontFamily: 'FiraCode',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isTapped
                                      ? kAccentCyan.withValues(alpha: 0.4)
                                      : kTextPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
