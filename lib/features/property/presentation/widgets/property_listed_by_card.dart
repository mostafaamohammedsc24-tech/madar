import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/property_documents.dart';

class PropertyListedByCard extends StatelessWidget {
  const PropertyListedByCard({
    super.key,
    required this.publisher,
    required this.onContact,
  });

  final PropertyPublisher publisher;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final toAgent = publisher.routesToAgent;
    final title = toAgent ? loc.listedBy : loc.madarSalesTeam;
    final name = toAgent ? publisher.displayName : loc.madarSalesTeam;
    final subtitle = publisher.companyName;
    final avatar = publisher.avatarUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EAF0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 88,
                  child: avatar != null
                      ? Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallback(toAgent),
                        )
                      : _fallback(toAgent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (toAgent &&
                        subtitle != null &&
                        subtitle.trim().isNotEmpty &&
                        subtitle != name) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: onContact,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          toAgent
                              ? loc.contactAgentName(name)
                              : loc.contactSalesTeam,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallback(bool toAgent) {
    return ColoredBox(
      color: const Color(0xFFE3F2FD),
      child: Icon(
        toAgent ? Icons.person : Icons.apartment_outlined,
        color: AppTheme.primary,
        size: 36,
      ),
    );
  }
}
