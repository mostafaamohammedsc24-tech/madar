import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../theme/auth_theme.dart';

/// White + primary-blue shell for every authentication screen.
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
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
  });

  final bool showLanguageAction;
  final VoidCallback? onLanguageTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.authBrandName,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            Text(
              loc.authBrandTagline,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
              size: 18,
              color: AppTheme.primary,
            ),
            label: Text(
              loc.languageLabel,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
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
