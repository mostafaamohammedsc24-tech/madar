import 'package:flutter/material.dart';

import 'app_theme.dart';

extension MadarTheme on ThemeData {
  bool get isDarkMode => brightness == Brightness.dark;

  Color get surfaceVariantColor =>
      isDarkMode ? AppTheme.surfaceVariantDark : AppTheme.surfaceVariantLight;

  Color get borderColor => isDarkMode ? AppTheme.borderDark : AppTheme.borderLight;

  Color get sheetBackground => colorScheme.surface;

  Color get mutedTextColor => colorScheme.onSurfaceVariant;

  Color get primaryTextColor => colorScheme.onSurface;
}
