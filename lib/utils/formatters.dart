import 'package:intl/intl.dart';

/// Utility class untuk formatting currency, date, dan numbers
class Formatters {
  // Format currency ke Rupiah (IDR)
  // Contoh: 1000000 -> "Rp 1.000.000"
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
  
  // Format date ke format Indonesia
  // Contoh: 2026-01-04 -> "4 Januari 2026"
  static String formatDate(DateTime date) {
    final formatter = DateFormat('d MMMM yyyy', 'en_US');
    return formatter.format(date);
  }
  
  // Format date dengan waktu
  // Contoh: 2026-01-04 14:30 -> "4 Jan 2026, 14:30"
  static String formatDateTime(DateTime date) {
    final formatter = DateFormat('d MMM yyyy, HH:mm', 'en_US');
    return formatter.format(date);
  }
  
  // Format number dengan thousand separator
  // Contoh: 1000000 -> "1.000.000"
  static String formatNumber(double number) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(number);
  }
  
  // Parse string currency ke double
  // Contoh: "1.000.000" -> 1000000.0
  static double parseCurrency(String text) {
    // Remove non-digit characters except decimal point
    final cleaned = text.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
