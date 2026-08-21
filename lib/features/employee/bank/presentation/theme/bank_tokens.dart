import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stitch “Madar Bank Operations” tokens — primary #00317e.
abstract final class BankTokens {
  static const Color primary = Color(0xFF00317E);
  static const Color primaryContainer = Color(0xFF0046AD);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFA5BDFF);
  static const Color secondary = Color(0xFF515F78);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceLow = Color(0xFFF3F4F5);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceHighest = Color(0xFFE1E3E4);
  static const Color card = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF434653);
  static const Color outline = Color(0xFF737784);
  static const Color outlineVariant = Color(0xFFC3C6D5);
  static const Color success = Color(0xFF1B7A4E);
  static const Color successSoft = Color(0xFFE6F4EC);
  static const Color warning = Color(0xFFB07000);
  static const Color warningSoft = Color(0xFFFFF4E0);
  static const Color error = Color(0xFFBA1A1A);
  static const Color navy = Color(0xFF0B1C30);

  static List<BoxShadow> get microDepth => [
        BoxShadow(
          color: primary.withValues(alpha: 0.06),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static TextTheme textTheme(TextTheme base) {
    final arabic = GoogleFonts.ibmPlexSansArabicTextTheme(base);
    return arabic.copyWith(
      titleLarge: arabic.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleMedium: arabic.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyMedium: arabic.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: onSurface,
      ),
      bodySmall: arabic.bodySmall?.copyWith(
        color: onSurfaceVariant,
        height: 1.35,
      ),
      labelMedium: arabic.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: onSurfaceVariant,
      ),
    );
  }
}
