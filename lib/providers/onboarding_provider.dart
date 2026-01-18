import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/onboarding_step.dart';

/// State untuk onboarding
class OnboardingState {
  final List<OnboardingStep> steps;
  final int currentStepIndex;
  final bool isActive;
  final bool isModalOpen; // Track jika modal sedang dibuka
  final bool shouldShowFeedbackModal; // Trigger untuk show feedback modal
  
  const OnboardingState({
    required this.steps,
    this.currentStepIndex = 0,
    this.isActive = false,
    this.isModalOpen = false,
    this.shouldShowFeedbackModal = false,
  });
  
  OnboardingStep get currentStep => steps[currentStepIndex];
  bool get isLastStep => currentStepIndex == steps.length - 1;
  bool get isFirstStep => currentStepIndex == 0;
  double get progress => (currentStepIndex + 1) / steps.length;
  
  OnboardingState copyWith({
    List<OnboardingStep>? steps,
    int? currentStepIndex,
    bool? isActive,
    bool? isModalOpen,
    bool? shouldShowFeedbackModal,
  }) {
    return OnboardingState(
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isActive: isActive ?? this.isActive,
      isModalOpen: isModalOpen ?? this.isModalOpen,
      shouldShowFeedbackModal: shouldShowFeedbackModal ?? this.shouldShowFeedbackModal,
    );
  }
}

/// Provider instance
final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(() {
  return OnboardingNotifier();
});

/// Notifier untuk manage onboarding state
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return OnboardingState(steps: _getInitialSteps());
  }
  
  /// Get predefined 6 steps
  static List<OnboardingStep> _getInitialSteps() {
    return const [
      // Step 1: Navigasi
      OnboardingStep(
        id: 1,
        icon: '📱',
        title: 'Navigasi Antar Kartu',
        description: 'Selamat datang!\n\nScroll atau swipe ke atas/bawah\nuntuk berpindah antar kartu',
        actionRequired: OnboardingActionType.scroll,
        targetCardIndex: null,
      ),
      
      // Step 2: Ganti Tema
      OnboardingStep(
        id: 2,
        icon: '🎨',
        title: 'Ubah Tema Aplikasi',
        description: 'Personalisasi Tema\n\nTap 2 kali di area kosong\nuntuk mengubah warna tema aplikasi',
        actionRequired: OnboardingActionType.doubleTap,
        targetCardIndex: 0,
      ),
      
      // Step 3: Drop Your Prop
      OnboardingStep(
        id: 3,
        icon: '💰',
        title: 'Shared Pool',
        description: 'Shared Pool\n\nTap tombol \'Drop Your Prop\'\nuntuk melihat cara berkontribusi',
        actionRequired: OnboardingActionType.tapButton,
        targetCardIndex: 0,
        modalInstruction: 'Fitur Kontribusi\n\n• Upload bukti transfer\n• Input nominal kontribusi\n• Pantau riwayat kontribusi\n\nTutup modal untuk melanjutkan',
      ),
      
      // Step 4: Income Card
      OnboardingStep(
        id: 4,
        icon: '💚',
        title: 'Riwayat Props Masuk',
        description: 'Props yang Masuk\n\nTap kartu ini untuk melihat\nsemua kontribusi yang terkumpul',
        actionRequired: OnboardingActionType.tapCard,
        targetCardIndex: 1,
        modalInstruction: 'Detail Props\n\nSemua kontribusi yang masuk ditampilkan\ndi sini dengan informasi lengkap\n\nTutup modal untuk melanjutkan',
      ),
      
      // Step 5: Expense Card
      OnboardingStep(
        id: 5,
        icon: '💸',
        title: 'Riwayat Pengeluaran',
        description: 'Pengeluaran\n\nTap kartu ini untuk melihat\nalokasi dan penggunaan dana',
        actionRequired: OnboardingActionType.tapCard,
        targetCardIndex: 2,
        modalInstruction: 'Transparansi Dana\n\nSemua pengeluaran tercatat di sini\nuntuk memastikan transparansi penuh\n\nTutup modal untuk melanjutkan',
      ),
    ];
  }
  
  /// Start onboarding
  void startOnboarding() {
    state = state.copyWith(
      isActive: true,
      currentStepIndex: 0,
      steps: _getInitialSteps(),
    );
  }
  
  /// Stop/exit onboarding
  void stopOnboarding() {
    state = state.copyWith(isActive: false);
  }
  
  /// Go to next step
  void nextStep() {
    if (!state.isLastStep) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex + 1);
    }
  }
  
  /// Go to previous step
  void previousStep() {
    if (!state.isFirstStep) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex - 1);
    }
  }
  
  /// Mark current step as completed and auto-advance
  void completeCurrentStep() {
    final updatedSteps = List<OnboardingStep>.from(state.steps);
    updatedSteps[state.currentStepIndex] = state.currentStep.copyWith(isCompleted: true);
    
    state = state.copyWith(steps: updatedSteps);
    
    // Jika ini adalah step terakhir, trigger feedback modal
    if (state.isLastStep) {
      debugPrint('[OnboardingProvider] Last step completed - triggering feedback modal');
      debugPrint('[OnboardingProvider] Current shouldShowFeedbackModal: ${state.shouldShowFeedbackModal}');
      state = state.copyWith(shouldShowFeedbackModal: true);
      debugPrint('[OnboardingProvider] Set shouldShowFeedbackModal = true');
      return;
    }
    
    // Auto-advance to next step after short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (state.isActive && !state.isLastStep) {
        nextStep();
      }
    });
  }
  
  /// Set modal open state
  void setModalOpen(bool isOpen) {
    final wasOpen = state.isModalOpen;
    // debugPrint('[OnboardingProvider] setModalOpen called: wasOpen=$wasOpen, isOpen=$isOpen');
    state = state.copyWith(isModalOpen: isOpen);
    
    // If modal just closed (transition from open to closed), complete step
    if (wasOpen && !isOpen &&
        (state.currentStep.actionRequired == OnboardingActionType.tapButton ||
         state.currentStep.actionRequired == OnboardingActionType.tapCard)) {
      // debugPrint('[OnboardingProvider] Modal closed - calling completeCurrentStep()');
      completeCurrentStep();
    } else {
      // debugPrint('[OnboardingProvider] Not completing step - condition not met');
    }
  }
  
  /// Reset feedback modal flag (after modal is shown)
  void resetFeedbackModalFlag() {
    state = state.copyWith(shouldShowFeedbackModal: false);
  }
  
  /// Complete entire onboarding (stop dan cleanup)
  void completeOnboarding() {
    state = state.copyWith(
      isActive: false,
      shouldShowFeedbackModal: false,
    );
  }
  
  /// Reset onboarding to initial state
  void reset() {
    state = OnboardingState(steps: _getInitialSteps());
  }
}
