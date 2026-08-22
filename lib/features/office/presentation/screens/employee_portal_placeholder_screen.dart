import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/legal_strings.dart';
import '../../../../core/localization/closing_strings.dart';
import '../../../../core/localization/mapping_strings.dart';
import '../../../../core/localization/field_strings.dart';
import '../../../../core/localization/photo_strings.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../../../authentication/presentation/theme/auth_theme.dart';
import '../../../authentication/presentation/widgets/auth_container.dart';
import '../../../authentication/presentation/widgets/auth_header.dart';
import '../../../authentication/presentation/widgets/primary_auth_button.dart';
import '../../../legal/presentation/theme/legal_theme.dart';

/// Staff domain picker — Contract Lawyer is the live workspace.
class EmployeePortalPlaceholderScreen extends StatelessWidget {
  const EmployeePortalPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final legal = LegalStrings.of(loc);
    final closing = ClosingStrings.of(loc);
    final mapping = MappingStrings.of(loc);
    final field = FieldStrings.of(loc);
    final photo = PhotoStrings.of(loc);
    final theme = Theme.of(context);

    return AuthContainer(
      onLanguageTap: () => LanguageSelectorSheet.show(context),
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(title: legal.staffHubTitle, subtitle: legal.staffHubBody),
          const SizedBox(height: AuthSpacing.lg),
          Text(legal.notPublicSite, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
          const SizedBox(height: AuthSpacing.xl),
          PrimaryAuthButton(
            label: legal.enterLegal,
            onPressed: () => context.go('/legal-login'),
          ),
          const SizedBox(height: AuthSpacing.md),
          PrimaryAuthButton(
            label: closing.enterClosing,
            onPressed: () => context.go('/closing-login'),
          ),
          const SizedBox(height: AuthSpacing.md),
          PrimaryAuthButton(
            label: mapping.enterMapping,
            onPressed: () => context.go('/mapping-login'),
          ),
          const SizedBox(height: AuthSpacing.md),
          PrimaryAuthButton(
            label: field.enterField,
            onPressed: () => context.go('/field-login'),
          ),
          const SizedBox(height: AuthSpacing.md),
          PrimaryAuthButton(
            label: photo.enterPhoto,
            onPressed: () => context.go('/photo-login'),
          ),
          const SizedBox(height: AuthSpacing.md),
          _DisabledCard(text: legal.financeUnavailable, theme: theme),
          const SizedBox(height: 8),
          _DisabledCard(text: legal.bankUnavailable, theme: theme),
          const SizedBox(height: 8),
          _DisabledCard(text: legal.officeUnavailable, theme: theme),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go('/auth'),
            child: Text(loc.officeBackToUserLogin),
          ),
        ],
        ),
      ),
    );
  }
}

class _DisabledCard extends StatelessWidget {
  const _DisabledCard({required this.text, required this.theme});
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
    );
  }
}
