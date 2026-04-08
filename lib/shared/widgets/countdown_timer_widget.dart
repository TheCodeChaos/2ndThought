import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';

class CountdownTimerWidget extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback onExpired;
  final bool autoStart;

  const CountdownTimerWidget({
    super.key,
    required this.totalSeconds,
    required this.onExpired,
    this.autoStart = true,
  });

  @override
  State<CountdownTimerWidget> createState() => CountdownTimerWidgetState();
}

class CountdownTimerWidgetState extends State<CountdownTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.totalSeconds),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onExpired();
      }
    });
    if (widget.autoStart) {
      _controller.forward();
    }
  }

  void start() => _controller.forward();
  void stop() => _controller.stop();

  double get remainingFraction => 1.0 - _controller.value;
  int get remainingSeconds =>
      ((1.0 - _controller.value) * widget.totalSeconds).ceil();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor(double fraction) {
    if (fraction > 0.5) return kAccentGreen;
    if (fraction > 0.3) return kAccentAmber;
    return kAccentRed;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final fraction = 1.0 - _controller.value;
        final seconds = (fraction * widget.totalSeconds).ceil();
        final color = _getColor(fraction);

        return SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(80, 80),
                painter: _TimerRingPainter(
                  fraction: fraction,
                  color: color,
                ),
              ),
              Text(
                '${seconds}s',
                style: TextStyle(
                  fontFamily: 'FiraCode',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double fraction;
  final Color color;

  _TimerRingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;

    // Background ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = kDivider;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;

    final sweepAngle = 2 * pi * fraction;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}
