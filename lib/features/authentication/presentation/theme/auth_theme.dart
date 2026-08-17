import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

/// Spacing and layout tokens for authentication screens.
abstract final class AuthSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double buttonHeight = 56;
  static const double inputHeight = 60;
  static const double maxContentWidth = 480;
  static const double wideBreakpoint = 900;
  static const double horizontalPadding = 28;
  static const double radiusSm = 14;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
}

/// Typography helpers for auth screens — uses theme text styles.
abstract final class AuthTypography {
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AuthSpacing.wideBreakpoint;

  static TextStyle display(BuildContext context) {
    final wide = isWide(context);
    return Theme.of(context).textTheme.displayMedium!.copyWith(
      fontSize: wide ? 40 : 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.1,
      height: 1.15,
      color: const Color(0xFF0D47A1),
    );
  }

  static TextStyle heading(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.3,
    );
  }

  static TextStyle welcome(BuildContext context) {
    return const TextStyle(
      color: AppTheme.primary,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
  }

  static TextStyle body(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 16,
      height: 1.55,
    );
  }

  static TextStyle caption(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle button(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 17,
      letterSpacing: 0.2,
    );
  }
}

/// Shared color tokens for auth surfaces.
abstract final class AuthColors {
  static const Color accent = AppTheme.primary;
  static const Color accentMuted = AppTheme.primaryContainer;
  static const Color errorSurface = AppTheme.errorLight;
  static const Color errorText = AppTheme.error;
  static const Color ink = Color(0xFF0D47A1);
}
