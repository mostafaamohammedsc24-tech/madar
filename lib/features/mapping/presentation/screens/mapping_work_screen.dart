import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/mapping_strings.dart';
import '../../../legal/presentation/theme/legal_theme.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart' hide labelPriority, labelAction, labelStage, labelDoc, toneForPriority, toneForDoc;
import '../../domain/enums/mapping_enums.dart';
import '../../domain/models/mapping_models.dart';
import '../providers/mapping_workspace_controller.dart';
import '../widgets/mapping_labels.dart';

class MappingWorkScreen extends StatelessWidget {
  const MappingWorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = MappingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<MappingWorkspaceController>();
    final items = ws.actionable;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: dark ? LegalTheme.darkBg : LegalTheme.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.workQ, style: LegalTheme.ibm(size: 20, weight: FontWeight.w600, color: dark ? LegalTheme.darkText : LegalTheme.charcoal)),
                const SizedBox(height: 8),
                Text(loc.notInfo, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: ws.setSearch,
                  decoration: InputDecoration(
                    hintText: loc.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: dark ? LegalTheme.darkSurface : LegalTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip(label: loc.all, selected: ws.actionFilter == null, onTap: () => ws.setAction(null)),
                      ...MappingWorkAction.values.map(
                        (a) => _Chip(
                          label: labelAction(loc, a),
                          selected: ws.actionFilter == a,
                          onTap: () => ws.setAction(ws.actionFilter == a ? null : a),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(loc.noActions, style: LegalTheme.ibm(size: 16, color: LegalTheme.muted), textAlign: TextAlign.center))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MappingJobTile(
                        job: items[i],
                        loc: loc,
                        onOpen: () => context.push('/mapping/property/${items[i].id}'),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? LegalTheme.softBlue : LegalTheme.surfaceLow,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: selected ? LegalTheme.primary : LegalTheme.outline),
          ),
          child: Text(label, style: LegalTheme.ibm(size: 11, weight: FontWeight.w600, color: selected ? LegalTheme.primary : LegalTheme.muted)),
        ),
      ),
    );
  }
}

class MappingJobTile extends StatelessWidget {
  const MappingJobTile({super.key, required this.job, required this.loc, required this.onOpen});
  final MappingJob job;
  final MappingStrings loc;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final j = job;
    final urgent = j.priority == MappingPriority.urgent || j.priority == MappingPriority.blocked;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: dark ? LegalTheme.darkSurface : LegalTheme.surface,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.symmetric(
              horizontal: const BorderSide(color: LegalTheme.outline),
              vertical: BorderSide(color: urgent ? LegalTheme.danger : LegalTheme.outline, width: urgent ? 3 : 1),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(j.propertyId, style: LegalTheme.mono(size: 14, weight: FontWeight.w700, color: LegalTheme.primary)),
                  ),
                  LegalStatusChip(label: labelPriority(loc, j.priority), tone: toneForPriority(j.priority)),
                ],
              ),
              Text('${loc.requestNo}: ${j.requestNumber}', style: LegalTheme.mono(size: 12, color: LegalTheme.muted)),
              const SizedBox(height: 6),
              Text('${j.propertyType} · ${j.address}', style: LegalTheme.ibm(size: 14, weight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _kv(loc.publisher, j.publisher)),
                Expanded(child: _kv(loc.infoEmp, j.informationEmployee)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: _kv(loc.photoEmp, j.photographer)),
                Expanded(child: _kv(loc.status, labelStatus(loc, j.status))),
              ]),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: LegalTheme.activeSoft,
                child: Text('${loc.requiredAction}: ${labelAction(loc, j.requiredAction)}', style: LegalTheme.ibm(size: 13, weight: FontWeight.w700, color: LegalTheme.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: LegalTheme.ibm(size: 10, color: LegalTheme.muted)),
        Text(v, style: LegalTheme.ibm(size: 12, weight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
