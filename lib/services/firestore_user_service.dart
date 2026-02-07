import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_storage_service.dart';

/// Firestore service untuk user identification
/// Collection: brand_identity_users_test (untuk testing)
class FirestoreUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'brand_identity_users_test';

  /// Get collection reference
  CollectionReference get _usersCollection =>
      _firestore.collection(_collectionName);

  /// Get all users
  Future<List<UserData>> getAllUsers() async {
      // print('🔍 [Firestore] Fetching all users...');
    try {
      final snapshot = await _usersCollection.orderBy('createdAt', descending: true).get();
      final users = snapshot.docs
          .map((doc) => UserData.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      // print('✅ [Firestore] Loaded ${users.length} users');
      return users;
    } catch (e) {
      // print('❌ [Firestore] Error fetching users: $e');
      return [];
    }
  }

  /// Get user by userId
  Future<UserData?> getUser(String userId) async {
      // print('🔍 [Firestore] Getting user by ID: $userId');
    try {
      final doc = await _usersCollection.doc(userId).get();
      
      if (!doc.exists) {
      // print('❌ [Firestore] User not found');
        return null;
      }

      final user = UserData.fromJson(doc.data() as Map<String, dynamic>);
      // print('✅ [Firestore] User found: ${user.displayName}');
      return user;
    } catch (e) {
      // print('❌ [Firestore] Error getting user: $e');
      return null;
    }
  }

  /// Find user by fingerprint
  Future<UserData?> findUserByFingerprint(String fingerprint) async {
      // print('🔍 [Firestore] Finding user by fingerprint: ${fingerprint.substring(0, 16)}...');
    try {
      final snapshot = await _usersCollection
          .where('fingerprints', arrayContains: fingerprint)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
      // print('❌ [Firestore] No user found with this fingerprint');
        return null;
      }

      final user = UserData.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
      // print('✅ [Firestore] User found: ${user.displayName}');
      return user;
    } catch (e) {
      // print('❌ [Firestore] Error finding user by fingerprint: $e');
      return null;
    }
  }

  /// Find user by display name
  Future<UserData?> findUserByName(String displayName) async {
      // print('🔍 [Firestore] Finding user by name: $displayName');
    try {
      final snapshot = await _usersCollection
          .where('displayName', isEqualTo: displayName)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
      // print('❌ [Firestore] No user found with this name');
        return null;
      }

      final user = UserData.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
      // print('✅ [Firestore] User found: ${user.displayName} with ${user.fingerprints.length} device(s)');
      return user;
    } catch (e) {
      // print('❌ [Firestore] Error finding user by name: $e');
      return null;
    }
  }

  /// Save or update user
  Future<void> saveUser(UserData userData) async {
      // print('🔍 [Firestore] Saving user: ${userData.displayName}...');
    try {
      await _usersCollection.doc(userData.userId).set(
        userData.toJson(),
        SetOptions(merge: true), // Merge instead of overwrite
      );
      // print('✅ [Firestore] User saved successfully');
    } catch (e) {
      // print('❌ [Firestore] Error saving user: $e');
      rethrow;
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
      // print('🔍 [Firestore] Deleting user: $userId...');
    try {
      await _usersCollection.doc(userId).delete();
      // print('✅ [Firestore] User deleted');
    } catch (e) {
      // print('❌ [Firestore] Error deleting user: $e');
      rethrow;
    }
  }

  /// Clear all users (untuk testing)
  Future<void> clearAllUsers() async {
      // print('🔍 [Firestore] Clearing all users...');
    try {
      final snapshot = await _usersCollection.get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      // print('✅ [Firestore] All users cleared (${snapshot.docs.length} deleted)');
    } catch (e) {
      // print('❌ [Firestore] Error clearing users: $e');
      rethrow;
    }
  }

  /// Remove device from user
  Future<void> removeDeviceFromUser(String userId, String fingerprint) async {
      // print('🔍 [Firestore] Removing device from user: $userId');
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) {
      // print('❌ [Firestore] User not found');
        return;
      }

      final user = UserData.fromJson(doc.data() as Map<String, dynamic>);
      final updatedUser = user.removeFingerprint(fingerprint);

      await _usersCollection.doc(userId).update(updatedUser.toJson());
      // print('✅ [Firestore] Device removed successfully');
    } catch (e) {
      // print('❌ [Firestore] Error removing device: $e');
      rethrow;
    }
  }

  /// Add device to user
  Future<void> addDeviceToUser(String userId, String fingerprint) async {
      // print('🔍 [Firestore] Adding device to user: $userId');
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) {
      // print('❌ [Firestore] User not found');
        return;
      }

      final user = UserData.fromJson(doc.data() as Map<String, dynamic>);
      
      // Check if device already exists
      if (user.hasFingerprint(fingerprint)) {
      // print('⚠️ [Firestore] Device already exists');
        return;
      }

      final updatedUser = user.addFingerprint(fingerprint);
      await _usersCollection.doc(userId).update(updatedUser.toJson());
      // print('✅ [Firestore] Device added successfully');
    } catch (e) {
      // print('❌ [Firestore] Error adding device: $e');
      rethrow;
    }
  }

  /// Get total users count
  Future<int> getUsersCount() async {
    try {
      final snapshot = await _usersCollection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      // print('❌ [Firestore] Error getting count: $e');
      return 0;
    }
  }

  /// Listen to users changes (real-time)
  Stream<List<UserData>> watchUsers() {
    return _usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserData.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }
}
