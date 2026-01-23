import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Confetti animation widget untuk celebrate 100% target
class ConfettiAnimation extends StatefulWidget {
  final bool show;
  final Duration duration;

  const ConfettiAnimation({
    super.key,
    required this.show,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Confetti> _confettiPieces = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Generate confetti pieces
    for (int i = 0; i < 50; i++) {
      _confettiPieces.add(_Confetti(
        color: _getRandomColor(),
        x: _random.nextDouble(),
        y: -0.1,
        rotation: _random.nextDouble() * 2 * math.pi,
        velocity: 0.3 + _random.nextDouble() * 0.5,
      ));
    }

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(ConfettiAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(
          confettiPieces: _confettiPieces,
          progress: _controller.value,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _Confetti {
  final Color color;
  final double x;
  final double y;
  final double rotation;
  final double velocity;

  _Confetti({
    required this.color,
    required this.x,
    required this.y,
    required this.rotation,
    required this.velocity,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confettiPieces;
  final double progress;

  _ConfettiPainter({
    required this.confettiPieces,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var confetti in confettiPieces) {
      final paint = Paint()
        ..color = confetti.color.withOpacity(1 - progress)
        ..style = PaintingStyle.fill;

      final x = confetti.x * size.width;
      final y = confetti.y * size.height +
          (progress * size.height * confetti.velocity);
      final rotation = confetti.rotation + (progress * 4 * math.pi);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Draw confetti piece (rectangle)
      canvas.drawRect(
        const Rect.fromLTWH(-5, -10, 10, 20),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
