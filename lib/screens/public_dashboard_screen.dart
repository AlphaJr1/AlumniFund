import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../widgets/card_stack_widget.dart';
import '../widgets/balance_target_card.dart';
import '../widgets/income_card.dart';
import '../widgets/expense_card.dart';
import '../providers/theme_provider.dart';
import '../models/theme_colors.dart';

/// Main public dashboard screen - Redesigned dengan card stack
/// Clean, simple interface tanpa header/footer
class PublicDashboardScreen extends ConsumerStatefulWidget {
  const PublicDashboardScreen({super.key});

  @override
  ConsumerState<PublicDashboardScreen> createState() => _PublicDashboardScreenState();
}

class _PublicDashboardScreenState extends ConsumerState<PublicDashboardScreen>
    with TickerProviderStateMixin {
  // Confetti controllers
  late ConfettiController _confettiControllerLeft;
  late ConfettiController _confettiControllerRight;
  
  // Callback reference to navigate cards
  void Function(int)? _navigateToCardCallback;
  
  // Theme reveal animation state
  AnimationController? _revealController;
  Animation<double>? _revealAnimation;
  Offset? _tapPosition;
  ThemeColors? _oldTheme;
  List<Color>? _oldGradientColors;
  double _maxRadius = 0;

  @override
  void initState() {
    super.initState();
    // Initialize confetti
    _confettiControllerLeft = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiControllerRight = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiControllerLeft.dispose();
    _confettiControllerRight.dispose();
    _revealController?.dispose();
    super.dispose();
  }
  
  // Method to trigger reveal animation - called from CardStackWidget
  void triggerThemeReveal(Offset tapPosition) {
    // Get current theme before changing
    final currentTheme = ref.read(themeProvider);
    final oldPrimaryColor = currentTheme.colors.primary;
    
    // Create gradient shades for old theme
    final hsl = HSLColor.fromColor(oldPrimaryColor);
    final oldColor1 = oldPrimaryColor;
    final oldColor2 = hsl.withLightness((hsl.lightness - 0.05).clamp(0.0, 1.0)).toColor();
    final oldColor3 = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    
    // Calculate max radius
    final size = MediaQuery.of(context).size;
    final corners = [
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    
    double maxDistance = 0;
    for (final corner in corners) {
      final dx = tapPosition.dx - corner.dx;
      final dy = tapPosition.dy - corner.dy;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }
    
    // Dispose old controller if exists
    _revealController?.dispose();
    
    // Create new controller
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _revealAnimation = Tween<double>(
      begin: 0.0,
      end: maxDistance,
    ).animate(CurvedAnimation(
      parent: _revealController!,
      curve: Curves.fastOutSlowIn,
    ));
    
    // Set state with old theme FIRST
    setState(() {
      _tapPosition = tapPosition;
      _oldTheme = currentTheme;
      _oldGradientColors = [oldColor1, oldColor2, oldColor3];
      _maxRadius = maxDistance;
    });
    
    // Wait for next frame to ensure old theme is painted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Trigger theme change after old theme layer is visible
      ref.read(themeProvider.notifier).randomizeThemeWithAnimation();
      
      // Start animation immediately after theme change
      _revealController!.forward().then((_) {
        if (mounted) {
          setState(() {
            _tapPosition = null;
            _oldGradientColors = null;
          });
        }
      });
    });
  }

  // Method to trigger confetti from child widgets AND navigate to IncomeCard
  void triggerConfetti() {
    _confettiControllerLeft.play();
    _confettiControllerRight.play();
    
    // Navigate to IncomeCard (index 1 - Recent Props) after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _navigateToCardCallback?.call(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get dynamic theme colors (NEW theme if animation is running)
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    // Create gradient shades for NEW theme
    final hsl = HSLColor.fromColor(primaryColor);
    final color1 = primaryColor;
    final color2 = hsl.withLightness((hsl.lightness - 0.05).clamp(0.0, 1.0)).toColor();
    final color3 = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND LAYER: New theme gradient (always visible)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTapDown: (details) {
                triggerThemeReveal(details.globalPosition);
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color1, color2, color3],
                  ),
                ),
              ),
            ),
          ),
          
          // REVEAL ANIMATION LAYER: Old theme gradient with circular hole (only during animation)
          if (_tapPosition != null && _oldGradientColors != null && _revealController != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _revealController!,
                  builder: (context, child) {
                    final radius = _revealAnimation?.value ?? 0.0;
                    
                    return CustomPaint(
                      painter: _GradientRevealPainter(
                        center: _tapPosition!,
                        radius: radius,
                        gradientColors: _oldGradientColors!,
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // CONTENT LAYER: Cards (always on top)
          CardStackWidget(
            cards: [
              BalanceTargetCard(
                key: const ValueKey(0),
                onProofSubmitted: triggerConfetti, // Re-add confetti callback!
              ),
              const IncomeCard(key: ValueKey(1)),
              const ExpenseCard(key: ValueKey(2)),
            ],
            onCardChange: (index) {
              // Expose navigate method via callback
            },
            onNavigateReady: (navigateCallback) {
              _navigateToCardCallback = navigateCallback;
            },
          ),
          
          // Confetti from LEFT (shoots to SOUTHEAST - diagonal down-right)
          Positioned(
            left: 0,
            top: MediaQuery.of(context).size.height * 0.4,
            child: ConfettiWidget(
              confettiController: _confettiControllerLeft,
              blastDirection: -pi / 4, // SOUTHEAST (diagonal down-right)
              emissionFrequency: 0.05,
              numberOfParticles: 40,
              maxBlastForce: 60,
              minBlastForce: 30,
              gravity: 0.2,
              colors: const [
                Color(0xFF14B8A6), // Teal
                Color(0xFFEC4899), // Pink
                Color(0xFF8B5CF6), // Purple
                Color(0xFFF97316), // Orange
                Color(0xFFFBBF24), // Yellow
              ],
            ),
          ),
          // Confetti from RIGHT (shoots to SOUTHWEST - diagonal down-left)
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height * 0.4,
            child: ConfettiWidget(
              confettiController: _confettiControllerRight,
              blastDirection: pi + pi / 4, // SOUTHWEST (diagonal down-left)
              emissionFrequency: 0.05,
              numberOfParticles: 40,
              maxBlastForce: 60,
              minBlastForce: 30,
              gravity: 0.2,
              colors: const [
                Color(0xFF14B8A6), // Teal
                Color(0xFFEC4899), // Pink
                Color(0xFF8B5CF6), // Purple
                Color(0xFFF97316), // Orange
                Color(0xFFFBBF24), // Yellow
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that paints gradient with circular hole (inverse clipping)
class _GradientRevealPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final List<Color> gradientColors;
  
  _GradientRevealPainter({
    required this.center,
    required this.radius,
    required this.gradientColors,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create gradient shader
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
    );
    
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final shader = gradient.createShader(rect);
    
    // Create inverse path: full screen MINUS the circle
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final circlePath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    
    final inversePath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(screenRect)
      ..addPath(circlePath, Offset.zero);
    
    // Paint gradient everywhere EXCEPT the circle
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(inversePath, paint);
  }
  
  @override
  bool shouldRepaint(_GradientRevealPainter oldDelegate) {
    return oldDelegate.radius != radius || 
           oldDelegate.center != center ||
           oldDelegate.gradientColors != gradientColors;
  }
}
