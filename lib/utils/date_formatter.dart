import 'package:intl/intl.dart';

/// Utility class untuk format tanggal dalam Bahasa Indonesia
class DateFormatter {
  /// Indonesian month names
  static const List<String> monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Indonesian month names (lowercase untuk database)
  static const List<String> monthNamesLower = [
    'januari',
    'februari',
    'maret',
    'april',
    'mei',
    'juni',
    'juli',
    'agustus',
    'september',
    'oktober',
    'november',
    'desember',
  ];

  /// Format date ke format Indonesia: "28 April 2026"
  /// 
  /// Example:
  /// ```dart
  /// formatDate(DateTime(2026, 4, 28)) // "28 April 2026"
  /// ```
  static String formatDate(DateTime date) {
    final day = date.day;
    final month = monthNames[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  /// Format date dengan hari: "Senin, 28 April 2026"
  /// 
  /// Example:
  /// ```dart
  /// formatDateWithDay(DateTime(2026, 4, 28)) // "Selasa, 28 April 2026"
  /// ```
  static String formatDateWithDay(DateTime date) {
    final dayNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final dayName = dayNames[date.weekday - 1];
    return '$dayName, ${formatDate(date)}';
  }

  /// Format datetime ke format short: "04/01 14:30"
  /// 
  /// Example:
  /// ```dart
  /// formatDateTime(DateTime(2026, 1, 4, 14, 30)) // "04/01 14:30"
  /// ```
  static String formatDateTime(DateTime date) {
    final formatter = DateFormat('dd/MM HH:mm');
    return formatter.format(date);
  }

  /// Format datetime ke format full: "04 Januari 2026, 14:30"
  /// 
  /// Example:
  /// ```dart
  /// formatDateTimeFull(DateTime(2026, 1, 4, 14, 30)) // "04 Januari 2026, 14:30"
  /// ```
  static String formatDateTimeFull(DateTime date) {
    final dateStr = formatDate(date);
    final timeStr = DateFormat('HH:mm').format(date);
    return '$dateStr, $timeStr';
  }

  /// Get relative time dalam Bahasa Indonesia
  /// 
  /// Example:
  /// ```dart
  /// getRelativeTime(DateTime.now().subtract(Duration(minutes: 5))) // "5 menit lalu"
  /// getRelativeTime(DateTime.now().subtract(Duration(hours: 2))) // "2 jam lalu"
  /// getRelativeTime(DateTime.now().subtract(Duration(days: 3))) // "3 hari lalu"
  /// ```
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months bulan lalu';
    } else {
      final years = (diff.inDays / 365).floor();
      return '$years tahun lalu';
    }
  }

  /// Get month name dari index (1-12)
  /// 
  /// Example:
  /// ```dart
  /// getMonthName(5) // "Mei"
  /// getMonthName(12) // "Desember"
  /// ```
  static String getMonthName(int month) {
    if (month < 1 || month > 12) return '';
    return monthNames[month - 1];
  }

  /// Get lowercase month name dari index (1-12)
  /// 
  /// Example:
  /// ```dart
  /// getMonthNameLower(5) // "mei"
  /// ```
  static String getMonthNameLower(int month) {
    if (month < 1 || month > 12) return '';
    return monthNamesLower[month - 1];
  }

  /// Format countdown: "5 hari lagi", "2 jam lagi"
  /// 
  /// Example:
  /// ```dart
  /// formatCountdown(DateTime.now().add(Duration(days: 5))) // "5 hari lagi"
  /// formatCountdown(DateTime.now().add(Duration(hours: 2))) // "2 jam lagi"
  /// ```
  static String formatCountdown(DateTime futureDate) {
    final now = DateTime.now();
    final diff = futureDate.difference(now);

    if (diff.isNegative) {
      return 'Sudah lewat';
    }

    if (diff.inDays > 0) {
      return '${diff.inDays} hari lagi';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam lagi';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit lagi';
    } else {
      return 'Kurang dari 1 menit';
    }
  }

  /// Get days until date (bisa negatif jika sudah lewat)
  /// 
  /// Example:
  /// ```dart
  /// getDaysUntil(DateTime.now().add(Duration(days: 5))) // 5
  /// getDaysUntil(DateTime.now().subtract(Duration(days: 2))) // -2
  /// ```
  static int getDaysUntil(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    return diff.inDays;
  }
}
