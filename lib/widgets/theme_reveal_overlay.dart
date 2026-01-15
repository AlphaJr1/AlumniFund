import 'package:flutter/material.dart';
import 'theme_reveal_painter.dart';

/// Overlay widget that handles circular reveal animation for theme changes
/// Uses INVERSE CLIPPING to reveal new theme inside expanding circle
class ThemeRevealOverlay extends StatefulWidget {
  final Offset tapPosition;
  final VoidCallback onComplete;
  
  const ThemeRevealOverlay({
    super.key,
    required this.tapPosition,
    required this.onComplete,
  });
  
  @override
  State<ThemeRevealOverlay> createState() => _ThemeRevealOverlayState();
}

class _ThemeRevealOverlayState extends State<ThemeRevealOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _radiusAnimation;
  late double _maxRadius;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation controller immediately to avoid LateInitializationError
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Get screen size and start animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final size = MediaQuery.of(context).size;
      _maxRadius = calculateMaxRadius(widget.tapPosition, size);
      
      // Setup radius animation
      _radiusAnimation = Tween<double>(
        begin: 0.0,
        end: _maxRadius,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.fastOutSlowIn,
      ));
      
      // Start animation
      _controller.forward().then((_) {
        // Animation complete - notify parent
        if (mounted) {
          widget.onComplete();
        }
      });
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Use 0.0 radius until animation is set up
        final radius = _radiusAnimation?.value ?? 0.0;
        
        // Transparent paint - the gradient is painted by parent Container
        // We only clip the circular hole
        return CustomPaint(
          painter: ThemeRevealHolePainter(
            center: widget.tapPosition,
            radius: radius,
          ),
          child: Container(),
        );
      },
    );
  }
}

/// Painter that cuts a circular hole to reveal content underneath
class ThemeRevealHolePainter extends CustomPainter {
  final Offset center;
  final double radius;
  
  ThemeRevealHolePainter({
    required this.center,
    required this.radius,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create full screen rect
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Create circular path
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    
    // Create inverse path: full screen MINUS the circle
    // This makes the circle transparent to show new theme
    final inversePath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(screenRect)
      ..addPath(circlePath, Offset.zero);
    
    // Clip to inverse path (everything EXCEPT the circle)
    canvas.clipPath(inversePath);
  }
  
  @override
  bool shouldRepaint(ThemeRevealHolePainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.center != center;
  }
}
