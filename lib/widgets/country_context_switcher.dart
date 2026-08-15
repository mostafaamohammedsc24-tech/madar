import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as prov;

import '../core/app_export.dart';
import '../providers/country_context_provider.dart';
import '../services/mixpanel_service.dart';

/// Country Context Switcher — bottom sheet modal
/// Shows all supported countries with active state highlight.
class CountryContextSwitcherSheet extends StatefulWidget {
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
  State<CountryContextSwitcherSheet> createState() =>
      _CountryContextSwitcherSheetState();
}

class _CountryContextSwitcherSheetState
    extends State<CountryContextSwitcherSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = prov.Provider.of<CountryContextProvider>(context);
    final activeCode = provider.activeCountryCode;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2035) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
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
                        'Active Country',
                        style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Switch your market context',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Active country badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primary.withAlpha(60),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.activeFlag,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        provider.activeCountryName,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Country grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: kSupportedCountries.length,
              itemBuilder: (context, index) {
                final country = kSupportedCountries[index];
                final isActive = country.code == activeCode;
                return _CountryTile(
                  country: country,
                  isActive: isActive,
                  onTap: () {
                    final fromCountry = provider.activeCountryName;
                    provider.setCountry(country);
                    MixpanelService.instance.trackCountryContextChanged(
                      fromCountry: fromCountry,
                      toCountry: country.nameEn,
                    );
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  final AppCountry country;
  final bool isActive;
  final VoidCallback onTap;

  const _CountryTile({
    required this.country,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withAlpha(20)
              : isDark
              ? const Color(0xFF243050)
              : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppTheme.primary
                : theme.colorScheme.outline.withAlpha(40),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    country.nameEn,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppTheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${country.currencySymbol} ${country.currency}',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: isActive
                          ? AppTheme.primary.withAlpha(180)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact country context chip — shown in AppBar / navigation
class CountryContextChip extends StatelessWidget {
  final VoidCallback? onTap;

  const CountryContextChip({super.key, this.onTap});

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
                Text(provider.activeFlag, style: const TextStyle(fontSize: 14)),
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
