import 'package:provider/provider.dart';

import '../core/app_export.dart';
import '../core/localization/app_localizations.dart';
import '../core/localization/locale_provider.dart';

/// Language selector bottom sheet — call from Profile or Settings.
class LanguageSelectorSheet extends StatelessWidget {
  const LanguageSelectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: Provider.of<LocaleProvider>(context, listen: false),
        child: const LanguageSelectorSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final provider = Provider.of<LocaleProvider>(context);

    final langs = [
      (AppLanguage.english, loc.langEnglish, Icons.language),
      (AppLanguage.arabic, loc.langArabic, Icons.translate),
      (AppLanguage.kurdish, loc.langKurdish, Icons.record_voice_over_outlined),
    ];

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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.languageLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ...langs.map((item) {
            final isSelected = provider.language == item.$1;
            return GestureDetector(
              onTap: () {
                provider.setLanguage(item.$1);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withAlpha(20)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected
                      ? Border.all(color: AppTheme.primary, width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.$3,
                      size: 22,
                      color: isSelected
                          ? AppTheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isSelected)
                      CustomIconWidget(
                        iconName: 'check_circle',
                        color: AppTheme.primary,
                        size: 22,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
