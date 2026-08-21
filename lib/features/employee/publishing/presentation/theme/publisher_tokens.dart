import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stitch “Madar Publisher Workspace” tokens.
abstract final class PublisherTokens {
  static const Color primary = Color(0xFF002045);
  static const Color primaryContainer = Color(0xFF1A365D);
  static const Color onPrimaryContainer = Color(0xFF86A0CD);
  static const Color secondary = Color(0xFF1960A3);
  static const Color background = Color(0xFFFAF9FD);
  static const Color surface = Color(0xFFFAF9FD);
  static const Color surfaceLow = Color(0xFFF4F3F7);
  static const Color surfaceContainer = Color(0xFFEFEDF1);
  static const Color surfaceHighest = Color(0xFFE3E2E6);
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color onSurfaceVariant = Color(0xFF43474E);
  static const Color outlineVariant = Color(0xFFC4C6CF);
  static const Color tertiaryContainer = Color(0xFF4F2E00);
  static const Color onTertiaryContainer = Color(0xFFC6955E);
  static const Color card = Color(0xFFFFFFFF);

  static List<BoxShadow> get microDepth => [
        BoxShadow(
          color: const Color(0xFF1A365D).withValues(alpha: 0.05),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: const Color(0xFF1A365D).withValues(alpha: 0.03),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static TextTheme textTheme(TextTheme base) {
    final inter = GoogleFonts.interTextTheme(base);
    return inter.copyWith(
      titleLarge: inter.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyMedium: inter.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: onSurface,
      ),
      bodySmall: inter.bodySmall?.copyWith(
        color: onSurfaceVariant,
        height: 1.35,
      ),
      labelMedium: inter.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: onSurfaceVariant,
      ),
      labelSmall: inter.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
