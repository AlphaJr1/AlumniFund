import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../services/user_identification_service.dart';
import '../services/user_storage_service.dart';
import '../services/firestore_user_service.dart';

/// State untuk user identification
class UserIdentificationState {
  final UserData? userData;
  final bool isLoading;
  final bool needsNameInput;
  final String? error;
  final bool useFirestore; // Toggle untuk testing

  const UserIdentificationState({
    this.userData,
    this.isLoading = false,
    this.needsNameInput = false,
    this.error,
    this.useFirestore = true, // Default: pakai Firestore
  });

  UserIdentificationState copyWith({
    UserData? userData,
    bool? isLoading,
    bool? needsNameInput,
    String? error,
    bool? useFirestore,
  }) {
    return UserIdentificationState(
      userData: userData ?? this.userData,
      isLoading: isLoading ?? this.isLoading,
      needsNameInput: needsNameInput ?? this.needsNameInput,
      error: error,
      useFirestore: useFirestore ?? this.useFirestore,
    );
  }

  bool get isIdentified => userData != null;
  String? get displayName => userData?.displayName;
  String? get userId => userData?.userId;
}

/// Provider untuk user identification
class UserIdentificationNotifier
    extends Notifier<UserIdentificationState> {
  UserIdentificationService get _identificationService =>
      ref.read(userIdentificationServiceProvider);
  UserStorageService get _storageService =>
      ref.read(userStorageServiceProvider);
  FirestoreUserService get _firestoreService =>
      ref.read(firestoreUserServiceProvider);

  bool _initialized = false;

  @override
  UserIdentificationState build() {
      // print('🔍 [UserID] Provider build() called');
    
    // Auto-initialize on first build
    if (!_initialized) {
      _initialized = true;
      // print('🔍 [UserID] First build - scheduling initialize()');
      Future.microtask(() => initialize());
    }
    
    return const UserIdentificationState();
  }

  /// Toggle between Firestore and Mock
  void toggleStorage(bool useFirestore) {
      // print('🔍 [UserID] Toggling storage: ${useFirestore ? "Firestore" : "Mock"}');
    state = state.copyWith(useFirestore: useFirestore);
    reinitialize();
  }

  /// Get appropriate storage service based on toggle
  Future<UserData?> _findUserByFingerprint(String fingerprint) async {
    if (state.useFirestore) {
      return await _firestoreService.findUserByFingerprint(fingerprint);
    } else {
      return await _storageService.findUserByFingerprint(fingerprint);
    }
  }

  Future<UserData?> _findUserByName(String displayName) async {
    if (state.useFirestore) {
      return await _firestoreService.findUserByName(displayName);
    } else {
      return await _storageService.findUserByName(displayName);
    }
  }

  Future<void> _saveUser(UserData userData) async {
    // Always save to local storage for caching
    await _storageService.saveUserData(userData);
    
    // Save to Firestore or mock based on toggle
    if (state.useFirestore) {
      await _firestoreService.saveUser(userData);
    } else {
      await _storageService.saveMockUser(userData);
    }
  }

  /// Watch for user deletion in realtime
  void watchUserDeletion(String userId, String currentFingerprint) {
    if (!state.useFirestore) return;

    _firestoreService.watchUsers().listen((users) {
      final currentUser = users.where((u) => u.userId == userId).firstOrNull;
      
      if (currentUser == null) {
        // User deleted - logout
      // print('⚠️ [UserID] User deleted - logging out');
        logout();
      } else if (!currentUser.hasFingerprint(currentFingerprint)) {
        // Device removed - logout
      // print('⚠️ [UserID] Device removed - logging out');
        logout();
      }
    });
  }

  /// Logout - clear local data dan reset state
  Future<void> logout() async {
    await _storageService.clearUserData();
    state = state.copyWith(
      userData: null,
      needsNameInput: true,
      isLoading: false,
    );
  }

  /// Initialize user identification flow
  Future<void> initialize() async {
      // print('🔍 [UserID] Initialize called');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Step 1: Check IndexedDB (SharedPreferences)
      // print('🔍 [UserID] Step 1: Checking local storage...');
      final localUser = await _storageService.getUserData();
      
      if (localUser != null) {
        // User found in local storage - verify still exists in Firestore
      // print('✅ [UserID] User found in local storage: ${localUser.displayName}');
        
        if (state.useFirestore) {
      // print('🔍 [UserID] Verifying user still exists in Firestore...');
          
          // Check if user still exists in Firestore by userId
          try {
            final firestoreUser = await _firestoreService.getUser(localUser.userId);
            
            if (firestoreUser == null) {
              // User was deleted from Firestore - clear local cache
      // print('⚠️ [UserID] User deleted from Firestore - clearing local cache');
              await _storageService.clearUserData();
              
              // Continue to generate fingerprint and check
      // print('🔍 [UserID] Proceeding as new user...');
            } else {
              // User still exists - use it
      // print('✅ [UserID] User verified in Firestore');
              await _storageService.updateLastSeen();
              state = state.copyWith(
                userData: firestoreUser,
                isLoading: false,
                needsNameInput: false,
              );
      // print('🔍 [UserID] State updated - needsNameInput: false');
              
              // Watch for deletion with CURRENT device fingerprint
              final currentFingerprint = await _identificationService.generateFingerprint();
              watchUserDeletion(firestoreUser.userId, currentFingerprint);
              return;
            }
          } catch (e) {
      // print('⚠️ [UserID] Error verifying Firestore user: $e');
            // On error, trust local cache
            await _storageService.updateLastSeen();
            state = state.copyWith(
              userData: localUser,
              isLoading: false,
              needsNameInput: false,
            );
            return;
          }
        } else {
          // Not using Firestore - trust local cache
          await _storageService.updateLastSeen();
          state = state.copyWith(
            userData: localUser,
            isLoading: false,
            needsNameInput: false,
          );
      // print('🔍 [UserID] State updated - needsNameInput: false');
          return;
        }
      }

      // print('❌ [UserID] No local user found');

      // Step 2: Generate fingerprint
      // print('🔍 [UserID] Step 2: Generating fingerprint...');
      await _identificationService.simulateDelay();
      final fingerprint = await _identificationService.generateFingerprint();
      // print('🔍 [UserID] Fingerprint: ${fingerprint.substring(0, 16)}...');

      // Step 3: Check Firestore/Mock for existing user with this fingerprint
      // print('🔍 [UserID] Step 3: Checking ${state.useFirestore ? "Firestore" : "Mock"} by fingerprint...');
      final existingUserByFingerprint = await _findUserByFingerprint(fingerprint);

      if (existingUserByFingerprint != null) {
        // User found by fingerprint - restore data
      // print('✅ [UserID] User found by fingerprint: ${existingUserByFingerprint.displayName}');
        final restoredUser = existingUserByFingerprint.copyWith(lastSeen: DateTime.now());
        await _saveUser(restoredUser);
        
        state = state.copyWith(
          userData: restoredUser,
          isLoading: false,
          needsNameInput: false,
        );
      // print('🔍 [UserID] State updated - needsNameInput: false');
        return;
      }

      // print('❌ [UserID] No user found by fingerprint');

      // Step 4: New user - need name input
      // print('🚨 [UserID] Step 4: NEW USER - Setting needsNameInput = true');
      state = state.copyWith(
        isLoading: false,
        needsNameInput: true,
      );
      // print('🔍 [UserID] State updated - needsNameInput: ${state.needsNameInput}');
    } catch (e) {
      // print('❌ [UserID] Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create new user with provided name
  /// Returns map with: success, needsConfirmation, similarUser, similarity
  Future<Map<String, dynamic>> createUser(String displayName) async {
      // print('🔍 [UserID] createUser called with: $displayName');
    if (displayName.trim().isEmpty) {
      // print('❌ [UserID] Empty name');
      state = state.copyWith(error: 'Nama tidak boleh kosong');
      return {'success': false, 'error': 'Nama tidak boleh kosong'};
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final fingerprint = await _identificationService.generateFingerprint();
      final now = DateTime.now();

      // Check if user with this name already exists (exact match)
      // print('🔍 [UserID] Checking if user exists by name...');
      final existingUserByName = await _findUserByName(displayName.trim());

      if (existingUserByName != null) {
        // Exact match - add device
      // print('🔍 [UserID] User exists! Adding new device...');
        
        // Use dedicated method to safely add device
        if (state.useFirestore) {
          await _firestoreService.addDeviceToUser(existingUserByName.userId, fingerprint);
          // Fetch updated user
          final updatedUser = await _firestoreService.getUser(existingUserByName.userId);
          if (updatedUser != null) {
            await _storageService.saveUserData(updatedUser);
      // print('✅ [UserID] Device added. Total devices: ${updatedUser.devices.length}');
            
            state = state.copyWith(
              userData: updatedUser,
              isLoading: false,
              needsNameInput: false,
            );
            
            watchUserDeletion(updatedUser.userId, fingerprint);
            return {'success': true};
          }
        } else {
          // Mock storage
          final newUser = existingUserByName.addFingerprint(fingerprint);
          await _storageService.saveMockUser(newUser);
          await _storageService.saveUserData(newUser);
      // print('✅ [UserID] Device added. Total devices: ${newUser.devices.length}');

          state = state.copyWith(
            userData: newUser,
            isLoading: false,
            needsNameInput: false,
          );

          return {'success': true};
        }
      }

      // No exact match - create new user
      // print('🔍 [UserID] Creating new user...');
      final newUser = UserData(
        userId: const Uuid().v4(),
        displayName: displayName.trim(),
        fingerprints: [fingerprint],
        devices: [DeviceInfo(fingerprint: fingerprint, addedAt: now)],
        createdAt: now,
        lastSeen: now,
      );
      // print('✅ [UserID] New user created');

      // print('🔍 [UserID] Saving user: ${newUser.displayName}');
      await _saveUser(newUser);
      // print('✅ [UserID] User saved successfully');

      state = state.copyWith(
        userData: newUser,
        isLoading: false,
        needsNameInput: false,
      );

      // Watch for deletion
      if (state.useFirestore) {
        watchUserDeletion(newUser.userId, fingerprint);
      }

      return {'success': true};
    } catch (e) {
      // print('❌ [UserID] Error creating user: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check for similar names and return match info
  /// This should be called BEFORE createUser
  Future<Map<String, dynamic>> checkSimilarNames(String inputName) async {
      // print('🔍 [UserID] ========== CHECK SIMILAR NAMES ==========');
      // print('🔍 [UserID] Input: "$inputName"');
    
    try {
      // Get all users
      final List<UserData> allUsers;
      if (state.useFirestore) {
      // print('🔍 [UserID] Loading users from Firestore...');
        allUsers = await _firestoreService.getAllUsers();
      } else {
      // print('🔍 [UserID] Loading users from Mock...');
        allUsers = await _storageService.getMockUsers();
      }

      // print('🔍 [UserID] Found ${allUsers.length} existing users');

      if (allUsers.isEmpty) {
      // print('✅ [UserID] No existing users - no similarity check needed');
        return {'hasSimilar': false};
      }

      // Find most similar name
      String? mostSimilarName;
      double highestSimilarity = 0.0;
      UserData? similarUser;

      // print('🔍 [UserID] Checking similarity with each user...');
      for (final user in allUsers) {
        // Skip if EXACTLY the same (including case)
        if (inputName.trim() == user.displayName) {
      // print('🔍 [UserID]   "${user.displayName}" -> Exact match (same case) - skipping');
          continue;
        }
        
        final similarity = _calculateSimilarity(inputName, user.displayName);
        
      // print('🔍 [UserID]   "${user.displayName}" -> ${similarity.toStringAsFixed(1)}% similar');
        
        if (similarity >= 80.0 && similarity > highestSimilarity) {
      // print('🔍 [UserID]   ↳ NEW BEST MATCH! (threshold: 80%)');
          highestSimilarity = similarity;
          mostSimilarName = user.displayName;
          similarUser = user;
        }
      }

      if (mostSimilarName != null && similarUser != null) {
      // print('⚠️ [UserID] ========== SIMILAR NAME FOUND ==========');
      // print('⚠️ [UserID] Best match: "$mostSimilarName"');
      // print('⚠️ [UserID] Similarity: ${highestSimilarity.toStringAsFixed(1)}%');
        return {
          'hasSimilar': true,
          'similarName': mostSimilarName,
          'similarity': highestSimilarity,
          'similarUser': similarUser,
        };
      }

      // print('✅ [UserID] No similar names found (all below 80% threshold)');
      return {'hasSimilar': false};
    } catch (e) {
      // print('❌ [UserID] Error checking similar names: $e');
      return {'hasSimilar': false};
    }
  }

  /// Calculate similarity between two names
  double _calculateSimilarity(String name1, String name2) {
    final normalized1 = name1.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalized2 = name2.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

    if (normalized1 == normalized2) return 100.0;

    final distance = _levenshteinDistance(normalized1, normalized2);
    final maxLength = normalized1.length > normalized2.length
        ? normalized1.length
        : normalized2.length;

    if (maxLength == 0) return 100.0;

    return ((maxLength - distance) / maxLength) * 100;
  }

  /// Levenshtein Distance algorithm
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final len1 = s1.length;
    final len2 = s2.length;
    final matrix = List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));

    for (var i = 0; i <= len1; i++) matrix[i][0] = i;
    for (var j = 0; j <= len2; j++) matrix[0][j] = j;

    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  /// Link to existing user (used when user confirms similar name)
  Future<void> linkToExistingUser(UserData existingUser) async {
    try {
      final fingerprint = await _identificationService.generateFingerprint();
      final updatedUser = existingUser.addFingerprint(fingerprint);
      
      await _saveUser(updatedUser);
      
      state = state.copyWith(
        userData: updatedUser,
        isLoading: false,
        needsNameInput: false,
      );
      
      // print('✅ [UserID] Linked to existing user: ${existingUser.displayName}');
    } catch (e) {
      // print('❌ [UserID] Error linking to existing user: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear user data (untuk testing)
  Future<void> clearUser() async {
    await _storageService.clearUserData();
    state = const UserIdentificationState();
  }

  /// Re-initialize (untuk testing)
  Future<void> reinitialize() async {
    state = const UserIdentificationState();
    await initialize();
  }

  /// Get mock users count (untuk testing)
  Future<int> getMockUsersCount() async {
    return await _storageService.getMockUsersCount();
  }

  /// Clear all mock users (untuk testing)
  Future<void> clearAllMockUsers() async {
    await _storageService.clearMockUsers();
  }

  /// Clear all Firestore users (untuk testing)
  Future<void> clearAllFirestoreUsers() async {
    await _firestoreService.clearAllUsers();
  }
}

/// Provider instances
final userIdentificationServiceProvider = Provider((ref) {
  return UserIdentificationService();
});

final userStorageServiceProvider = Provider((ref) {
  return UserStorageService();
});

final firestoreUserServiceProvider = Provider((ref) {
  return FirestoreUserService();
});

final userIdentificationProvider =
    NotifierProvider<UserIdentificationNotifier, UserIdentificationState>(
  UserIdentificationNotifier.new,
);
