import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../authentication/presentation/theme/auth_theme.dart';

/// Elegant partner / staff entry below user phone login — not a cluttered bolt-on.
class PartnerEntrySection extends StatelessWidget {
  const PartnerEntrySection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AuthSpacing.xxl),
        Row(
          children: [
            Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AuthSpacing.md),
              child: Text(
                loc.partnerEntryPrompt,
                style: AuthTypography.caption(context),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: AuthSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/office-login'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: theme.colorScheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  loc.officeEntryCta,
                  style: AuthTypography.button(context).copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AuthSpacing.md),
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/employee-login'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: theme.colorScheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  loc.employeeEntryCta,
                  style: AuthTypography.button(context).copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
