import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/general_fund_provider.dart';
import '../providers/graduation_target_provider.dart';
import '../providers/transaction_provider.dart';

/// Warmup screen that preloads all critical data before showing dashboard
/// This ensures dashboard appears fully loaded with no skeleton loaders
class WarmupScreen extends ConsumerStatefulWidget {
  const WarmupScreen({super.key});

  @override
  ConsumerState<WarmupScreen> createState() => _WarmupScreenState();
}

class _WarmupScreenState extends ConsumerState<WarmupScreen> {
  @override
  void initState() {
    super.initState();
    // Start preloading immediately
    _checkDataAndNavigate();
  }

  Future<void> _checkDataAndNavigate() async {
    // Small delay to ensure smooth transition from HTML splash
    await Future.delayed(const Duration(milliseconds: 300));

    // Add timeout fallback - if data doesn't load within 5 seconds, proceed anyway
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch all critical providers
    final generalFundAsync = ref.watch(generalFundProvider);
    final graduationTargetsAsync = ref.watch(graduationTargetsProvider);
    final recentIncomeAsync = ref.watch(recentIncomeProvider);
    final recentExpenseAsync = ref.watch(recentExpenseProvider);

    // Check if ALL data is loaded OR has error (proceed either way)
    final allLoaded = (generalFundAsync.hasValue ||
            generalFundAsync.hasError) &&
        (graduationTargetsAsync.hasValue || graduationTargetsAsync.hasError) &&
        (recentIncomeAsync.hasValue || recentIncomeAsync.hasError) &&
        (recentExpenseAsync.hasValue || recentExpenseAsync.hasError);

    // Navigate to dashboard when all data is ready (or errored)
    if (allLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/');
        }
      });
    }

    // Show minimal loading UI (matching HTML splash aesthetic)
    return const Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Brand name
            Text(
              'UNAME',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 42,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 12),
            // Slogan
            Text(
              'Together, anyway',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 48),
            // Subtle loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFFEC4899),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
