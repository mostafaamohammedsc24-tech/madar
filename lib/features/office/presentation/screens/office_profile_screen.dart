import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../providers/office_auth_notifier.dart';

class OfficeProfileScreen extends StatelessWidget {
  const OfficeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final office = context.watch<OfficeAuthNotifier>().office;

    if (office == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.officeProfile)),
        body: Center(child: Text(loc.officeActionFailed)),
      );
    }

    final rows = <(String, String)>[
      (loc.officeName, office.name),
      (loc.officeCodeLabel, office.officeCode),
      (loc.officeAddress, office.address ?? '—'),
      (loc.officePhone, office.phone ?? '—'),
      (loc.officeManager, office.managerName ?? '—'),
      (loc.officeLicense, office.licenseNumber ?? '—'),
      (loc.officeCountry, office.countryCode),
      (loc.officeCurrency, office.currencyCode),
      (loc.officeStatus, office.status.name),
      (
        loc.officeJoined,
        office.joinedAt?.toLocal().toString().split(' ').first ?? '—',
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: Text(loc.officeProfile)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            loc.officeProfileReadOnlyNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.$1,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(r.$2, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
