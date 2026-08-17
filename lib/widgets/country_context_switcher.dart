import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as prov;

import '../core/app_export.dart';
import '../core/localization/app_localizations.dart';
import '../providers/country_context_provider.dart';
import '../services/mixpanel_service.dart';
import 'country_flag_widget.dart';
import 'madar_country_selector_sheet.dart';

/// Country context switcher — opens full ISO country selector.
class CountryContextSwitcherSheet extends StatelessWidget {
  const CountryContextSwitcherSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => prov.ChangeNotifierProvider.value(
        value: prov.Provider.of<CountryContextProvider>(context, listen: false),
        child: const CountryContextSwitcherSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final provider = prov.Provider.of<CountryContextProvider>(context);
    final country = provider.activeCountry;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.activeCountryTitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      loc.switchMarketContext,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withAlpha(60)),
            ),
            child: Row(
              children: [
                CountryFlagWidget(countryCode: country.isoCode, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        country.localizedName(loc.languageCode),
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${provider.activeCurrencySymbol} ${provider.activeCurrency}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final selected = await MadarCountrySelectorSheet.show(
                  context,
                  selectedCountry: country,
                );
                if (selected != null && context.mounted) {
                  final fromCountry = provider.activeCountry.nameEn;
                  await provider.setCountry(selected);
                  MixpanelService.instance.trackCountryContextChanged(
                    fromCountry: fromCountry,
                    toCountry: selected.nameEn,
                  );
                }
              },
              icon: const Icon(Icons.search),
              label: Text(loc.settingsChangeCountry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact country context chip — shown in search AppBar.
class CountryContextChip extends StatelessWidget {
  const CountryContextChip({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return prov.Consumer<CountryContextProvider>(
      builder: (context, provider, _) {
        return GestureDetector(
          onTap: onTap ?? () => CountryContextSwitcherSheet.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primary.withAlpha(50),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountryFlagWidget(
                  countryCode: provider.activeCountryCode,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  provider.activeCountryCode,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.primary,
                  size: 14,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
