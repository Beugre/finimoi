import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Inspired by Revolut/Lydia
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryViolet = Color(0xFF6C5CE7); // Alias for primary
  static const Color primaryLight = Color(0xFF9B8CE7);
  static const Color primaryDark = Color(0xFF4834D4);

  static const Color secondary = Color(0xFF00D2FF);
  static const Color secondaryLight = Color(0xFF4DE6FF);
  static const Color secondaryDark = Color(0xFF0099CC);

  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF9999);
  static const Color accentDark = Color(0xFFE84343);

  // Semantic Colors
  static const Color success = Color(0xFF00B894);
  static const Color successLight = Color(0xFF4DD0B8);
  static const Color successDark = Color(0xFF008F72);

  static const Color warning = Color(0xFFFDAB3C);
  static const Color warningLight = Color(0xFFFFC266);
  static const Color warningDark = Color(0xFFE08900);

  static const Color error = Color(0xFFE17055);
  static const Color errorLight = Color(0xFFE89478);
  static const Color errorDark = Color(0xFFBD4932);

  static const Color info = Color(0xFF74B9FF);
  static const Color infoLight = Color(0xFF98CAFF);
  static const Color infoDark = Color(0xFF4A9BFF);

  // Neutral Colors - Light Theme
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF5F5F5);

  static const Color onBackgroundLight = Color(0xFF2D3436);
  static const Color onSurfaceLight = Color(0xFF2D3436);
  static const Color onSurfaceVariantLight = Color(0xFF636E72);

  static const Color outlineLight = Color(0xFFDDD6FE);
  static const Color outlineVariantLight = Color(0xFFE5E5E5);

  // Neutral Colors - Dark Theme
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceVariantDark = Color(0xFF2D2D2D);

  static const Color onBackgroundDark = Color(0xFFE1E1E1);
  static const Color onSurfaceDark = Color(0xFFE1E1E1);
  static const Color onSurfaceVariantDark = Color(0xFFB2B2B2);

  static const Color outlineDark = Color(0xFF4A4458);
  static const Color outlineVariantDark = Color(0xFF363636);

  // Financial Colors
  static const Color income = Color(0xFF00B894);
  static const Color expense = Color(0xFFE17055);
  static const Color savings = Color(0xFF74B9FF);
  static const Color investment = Color(0xFF6C5CE7);

  // Card Colors
  static const List<Color> cardGradients = [
    Color(0xFF667eea),
    Color(0xFF764ba2),
    Color(0xFF2193b0),
    Color(0xFF6dd5ed),
    Color(0xFFee9ca7),
    Color(0xFFffdde1),
    Color(0xFFa8edea),
    Color(0xFFfed6e3),
  ];

  // Tontine Status Colors
  static const Color tontineActive = Color(0xFF00B894);
  static const Color tontinePending = Color(0xFFFDAB3C);
  static const Color tontineCompleted = Color(0xFF6C5CE7);
  static const Color tontineOverdue = Color(0xFFE17055);

  // Credit Score Colors
  static const Color creditExcellent = Color(0xFF00B894);
  static const Color creditGood = Color(0xFF74B9FF);
  static const Color creditFair = Color(0xFFFDAB3C);
  static const Color creditPoor = Color(0xFFE17055);

  // Transaction Status Colors
  static const Color transactionPending = Color(0xFFFDAB3C);
  static const Color transactionCompleted = Color(0xFF00B894);
  static const Color transactionFailed = Color(0xFFE17055);
  static const Color transactionCancelled = Color(0xFF636E72);

  // Gamification Colors
  static const Color badge = Color(0xFFFFD700);
  static const Color points = Color(0xFF6C5CE7);
  static const Color achievement = Color(0xFF00B894);
  static const Color streak = Color(0xFFFF6B6B);
}

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, AppColors.secondaryDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.success, AppColors.successDark],
  );

  static const LinearGradient cardGradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
  );

  static const LinearGradient cardGradient2 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
  );

  static const LinearGradient cardGradient3 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFee9ca7), Color(0xFFffdde1)],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [Color(0xFFE0E0E0), Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
  );

  static const LinearGradient darkShimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [Color(0xFF424242), Color(0xFF616161), Color(0xFF424242)],
  );
}
