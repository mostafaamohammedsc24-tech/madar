import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/mapping_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../../../legal/presentation/theme/legal_theme.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart' hide labelPriority, labelAction, labelStage, labelDoc, toneForPriority, toneForDoc;
import '../../domain/enums/mapping_enums.dart';
import '../providers/mapping_auth_notifier.dart';
import '../providers/mapping_workspace_controller.dart';
import '../widgets/mapping_labels.dart';
import 'mapping_work_screen.dart';

class MappingPropertiesScreen extends StatelessWidget {
  const MappingPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = MappingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<MappingWorkspaceController>();
    final items = ws.allFiltered;
    return _SearchList(
      hint: loc.searchHint,
      onSearch: ws.setSearch,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MappingJobTile(job: items[i], loc: loc, onOpen: () => context.push('/mapping/property/${items[i].id}')),
        ),
      ),
    );
  }
}

class MappingPlansScreen extends StatelessWidget {
  const MappingPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = MappingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<MappingWorkspaceController>();
    final rows = <(String, String)>[];
    for (final j in ws.allFiltered) {
      for (final f in j.floors) {
        rows.add((j.id, '${j.propertyId} · ${f.names.ar} · ${f.areaM2} م² · ${labelStatus(loc, f.status)}'));
      }
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(rows[i].$2),
        onTap: () => context.push('/mapping/property/${rows[i].$1}'),
      ),
    );
  }
}

class MappingConnectionsScreen extends StatelessWidget {
  const MappingConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = MappingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<MappingWorkspaceController>();
    final rows = <(String, String)>[];
    for (final j in ws.allFiltered) {
      for (final f in j.floors) {
        for (final r in f.rooms) {
          if (r.tourPointIds.isNotEmpty || r.photoIds.isNotEmpty) {
            rows.add((j.id, '${j.propertyId} · ${r.names.ar} → ${r.tourPointIds.join(', ')} / ${r.photoIds.join(', ')}'));
          }
        }
      }
    }
    if (rows.isEmpty) return Center(child: Text(loc.noActions, style: LegalTheme.ibm(size: 14, color: LegalTheme.muted)));
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(rows[i].$2, style: LegalTheme.ibm(size: 13)),
        onTap: () => context.push('/mapping/property/${rows[i].$1}'),
      ),
    );
  }
}

class MappingMeasurementsScreen extends StatelessWidget {
  const MappingMeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = MappingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<MappingWorkspaceController>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(loc.metric, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
        for (final j in ws.allFiltered)
          ListTile(
            title: Text(j.propertyId, style: LegalTheme.mono(size: 13, color: LegalTheme.primary)),
            subtitle: Text('${loc.built}: ${j.metrics.totalBuiltM2} م² · ${loc.land}: ${j.metrics.landM2} م²'),
            onTap: () => context.push('/mapping/property/${j.id}'),
          ),
      ],
    );
  }
}

class MappingReviewScreen extends StatelessWidget {
  const MappingReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = MappingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<MappingWorkspaceController>();
    final items = ws.allFiltered.where((j) => j.status == MappingPlanStatus.readyForReview || j.status == MappingPlanStatus.correctionRequired).toList();
    if (items.isEmpty) return Center(child: Text(loc.noActions));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final j in items)
          MappingJobTile(job: j, loc: loc, onOpen: () => context.push('/mapping/property/${j.id}')),
      ],
    );
  }
}

class MappingArchiveScreen extends StatelessWidget {
  const MappingArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = MappingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<MappingWorkspaceController>();
    final items = ws.archive;
    return _SearchList(
      hint: loc.searchHint,
      onSearch: ws.setSearch,
      child: items.isEmpty
          ? Center(child: Text(loc.noActions))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MappingJobTile(job: items[i], loc: loc, onOpen: () => context.push('/mapping/property/${items[i].id}')),
              ),
            ),
    );
  }
}

class MappingMessagesScreen extends StatelessWidget {
  const MappingMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = MappingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<MappingWorkspaceController>();
    final threads = ws.allFiltered.where((j) => j.messages.isNotEmpty).toList();
    if (threads.isEmpty) return Center(child: Text(loc.noActions, style: LegalTheme.ibm(size: 14, color: LegalTheme.muted)));
    return ListView.builder(
      itemCount: threads.length,
      itemBuilder: (_, i) {
        final j = threads[i];
        return ListTile(
          title: Text('${j.propertyId} · ${j.requestNumber}'),
          subtitle: Text(j.messages.last.body, maxLines: 2),
          onTap: () => context.push('/mapping/property/${j.id}'),
        );
      },
    );
  }
}

class MappingProfileScreen extends StatelessWidget {
  const MappingProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = MappingStrings.of(AppLocalizations.of(context));
    final auth = context.watch<MappingAuthNotifier>();
    final ws = context.watch<MappingWorkspaceController>();
    final locale = context.watch<LocaleProvider>();
    final staff = auth.staff;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(loc.role, style: LegalTheme.ibm(size: 20, weight: FontWeight.w700)),
        Text(staff?.displayName ?? '', style: LegalTheme.ibm(size: 16)),
        Text(staff?.employeeId ?? '', style: LegalTheme.mono(size: 13, color: LegalTheme.primary)),
        Text(staff?.department ?? '', style: LegalTheme.ibm(size: 13, color: LegalTheme.muted)),
        Text(staff?.specialization ?? '', style: LegalTheme.ibm(size: 13, color: LegalTheme.muted)),
        const SizedBox(height: 12),
        Text(loc.notInfo, style: LegalTheme.ibm(size: 13, color: LegalTheme.muted)),
        const SizedBox(height: 8),
        Text(loc.permissions, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
        Text(loc.canDo),
        const SizedBox(height: 8),
        Text(loc.cannotDo, style: LegalTheme.ibm(size: 13, color: LegalTheme.danger)),
        Text('${loc.session}: ${auth.sessionStartedAt ?? '—'}', style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
        SwitchListTile(title: Text(loc.dark), value: locale.isDarkMode, onChanged: locale.setDarkMode),
        ListTile(title: Text(loc.language), trailing: const Icon(Icons.language), onTap: () => LanguageSelectorSheet.show(context)),
        const Divider(),
        Text(loc.notifications, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700)),
        for (final j in ws.actionable.take(8))
          ListTile(
            title: Text(j.propertyId, style: LegalTheme.mono(size: 13)),
            subtitle: Text(labelAction(loc, j.requiredAction)),
            trailing: LegalStatusChip(label: labelPriority(loc, j.priority), tone: toneForPriority(j.priority)),
            onTap: () => context.push('/mapping/property/${j.id}'),
          ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () async {
            await auth.logout();
            if (context.mounted) context.go('/mapping-login');
          },
          child: Text(loc.signOut),
        ),
      ],
    );
  }
}

class _SearchList extends StatelessWidget {
  const _SearchList({required this.hint, required this.onSearch, required this.child});
  final String hint;
  final ValueChanged<String> onSearch;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              isDense: true,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
