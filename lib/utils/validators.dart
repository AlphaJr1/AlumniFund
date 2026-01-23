/// Utility class untuk validasi input
class Validators {
  /// Validate file size (max 5MB)
  ///
  /// Returns error message jika invalid, null jika valid
  static String? validateFileSize(int bytes) {
    const maxSize = 5 * 1024 * 1024; // 5MB in bytes

    if (bytes > maxSize) {
      return 'Ukuran file terlalu besar (Max: 5MB)';
    }

    return null;
  }

  /// Validate file type (jpg, jpeg, png only)
  ///
  /// Returns error message jika invalid, null jika valid
  static String? validateFileType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    const allowedExtensions = ['jpg', 'jpeg', 'png'];

    if (!allowedExtensions.contains(extension)) {
      return 'Format file tidak didukung. Gunakan JPG atau PNG';
    }

    return null;
  }

  /// Validate amount (minimum contribution)
  ///
  /// Returns error message jika invalid, null jika valid
  static String? validateAmount(double amount, {double minAmount = 10000}) {
    if (amount < minAmount) {
      return 'Nominal minimum adalah Rp ${minAmount.toStringAsFixed(0)}';
    }

    return null;
  }

  /// Validate email format
  ///
  /// Returns error message jika invalid, null jika valid
  static String? validateEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  /// Validate phone number (Indonesian format)
  ///
  /// Returns error message jika invalid, null jika valid
  static String? validatePhoneNumber(String phone) {
    // Remove spaces, dashes, and parentheses
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if starts with +62, 62, or 0
    if (!cleaned.startsWith('+62') &&
        !cleaned.startsWith('62') &&
        !cleaned.startsWith('0')) {
      return 'Nomor telepon harus dimulai dengan +62, 62, atau 0';
    }

    // Check length (10-13 digits after country code)
    final digitsOnly = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 10 || digitsOnly.length > 13) {
      return 'Nomor telepon tidak valid';
    }

    return null;
  }

  /// Validate description (minimum length)
  ///
  /// Returns error message jika invalid, null jika valid
  static String? validateDescription(String description, {int minLength = 10}) {
    if (description.trim().isEmpty) {
      return 'Deskripsi tidak boleh kosong';
    }

    if (description.trim().length < minLength) {
      return 'Deskripsi minimal $minLength karakter';
    }

    return null;
  }

  /// Validate date (tidak boleh future date untuk transaction)
  ///
  /// Returns error message jika invalid, null jika valid
  static String? validateTransactionDate(DateTime date) {
    final now = DateTime.now();

    if (date.isAfter(now)) {
      return 'Tanggal transaksi tidak boleh di masa depan';
    }

    return null;
  }

  /// Check if file is image
  static bool isImageFile(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  /// Format file size untuk display
  ///
  /// Example:
  /// ```dart
  /// formatFileSize(1024) // "1 KB"
  /// formatFileSize(1048576) // "1 MB"
  /// formatFileSize(5242880) // "5 MB"
  /// ```
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  /// Validate numeric input
  static String? validateNumeric(String value, String fieldName) {
    if (double.tryParse(value) == null) {
      return '$fieldName harus berupa angka';
    }
    return null;
  }
}
