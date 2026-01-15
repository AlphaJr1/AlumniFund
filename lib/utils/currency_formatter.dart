import 'package:intl/intl.dart';

/// Utility class untuk format currency dalam Rupiah Indonesia
class CurrencyFormatter {
  /// Format amount ke format Rupiah: "Rp 1.000.000"
  /// 
  /// Example:
  /// ```dart
  /// formatCurrency(1000000) // "Rp 1.000.000"
  /// formatCurrency(250000) // "Rp 250.000"
  /// formatCurrency(50000) // "Rp 50.000"
  /// ```
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format amount ke format compact: "Rp 1,2 Jt", "Rp 500 Rb"
  /// 
  /// Example:
  /// ```dart
  /// formatCompact(1200000) // "Rp 1,2 Jt"
  /// formatCompact(500000) // "Rp 500 Rb"
  /// formatCompact(50000) // "Rp 50 Rb"
  /// ```
  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return 'Rp ${millions.toStringAsFixed(millions % 1 == 0 ? 0 : 1)} Jt';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      return 'Rp ${thousands.toStringAsFixed(thousands % 1 == 0 ? 0 : 0)} Rb';
    } else {
      return formatCurrency(amount);
    }
  }

  /// Parse currency string kembali ke double
  /// 
  /// Example:
  /// ```dart
  /// parseCurrency("Rp 1.000.000") // 1000000.0
  /// parseCurrency("1000000") // 1000000.0
  /// ```
  static double parseCurrency(String currencyString) {
    // Remove "Rp", spaces, and dots
    final cleaned = currencyString
        .replaceAll('Rp', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Format amount tanpa symbol (hanya angka dengan separator)
  /// 
  /// Example:
  /// ```dart
  /// formatNumber(1000000) // "1.000.000"
  /// ```
  static String formatNumber(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }
}
