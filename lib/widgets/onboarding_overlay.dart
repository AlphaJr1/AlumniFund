import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../models/onboarding_step.dart';
import 'onboarding_feedback_modal.dart';

/// Minimal hint-style onboarding overlay (positioned at top, tidak blocking)
class OnboardingOverlay extends ConsumerStatefulWidget {
  final VoidCallback? onThemeChangeRequest;
  final Function(int)? onNavigateToCard;
  final GlobalKey? cardStackKey;
  
  const OnboardingOverlay({
    super.key,
    this.onThemeChangeRequest,
    this.onNavigateToCard,
    this.cardStackKey,
  });

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Slide down animation for hint (slower for smoother)
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Increased for smoother
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animation
    _slideController.forward();
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
  
  void _closeOnboarding() async {
    await _slideController.reverse();
    if (mounted) {
      ref.read(onboardingProvider.notifier).stopOnboarding();
    }
  }
  
  void _showFeedbackModal() {
    // Reset flag first
    ref.read(onboardingProvider.notifier).resetFeedbackModalFlag();
    
    // Show modal
    showDialog(
      context: context,
      barrierDismissible: false, // Harus click Selesai
      builder: (context) => OnboardingFeedbackModal(
        onComplete: () {
          // Complete onboarding after feedback
          ref.read(onboardingProvider.notifier).completeOnboarding();
        },
      ),
    );
  }
  
  @override
  void didUpdateWidget(OnboardingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
  
  @override
  Widget build(BuildContext context) {
    // Listen to onboarding state changes
    ref.listen(onboardingProvider, (previous, next) {
      if (next.isActive && (previous == null || !previous.isActive)) {
        // Just became active - play animation
        _slideController.reset();
        _slideController.forward();
      } else if (!next.isActive && previous != null && previous.isActive) {
        // Just became inactive - no need to reverse, widget will hide
      }
      
      // Show feedback modal when triggered
      if (next.shouldShowFeedbackModal && (previous == null || !previous.shouldShowFeedbackModal)) {
        _showFeedbackModal();
      }
    });
    
    final state = ref.watch(onboardingProvider);
    
    if (!state.isActive) {
      return const SizedBox.shrink();
    }
    
    final currentStep = state.currentStep;
    
    // Navigate to target card if specified
    if (currentStep.targetCardIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onNavigateToCard?.call(currentStep.targetCardIndex!);
      });
    }
    
    return Stack(
      children: [
        // Minimal hint at top
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildHintPanel(state, currentStep),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHintPanel(OnboardingState state, OnboardingStep step) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isLastStep = step.actionRequired == OnboardingActionType.tapToComplete;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Step number indicator
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${state.currentStepIndex + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          
          // Compact description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.description.split('\n\n').last, // Only instruction part
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Progress dots (mini)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(state.steps.length, (index) {
              final isActive = index == state.currentStepIndex;
              final isCompleted = index < state.currentStepIndex;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: isActive ? 6 : 4,
                height: 4,
                decoration: BoxDecoration(
                  color: (isCompleted || isActive)
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          
          const SizedBox(width: 8),
          
          // Action buttons
          if (!isLastStep)
            TextButton(
              onPressed: () {
                // Lewati → langsung trigger feedback modal
                ref.read(onboardingProvider.notifier).state = 
                  ref.read(onboardingProvider).copyWith(
                    shouldShowFeedbackModal: true,
                  );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Lewati',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                // Complete current step (akan trigger feedback modal)
                ref.read(onboardingProvider.notifier).completeCurrentStep();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                elevation: 0,
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
