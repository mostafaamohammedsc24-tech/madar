import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/field_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../../../legal/presentation/theme/legal_theme.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart' hide labelPriority, labelAction, labelStage, labelDoc, toneForPriority, toneForDoc;
import '../../domain/models/field_models.dart';
import '../providers/field_auth_notifier.dart';
import '../providers/field_workspace_controller.dart';
import '../widgets/field_labels.dart';
import 'field_work_screen.dart';

class FieldAssignmentsScreen extends StatelessWidget {
  const FieldAssignmentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = FieldStrings.of(AppLocalizations.of(context));
    final ws = context.watch<FieldWorkspaceController>();
    return _list(context, loc, ws.allFiltered);
  }
}

class FieldPropertiesScreen extends StatelessWidget {
  const FieldPropertiesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = FieldStrings.of(AppLocalizations.of(context));
    final ws = context.watch<FieldWorkspaceController>();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(onChanged: ws.setSearch, decoration: InputDecoration(hintText: loc.searchHint, prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)), isDense: true)),
      ),
      Expanded(child: _list(context, loc, ws.allFiltered)),
    ]);
  }
}

class FieldReportsScreen extends StatelessWidget {
  const FieldReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = FieldStrings.of(AppLocalizations.of(context));
    final ws = context.watch<FieldWorkspaceController>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final j in ws.allFiltered)
          ListTile(
            title: Text(j.propertyId, style: LegalTheme.mono(size: 13, color: LegalTheme.primary)),
            subtitle: Text('${ws.completionPercent(j)}٪ · ${labelSt(loc, j.status)}'),
            onTap: () => context.push('/field/property/${j.id}'),
          ),
      ],
    );
  }
}

class FieldMessagesScreen extends StatelessWidget {
  const FieldMessagesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = FieldStrings.of(AppLocalizations.of(context));
    final ws = context.watch<FieldWorkspaceController>();
    final t = ws.allFiltered.where((j) => j.messages.isNotEmpty).toList();
    if (t.isEmpty) return Center(child: Text(loc.noActions));
    return ListView(children: [
      for (final j in t) ListTile(title: Text('${j.propertyId} · ${j.requestNumber}'), subtitle: Text(j.messages.last.body, maxLines: 2), onTap: () => context.push('/field/property/${j.id}')),
    ]);
  }
}

class FieldArchiveScreen extends StatelessWidget {
  const FieldArchiveScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = FieldStrings.of(AppLocalizations.of(context));
    final ws = context.watch<FieldWorkspaceController>();
    return _list(context, loc, ws.archive);
  }
}

class FieldProfileScreen extends StatelessWidget {
  const FieldProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = FieldStrings.of(AppLocalizations.of(context));
    final auth = context.watch<FieldAuthNotifier>();
    final ws = context.watch<FieldWorkspaceController>();
    final locale = context.watch<LocaleProvider>();
    final staff = auth.staff;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(loc.role, style: LegalTheme.ibm(size: 20, weight: FontWeight.w700)),
      Text(staff?.displayName ?? ''),
      Text(staff?.employeeId ?? '', style: LegalTheme.mono(size: 13, color: LegalTheme.primary)),
      Text(staff?.department ?? ''),
      const SizedBox(height: 12),
      Text(loc.notOthers, style: LegalTheme.ibm(size: 13, color: LegalTheme.muted)),
      Text(loc.canDo),
      const SizedBox(height: 8),
      Text(loc.cannotDo, style: LegalTheme.ibm(size: 13, color: LegalTheme.danger)),
      Text('${loc.session}: ${auth.sessionStartedAt ?? '—'}'),
      SwitchListTile(title: Text(loc.dark), value: locale.isDarkMode, onChanged: locale.setDarkMode),
      ListTile(title: Text(loc.language), onTap: () => LanguageSelectorSheet.show(context)),
      for (final j in ws.actionable.take(6))
        ListTile(
          title: Text(j.propertyId, style: LegalTheme.mono(size: 13)),
          subtitle: Text(labelAct(loc, j.requiredAction)),
          trailing: LegalStatusChip(label: labelPri(loc, j.priority), tone: tonePri(j.priority)),
          onTap: () => context.push('/field/property/${j.id}'),
        ),
      OutlinedButton(onPressed: () async { await auth.logout(); if (context.mounted) context.go('/field-login'); }, child: Text(loc.signOut)),
    ]);
  }
}

Widget _list(BuildContext context, FieldStrings loc, List<FieldJob> items) {
  if (items.isEmpty) return Center(child: Text(loc.noActions));
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: items.length,
    itemBuilder: (_, i) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FieldJobTile(job: items[i], loc: loc, onOpen: () => context.push('/field/property/${items[i].id}')),
    ),
  );
}
