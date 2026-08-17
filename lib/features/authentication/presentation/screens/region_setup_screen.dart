import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/currency/currency_registry.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../providers/country_context_provider.dart';
import '../../../../core/layout/directional_layout.dart';
import '../../../../widgets/country_flag_widget.dart';
import '../../../../widgets/currency_selector_sheet.dart';
import '../../../../widgets/madar_country_selector_sheet.dart';
import '../providers/user_auth_notifier.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_container.dart';
import '../widgets/auth_header.dart';
import '../widgets/primary_auth_button.dart';

/// Confirm detected country, language, and currency before sign-in.
class RegionSetupScreen extends StatefulWidget {
  const RegionSetupScreen({super.key});

  @override
  State<RegionSetupScreen> createState() => _RegionSetupScreenState();
}

class _RegionSetupScreenState extends State<RegionSetupScreen> {
  bool _currencyManuallySet = false;

  Future<void> _confirm(UserAuthNotifier auth) async {
    final localeProvider = context.read<LocaleProvider>();
    final countryProvider = context.read<CountryContextProvider>();

    await localeProvider.setLanguage(auth.state.selectedLanguage);
    await countryProvider.setCountry(
      auth.state.selectedCountry,
      updateCurrency: !_currencyManuallySet,
    );
    if (_currencyManuallySet) {
      await countryProvider.setCurrency(auth.state.selectedCurrencyCode);
    }

    await auth.confirmRegionSetup();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final auth = context.watch<UserAuthNotifier>();
    final state = auth.state;
    final theme = Theme.of(context);
    final currency = CurrencyRegistry.findByCode(state.selectedCurrencyCode);

    return AuthContainer(
      showLanguageAction: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: loc.authRegionTitle,
            subtitle: loc.authRegionSubtitle,
          ),
          const SizedBox(height: AuthSpacing.xl),
          _RegionRow(
            icon: Icons.public_outlined,
            label: loc.authRegionCountry,
            value: state.selectedCountry.localizedNameFromLoc(loc),
            trailing: CountryFlagWidget(
              countryCode: state.selectedCountry.isoCode,
              size: 20,
            ),
            onTap: () async {
              final selected = await MadarCountrySelectorSheet.show(
                context,
                selectedCountry: state.selectedCountry,
              );
              if (selected != null) {
                auth.selectCountry(selected);
                if (!_currencyManuallySet) {
                  auth.selectCurrency(selected.defaultCurrencyCode);
                }
              }
            },
          ),
          const SizedBox(height: AuthSpacing.md),
          _RegionRow(
            icon: Icons.language_outlined,
            label: loc.authRegionLanguage,
            value: _languageLabel(loc, state.selectedLanguage),
            onTap: () => _showLanguagePicker(context, auth),
          ),
          const SizedBox(height: AuthSpacing.md),
          _RegionRow(
            icon: Icons.payments_outlined,
            label: loc.authRegionCurrency,
            value: currency != null
                ? '${currency.symbol} ${currency.code}'
                : state.selectedCurrencyCode,
            onTap: () async {
              final code = await CurrencySelectorSheet.show(
                context,
                selectedCode: state.selectedCurrencyCode,
              );
              if (code != null) {
                setState(() => _currencyManuallySet = true);
                auth.selectCurrency(code);
              }
            },
          ),
          const SizedBox(height: AuthSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AuthSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AuthSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AuthSpacing.sm),
                Expanded(
                  child: Text(
                    loc.authRegionDetectedHint,
                    style: AuthTypography.caption(context),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          PrimaryAuthButton(
            label: loc.authRegionConfirm,
            isLoading: state.isBusy,
            onPressed: () => _confirm(auth),
          ),
        ],
      ),
    );
  }

  String _languageLabel(AppLocalizations loc, AppLanguage language) {
    switch (language) {
      case AppLanguage.arabic:
        return loc.langArabic;
      case AppLanguage.kurdish:
        return loc.langKurdish;
      case AppLanguage.english:
        return loc.langEnglish;
    }
  }

  void _showLanguagePicker(BuildContext context, UserAuthNotifier auth) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.authRegionLanguage,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...AppLanguage.values.map((lang) {
                final selected = auth.state.selectedLanguage == lang;
                return ListTile(
                  leading: Icon(
                    Icons.translate_outlined,
                    color: selected ? theme.colorScheme.primary : null,
                  ),
                  title: Text(_languageLabel(loc, lang)),
                  trailing: selected
                      ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    auth.selectLanguage(lang);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _RegionRow extends StatelessWidget {
  const _RegionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AuthSpacing.md,
            vertical: AuthSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            textDirection: Directionality.of(context),
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: AuthSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AuthTypography.caption(context)),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: AuthSpacing.sm),
              ],
              DirectionalChevronIcon(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
