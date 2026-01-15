import 'package:flutter/material.dart';

// ==================== FIRESTORE COLLECTIONS ====================

/// Firestore collection names
class FirestoreCollections {
  static const String graduationTargets = 'graduation_targets';
  static const String transactions = 'transactions';
  static const String generalFund = 'general_fund';
  static const String settings = 'settings';
  static const String pendingSubmissions = 'pending_submissions';
  static const String adminUsers = 'admin_users';
}

// ==================== STORAGE PATHS ====================

/// Firebase Storage paths
class StoragePaths {
  static const String proofImages = 'proof_images';
  static const String qrCodes = 'qr_codes';
}

// ==================== TRANSACTION CATEGORIES ====================

/// Transaction categories untuk expense
class TransactionCategories {
  static const String wisuda = 'wisuda';
  static const String community = 'community';
  static const String operational = 'operational';
  static const String others = 'others';
  
  static const List<String> all = [
    wisuda,
    community,
    operational,
    others,
  ];
  
  /// Get display name untuk category
  static String getDisplayName(String category) {
    switch (category) {
      case wisuda:
        return 'Wisuda';
      case community:
        return 'Komunitas';
      case operational:
        return 'Operasional';
      case others:
        return 'Lainnya';
      default:
        return category;
    }
  }
}

// ==================== APP CONSTANTS ====================

/// App constants untuk colors, sizes, breakpoints, dll
class AppConstants {
  // ==================== COLORS ====================
  
  /// Primary teal color
  static const Color primaryTeal = Color(0xFF14b8a6);
  
  /// Darker teal for gradients
  static const Color darkTeal = Color(0xFF0d9488);
  
  /// Light teal for backgrounds
  static const Color lightTeal = Color(0xFFCCFBF1);
  
  /// Green colors
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color lightGreen = Color(0xFFD1FAE5);
  static const Color darkGreen = Color(0xFF065F46);
  
  /// Gray shades
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
  
  /// Status colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color infoBlue = Color(0xFF3B82F6);
  
  /// Background colors for status
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color infoBg = Color(0xFFEFF6FF);
  
  /// Border colors for status
  static const Color successBorder = Color(0xFF10B981);
  static const Color warningBorder = Color(0xFFF59E0B);
  static const Color errorBorder = Color(0xFFFCA5A5);
  static const Color infoBorder = Color(0xFFBFDBFE);
  
  /// Progress bar gradient colors
  static const List<Color> progressGray = [Color(0xFFD1D5DB), Color(0xFF9CA3AF)];
  static const List<Color> progressBronze = [Color(0xFFFCD34D), Color(0xFFF59E0B)];
  static const List<Color> progressSilver = [Color(0xFFFB923C), Color(0xFFEA580C)];
  static const List<Color> progressGold = [Color(0xFF4ADE80), Color(0xFF16A34A)];
  static const List<Color> progressComplete = [Color(0xFF14b8a6), Color(0xFF0891B2)];
  
  // ==================== BREAKPOINTS ====================
  
  /// Mobile breakpoint (< 600px)
  static const double mobileBreakpoint = 600;
  
  /// Tablet breakpoint (< 1024px)
  static const double tabletBreakpoint = 1024;
  
  /// Desktop breakpoint (>= 1024px)
  static const double desktopBreakpoint = 1024;
  
  // ==================== SIZES ====================
  
  /// Header heights
  static const double headerHeightDesktop = 60;
  static const double headerHeightMobile = 56;
  
  /// Card padding
  static const double cardPaddingDesktop = 32;
  static const double cardPaddingTablet = 20;
  static const double cardPaddingMobile = 16;
  
  /// Card max widths
  static const double cardMaxWidthSmall = 600;
  static const double cardMaxWidthMedium = 700;
  static const double cardMaxWidthLarge = 800;
  
  /// Button heights
  static const double buttonHeightLarge = 48;
  static const double buttonHeightMedium = 44;
  static const double buttonHeightSmall = 40;
  
  /// Border radius
  static const double borderRadiusSmall = 8;
  static const double borderRadiusMedium = 12;
  static const double borderRadiusLarge = 16;
  static const double borderRadiusRounded = 24;
  
  /// Icon sizes
  static const double iconSizeSmall = 16;
  static const double iconSizeMedium = 24;
  static const double iconSizeLarge = 32;
  
  // ==================== SPACING ====================
  
  /// Standard spacing values
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing48 = 48;
  static const double spacing60 = 60;
  
  // ==================== DEFAULT VALUES ====================
  
  /// App name
  static const String appName = 'UNAME';
  
  /// Community name
  static const String communityName = 'Alumni Community';
  
  /// Per person allocation (Rp 250.000)
  static const double defaultPerPersonAllocation = 250000;
  
  /// Deadline offset (H-3)
  static const int defaultDeadlineOffsetDays = 3;
  
  /// Minimum contribution (Rp 10.000)
  static const double defaultMinimumContribution = 10000;
  
  /// Max file size for upload (5MB)
  static const int maxFileSize = 5 * 1024 * 1024;
  
  /// Allowed file extensions
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];
  
  /// WhatsApp green color
  static const Color whatsappGreen = Color(0xFF25D366);
  
  // ==================== ANIMATION DURATIONS ====================
  
  /// Progress bar animation duration
  static const Duration progressAnimationDuration = Duration(milliseconds: 500);
  
  /// Toast notification duration
  static const Duration toastDuration = Duration(seconds: 3);
  
  /// Modal animation duration
  static const Duration modalAnimationDuration = Duration(milliseconds: 300);
  
  /// Confetti animation duration
  static const Duration confettiDuration = Duration(seconds: 3);
  
  // ==================== Z-INDEX ====================
  
  /// Header z-index
  static const int zIndexHeader = 1000;
  
  /// Modal overlay z-index
  static const int zIndexModal = 2000;
  
  /// Toast notification z-index
  static const int zIndexToast = 3000;
  
  // ==================== HELPER METHODS ====================
  
  /// Get responsive padding based on screen width
  static double getCardPadding(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return cardPaddingMobile;
    } else if (screenWidth < tabletBreakpoint) {
      return cardPaddingTablet;
    } else {
      return cardPaddingDesktop;
    }
  }
  
  /// Get responsive header height based on screen width
  static double getHeaderHeight(double screenWidth) {
    return screenWidth < mobileBreakpoint 
        ? headerHeightMobile 
        : headerHeightDesktop;
  }
  
  /// Get progress bar gradient based on percentage
  static List<Color> getProgressGradient(double percentage) {
    if (percentage < 25) {
      return progressGray;
    } else if (percentage < 50) {
      return progressBronze;
    } else if (percentage < 75) {
      return progressSilver;
    } else if (percentage < 100) {
      return progressGold;
    } else {
      return progressComplete;
    }
  }
  
  /// Check if screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  /// Check if screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }
  
  /// Check if screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
}
