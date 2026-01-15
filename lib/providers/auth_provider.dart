import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Provider untuk AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider untuk auth state stream
/// Akan emit User? setiap kali auth state berubah (login/logout)
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider untuk current user
/// Null jika belum login
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

/// Provider untuk check apakah user adalah admin
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
