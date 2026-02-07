import 'dart:convert';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

/// Local database service untuk testing
/// Menggunakan SQLite yang bisa di-share (untuk web: IndexedDB)
class LocalDatabaseService {
  static Database? _database;
  static const String _dbName = 'brand_identity_test.db';
  static const String _tableName = 'users';

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    // For web, use sqflite_common_ffi_web
    databaseFactory = databaseFactoryFfiWeb;

    final db = await openDatabase(
      _dbName,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            userId TEXT PRIMARY KEY,
            displayName TEXT NOT NULL,
            fingerprints TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            lastSeen TEXT NOT NULL
          )
        ''');
        print('✅ [LocalDB] Database created');
      },
    );

    print('✅ [LocalDB] Database initialized');
    return db;
  }

  /// Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    final users = await db.query(_tableName, orderBy: 'createdAt DESC');
    print('🔍 [LocalDB] Loaded ${users.length} users');
    return users;
  }

  /// Find user by fingerprint
  Future<Map<String, dynamic>?> findUserByFingerprint(
      String fingerprint) async {
    print(
        '🔍 [LocalDB] Finding user by fingerprint: ${fingerprint.substring(0, 16)}...');
    final users = await getAllUsers();

    for (final user in users) {
      final fingerprints =
          List<String>.from(jsonDecode(user['fingerprints'] as String));
      if (fingerprints.contains(fingerprint)) {
        print('✅ [LocalDB] User found: ${user['displayName']}');
        return user;
      }
    }

    print('❌ [LocalDB] No user found with this fingerprint');
    return null;
  }

  /// Find user by display name
  Future<Map<String, dynamic>?> findUserByName(String displayName) async {
    print('🔍 [LocalDB] Finding user by name: $displayName');
    final db = await database;
    final results = await db.query(
      _tableName,
      where: 'LOWER(displayName) = ?',
      whereArgs: [displayName.toLowerCase()],
    );

    if (results.isEmpty) {
      print('❌ [LocalDB] No user found with this name');
      return null;
    }

    final user = results.first;
    final fingerprints =
        List<String>.from(jsonDecode(user['fingerprints'] as String));
    print(
        '✅ [LocalDB] User found: ${user['displayName']} with ${fingerprints.length} device(s)');
    return user;
  }

  /// Save or update user
  Future<void> saveUser(Map<String, dynamic> userData) async {
    final db = await database;

    await db.insert(
      _tableName,
      userData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('✅ [LocalDB] User saved: ${userData['displayName']}');
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print('✅ [LocalDB] User deleted');
  }

  /// Clear all users
  Future<void> clearAllUsers() async {
    final db = await database;
    await db.delete(_tableName);
    print('✅ [LocalDB] All users cleared');
  }

  /// Get total users count
  Future<int> getUsersCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Export database to JSON (for backup/sharing)
  Future<String> exportToJson() async {
    final users = await getAllUsers();
    return jsonEncode(users);
  }

  /// Import database from JSON
  Future<void> importFromJson(String jsonString) async {
    final List<dynamic> users = jsonDecode(jsonString);
    final db = await database;

    await db.transaction((txn) async {
      for (final user in users) {
        await txn.insert(
          _tableName,
          user as Map<String, dynamic>,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    print('✅ [LocalDB] Imported ${users.length} users');
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('✅ [LocalDB] Database closed');
    }
  }
}
