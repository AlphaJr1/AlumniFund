import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum untuk tipe payment method
enum PaymentMethodType {
  bank,    // Bank transfer
  ewallet, // E-wallet
}

/// Model untuk single payment method
class PaymentMethod {
  final PaymentMethodType type;
  final String provider; // "BNI", "BCA", "OVO", "Gopay"
  final String accountNumber;
  final String accountName;
  final String? qrCodeUrl; // URL QR code dari Firebase Storage

  const PaymentMethod({
    required this.type,
    required this.provider,
    required this.accountNumber,
    required this.accountName,
    this.qrCodeUrl,
  });

  /// Convert dari Map ke PaymentMethod
  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      type: map['type'] == 'bank' 
          ? PaymentMethodType.bank 
          : PaymentMethodType.ewallet,
      provider: map['provider'] as String,
      accountNumber: map['account_number'] as String,
      accountName: map['account_name'] as String,
      qrCodeUrl: map['qr_code_url'] as String?,
    );
  }

  /// Convert PaymentMethod ke Map
  Map<String, dynamic> toMap() {
    return {
      'type': type == PaymentMethodType.bank ? 'bank' : 'ewallet',
      'provider': provider,
      'account_number': accountNumber,
      'account_name': accountName,
      'qr_code_url': qrCodeUrl,
    };
  }

  /// Check if this is a bank transfer method
  bool get isBank => type == PaymentMethodType.bank;

  /// Check if this is an e-wallet method
  bool get isEwallet => type == PaymentMethodType.ewallet;
}

/// Model untuk system configuration
class SystemConfig {
  final double perPersonAllocation; // Default: 250000
  final int deadlineOffsetDays; // Default: 3 (H-3)
  final double minimumContribution; // Default: 10000
  final bool autoOpenNextTarget; // Default: true

  const SystemConfig({
    required this.perPersonAllocation,
    required this.deadlineOffsetDays,
    required this.minimumContribution,
    required this.autoOpenNextTarget,
  });

  factory SystemConfig.defaults() {
    return const SystemConfig(
      perPersonAllocation: 250000,
      deadlineOffsetDays: 3,
      minimumContribution: 10000,
      autoOpenNextTarget: true,
    );
  }

  factory SystemConfig.fromMap(Map<String, dynamic> map) {
    return SystemConfig(
      perPersonAllocation: (map['per_person_allocation'] as num?)?.toDouble() ?? 250000,
      deadlineOffsetDays: (map['deadline_offset_days'] as num?)?.toInt() ?? 3,
      minimumContribution: (map['minimum_contribution'] as num?)?.toDouble() ?? 10000,
      autoOpenNextTarget: (map['auto_open_next_target'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'per_person_allocation': perPersonAllocation,
      'deadline_offset_days': deadlineOffsetDays,
      'minimum_contribution': minimumContribution,
      'auto_open_next_target': autoOpenNextTarget,
    };
  }
}

/// Model untuk admin configuration
class AdminConfig {
  final String whatsappNumber; // With country code: "+6281377707700"
  final String adminEmail;

  const AdminConfig({
    required this.whatsappNumber,
    required this.adminEmail,
  });

  factory AdminConfig.fromMap(Map<String, dynamic> map) {
    return AdminConfig(
      whatsappNumber: map['whatsapp_number'] as String? ?? '',
      adminEmail: map['admin_email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'whatsapp_number': whatsappNumber,
      'admin_email': adminEmail,
    };
  }
}

/// Model untuk app settings/configuration
class AppSettings {
  final String id;
  final List<PaymentMethod> paymentMethods;
  final SystemConfig systemConfig;
  final AdminConfig adminConfig;
  final DateTime updatedAt;
  final String? updatedBy;

  const AppSettings({
    required this.id,
    required this.paymentMethods,
    required this.systemConfig,
    required this.adminConfig,
    required this.updatedAt,
    this.updatedBy,
  });

  /// Create default settings untuk Adrian
  factory AppSettings.defaults() {
    return AppSettings(
      id: 'app_config',
      paymentMethods: [
        const PaymentMethod(
          type: PaymentMethodType.bank,
          provider: 'BNI',
          accountNumber: '1428471525',
          accountName: 'Adrian Alfajri',
        ),
        const PaymentMethod(
          type: PaymentMethodType.bank,
          provider: 'BCA',
          accountNumber: '3000968357',
          accountName: 'Adrian Alfajri',
        ),
        const PaymentMethod(
          type: PaymentMethodType.ewallet,
          provider: 'OVO',
          accountNumber: '081377707700',
          accountName: 'Adrian Alfajri',
        ),
        const PaymentMethod(
          type: PaymentMethodType.ewallet,
          provider: 'Gopay',
          accountNumber: '081377707700',
          accountName: 'Adrian Alfajri',
        ),
      ],
      systemConfig: SystemConfig.defaults(),
      adminConfig: const AdminConfig(
        whatsappNumber: '+6281377707700',
        adminEmail: 'adrianalfajri@gmail.com',
      ),
      updatedAt: DateTime.now(),
      updatedBy: 'system',
    );
  }

  /// Convert dari Firestore DocumentSnapshot ke AppSettings
  factory AppSettings.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      return AppSettings.defaults();
    }

    final data = doc.data() as Map<String, dynamic>;

    return AppSettings(
      id: doc.id,
      paymentMethods: (data['payment_methods'] as List<dynamic>?)
              ?.map((m) => PaymentMethod.fromMap(m as Map<String, dynamic>))
              .toList() ??
          AppSettings.defaults().paymentMethods,
      systemConfig: data['system_config'] != null
          ? SystemConfig.fromMap(data['system_config'] as Map<String, dynamic>)
          : SystemConfig.defaults(),
      adminConfig: data['admin_config'] != null
          ? AdminConfig.fromMap(data['admin_config'] as Map<String, dynamic>)
          : AppSettings.defaults().adminConfig,
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedBy: data['updated_by'] as String?,
    );
  }

  /// Convert AppSettings ke Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'payment_methods': paymentMethods.map((m) => m.toMap()).toList(),
      'system_config': systemConfig.toMap(),
      'admin_config': adminConfig.toMap(),
      'updated_at': Timestamp.fromDate(updatedAt),
      'updated_by': updatedBy,
    };
  }

  /// Get bank payment methods only
  List<PaymentMethod> get bankMethods =>
      paymentMethods.where((m) => m.isBank).toList();

  /// Get e-wallet payment methods only
  List<PaymentMethod> get ewalletMethods =>
      paymentMethods.where((m) => m.isEwallet).toList();

  /// Copy with method
  AppSettings copyWith({
    String? id,
    List<PaymentMethod>? paymentMethods,
    SystemConfig? systemConfig,
    AdminConfig? adminConfig,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AppSettings(
      id: id ?? this.id,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      systemConfig: systemConfig ?? this.systemConfig,
      adminConfig: adminConfig ?? this.adminConfig,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  String toString() => 'AppSettings(id: $id, paymentMethods: ${paymentMethods.length})';
}

