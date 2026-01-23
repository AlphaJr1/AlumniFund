import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/general_fund_provider.dart';
import '../providers/graduation_target_provider.dart';
import '../providers/transaction_provider.dart';

/// Splash screen that preloads critical data before showing dashboard
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _statusMessage = 'Initializing...';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Initialize gradient animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Start preloading data
    _preloadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _preloadData() async {
    try {
      final totalSteps = 4;
      int completedSteps = 0;

      // Helper to update progress
      void updateProgress(String message) {
        completedSteps++;
        if (mounted) {
          setState(() {
            _progress = completedSteps / totalSteps;
            _statusMessage = message;
          });
        }
      }

      // Step 1: Load general fund
      setState(() => _statusMessage = 'Loading fund balance...');
      await ref.read(generalFundProvider.future);
      updateProgress('Fund balance loaded');
      await Future.delayed(const Duration(milliseconds: 200));

      // Step 2: Load graduation targets (includes active target)
      setState(() => _statusMessage = 'Loading targets...');
      await ref.read(graduationTargetsProvider.future);
      updateProgress('Targets loaded');
      await Future.delayed(const Duration(milliseconds: 200));

      // Step 3: Load recent income
      setState(() => _statusMessage = 'Loading income data...');
      await ref.read(recentIncomeProvider.future);
      updateProgress('Income data loaded');
      await Future.delayed(const Duration(milliseconds: 200));

      // Step 4: Load recent expenses
      setState(() => _statusMessage = 'Loading expense data...');
      await ref.read(recentExpenseProvider.future);
      updateProgress('All data loaded');
      await Future.delayed(const Duration(milliseconds: 300));

      // All data loaded - navigate to dashboard
      if (mounted) {
        setState(() => _statusMessage = 'Ready!');
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          context.go('/');
        }
      }
    } catch (e) {
      // Handle errors - still navigate

      if (mounted) {
        setState(() {
          _progress = 1.0;
          _statusMessage = 'Loading complete';
        });

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          context.go('/');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Name
            const Text(
              'UNAME',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 12),

            // Slogan
            const Text(
              'Together, anyway',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 64),

            // Progress Bar
            SizedBox(
              width: 320,
              child: Column(
                children: [
                  // Animated Gradient Progress Bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Stack(
                            children: [
                              // Actual progress
                              FractionallySizedBox(
                                widthFactor: _progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: const [
                                        Color(0xFFEC4899), // Pink
                                        Color(0xFF8B5CF6), // Purple
                                        Color(0xFF3B82F6), // Blue
                                        Color(0xFF06B6D4), // Cyan
                                        Color(0xFF10B981), // Green
                                        Color(0xFFF59E0B), // Orange
                                        Color(0xFFEF4444), // Red
                                      ],
                                      stops: const [
                                        0.0,
                                        0.17,
                                        0.33,
                                        0.5,
                                        0.67,
                                        0.83,
                                        1.0
                                      ],
                                      begin: Alignment(
                                          _animationController.value * 2 - 1,
                                          0),
                                      end: Alignment(
                                          _animationController.value * 2 + 1,
                                          0),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEC4899)
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress Percentage
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Status Message
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
