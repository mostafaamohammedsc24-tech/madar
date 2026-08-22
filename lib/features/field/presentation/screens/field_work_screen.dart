import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/field_strings.dart';
import '../../../legal/presentation/theme/legal_theme.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart' hide labelPriority, labelAction, labelStage, labelDoc, toneForPriority, toneForDoc;
import '../../domain/enums/field_enums.dart';
import '../../domain/models/field_models.dart';
import '../providers/field_workspace_controller.dart';
import '../widgets/field_labels.dart';

class FieldWorkScreen extends StatelessWidget {
  const FieldWorkScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = FieldStrings.of(AppLocalizations.of(context));
    final ws = context.watch<FieldWorkspaceController>();
    final items = ws.actionable;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: dark ? LegalTheme.darkBg : LegalTheme.paper,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc.workQ, style: LegalTheme.ibm(size: 20, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(loc.notOthers, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
            const SizedBox(height: 12),
            TextField(
              onChanged: ws.setSearch,
              decoration: InputDecoration(hintText: loc.searchHint, prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)), isDense: true),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip(loc.all, ws.actionFilter == null, () => ws.setAction(null)),
                ...FieldWorkAction.values.map((a) => _chip(labelAct(loc, a), ws.actionFilter == a, () => ws.setAction(ws.actionFilter == a ? null : a))),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text(loc.noActions, style: LegalTheme.ibm(size: 16, color: LegalTheme.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FieldJobTile(job: items[i], loc: loc, onOpen: () => context.push('/field/property/${items[i].id}')),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _chip(String label, bool on, VoidCallback tap) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: InkWell(
        onTap: tap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: on ? LegalTheme.softBlue : LegalTheme.surfaceLow, border: Border.all(color: on ? LegalTheme.primary : LegalTheme.outline), borderRadius: BorderRadius.circular(4)),
          child: Text(label, style: LegalTheme.ibm(size: 11, weight: FontWeight.w600, color: on ? LegalTheme.primary : LegalTheme.muted)),
        ),
      ),
    );
  }
}

class FieldJobTile extends StatelessWidget {
  const FieldJobTile({super.key, required this.job, required this.loc, required this.onOpen});
  final FieldJob job;
  final FieldStrings loc;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final urgent = job.priority == FieldPriority.urgent;
    return Material(
      color: Theme.of(context).brightness == Brightness.dark ? LegalTheme.darkSurface : LegalTheme.surface,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.symmetric(horizontal: const BorderSide(color: LegalTheme.outline), vertical: BorderSide(color: urgent ? LegalTheme.danger : LegalTheme.outline, width: urgent ? 3 : 1)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(job.propertyId, style: LegalTheme.mono(size: 14, weight: FontWeight.w700, color: LegalTheme.primary))),
              LegalStatusChip(label: labelPri(loc, job.priority), tone: tonePri(job.priority)),
            ]),
            Text(job.requestNumber, style: LegalTheme.mono(size: 12, color: LegalTheme.muted)),
            Text('${job.propertyType} · ${job.address}', style: LegalTheme.ibm(size: 14, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('${loc.publisher}: ${job.publisher}', style: LegalTheme.ibm(size: 12)),
            Text('${loc.photography}: ${job.photographer}', style: LegalTheme.ibm(size: 12)),
            Text('${loc.floorPlan}: ${job.floorPlanEngineer}', style: LegalTheme.ibm(size: 12)),
            Text('${loc.visit}: ${fmtWhen(job.visitAt)}', style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: LegalTheme.activeSoft,
              child: Text('${loc.requiredAction}: ${labelAct(loc, job.requiredAction)}', style: LegalTheme.ibm(size: 13, weight: FontWeight.w700, color: LegalTheme.primary)),
            ),
          ]),
        ),
      ),
    );
  }
}
