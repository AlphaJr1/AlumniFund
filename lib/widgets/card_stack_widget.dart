import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'income_card.dart';
import 'expense_card.dart';
import 'balance_target_card.dart';
import 'hint_provider.dart';
import '../providers/theme_provider.dart';
import '../models/theme_colors.dart';
import 'theme_reveal_overlay.dart';

/// Card stack widget dengan smooth transition tanpa glitch
class CardStackWidget extends ConsumerStatefulWidget {
  final List<Widget> cards;
  final Function(int cardIndex)? onCardChange;
  final Function(void Function(int))? onNavigateReady;
  final VoidCallback? onScrollDetected; // NEW: Callback for scroll detection

  const CardStackWidget({
    super.key,
    required this.cards,
    this.onCardChange,
    this.onNavigateReady,
    this.onScrollDetected,
  });

  @override
  ConsumerState<CardStackWidget> createState() => _CardStackWidgetState();
}

class _CardStackWidgetState extends ConsumerState<CardStackWidget>
    with SingleTickerProviderStateMixin {
  List<int> _cardOrder = [0, 1, 2]; // Front, middle, back
  double _dragPosition = 0.0;
  bool _isAnimating = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  late FocusNode _focusNode;

  // Track button press state for 3D effect
  bool _isUpButtonPressed = false;
  bool _isDownButtonPressed = false;

  // Scroll debounce - nullable untuk safety
  DateTime? _lastScrollTime;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    // Request focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Expose navigateToCard method to parent
      widget.onNavigateReady?.call(navigateToCard);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _dragPosition += details.delta.dy;
      _dragPosition = _dragPosition.clamp(-600.0, 600.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isAnimating) return;

    final velocity = details.primaryVelocity ?? 0;

    if (_dragPosition < -120 || velocity < -1000) {
      // Swipe up - front card goes to back
      _animateTransition(toBack: true);
    } else if (_dragPosition > 120 || velocity > 1000) {
      // Swipe down - back card comes to front
      _animateTransition(toBack: false);
    } else {
      // Snap back to center
      _snapToCenter();
    }
  }

  void _animateTransition({required bool toBack}) {
    setState(() => _isAnimating = true);

    // Notify parent about scroll/swipe (for onboarding)
    widget.onScrollDetected?.call();

    if (toBack) {
      // Swipe up - single phase: front card exits top
      final target = -700.0;

      _animation = Tween<double>(
        begin: _dragPosition,
        end: target,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ));

      _controller.forward(from: 0).then((_) {
        setState(() {
          final front = _cardOrder.removeAt(0);
          _cardOrder.add(front);
          _dragPosition = 0;
          _isAnimating = false;
        });
        _controller.reset();
      });
    } else {
      // Swipe down - 2-phase animation
      // Phase 1: Back card exits bottom
      final exitTarget = 700.0;

      _animation = Tween<double>(
        begin: _dragPosition,
        end: exitTarget,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInCubic,
      ));

      _controller.forward(from: 0).then((_) {
        // Update order
        setState(() {
          final back = _cardOrder.removeLast();
          _cardOrder.insert(0, back);
        });
        _controller.reset();

        // Phase 2: New front card enters from top
        setState(() {
          _dragPosition = -700.0;
        });

        _animation = Tween<double>(
          begin: -700.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ));

        _controller.forward(from: 0).then((_) {
          setState(() {
            _dragPosition = 0;
            _isAnimating = false;
          });
          _controller.reset();
        });
      });
    }
  }

  // Public method to navigate to specific card
  void navigateToCard(int targetIndex) {
    if (_isAnimating) return;
    if (targetIndex < 0 || targetIndex >= widget.cards.length) return;

    final currentFrontIndex = _cardOrder[0];
    if (currentFrontIndex == targetIndex) return; // Already at target

    // Calculate how many swipes needed
    final currentPos = _cardOrder.indexOf(targetIndex);

    if (currentPos == 1) {
      // Target is middle card - swipe up once
      setState(() => _dragPosition = -200);
      _animateTransition(toBack: true);
    } else if (currentPos == 2) {
      // Target is back card - swipe up twice
      setState(() => _dragPosition = -200);
      _animateTransition(toBack: true);
      // Schedule second swipe after first completes
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && !_isAnimating) {
          setState(() => _dragPosition = -200);
          _animateTransition(toBack: true);
        }
      });
    }
  }

  void _snapToCenter() {
    setState(() => _isAnimating = true);

    _animation = Tween<double>(
      begin: _dragPosition,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward(from: 0).then((_) {
      setState(() => _isAnimating = false);
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    final cardWidth = (size.width * 0.9).clamp(0.0, 600.0);

    return Listener(
      onPointerSignal: (signal) {
        // Handle scroll events
        if (signal is PointerScrollEvent) {
          if (_isAnimating) return;

          // Debouncing: only process scroll every 400ms (increased for more control)
          final now = DateTime.now();
          if (_lastScrollTime != null) {
            final diff = now.difference(_lastScrollTime!).inMilliseconds;
            if (diff < 400) return; // Increased from 300ms
          }
          _lastScrollTime = now;

          final dy = signal.scrollDelta.dy;

          // Higher threshold = need more effort to scroll (less sensitive)
          if (dy.abs() < 60) return; // Increased from 10 to 60

          // Scroll DOWN (positive) = swipe UP (front to back) - SWAPPED
          if (dy > 0) {
            setState(() {
              _isUpButtonPressed = true;
              _dragPosition = -200;
            });
            _animateTransition(toBack: true);

            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) setState(() => _isUpButtonPressed = false);
            });
          }
          // Scroll UP (negative) = swipe DOWN (back to front) - SWAPPED
          else if (dy < 0) {
            setState(() {
              _isDownButtonPressed = true;
              _dragPosition = 200;
            });
            _animateTransition(toBack: false);

            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) setState(() => _isDownButtonPressed = false);
            });
          }
        }
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            // UP actions: PageUp or ArrowUp = swipe up (front to back)
            if (event.logicalKey == LogicalKeyboardKey.pageUp ||
                event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (!_isAnimating) {
                // Trigger UP button press animation
                setState(() => _isUpButtonPressed = true);
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted) setState(() => _isUpButtonPressed = false);
                });

                setState(() => _dragPosition = -200);
                _animateTransition(toBack: true);
              }
            }
            // DOWN actions: PageDown or ArrowDown = swipe down (back to front)
            else if (event.logicalKey == LogicalKeyboardKey.pageDown ||
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (!_isAnimating) {
                // Trigger DOWN button press animation
                setState(() => _isDownButtonPressed = true);
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted) setState(() => _isDownButtonPressed = false);
                });

                setState(() => _dragPosition = 200);
                _animateTransition(toBack: false);
              }
            }
          }
        },
        child: GestureDetector(
          // translucent allows both child AND parent to receive events
          behavior: HitTestBehavior.translucent,
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          child: Stack(
            children: [
              // Cards
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: cardWidth,
                    height: size.height * 0.85,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final currentOffset =
                            _isAnimating ? _animation.value : _dragPosition;

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildCard(2, currentOffset, cardWidth),
                            _buildCard(1, currentOffset, cardWidth),
                            _buildCard(0, currentOffset, cardWidth),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Buttons - positioned relative to card
              if (isDesktop) ...[
                // Calculate button position: card edge + spacing
                Positioned(
                  left: (size.width - cardWidth) / 2 + cardWidth + 24,
                  top: size.height * 0.5 - 80,
                  child: _buildButton(
                    Icons.keyboard_arrow_up,
                    'UP',
                    _isUpButtonPressed,
                    () {
                      if (_isAnimating) return;
                      // UP = swipe up (front card to back)
                      setState(() => _dragPosition = -200);
                      _animateTransition(toBack: true);
                    },
                  ),
                ),

                // Navigation button - DOWN di kanan
                Positioned(
                  left: (size.width - cardWidth) / 2 + cardWidth + 24,
                  top: size.height * 0.5 + 10,
                  child: _buildButton(
                    Icons.keyboard_arrow_down,
                    'DOWN',
                    _isDownButtonPressed,
                    () {
                      if (_isAnimating) return;
                      // DOWN = swipe down (back card to front)
                      setState(() => _dragPosition = 200);
                      _animateTransition(toBack: false);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(int position, double offset, double cardWidth) {
    final index = _cardOrder[position];

    // Base configuration
    double scale = 1.0;
    double yOffset = 0.0;
    // TESTING: ALL SHADOW DISABLED INCLUDING OVERLAY
    double shadowOpacity = 0.0; // FORCED TO 0 - NO OVERLAY AT ALL

    if (position == 2) {
      // Back card
      scale = 0.86;
      yOffset = 48;
      shadowOpacity = 0.0; // DISABLED - was 0.2
    } else if (position == 1) {
      // Middle card
      scale = 0.93;
      yOffset = 24;
      shadowOpacity = 0.0; // DISABLED
    } else {
      // Front card
      scale = 1.0;
      yOffset = 0;
      shadowOpacity = 0.0; // DISABLED
    }

    // Apply drag offset based on direction and position
    if (offset < 0 && position == 0) {
      // Swipe UP - front card moves up and exits
      yOffset += offset;

      final dragProgress = (offset.abs() / 500).clamp(0.0, 1.0);
      scale = 1.0 - (dragProgress * 0.14);
      // NO SHADOW OVERLAY - disabled for testing
      // shadowOpacity = dragProgress * 0.2;
    } else if (offset > 0 && position == 2) {
      // Swipe DOWN Phase 1 - back card moves down and exits
      yOffset += offset;

      final dragProgress = (offset.abs() / 500).clamp(0.0, 1.0);
      scale = 0.86 + (dragProgress * 0.14);
      // NO SHADOW - keep shadowOpacity at 0
      // shadowOpacity = 0.3 - (dragProgress * 0.3);
    } else if (offset < 0 && position == 0 && offset < -600) {
      // Swipe DOWN Phase 2 - front card (ex-back) enters from top to front
      yOffset += offset + 700;

      final progress = ((offset.abs() - 700) / 50).clamp(0.0, 1.0);
      scale = 1.0;
      shadowOpacity = 0.0;
    }

    // Middle and other cards scale up ONLY during phase 1
    if (position == 1) {
      if (offset < -150) {
        // Swipe UP - middle scales up to become front
        final progress = ((offset.abs() - 150) / 350).clamp(0.0, 1.0);
        scale = 0.93 + (progress * 0.07);
        yOffset = 24 - (progress * 24);
        // NO SHADOW - keep shadowOpacity at 0
        // shadowOpacity = 0.15 - (progress * 0.15);
      } else if (offset > 150) {
        // Swipe DOWN phase 1 - middle scales up
        final progress = ((offset.abs() - 150) / 350).clamp(0.0, 1.0);
        scale = 0.93 + (progress * 0.07);
        yOffset = 24 - (progress * 24);
        // NO SHADOW - keep shadowOpacity at 0
        // shadowOpacity = 0.15 - (progress * 0.15);
      }
    } else if (position == 2 && offset < -150) {
      // Swipe UP - back scales up slightly
      final progress = ((offset.abs() - 150) / 350).clamp(0.0, 1.0);
      scale = 0.86 + (progress * 0.07);
      yOffset = 48 - (progress * 24);
      // NO SHADOW - keep shadowOpacity at 0
      // shadowOpacity = 0.3 - (progress * 0.15);
    }

    // Shadow logic: DISABLED FOR TESTING
    // ONLY front card CAN have shadow, and ONLY when moving
    // Shadow intensity grows gradually with movement
    final bool isFrontCard = position == 0;
    final bool isMoving = offset.abs() > 5; // Small threshold to start
    double shadowIntensity = 0.0; // FORCED TO 0 - NO SHADOW AT ALL

    // COMMENTED OUT - testing no shadow
    // if (isFrontCard && isMoving) {
    //   // Gradual shadow intensity based on how far card has moved
    //   final moveProgress = (offset.abs() / 100).clamp(0.0, 1.0);  // 0-100px range
    //   shadowIntensity = moveProgress;  // 0.0 to 1.0
    // }

    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // NO SHADOW - shadowIntensity always 0
            boxShadow: shadowIntensity > 0
                ? [
                    // Ambient shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04 * shadowIntensity),
                      blurRadius: 8 * shadowIntensity,
                      offset: const Offset(0, 0),
                      spreadRadius: 0,
                    ),
                    // Directional shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03 * shadowIntensity),
                      blurRadius: 4 * shadowIntensity,
                      offset: Offset(0, 2 * shadowIntensity),
                      spreadRadius: 0,
                    ),
                  ]
                : const [], // No shadow when not moving
          ),
          child: Opacity(
            opacity: 1.0, // Force 100% solid - no transparency
            child: Stack(
              children: [
                // Original card - always solid
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: widget.cards[index],
                ),
                // Dark overlay DISABLED - no overlay at all
                // if (shadowOpacity > 0.01)
                //   ClipRRect(
                //     borderRadius: BorderRadius.circular(24),
                //     child: Container(
                //       decoration: BoxDecoration(
                //         color: Colors.black.withOpacity(shadowOpacity),
                //         borderRadius: BorderRadius.circular(24),
                //       ),
                //     ),
                //   ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
      IconData icon, String label, bool isPressed, VoidCallback onPressed) {
    return GestureDetector(
      onTapDown: (_) {
        // Set pressed state saat tap down
        setState(() {
          if (label == 'UP') {
            _isUpButtonPressed = true;
          } else {
            _isDownButtonPressed = true;
          }
        });
      },
      onTapUp: (_) {
        // Reset pressed state saat tap up
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              if (label == 'UP') {
                _isUpButtonPressed = false;
              } else {
                _isDownButtonPressed = false;
              }
            });
          }
        });
      },
      onTapCancel: () {
        // Reset jika tap dibatalkan
        setState(() {
          if (label == 'UP') {
            _isUpButtonPressed = false;
          } else {
            _isDownButtonPressed = false;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        // Transform untuk push down effect
        transform: Matrix4.translationValues(
          0,
          isPressed ? 3 : 0, // Geser 3px ke bawah saat pressed
          0,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 70,
            maxHeight: 70,
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            // Kurangi elevation saat pressed untuk depth effect
            elevation: isPressed ? 2 : 6,
            shadowColor: Colors.black.withOpacity(0.3),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              // Splash color yang tegas saat di-tap
              splashColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.4),
              // Highlight color saat pressed
              highlightColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
              // Hover color untuk desktop
              hoverColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              // Splash radius yang lebih besar
              radius: 40,
              child: Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        color: Theme.of(context).colorScheme.primary, size: 24),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
