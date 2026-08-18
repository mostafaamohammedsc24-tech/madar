import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/property_documents.dart';

class PropertyStickyActionBar extends StatelessWidget {
  const PropertyStickyActionBar({
    super.key,
    required this.onContact,
    required this.onAskAi,
    required this.onScheduleTour,
    this.publisher,
  });

  final VoidCallback onContact;
  final VoidCallback onAskAi;
  final VoidCallback onScheduleTour;
  final PropertyPublisher? publisher;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final toAgent = publisher?.routesToAgent == true;
    final name = toAgent
        ? publisher!.displayName
        : loc.madarSalesTeam;
    final avatar = publisher?.avatarUrl;

    return Material(
      elevation: 12,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: onAskAi,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  loc.askAi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onContact,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFE3F2FD),
                            backgroundImage: avatar != null
                                ? NetworkImage(avatar)
                                : null,
                            child: avatar == null
                                ? Icon(
                                    toAgent
                                        ? Icons.person_outline
                                        : Icons.storefront_outlined,
                                    size: 18,
                                    color: AppTheme.primary,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.contactSalesShort,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: onScheduleTour,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            loc.requestTour,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            loc.requestTourHint,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
