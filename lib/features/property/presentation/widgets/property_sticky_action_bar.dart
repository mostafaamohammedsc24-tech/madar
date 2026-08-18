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
    final bottom = MediaQuery.paddingOf(context).bottom;
    final toAgent = publisher?.routesToAgent == true;
    final name = toAgent ? publisher!.displayName : loc.madarSalesTeam;
    final avatar = publisher?.avatarUrl;

    return Material(
      elevation: 16,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: onContact,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary, width: 1.4),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFE3F2FD),
                        backgroundImage:
                            avatar != null ? NetworkImage(avatar) : null,
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
                height: 56,
                child: FilledButton(
                  onPressed: onScheduleTour,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        loc.requestTourHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
