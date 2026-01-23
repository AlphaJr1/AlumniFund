import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/feedback_service.dart';

/// Modal untuk user feedback di akhir onboarding (step 6)
class OnboardingFeedbackModal extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFeedbackModal({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<OnboardingFeedbackModal> createState() =>
      _OnboardingFeedbackModalState();
}

class _OnboardingFeedbackModalState
    extends ConsumerState<OnboardingFeedbackModal> {
  final TextEditingController _feedbackController = TextEditingController();
  final FeedbackService _feedbackService = FeedbackService();
  bool _isSubmitting = false;

  static const int _maxCharacters = 500;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _handleSelesai() async {
    final feedbackText = _feedbackController.text.trim();

    // Jika ada feedback, submit
    if (feedbackText.isNotEmpty) {
      setState(() => _isSubmitting = true);

      try {
        await _feedbackService.submitFeedback(feedbackText);
      } catch (e) {
        // Silent fail - user tidak perlu tahu jika submit gagal
      } finally {
        setState(() => _isSubmitting = false);
      }
    }

    // Close modal dan complete onboarding
    if (mounted) {
      Navigator.pop(context);
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isMobile = screenWidth < 600;
    final remainingChars = _maxCharacters - _feedbackController.text.length;

    // Hitung tinggi yang tersedia (dengan mempertimbangkan keyboard)
    final availableHeight = screenHeight - keyboardHeight - 100;
    final modalHeight = isMobile 
        ? availableHeight.clamp(300.0, 550.0) 
        : 520.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 40,
        bottom: keyboardHeight + 16, // Tambahkan padding bottom saat keyboard muncul
      ),
      child: Container(
        width: screenWidth * 0.9,
        constraints: BoxConstraints(
          maxWidth: isMobile ? 420 : 520,
          minHeight: 300,
          maxHeight: modalHeight,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (Simplified)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isMobile ? 20 : 24,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Simple title
                  Text(
                    'Tutorial Selesai! ✓',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ada saran untuk perbaikan app?',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content Area (Scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Simple info
                    Text(
                      'Opsional - tulis saran atau feedback kamu',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TextField - TANPA Expanded, gunakan minLines/maxLines
                    TextField(
                      controller: _feedbackController,
                      autofocus: true, // Auto-focus saat modal dibuka
                      maxLength: _maxCharacters,
                      minLines: isMobile ? 4 : 6,
                      maxLines: isMobile ? 8 : 10,
                      textAlignVertical: TextAlignVertical.top,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Tulis di sini...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: isMobile ? 13 : 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        counterText: '',
                        contentPadding: const EdgeInsets.all(16),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 15,
                        height: 1.5,
                      ),
                      onChanged: (value) {
                        setState(() {}); // Update char counter
                      },
                    ),

                    const SizedBox(height: 8),

                    // Character counter
                    Text(
                      '$remainingChars karakter tersisa',
                      style: TextStyle(
                        fontSize: 11,
                        color: remainingChars < 50
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Selesai button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSelesai,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 14 : 16,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'Selesai',
                                style: TextStyle(
                                  fontSize: isMobile ? 15 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
