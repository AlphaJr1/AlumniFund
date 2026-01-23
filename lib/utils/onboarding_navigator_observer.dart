import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../models/onboarding_step.dart';

/// NavigatorObserver untuk detect modal dialogs dalam onboarding
class OnboardingNavigatorObserver extends NavigatorObserver {
  final WidgetRef ref;

  OnboardingNavigatorObserver(this.ref);

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);

    // Check if a dialog was pushed
    if (route is DialogRoute) {
      final onboardingState = ref.read(onboardingProvider);

      // If onboarding active and on steps that require modal interaction
      if (onboardingState.isActive) {
        final currentAction = onboardingState.currentStep.actionRequired;

        if (currentAction == OnboardingActionType.tapButton ||
            currentAction == OnboardingActionType.tapCard) {
          // Modal opened - mark as open
          ref.read(onboardingProvider.notifier).setModalOpen(true);
        }
      }
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);

    // Check if a dialog was popped
    if (route is DialogRoute) {
      final onboardingState = ref.read(onboardingProvider);

      // If onboarding active and modal was open
      if (onboardingState.isActive && onboardingState.isModalOpen) {
        // Modal closed - complete step
        ref.read(onboardingProvider.notifier).setModalOpen(false);
      }
    }
  }
}
