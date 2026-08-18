import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../theme/auth_theme.dart';
import 'auth_brand_mark.dart';
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
        showLanguageAction: showLanguageAction,
        onLanguageTap: onLanguageTap,
        footer: footer,
        child: child,
      );
    }
    return _MobileAuthShell(
      showLanguageAction: showLanguageAction,
      onLanguageTap: onLanguageTap,
      footer: footer,
      child: child,
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AuthColors.canvas,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, 12, 22, 20 + bottomInset),
          child: Column(
            children: [
              const AuthBrandMark(fontSize: 36),
              const SizedBox(height: 22),
              _AuthCard(
                showLanguageAction: showLanguageAction,
                onLanguageTap: onLanguageTap,
                child: child,
              ),
              if (footer != null) ...[const SizedBox(height: 16), footer!],
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
            child: ColoredBox(
              color: AuthColors.canvas,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AuthBrandMark(fontSize: 44, showIcon: true),
                      const SizedBox(height: 20),
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
              color: const Color(0xFFF3F6FB),
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
                          elevation: 8,
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
    this.elevation = 10,
  });

  final Widget child;
  final bool showLanguageAction;
  final VoidCallback? onLanguageTap;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: elevation,
      shadowColor: const Color(0x3D000000),
      borderRadius: BorderRadius.circular(AuthSpacing.radiusCard),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 22, 26, 30),
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
