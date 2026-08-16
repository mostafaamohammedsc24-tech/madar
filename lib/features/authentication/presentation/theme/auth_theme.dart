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

  static const double buttonHeight = 52;
  static const double inputHeight = 56;
  static const double maxContentWidth = 440;
  static const double horizontalPadding = 24;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
}

/// Typography helpers for auth screens — uses theme text styles.
abstract final class AuthTypography {
  static TextStyle display(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.2,
    );
  }

  static TextStyle heading(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.3,
    );
  }

  static TextStyle body(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.5,
    );
  }

  static TextStyle caption(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle button(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );
  }
}

/// Shared color tokens for auth surfaces.
abstract final class AuthColors {
  static const Color accent = AppTheme.primary;
  static const Color accentMuted = AppTheme.primaryContainer;
  static const Color errorSurface = AppTheme.errorLight;
  static const Color errorText = AppTheme.error;
}
