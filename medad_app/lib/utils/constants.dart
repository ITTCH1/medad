import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'مدد';
  static const String appVersion = '1.0.0';
  
  // API & Services
  static const String firebaseProjectId = 'medad-1';
  
  // Pagination
  static const int adsPageSize = 20;
  static const int recentAdsLimit = 10;
  
  // Image Upload
  static const int maxImagesPerAd = 5;
  static const int maxImageSizeMB = 5;
  static const int imageQuality = 70;
  static const int maxImageWidth = 1024;
  
  // Rate Limiting
  static const int maxAdsPerDay = 5;
  static const int maxOTPAttempts = 3;
  static const Duration otpCooldownDuration = Duration(minutes: 5);
  
  // Cache
  static const Duration cacheDuration = Duration(hours: 1);
  static const int cacheSizeMB = 50;
  
  // Search
  static const int searchResultsLimit = 20;
  static const int minSearchQueryLength = 3;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int minNameLength = 2;
  static const int maxTitleLength = 100;
  static const int minTitleLength = 5;
  static const int maxDescriptionLength = 2000;
  static const int minDescriptionLength = 10;
  static const int maxPhoneLength = 15;
  static const int minPhoneLength = 7;
  static const int maxPrice = 1000000000;
  
  // Phone
  static const String defaultCountryCode = '+967';
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleMerchant = 'merchant';
  static const String roleCustomer = 'customer';
  static const String roleDelivery = 'delivery';
  
  // Ad Status
  static const String adStatusActive = 'active';
  static const String adStatusInactive = 'inactive';
  static const String adStatusSold = 'sold';
  static const String adStatusPending = 'pending';
  
  // User Status
  static const String userStatusApproved = 'approved';
  static const String userStatusRejected = 'rejected';
  static const String userStatusPending = 'pending';
}

/// App theme colors
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF009688); // Teal
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color primaryDark = Color(0xFF00796B);
  
  // Background colors
  static const Color backgroundLight = Color(0xFFF8F9FB);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E1E1E);
  
  // Text colors
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Social media colors
  static const Color whatsapp = Color(0xFF25D366);
  static const Color facebook = Color(0xFF1877F2);
  static const Color twitter = Color(0xFF1DA1F2);
}

/// App text styles
class AppTextStyles {
  static const String fontFamily = 'Cairo';
  
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryLight,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryLight,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryLight,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimaryLight,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondaryLight,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondaryLight,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondaryLight,
  );
}

/// Spacing constants
class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Border radius constants
class AppBorderRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double circle = 9999;
}

/// Shadow constants
class AppShadows {
  static BoxShadow get small => BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 4,
    offset: const Offset(0, 2),
  );
  
  static BoxShadow get medium => BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );
  
  static BoxShadow get large => BoxShadow(
    color: Colors.black.withOpacity(0.12),
    blurRadius: 16,
    offset: const Offset(0, 8),
  );
}
