import 'package:flutter/material.dart';

/// Action types yang harus dilakukan user untuk complete step
enum OnboardingActionType {
  scroll,        // User harus scroll/swipe
  doubleTap,     // User harus double tap
  tapButton,     // User harus tap button tertentu
  tapCard,       // User harus tap card
  modalClose,    // User harus close modal
  tapToComplete, // User hanya perlu tap untuk selesai
}

/// Model untuk setiap tahap onboarding
class OnboardingStep {
  final int id;
  final String title;
  final String description;
  final String icon; // Emoji icon
  final OnboardingActionType actionRequired;
  final int? targetCardIndex; // Index card yang harus ditampilkan (null jika tidak perlu navigate)
  final Rect? highlightArea; // Area yang harus di-highlight (null untuk full screen atau no highlight)
  final String? modalInstruction; // Instruction yang tampil saat modal muncul
  final bool isCompleted;
  
  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.actionRequired,
    this.targetCardIndex,
    this.highlightArea,
    this.modalInstruction,
    this.isCompleted = false,
  });
  
  OnboardingStep copyWith({
    int? id,
    String? title,
    String? description,
    String? icon,
    OnboardingActionType? actionRequired,
    int? targetCardIndex,
    Rect? highlightArea,
    String? modalInstruction,
    bool? isCompleted,
  }) {
    return OnboardingStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      actionRequired: actionRequired ?? this.actionRequired,
      targetCardIndex: targetCardIndex ?? this.targetCardIndex,
      highlightArea: highlightArea ?? this.highlightArea,
      modalInstruction: modalInstruction ?? this.modalInstruction,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
