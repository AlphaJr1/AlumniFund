import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/settings_model.dart';
import '../utils/constants.dart';

/// Provider untuk app settings stream (realtime)
final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.settings)
      .doc('app_config')
      .snapshots()
      .map((doc) => AppSettings.fromFirestore(doc));
});

/// Provider untuk payment methods
final paymentMethodsProvider = Provider<List<PaymentMethod>>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  
  return settingsAsync.when(
    data: (settings) => settings.paymentMethods,
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider untuk bank payment methods only
final bankPaymentMethodsProvider = Provider<List<PaymentMethod>>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  
  return settingsAsync.when(
    data: (settings) => settings.bankMethods,
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider untuk e-wallet payment methods only
final ewalletPaymentMethodsProvider = Provider<List<PaymentMethod>>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  
  return settingsAsync.when(
    data: (settings) => settings.ewalletMethods,
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider untuk system config
final systemConfigProvider = Provider<SystemConfig>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  
  return settingsAsync.when(
    data: (settings) => settings.systemConfig,
    loading: () => SystemConfig.defaults(),
    error: (_, __) => SystemConfig.defaults(),
  );
});

/// Provider untuk admin config
final adminConfigProvider = Provider<AdminConfig>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  
  return settingsAsync.when(
    data: (settings) => settings.adminConfig,
    loading: () => const AdminConfig(
      whatsappNumber: '+6281377707700',
      adminEmail: 'adrianalfajri@gmail.com',
    ),
    error: (_, __) => const AdminConfig(
      whatsappNumber: '+6281377707700',
      adminEmail: 'adrianalfajri@gmail.com',
    ),
  );
});
