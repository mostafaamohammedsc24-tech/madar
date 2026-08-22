import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/photo_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../../../legal/presentation/theme/legal_theme.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart' hide labelPriority, labelAction, labelStage, labelDoc, toneForPriority, toneForDoc;
import '../../domain/models/photo_models.dart';
import '../providers/photo_auth_notifier.dart';
import '../providers/photo_workspace_controller.dart';
import '../widgets/photo_labels.dart';
import 'photo_work_screen.dart';

class PhotoAssignmentsScreen extends StatelessWidget {
  const PhotoAssignmentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = PhotoStrings.of(AppLocalizations.of(context));
    final ws = context.watch<PhotoWorkspaceController>();
    return _list(context, loc, ws, ws.allFiltered);
  }
}

class PhotoMediaScreen extends StatelessWidget {
  const PhotoMediaScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = PhotoStrings.of(AppLocalizations.of(context));
    final ws = context.watch<PhotoWorkspaceController>();
    final media = ws.allMedia;
    if (media.isEmpty) return Center(child: Text(loc.noActions));
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
      itemCount: media.length,
      itemBuilder: (_, i) {
        final a = media[i];
        return InkWell(
          onTap: () {
            final job = ws.allFiltered.where((j) => j.assets.any((x) => x.id == a.id)).firstOrNull;
            if (job != null) context.push('/photo/property/${job.id}');
          },
          child: Container(
            color: Color(a.color),
            padding: const EdgeInsets.all(6),
            alignment: Alignment.bottomLeft,
            child: Text(a.label, style: LegalTheme.mono(size: 10, color: Colors.white)),
          ),
        );
      },
    );
  }
}

class PhotoToursScreen extends StatelessWidget {
  const PhotoToursScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = PhotoStrings.of(AppLocalizations.of(context));
    final ws = context.watch<PhotoWorkspaceController>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final j in ws.tours)
          ListTile(
            title: Text('${j.tourName} · ${j.propertyId}', style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
            subtitle: Text('${loc.tour3d} · ${j.device} · ${j.points.length} · ${ws.tourPercent(j)}٪'),
            onTap: () => context.push('/photo/property/${j.id}'),
          ),
      ],
    );
  }
}

class PhotoMessagesScreen extends StatelessWidget {
  const PhotoMessagesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = PhotoStrings.of(AppLocalizations.of(context));
    final ws = context.watch<PhotoWorkspaceController>();
    final t = ws.allFiltered.where((j) => j.messages.isNotEmpty).toList();
    if (t.isEmpty) return Center(child: Text(loc.noActions));
    return ListView(children: [
      for (final j in t) ListTile(title: Text('${j.propertyId} · ${j.requestNumber}'), subtitle: Text(j.messages.last.body, maxLines: 2), onTap: () => context.push('/photo/property/${j.id}')),
    ]);
  }
}

class PhotoArchiveScreen extends StatelessWidget {
  const PhotoArchiveScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = PhotoStrings.of(AppLocalizations.of(context));
    final ws = context.watch<PhotoWorkspaceController>();
    return _list(context, loc, ws, ws.archive);
  }
}

class PhotoProfileScreen extends StatelessWidget {
  const PhotoProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = PhotoStrings.of(AppLocalizations.of(context));
    final auth = context.watch<PhotoAuthNotifier>();
    final ws = context.watch<PhotoWorkspaceController>();
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
          onTap: () => context.push('/photo/property/${j.id}'),
        ),
      OutlinedButton(onPressed: () async { await auth.logout(); if (context.mounted) context.go('/photo-login'); }, child: Text(loc.signOut)),
    ]);
  }
}

Widget _list(BuildContext context, PhotoStrings loc, PhotoWorkspaceController ws, List<PhotoJob> items) {
  if (items.isEmpty) return Center(child: Text(loc.noActions));
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: items.length,
    itemBuilder: (_, i) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PhotoJobTile(job: items[i], loc: loc, ws: ws, onOpen: () => context.push('/photo/property/${items[i].id}')),
    ),
  );
}
