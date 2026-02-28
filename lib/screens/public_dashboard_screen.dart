import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../widgets/card_stack_widget.dart';
import '../widgets/brand_identity_card.dart';
import '../widgets/balance_target_card.dart';
import '../widgets/income_card.dart';
import '../widgets/expense_card.dart';
import '../widgets/onboarding_overlay.dart';
import '../providers/theme_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/user_identification_provider.dart';
import '../models/theme_colors.dart';
import '../models/onboarding_step.dart'; // For OnboardingActionType
import '../widgets/onboarding_feedback_modal.dart';

/// Main public dashboard screen - Redesigned dengan card stack
/// Clean, simple interface tanpa header/footer
class PublicDashboardScreen extends ConsumerStatefulWidget {
  const PublicDashboardScreen({super.key});

  @override
  ConsumerState<PublicDashboardScreen> createState() =>
      _PublicDashboardScreenState();
}

class _PublicDashboardScreenState extends ConsumerState<PublicDashboardScreen>
    with TickerProviderStateMixin {
  // Confetti controllers
  late ConfettiController _confettiControllerLeft;
  late ConfettiController _confettiControllerRight;

  // Callback reference to navigate cards
  void Function(int)? _navigateToCardCallback;

  // GlobalKey for CardStack to get position/bounds
  final GlobalKey _cardStackKey = GlobalKey();

  // Modal tracking for onboarding
  bool _wasModalOpen = false;

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
    // Check if onboarding is active and on double tap step
    final onboardingState = ref.read(onboardingProvider);
    if (onboardingState.isActive &&
        onboardingState.currentStep.actionRequired ==
            OnboardingActionType.doubleTap) {
      // Delay completion untuk lihat theme animation dulu (1.5 detik)
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          ref.read(onboardingProvider.notifier).completeCurrentStep();
        }
      });
    }

    // Get current theme before changing
    final currentTheme = ref.read(themeProvider);
    final oldPrimaryColor = currentTheme.colors.primary;

    // Create gradient shades for old theme
    final hsl = HSLColor.fromColor(oldPrimaryColor);
    final oldColor1 = oldPrimaryColor;
    final oldColor2 =
        hsl.withLightness((hsl.lightness - 0.05).clamp(0.0, 1.0)).toColor();
    final oldColor3 =
        hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();

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

  // Handle scroll detected from CardStackWidget (for onboarding step 1)
  void _handleScrollDetected() {
    final onboardingState = ref.read(onboardingProvider);
    if (onboardingState.isActive &&
        onboardingState.currentStep.actionRequired ==
            OnboardingActionType.scroll) {
      ref.read(onboardingProvider.notifier).completeCurrentStep();
    }
  }

  // Check modal state for onboarding steps 3-5
  void _checkModalStateForOnboarding(BuildContext context) {
    final onboardingState = ref.read(onboardingProvider);

    // Only check if onboarding is active and on steps that require modal
    if (!onboardingState.isActive) {
      _wasModalOpen = false;
      return;
    }

    final currentAction = onboardingState.currentStep.actionRequired;
    if (currentAction != OnboardingActionType.tapButton &&
        currentAction != OnboardingActionType.tapCard) {
      _wasModalOpen = false;
      return;
    }

    // Simple check: if Navigator can pop, there's likely a dialog/modal above
    // This works because PublicDashboardScreen is the root, so canPop means modal
    final isModalOpen = Navigator.of(context).canPop();

    // Debug print
    // if (_wasModalOpen != isModalOpen) {
    //   debugPrint('[Onboarding] Modal state changed: wasOpen=$_wasModalOpen, isNowOpen=$isModalOpen');
    // }

    // Detect state change: modal opened
    if (isModalOpen && !_wasModalOpen) {
      _wasModalOpen = true;
      ref.read(onboardingProvider.notifier).setModalOpen(true);
      // debugPrint('[Onboarding] Modal opened - set state to true');
    }
    // Detect state change: modal closed
    else if (!isModalOpen && _wasModalOpen) {
      _wasModalOpen = false;
      ref.read(onboardingProvider.notifier).setModalOpen(false);
      // debugPrint('[Onboarding] Modal closed - completing step');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check modal state for onboarding (steps 3-5)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkModalStateForOnboarding(context);
    });

    // Get dynamic theme colors (NEW theme if animation is running)
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Create gradient shades for NEW theme
    final hsl = HSLColor.fromColor(primaryColor);
    final color1 = primaryColor;
    final color2 =
        hsl.withLightness((hsl.lightness - 0.05).clamp(0.0, 1.0)).toColor();
    final color3 =
        hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();

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
          if (_tapPosition != null &&
              _oldGradientColors != null &&
              _revealController != null)
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
            key: _cardStackKey,
            cards: [
              Consumer(
                key: const ValueKey(0),
                builder: (context, ref, _) {
                  final userState = ref.watch(userIdentificationProvider);
                  final userId = userState.userData?.userId;
                  return BrandIdentityCard(
                    userId: userId,
                  );
                },
              ),
              BalanceTargetCard(
                key: const ValueKey(1),
                onProofSubmitted: triggerConfetti,
                onModalOpen: () {
                  final state = ref.read(onboardingProvider);
                  if (state.isActive &&
                      state.currentStep.actionRequired ==
                          OnboardingActionType.tapButton) {
                    ref.read(onboardingProvider.notifier).setModalOpen(true);
                  }
                },
                onModalClose: () {
                  final state = ref.read(onboardingProvider);
                  if (state.isActive &&
                      state.currentStep.actionRequired ==
                          OnboardingActionType.tapButton) {
                    ref.read(onboardingProvider.notifier).setModalOpen(false);
                  }
                },
              ),
              IncomeCard(
                key: const ValueKey(2),
                onModalOpen: () {
                  final state = ref.read(onboardingProvider);
                  if (state.isActive &&
                      state.currentStep.actionRequired ==
                          OnboardingActionType.tapCard) {
                    ref.read(onboardingProvider.notifier).setModalOpen(true);
                  }
                },
                onModalClose: () {
                  final state = ref.read(onboardingProvider);
                  if (state.isActive &&
                      state.currentStep.actionRequired ==
                          OnboardingActionType.tapCard) {
                    ref.read(onboardingProvider.notifier).setModalOpen(false);
                  }
                },
              ),
              ExpenseCard(
                key: const ValueKey(3),
                onModalOpen: () {
                  final state = ref.read(onboardingProvider);
                  if (state.isActive &&
                      state.currentStep.actionRequired ==
                          OnboardingActionType.tapCard) {
                    ref.read(onboardingProvider.notifier).setModalOpen(true);
                  }
                },
                onModalClose: () {
                  final state = ref.read(onboardingProvider);
                  if (state.isActive &&
                      state.currentStep.actionRequired ==
                          OnboardingActionType.tapCard) {
                    ref.read(onboardingProvider.notifier).setModalOpen(false);
                  }
                },
              ),
            ],
            onCardChange: (index) {
              // Expose navigate method via callback
            },
            onNavigateReady: (navigateCallback) {
              _navigateToCardCallback = navigateCallback;
            },
            onScrollDetected: _handleScrollDetected, // For onboarding step 1
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

          // ONBOARDING OVERLAY (above confetti)
          OnboardingOverlay(
            onThemeChangeRequest: () {
              triggerThemeReveal(Offset(
                MediaQuery.of(context).size.width / 2,
                MediaQuery.of(context).size.height / 2,
              ));
            },
            onNavigateToCard: (index) {
              _navigateToCardCallback?.call(index);
            },
            cardStackKey: _cardStackKey,
          ),
        ],
      ),
      // FLOATING ACTION BUTTON for feedback
      floatingActionButton: _buildFeedbackFAB(context),
    );
  }

  Widget _buildFeedbackFAB(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final scale = 1.0 + (0.1 * (0.5 - (value - 0.5).abs()));

        return Transform.scale(
          scale: scale,
          child: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => OnboardingFeedbackModal(
                  onComplete: () {},
                ),
              );
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
        );
      },
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
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

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
