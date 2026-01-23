import 'package:firebase_auth/firebase_auth.dart';

/// Service untuk handle Firebase Authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream auth state changes
  /// Digunakan untuk reactive UI updates ketika user login/logout
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login dengan email dan password
  /// Returns User jika berhasil, throw Exception jika gagal
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase auth errors
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Email tidak terdaftar');
        case 'wrong-password':
          throw Exception('Password salah');
        case 'invalid-email':
          throw Exception('Format email tidak valid');
        case 'user-disabled':
          throw Exception('Akun telah dinonaktifkan');
        default:
          throw Exception('Login gagal: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Logout gagal: $e');
    }
  }

  /// Check if user is admin
  /// Untuk MVP, semua authenticated users dianggap admin
  /// Di production, bisa ditambahkan custom claims atau check ke Firestore
  bool isAdmin() {
    return currentUser != null;
  }

  /// Change password
  /// Requires re-authentication dengan current password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('User tidak ditemukan');
      }

      // Re-authenticate user dengan current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw Exception('Password saat ini salah');
        case 'weak-password':
          throw Exception('Password baru terlalu lemah (min 8 karakter)');
        case 'requires-recent-login':
          throw Exception('Silakan login ulang untuk mengganti password');
        default:
          throw Exception('Gagal mengganti password: ${e.message}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
