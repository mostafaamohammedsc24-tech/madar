import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../providers/office_auth_notifier.dart';

class OfficeMoreScreen extends StatelessWidget {
  const OfficeMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = context.watch<OfficeAuthNotifier>();
    final office = auth.office;

    final items = <({IconData icon, String label, String route})>[
      (icon: Icons.insights_outlined, label: loc.officePerformance, route: '/office/performance'),
      (icon: Icons.notifications_outlined, label: loc.officeNotifications, route: '/office/notifications'),
      (icon: Icons.business_outlined, label: loc.officeProfile, route: '/office/profile'),
      (icon: Icons.folder_outlined, label: loc.officeDocuments, route: '/office/documents'),
      (icon: Icons.support_agent_outlined, label: loc.officeSupport, route: '/office/support'),
      (icon: Icons.history, label: loc.officeSalesHistory, route: '/office/history'),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: Text(loc.officeNavMore)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (office != null) ...[
            Text(office.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              office.officeCode,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
          ],
          ...items.map(
            (item) => ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              trailing: const Icon(Icons.chevron_right),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () => context.push(item.route),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/auth');
            },
            child: Text(loc.officeSignOut),
          ),
        ],
      ),
    );
  }
}
