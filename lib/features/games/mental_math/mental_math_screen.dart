import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mental_math_controller.dart';
import '../stroop/stroop_models.dart';
import '../../../shared/theme/color_tokens.dart';

class MentalMathScreen extends ConsumerStatefulWidget {
  final void Function(GameResult) onResult;

  const MentalMathScreen({super.key, required this.onResult});

  @override
  ConsumerState<MentalMathScreen> createState() => _MentalMathScreenState();
}

class _MentalMathScreenState extends ConsumerState<MentalMathScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _wrongAnimController;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _wrongAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _wrongAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mentalMathControllerProvider);

    ref.listen(mentalMathControllerProvider, (prev, next) {
      if (next.status == GameStatus.success) {
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onResult(GameResult.success);
        });
      }
      if (next.lastWasWrong && !(prev?.lastWasWrong ?? false)) {
        _wrongAnimController.forward(from: 0);
      }
    });

    if (!_started && state.status == GameStatus.idle) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mentalMathControllerProvider.notifier).start();
      });
    }

    return Container(
      color: kBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Streak dots
              _buildStreakDots(state.consecutiveCorrect),
              const SizedBox(height: 8),
              Text(
                'GET 5 CORRECT IN A ROW',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                  color: kTextSecondary,
                  letterSpacing: 2,
                ),
              ),
              // Question
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.lastWasWrong)
                        AnimatedBuilder(
                          animation: _wrongAnimController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: 1 - _wrongAnimController.value,
                              child: const Text(
                                'STREAK RESET!',
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: kAccentRed,
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 24),
                        decoration: BoxDecoration(
                          color: kSurfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kDivider),
                          boxShadow: [
                            BoxShadow(
                              color: kAccentCyan.withValues(alpha: 0.08),
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: Text(
                          state.currentQuestion?.displayString ?? '...',
                          style: const TextStyle(
                            fontFamily: 'FiraCode',
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Input display
                      Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: state.userInput.isNotEmpty
                                ? kAccentCyan
                                : kDivider,
                          ),
                        ),
                        child: Text(
                          state.userInput.isEmpty ? '_' : state.userInput,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'FiraCode',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: state.userInput.isEmpty
                                ? kTextSecondary
                                : kTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Custom keypad
              _buildKeypad(ref, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakDots(int streak) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final isFilled = index < streak;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isFilled ? 20 : 16,
            height: isFilled ? 20 : 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? kAccentGreen : kSurfaceAlt,
              border: Border.all(
                color: isFilled ? kAccentGreen : kDivider,
                width: 2,
              ),
              boxShadow: isFilled
                  ? [
                      BoxShadow(
                        color: kAccentGreen.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: isFilled
                ? const Icon(Icons.check, size: 12, color: Colors.black)
                : null,
          );
        }),
      ),
    );
  }

  Widget _buildKeypad(WidgetRef ref, MentalMathState state) {
    final notifier = ref.read(mentalMathControllerProvider.notifier);

    Widget keyButton(String label, {VoidCallback? onTap, Color? color}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: state.status == GameStatus.running ? onTap : null,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: color ?? kSurfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kDivider),
                ),
                child: Center(
                  child: label == '⌫'
                      ? const Icon(Icons.backspace_outlined,
                          color: kAccentAmber, size: 22)
                      : label == '→'
                          ? const Icon(Icons.arrow_forward,
                              color: Colors.black, size: 22)
                          : Text(
                              label,
                              style: const TextStyle(
                                fontFamily: 'FiraCode',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: kTextPrimary,
                              ),
                            ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [
          keyButton('1', onTap: () => notifier.onDigitTap('1')),
          keyButton('2', onTap: () => notifier.onDigitTap('2')),
          keyButton('3', onTap: () => notifier.onDigitTap('3')),
        ]),
        Row(children: [
          keyButton('4', onTap: () => notifier.onDigitTap('4')),
          keyButton('5', onTap: () => notifier.onDigitTap('5')),
          keyButton('6', onTap: () => notifier.onDigitTap('6')),
        ]),
        Row(children: [
          keyButton('7', onTap: () => notifier.onDigitTap('7')),
          keyButton('8', onTap: () => notifier.onDigitTap('8')),
          keyButton('9', onTap: () => notifier.onDigitTap('9')),
        ]),
        Row(children: [
          keyButton('⌫', onTap: () => notifier.onBackspace()),
          keyButton('0', onTap: () => notifier.onDigitTap('0')),
          keyButton('→', onTap: () => notifier.onSubmit(), color: kAccentCyan),
        ]),
      ],
    );
  }
}
