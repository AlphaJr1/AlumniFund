import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'providers/theme_provider.dart'; // Dynamic theme support
import 'widgets/app_colors.dart'; // Provide theme colors globally

// Flag untuk development mode (tanpa Firebase)
const bool kUseFirebase = true; // Firebase is configured and ready!

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use path URL strategy (remove # from URLs)
  usePathUrlStrategy();
  
  // Initialize English locale untuk date formatting
  await initializeDateFormatting('en_US', null);
  
  // Initialize Firebase ONLY if configured
  if (kUseFirebase) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      debugPrint('✅ Firebase initialized successfully');
      
      // Initialize default settings jika berhasil
      try {
        final firestoreService = FirestoreService();
        await firestoreService.initializeDefaultSettings();
      } catch (e) {
        debugPrint('Error initializing settings: $e');
      }
    } catch (e) {
      debugPrint('❌ Firebase initialization error: $e');
      // Continue without Firebase for development
    }
  } else {
    debugPrint('🔧 Running in DEVELOPMENT MODE without Firebase');
    debugPrint('   Set kUseFirebase = true in main.dart after configuring Firebase');
  }
  
  // Run app dengan ProviderScope untuk Riverpod
  runApp(
    const ProviderScope(
      child: DompetAlumniApp(),
    ),
  );
}

/// Main app widget
class DompetAlumniApp extends ConsumerWidget {
  const DompetAlumniApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    // Watch theme provider untuk dynamic colors
    final currentTheme = ref.watch(themeProvider);
    final themeColors = currentTheme.colors;
    
    return MaterialApp.router(
      key: ValueKey('theme_${currentTheme.name}'), // Force rebuild on theme change
      title: 'UNAME',
      debugShowCheckedModeBanner: false,
      
      // Theme - dynamic based on user selection
      theme: AppTheme.getLightTheme(themeColors),
      
      // Theme animation configuration
      themeAnimationDuration: const Duration(milliseconds: 500),
      themeAnimationCurve: Curves.easeInOut,
      
      // Builder to ensure router rebuilds with theme changes
      builder: (context, child) {
        return AppColors(
          colors: themeColors,
          child: child ?? const SizedBox(),
        );
      },
      
      // Routing
      routerConfig: router,
    );
  }
}
