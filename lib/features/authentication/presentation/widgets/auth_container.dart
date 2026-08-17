import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../theme/auth_theme.dart';

/// Responsive shell for all authentication screens.
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
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AuthSpacing.maxContentWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
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
                        isWide: isWide,
                      ),
                      const SizedBox(height: AuthSpacing.xl),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar({
    required this.showLanguageAction,
    this.onLanguageTap,
    required this.isWide,
  });

  final bool showLanguageAction;
  final VoidCallback? onLanguageTap;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Madar',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Real Estate',
              style: AuthTypography.caption(context),
            ),
          ],
        ),
        const Spacer(),
        if (showLanguageAction && onLanguageTap != null)
          TextButton.icon(
            onPressed: onLanguageTap,
            icon: Icon(
              Icons.language,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            label: Text(
              loc.languageLabel,
              style: AuthTypography.caption(context).copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AuthSpacing.md,
                vertical: AuthSpacing.sm,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }
}
