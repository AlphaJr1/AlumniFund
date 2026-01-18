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
        debugPrint('[FeedbackModal] Failed to submit: $e');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final remainingChars = _maxCharacters - _feedbackController.text.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenWidth * 0.9,
        constraints: BoxConstraints(
          maxWidth: isMobile ? 400 : 500,
          maxHeight: isMobile ? 400 : 500,
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
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    HSLColor.fromColor(Theme.of(context).colorScheme.primary)
                        .withLightness(0.3)
                        .toColor(),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Success icon + message
                  const Text(
                    '✅',
                    style: TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tutorial Selesai!',
                    style: TextStyle(
                      fontSize: isMobile ? 19 : 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Terima kasih sudah mengikuti tutorial',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(height: 12),
                  // Feedback prompt
                  Row(
                    children: [
                      const Text(
                        '💭',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ada saran? Bantu improve app ini bareng!',
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info text
                    Text(
                      'Opsional - sharing aja pengalaman atau ide kamu',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TextField
                    Expanded(
                      child: TextField(
                        controller: _feedbackController,
                        maxLength: _maxCharacters,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        enabled: !_isSubmitting,
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
                        ),
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                        ),
                        onChanged: (value) {
                          setState(() {}); // Update char counter
                        },
                      ),
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
