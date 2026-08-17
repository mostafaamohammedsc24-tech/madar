import 'package:flutter/material.dart';

import 'auth_responsive_shell.dart';

/// Responsive auth shell — mobile-first below 1200px, premium split on desktop.
class AuthContainer extends StatelessWidget {
  const AuthContainer({
    super.key,
    required this.child,
    this.footer,
    this.showLanguageAction = true,
    this.onLanguageTap,
  });

  final Widget child;
  final Widget? footer;
  final bool showLanguageAction;
  final VoidCallback? onLanguageTap;

  @override
  Widget build(BuildContext context) {
    return AuthResponsiveShell(
      showLanguageAction: showLanguageAction,
      onLanguageTap: onLanguageTap,
      footer: footer,
      child: child,
    );
  }
}
