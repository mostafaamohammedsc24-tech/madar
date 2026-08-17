import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../authentication/presentation/theme/auth_theme.dart';
import '../../../authentication/presentation/widgets/auth_container.dart';
import '../../../authentication/presentation/widgets/auth_header.dart';
import '../../../authentication/presentation/widgets/primary_auth_button.dart';
import '../../../../widgets/language_selector_sheet.dart';

/// Placeholder entry for company staff — wired later as a separate domain.
class EmployeePortalPlaceholderScreen extends StatelessWidget {
  const EmployeePortalPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AuthContainer(
      onLanguageTap: () => LanguageSelectorSheet.show(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: loc.employeePortalTitle,
            subtitle: loc.employeePortalSubtitle,
          ),
          const SizedBox(height: AuthSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AuthSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              loc.employeePortalBody,
              style: AuthTypography.body(context),
            ),
          ),
          const Spacer(),
          PrimaryAuthButton(
            label: loc.officeBackToUserLogin,
            onPressed: () => context.go('/auth'),
          ),
        ],
      ),
    );
  }
}
