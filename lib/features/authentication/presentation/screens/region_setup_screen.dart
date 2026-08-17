import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../providers/country_context_provider.dart';
import '../../../../core/layout/directional_layout.dart';
import '../../../../widgets/country_flag_widget.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../../../../widgets/madar_country_selector_sheet.dart';
import '../providers/user_auth_notifier.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_container.dart';
import '../widgets/auth_header.dart';
import '../widgets/demo_auto_advance.dart';
import '../widgets/primary_auth_button.dart';

class RegionSetupScreen extends StatelessWidget {
  const RegionSetupScreen({super.key});

  Future<void> _confirm(BuildContext context, UserAuthNotifier auth) async {
    final localeProvider = context.read<LocaleProvider>();
    final countryProvider = context.read<CountryContextProvider>();

    await localeProvider.setLanguage(auth.state.selectedLanguage);
    await countryProvider.setCountry(auth.state.selectedCountry);
    await countryProvider.setCurrency(
      auth.state.selectedCurrencyCode,
      overridden: false,
    );
    await auth.confirmRegionSetup();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final auth = context.watch<UserAuthNotifier>();
    final state = auth.state;
    final theme = Theme.of(context);

    return DemoAutoAdvance(
      onAdvance: () => _confirm(context, auth),
      child: AuthContainer(
        onLanguageTap: () => LanguageSelectorSheet.show(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: loc.authRegionTitle,
              subtitle: loc.authRegionSubtitle,
            ),
            const SizedBox(height: AuthSpacing.xl),
            Material(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
              child: InkWell(
                onTap: () async {
                  final selected = await MadarCountrySelectorSheet.show(
                    context,
                    selectedCountry: state.selectedCountry,
                  );
                  if (selected != null && context.mounted) {
                    auth.selectCountry(selected);
                    context.read<LocaleProvider>().setLanguage(
                      auth.state.selectedLanguage,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuthSpacing.lg,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      CountryFlagWidget(
                        countryCode: state.selectedCountry.isoCode,
                        size: 28,
                      ),
                      const SizedBox(width: AuthSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.authRegionCountry,
                              style: AuthTypography.caption(context),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.selectedCountry.localizedNameFromLoc(loc),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DirectionalChevronIcon(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AuthSpacing.xl),
            PrimaryAuthButton(
              label: loc.authRegionConfirm,
              isLoading: state.isBusy,
              onPressed: () => _confirm(context, auth),
            ),
          ],
        ),
      ),
    );
  }
}
