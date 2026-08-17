import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../theme/auth_theme.dart';

/// White + primary-blue shell for every authentication screen.
/// Phone: stacked brand + form. Wide web: split hero panel + form card.
class AuthContainer extends StatelessWidget {
  const AuthContainer({
    super.key,
    required this.child,
    this.showLanguageAction = true,
    this.onLanguageTap,
  });

  final Widget child;
  final bool showLanguageAction;
  final VoidCallback? onLanguageTap;

  @override
  Widget build(BuildContext context) {
    final wide = AuthTypography.isWide(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    if (wide) {
      return Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Row(
          children: [
            const Expanded(flex: 5, child: _AuthHeroPanel()),
            Expanded(
              flex: 6,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AuthSpacing.maxContentWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        40,
                        32,
                        40,
                        32 + bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AuthTopBar(
                            showLanguageAction: showLanguageAction,
                            onLanguageTap: onLanguageTap,
                            compactBrand: true,
                          ),
                          const SizedBox(height: AuthSpacing.xl),
                          Expanded(child: child),
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

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AuthSpacing.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                AuthSpacing.horizontalPadding,
                AuthSpacing.lg,
                AuthSpacing.horizontalPadding,
                AuthSpacing.lg + bottomInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AuthTopBar(
                    showLanguageAction: showLanguageAction,
                    onLanguageTap: onLanguageTap,
                  ),
                  const SizedBox(height: AuthSpacing.xl),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeroPanel extends StatelessWidget {
  const _AuthHeroPanel();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), AppTheme.primary, Color(0xFF42A5F5)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _blob(220, Colors.white.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: 80,
            right: -40,
            child: _blob(180, Colors.white.withValues(alpha: 0.10)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  loc.authBrandName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.authBrandTagline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 56,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  loc.authLocationTitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar({
    required this.showLanguageAction,
    this.onLanguageTap,
    this.compactBrand = false,
  });

  final bool showLanguageAction;
  final VoidCallback? onLanguageTap;
  final bool compactBrand;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final hideBrand = compactBrand;

    return Row(
      children: [
        if (!hideBrand)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.authBrandName,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                loc.authBrandTagline,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        const Spacer(),
        if (showLanguageAction && onLanguageTap != null)
          TextButton.icon(
            onPressed: onLanguageTap,
            icon: const Icon(
              Icons.language,
              size: 20,
              color: AppTheme.primary,
            ),
            label: Text(
              loc.languageLabel,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.06),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}
