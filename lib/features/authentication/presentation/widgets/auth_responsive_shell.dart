import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../theme/app_theme.dart';
import '../theme/auth_theme.dart';
import 'auth_language_button.dart';

/// Mobile-first auth below [desktopBreakpoint]; premium split layout on desktop.
class AuthResponsiveShell extends StatelessWidget {
  const AuthResponsiveShell({
    super.key,
    required this.child,
    this.footer,
    this.showLanguageAction = true,
    this.onLanguageTap,
  });

  static const double desktopBreakpoint = 1200;
  static const double tabletBreakpoint = 768;

  final Widget child;
  final Widget? footer;
  final bool showLanguageAction;
  final VoidCallback? onLanguageTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) {
      return _DesktopAuthShell(
        child: child,
        footer: footer,
        showLanguageAction: showLanguageAction,
        onLanguageTap: onLanguageTap,
      );
    }
    return _MobileAuthShell(
      child: child,
      footer: footer,
      showLanguageAction: showLanguageAction,
      onLanguageTap: onLanguageTap,
    );
  }
}

class _MobileAuthShell extends StatelessWidget {
  const _MobileAuthShell({
    required this.child,
    this.footer,
    required this.showLanguageAction,
    this.onLanguageTap,
  });

  final Widget child;
  final Widget? footer;
  final bool showLanguageAction;
  final VoidCallback? onLanguageTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AuthColors.canvas,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  loc.authBrandName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _AuthCard(
                showLanguageAction: showLanguageAction,
                onLanguageTap: onLanguageTap,
                child: child,
              ),
              if (footer != null) ...[
                const SizedBox(height: 16),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopAuthShell extends StatelessWidget {
  const _DesktopAuthShell({
    required this.child,
    this.footer,
    required this.showLanguageAction,
    this.onLanguageTap,
  });

  final Widget child;
  final Widget? footer;
  final bool showLanguageAction;
  final VoidCallback? onLanguageTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 11,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1565C0),
                    Color(0xFF1976D2),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.authBrandName,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.authDesktopTagline,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                      const Spacer(),
                      _DesktopFeatureRow(
                        icon: Icons.map_outlined,
                        label: loc.authDesktopFeatureMap,
                      ),
                      const SizedBox(height: 12),
                      _DesktopFeatureRow(
                        icon: Icons.verified_outlined,
                        label: loc.authDesktopFeatureVerified,
                      ),
                      const SizedBox(height: 12),
                      _DesktopFeatureRow(
                        icon: Icons.language_outlined,
                        label: loc.authDesktopFeatureLanguages,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        loc.authDesktopFooter,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 9,
            child: ColoredBox(
              color: theme.colorScheme.surface,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AuthCard(
                          showLanguageAction: showLanguageAction,
                          onLanguageTap: onLanguageTap,
                          elevation: 2,
                          child: child,
                        ),
                        if (footer != null) ...[
                          const SizedBox(height: 20),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.child,
    required this.showLanguageAction,
    this.onLanguageTap,
    this.elevation = 0,
  });

  final Widget child;
  final bool showLanguageAction;
  final VoidCallback? onLanguageTap;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: elevation,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLanguageAction && onLanguageTap != null)
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: AuthLanguageButton(onTap: onLanguageTap!),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

class _DesktopFeatureRow extends StatelessWidget {
  const _DesktopFeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
