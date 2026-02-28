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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isMobile = screenWidth < 600;
    final remainingChars = _maxCharacters - _feedbackController.text.length;
    final hasKeyboard = keyboardHeight > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: hasKeyboard ? 20 : 40,
        bottom: keyboardHeight > 0 ? keyboardHeight + 8 : 16,
      ),
      child: Container(
        width: screenWidth * 0.9,
        constraints: BoxConstraints(
          maxWidth: isMobile ? 420 : 520,
          minHeight: hasKeyboard ? 280 : 300,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(hasKeyboard ? 16 : 24),
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
            // Header (Compact saat keyboard muncul)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: hasKeyboard ? 12 : (isMobile ? 16 : 20),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(hasKeyboard ? 16 : 24),
                  topRight: Radius.circular(hasKeyboard ? 16 : 24),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Berikan Masukan 💭',
                    style: TextStyle(
                      fontSize: hasKeyboard ? 16 : (isMobile ? 18 : 20),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!hasKeyboard) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ada saran untuk perbaikan app?',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            // Content Area (Scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(hasKeyboard ? 16 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasKeyboard)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Opsional - tulis saran atau feedback kamu',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),

                    // TextField - Compact saat keyboard
                    TextField(
                      controller: _feedbackController,
                      autofocus: true,
                      maxLength: _maxCharacters,
                      minLines: hasKeyboard ? 3 : (isMobile ? 4 : 6),
                      maxLines: hasKeyboard ? 5 : (isMobile ? 8 : 10),
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
                        contentPadding: EdgeInsets.all(hasKeyboard ? 12 : 16),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 15,
                        height: 1.4,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),

                    SizedBox(height: hasKeyboard ? 6 : 8),

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

                    SizedBox(height: hasKeyboard ? 12 : 16),

                    // Selesai button - compact saat keyboard
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSelesai,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: hasKeyboard ? 12 : (isMobile ? 14 : 16),
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
                                'Kirim',
                                style: TextStyle(
                                  fontSize:
                                      hasKeyboard ? 14 : (isMobile ? 15 : 16),
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
