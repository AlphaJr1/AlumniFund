import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/graduate_model.dart';

/// Admin-specific validators untuk validasi kompleks
class AdminValidators {
  /// Validate expense amount tidak melebihi general fund balance
  /// 
  /// Returns error message jika invalid, null jika valid
  static String? validateExpenseBalance({
    required double expenseAmount,
    required double generalFundBalance,
  }) {
    if (expenseAmount > generalFundBalance) {
      return 'Pengeluaran (Rp ${expenseAmount.toStringAsFixed(0)}) melebihi saldo dompet bersama (Rp ${generalFundBalance.toStringAsFixed(0)})';
    }
    
    if (expenseAmount <= 0) {
      return 'Jumlah pengeluaran harus lebih dari 0';
    }
    
    return null;
  }

  /// Validate transaction date (tidak boleh future date)
  /// 
  /// Returns error message jika invalid, null jika valid
  static String? validateTransactionDate(DateTime date) {
    final now = DateTime.now();
    
    if (date.isAfter(now)) {
      return 'Tanggal transaksi tidak boleh di masa depan';
    }
    
    // Check if date is too far in the past (more than 1 year)
    final oneYearAgo = now.subtract(const Duration(days: 365));
    if (date.isBefore(oneYearAgo)) {
      return 'Tanggal transaksi terlalu lama (maksimal 1 tahun yang lalu)';
    }
    
    return null;
  }

  /// Validate 24h edit window untuk transaction
  /// 
  /// Returns error message jika invalid, null jika valid
  static String? validate24HourEditWindow(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inHours >= 24) {
      return 'Transaksi hanya dapat diedit dalam 24 jam pertama';
    }
    
    return null;
  }

  /// Validate graduate list (no duplicates, dates in correct month)
  /// 
  /// Returns error message jika invalid, null jika valid
  static String? validateGraduateList({
    required List<Graduate> graduates,
    required String targetMonth,
    required int targetYear,
  }) {
    if (graduates.isEmpty) {
      return 'Daftar wisudawan tidak boleh kosong';
    }

    // Check for duplicate names
    final names = graduates.map((g) => g.name.toLowerCase().trim()).toList();
    final uniqueNames = names.toSet();
    if (names.length != uniqueNames.length) {
      return 'Terdapat nama wisudawan yang duplikat';
    }

    // Get month number from Indonesian month name
    final monthNumber = _getMonthNumber(targetMonth);
    if (monthNumber == null) {
      return 'Bulan target tidak valid';
    }

    // Validate all graduate dates are in the correct month/year
    for (var graduate in graduates) {
      if (graduate.date.month != monthNumber || graduate.date.year != targetYear) {
        return 'Tanggal wisuda ${graduate.name} tidak sesuai dengan bulan/tahun target ($targetMonth $targetYear)';
      }
    }

    return null;
  }

  /// Validate no duplicate target for month/year
  /// 
  /// Returns error message jika invalid, null jika valid
  static Future<String?> validateNoDuplicateTarget({
    required String month,
    required int year,
    String? excludeTargetId, // For edit mode
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('graduation_targets')
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .where('status', whereIn: ['upcoming', 'active'])
          .get();

      // If editing, exclude current target from check
      final duplicates = snapshot.docs.where((doc) => doc.id != excludeTargetId).toList();

      if (duplicates.isNotEmpty) {
        return 'Target untuk $month $year sudah ada';
      }

      return null;
    } catch (e) {
      return 'Gagal validasi target: $e';
    }
  }

  /// Validate graduate date is within reasonable range
  /// 
  /// Returns error message jika invalid, null jika valid
  static String? validateGraduateDate(DateTime date) {
    final now = DateTime.now();
    
    // Cannot be more than 1 year in the future
    final oneYearFromNow = now.add(const Duration(days: 365));
    if (date.isAfter(oneYearFromNow)) {
      return 'Tanggal wisuda tidak boleh lebih dari 1 tahun ke depan';
    }
    
    // Cannot be more than 2 years in the past
    final twoYearsAgo = now.subtract(const Duration(days: 730));
    if (date.isBefore(twoYearsAgo)) {
      return 'Tanggal wisuda tidak boleh lebih dari 2 tahun yang lalu';
    }
    
    return null;
  }

  /// Validate target amount is reasonable
  /// 
  /// Returns error message jika invalid, null jika valid
  static String? validateTargetAmount(double amount, int graduateCount) {
    if (amount <= 0) {
      return 'Jumlah target harus lebih dari 0';
    }

    // Check if amount is reasonable per person (between 100k - 1M)
    final perPerson = amount / graduateCount;
    if (perPerson < 100000) {
      return 'Alokasi per orang terlalu kecil (< Rp 100.000)';
    }
    if (perPerson > 1000000) {
      return 'Alokasi per orang terlalu besar (> Rp 1.000.000)';
    }

    return null;
  }

  /// Get month number from Indonesian month name
  static int? _getMonthNumber(String month) {
    final monthMap = {
      'januari': 1,
      'februari': 2,
      'maret': 3,
      'april': 4,
      'mei': 5,
      'juni': 6,
      'juli': 7,
      'agustus': 8,
      'september': 9,
      'oktober': 10,
      'november': 11,
      'desember': 12,
    };
    
    return monthMap[month.toLowerCase()];
  }

  /// Validate QR code image
  /// 
  /// Returns error message jika invalid, null jika valid
  static String? validateQRCodeImage(int bytes, String filename) {
    // Check file size (max 2MB for QR codes)
    const maxSize = 2 * 1024 * 1024;
    if (bytes > maxSize) {
      return 'Ukuran file QR code terlalu besar (Max: 2MB)';
    }

    // Check file type
    final extension = filename.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(extension)) {
      return 'Format file tidak didukung. Gunakan JPG atau PNG';
    }

    return null;
  }

  /// Validate system config values
  /// 
  /// Returns error message jika invalid, null jika valid
  static String? validateSystemConfig({
    required double perPersonAllocation,
    required int deadlineOffsetDays,
    required double minimumContribution,
  }) {
    if (perPersonAllocation < 100000 || perPersonAllocation > 1000000) {
      return 'Alokasi per orang harus antara Rp 100.000 - Rp 1.000.000';
    }

    if (deadlineOffsetDays < 1 || deadlineOffsetDays > 30) {
      return 'Offset deadline harus antara 1-30 hari';
    }

    if (minimumContribution < 1000 || minimumContribution > 100000) {
      return 'Minimum donasi harus antara Rp 1.000 - Rp 100.000';
    }

    return null;
  }
}
