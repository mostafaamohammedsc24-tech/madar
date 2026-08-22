import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium legal-operations palette — Madar Blue, navy, paper gray.
class LegalTheme {
  static const Color primary = Color(0xFF003EC7);
  static const Color primaryDark = Color(0xFF001452);
  static const Color navy = Color(0xFF0D1C32);
  static const Color charcoal = Color(0xFF191C1D);
  static const Color muted = Color(0xFF434656);
  static const Color paper = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF3F4F5);
  static const Color outline = Color(0xFFE1E3E4);
  static const Color softBlue = Color(0xFFDDE1FF);
  static const Color success = Color(0xFF2E7D32);
  static const Color successSoft = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningSoft = Color(0xFFFFF3E0);
  static const Color danger = Color(0xFFBA1A1A);
  static const Color dangerSoft = Color(0xFFFFDAD6);
  static const Color active = Color(0xFF003EC7);
  static const Color activeSoft = Color(0xFFE8EEFF);

  static const Color darkBg = Color(0xFF0D1C32);
  static const Color darkSurface = Color(0xFF1A2438);
  static const Color darkElevated = Color(0xFF243044);
  static const Color darkText = Color(0xFFF0F1F2);
  static const Color darkMuted = Color(0xFFB9C7E4);

  static TextStyle ibm({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.ibmPlexSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle mono({
    required double size,
    Color? color,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }
}
