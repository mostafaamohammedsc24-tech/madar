import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../providers/employee_auth_notifier.dart';

class EmployeeProfileScreen extends StatelessWidget {
  const EmployeeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = context.watch<EmployeeAuthNotifier>();
    final e = auth.employee;
    if (e == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final rows = <(String, String)>[
      (loc.empIdLabel, e.employeeCode),
      (loc.empFullName, e.fullName),
      (loc.empJobTitle, e.jobTitle ?? '—'),
      (
        loc.empDepartment,
        e.department.localizedName(
          Localizations.localeOf(context).languageCode,
        ),
      ),
      (loc.empRole, e.role.nameEn),
      (loc.empCountry, e.countryCode),
      (loc.empBranch, e.branchCode ?? '—'),
      (loc.empStatus, e.employmentStatus),
      (
        loc.empJoined,
        e.joiningDate?.toLocal().toString().split(' ').first ?? '—',
      ),
      (
        loc.empLastLogin,
        e.lastLoginAt?.toLocal().toString().split('.').first ?? '—',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                e.fullName.isNotEmpty ? e.fullName[0].toUpperCase() : 'E',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.fullName, style: theme.textTheme.titleLarge),
                  Text(
                    e.jobTitle ?? e.role.nameEn,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          loc.empProfileReadOnlyNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.$1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(r.$2, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(loc.empPermissions, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: e.permissions
              .map(
                (p) => Chip(
                  label: Text(p, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: () async {
            await auth.logout();
            if (context.mounted) context.go('/auth');
          },
          child: Text(loc.empSignOut),
        ),
      ],
    );
  }
}
