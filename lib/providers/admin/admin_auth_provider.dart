import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/admin_config.dart';

// Current admin user stream
final adminUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Is admin check provider
final isAdminProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(adminUserProvider);
  return userAsync.when(
    data: (user) => AdminConfig.isAdmin(user?.email),
    loading: () => false,
    error: (_, __) => false,
  );
});

// Admin email provider (for display)
final adminEmailProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(adminUserProvider);
  return userAsync.when(
    data: (user) => user?.email,
    loading: () => null,
    error: (_, __) => null,
  );
});
