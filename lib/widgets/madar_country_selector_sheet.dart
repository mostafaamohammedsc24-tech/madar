import 'package:flutter/material.dart';

import '../core/geo/country_registry.dart';
import '../core/geo/madar_country.dart';
import '../core/localization/app_localizations.dart';
import 'country_flag_widget.dart';

/// Searchable country selector backed by ISO 3166 data.
class MadarCountrySelectorSheet extends StatefulWidget {
  const MadarCountrySelectorSheet({
    super.key,
    required this.selectedCountry,
    this.showFavoritesFirst = true,
  });

  final MadarCountry selectedCountry;
  final bool showFavoritesFirst;

  static Future<MadarCountry?> show(
    BuildContext context, {
    required MadarCountry selectedCountry,
    bool showFavoritesFirst = true,
  }) {
    return showModalBottomSheet<MadarCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MadarCountrySelectorSheet(
        selectedCountry: selectedCountry,
        showFavoritesFirst: showFavoritesFirst,
      ),
    );
  }

  @override
  State<MadarCountrySelectorSheet> createState() =>
      _MadarCountrySelectorSheetState();
}

class _MadarCountrySelectorSheetState extends State<MadarCountrySelectorSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MadarCountry> get _countries {
    final results = CountryRegistry.search(
      _query,
      languageCode: AppLocalizations.of(context).languageCode,
    );
    if (_query.isNotEmpty || !widget.showFavoritesFirst) return results;

    final favorites = CountryRegistry.favoriteIsoCodes
        .map(CountryRegistry.findByIso)
        .whereType<MadarCountry>()
        .toList();
    final favoriteSet = favorites.map((c) => c.isoCode).toSet();
    final rest = results.where((c) => !favoriteSet.contains(c.isoCode)).toList();
    return [...favorites, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final languageCode = loc.languageCode;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.authSelectCountry,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: loc.search,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _countries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final country = _countries[index];
                final isSelected =
                    country.isoCode == widget.selectedCountry.isoCode;

                return Material(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.35,
                        )
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, country),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          CountryFlagWidget(
                            countryCode: country.isoCode,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              country.localizedName(languageCode),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            country.dialCode,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}
