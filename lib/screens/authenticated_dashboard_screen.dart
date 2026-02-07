import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_identification_provider.dart';
import '../widgets/user_name_input_modal.dart';
import 'public_dashboard_screen.dart';

/// Wrapper untuk PublicDashboardScreen dengan user identification
/// Automatically show name input modal jika user belum teridentifikasi
class AuthenticatedDashboardScreen extends ConsumerStatefulWidget {
  const AuthenticatedDashboardScreen({super.key});

  @override
  ConsumerState<AuthenticatedDashboardScreen> createState() =>
      _AuthenticatedDashboardScreenState();
}

class _AuthenticatedDashboardScreenState
    extends ConsumerState<AuthenticatedDashboardScreen> {
  bool _hasShownModal = false;

  @override
  void initState() {
    super.initState();
    // Initialize user identification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userIdentificationProvider.notifier).initialize();
    });
  }

  void _showNameInputModal() {
    if (_hasShownModal) return;
    _hasShownModal = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UserNameInputModal(),
    ).then((_) {
      // Reset flag when modal closes
      _hasShownModal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userIdentificationProvider);

    // Show modal if needs name input
    if (userState.needsNameInput && !userState.isLoading && !_hasShownModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showNameInputModal();
        }
      });
    }

    // Show loading while initializing
    if (userState.isLoading && !userState.isIdentified) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    // Show main dashboard
    return const PublicDashboardScreen();
  }
}
