import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales - Thème violet professionnel
  static const Color primary = Color(0xFF6B46C1); // Violet principal
  static const Color primaryDark = Color(0xFF553C9A);
  static const Color primaryLight = Color(0xFF8B5CF6);

  // Couleurs secondaires
  static const Color secondary = Color(0xFF10B981); // Vert pour succès
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryLight = Color(0xFF34D399);

  // Couleurs d'accent
  static const Color accent = Color(0xFFF59E0B); // Orange pour CTAs
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFBBF24);

  // Couleurs neutres
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Couleurs de texte
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Couleurs d'état
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Couleurs de bordure
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);

  // Ombres
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowDark = Color(0x26000000);

  // Couleurs spécifiques aux services financiers
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color goldCard = Color(0xFFFFD700);
  static const Color platinumCard = Color(0xFFE5E4E2);
  static const Color premiumCard = Color(0xFF2D1B69);

  // Couleurs Mobile Money
  static const Color orangeMoney = Color(0xFFFF6600);
  static const Color mtnMoney = Color(0xFFFFCC00);
  static const Color moovMoney = Color(0xFF0066CC);
  static const Color wave = Color(0xFF6B46C1);

  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, secondaryDark],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, accentDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardBackground, Color(0xFF2D2D2D)],
  );

  // Couleurs avec opacité
  static Color primaryWithOpacity(double opacity) =>
      primary.withOpacity(opacity);
  static Color backgroundWithOpacity(double opacity) =>
      background.withOpacity(opacity);
  static Color textWithOpacity(double opacity) =>
      textPrimary.withOpacity(opacity);
}
