import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/field_strings.dart';
import '../../../legal/presentation/theme/legal_theme.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart'
    hide labelPriority, labelAction, labelStage, labelDoc, toneForPriority, toneForDoc;
import '../../domain/enums/field_enums.dart';
import '../../domain/models/field_models.dart';
import '../providers/field_workspace_controller.dart';
import '../widgets/field_labels.dart';

class FieldCaseScreen extends StatefulWidget {
  const FieldCaseScreen({required this.jobId, super.key});
  final String jobId;

  @override
  State<FieldCaseScreen> createState() => _FieldCaseScreenState();
}

class _FieldCaseScreenState extends State<FieldCaseScreen> {
  final _area = TextEditingController();
  final _voice = TextEditingController();
  final _corr = TextEditingController();
  final _msg = TextEditingController();
  FieldChannel _ch = FieldChannel.publisher;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = context.read<FieldWorkspaceController>();
      final j = ws.byId(widget.jobId);
      if (j != null) {
        ws.audit(j, 'assignment_opened');
        if (j.measuredBuiltM2 != null) {
          _area.text = j.measuredBuiltM2!.toString();
        }
      }
    });
  }

  @override
  void dispose() {
    _area.dispose();
    _voice.dispose();
    _corr.dispose();
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = FieldStrings.of(AppLocalizations.of(context));
    final ws = context.watch<FieldWorkspaceController>();
    final j = ws.byId(widget.jobId);
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (j == null) {
      return Scaffold(body: Center(child: Text(loc.noActions)));
    }

    final sections = ws.sections(j);
    final pct = ws.completionPercent(j);
    final dist = _distanceM(j);

    return Scaffold(
      backgroundColor: dark ? LegalTheme.darkBg : LegalTheme.paper,
      body: Column(
        children: [
          _Header(j: j, loc: loc, sync: j.sync),
          _Progress(j: j, loc: loc, pct: pct, sections: sections, ws: ws),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
              children: [
                _Banner(text: loc.notPublish, color: LegalTheme.warningSoft, border: LegalTheme.warning),
                const SizedBox(height: 8),
                _Banner(text: loc.notOthers, color: LegalTheme.activeSoft, border: LegalTheme.primary),
                const SizedBox(height: 12),
                _Quality(j: j, loc: loc, ws: ws),
                const SizedBox(height: 12),
                _Streams(j: j, loc: loc),
                const SizedBox(height: 12),
                _Brief(j: j, loc: loc),
                const SizedBox(height: 12),
                _Arrival(j: j, loc: loc, ws: ws, dist: dist),
                const SizedBox(height: 12),
                _Section(
                  title: loc.identity,
                  complete: sections[0].complete,
                  loc: loc,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${j.propertyType} · ${j.subtype}', style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
                      Text(loc.metric, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
                    ],
                  ),
                ),
                _Section(
                  title: loc.location,
                  complete: sections[1].complete,
                  loc: loc,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${j.country} · ${j.governorate} · ${j.city}'),
                      Text('${j.district} · ${j.street}'),
                      Text('${j.lat.toStringAsFixed(5)}, ${j.lng.toStringAsFixed(5)}', style: LegalTheme.mono(size: 12)),
                    ],
                  ),
                ),
                _Section(
                  title: loc.land,
                  complete: sections[2].complete,
                  loc: loc,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv(loc.land, '${j.landAreaM2 ?? '—'} م²'),
                      _kv('الواجهة', '${j.frontageM ?? '—'} م'),
                      _kv('عرض الشارع', '${j.streetWidthM ?? '—'} م'),
                    ],
                  ),
                ),
                _Section(
                  title: loc.building,
                  complete: sections[3].complete,
                  loc: loc,
                  child: Column(
                    children: [
                      _kv(loc.ownerArea, '${j.ownerClaimedBuiltM2 ?? '—'} م²'),
                      Text(loc.owner, style: LegalTheme.ibm(size: 11, color: LegalTheme.muted)),
                      const SizedBox(height: 8),
                      if (!j.isLocked)
                        TextField(
                          controller: _area,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: loc.measuredArea,
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          onSubmitted: (v) {
                            final n = double.tryParse(v);
                            if (n != null) ws.setMeasuredArea(j.id, n);
                          },
                        )
                      else
                        _kv(loc.measuredArea, '${j.measuredBuiltM2 ?? '—'} م²'),
                      const SizedBox(height: 6),
                      Text('${loc.observed} · ${j.floors} طوابق · ${j.units} وحدة', style: LegalTheme.ibm(size: 12)),
                    ],
                  ),
                ),
                _Section(
                  title: loc.rooms,
                  complete: sections[4].complete,
                  loc: loc,
                  child: Column(
                    children: [
                      Text('${j.rooms.length} / ${sections[4].total}', style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
                      const SizedBox(height: 8),
                      for (final r in j.rooms)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          color: LegalTheme.surfaceLow,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${r.name} · ${r.type} · ${r.floor}', style: LegalTheme.ibm(size: 13, weight: FontWeight.w700)),
                              Text(
                                '${r.lengthM ?? '—'} × ${r.widthM ?? '—'} × ${r.heightM ?? '—'} م · ${r.areaM2?.toStringAsFixed(1) ?? '—'} م²',
                                style: LegalTheme.mono(size: 12),
                              ),
                              Text('${labelCond(loc, r.condition)} · ${r.flooring ?? '—'}'),
                              if (r.photoRef != null) Text('${loc.photoRef}: ${r.photoRef}', style: LegalTheme.mono(size: 11)),
                              if (r.notes != null) Text(r.notes!, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
                            ],
                          ),
                        ),
                      if (!j.isLocked)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => ws.addRoom(j.id),
                            child: Text(loc.addRoom),
                          ),
                        ),
                    ],
                  ),
                ),
                _Section(
                  title: loc.utilities,
                  complete: sections[5].complete,
                  loc: loc,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final u in j.utilities) Text('· $u')],
                  ),
                ),
                _Section(
                  title: loc.interior,
                  complete: j.amenities.isNotEmpty,
                  loc: loc,
                  child: Text(j.amenities.join(' · ')),
                ),
                _Section(
                  title: loc.exterior,
                  complete: j.developer != null,
                  loc: loc,
                  child: Text('${j.developer ?? '—'} · ${j.contractor ?? '—'} · ${j.yearBuilt ?? '—'}'),
                ),
                _Section(
                  title: loc.construction,
                  complete: j.yearBuilt != null,
                  loc: loc,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${j.developer} · ${j.contractor}'),
                      for (final r in j.renovations)
                        Text('${r.year} · ${r.areas} · ${r.type} · ${r.notes ?? ''}', style: LegalTheme.ibm(size: 12)),
                    ],
                  ),
                ),
                _Section(
                  title: loc.neighborhood,
                  complete: sections[6].complete,
                  loc: loc,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.observation, style: LegalTheme.ibm(size: 12, color: LegalTheme.warning, weight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      for (final p in j.nearby)
                        Text(
                          '${p.kind} · ${p.name} · ${p.distanceM} م · ${p.verified ? loc.complete : loc.unverified}',
                          style: LegalTheme.ibm(size: 13),
                        ),
                    ],
                  ),
                ),
                _Section(
                  title: loc.nearby,
                  complete: j.nearby.isNotEmpty,
                  loc: loc,
                  child: Text(loc.mapHint, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
                ),
                _Section(
                  title: loc.development,
                  complete: sections[7].complete,
                  loc: loc,
                  child: Column(
                    children: [
                      for (final p in j.projects)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              '${p.name} · ${p.type} · ${p.status} · ${p.source} · ${p.verified ? loc.complete : loc.rumor}',
                              style: LegalTheme.ibm(size: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _Section(
                  title: loc.investment,
                  complete: j.ownerPrice != null,
                  loc: loc,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${loc.owner}: ${j.ownerPrice ?? '—'}'),
                      Text('${loc.observed}: ${j.rentalNote ?? '—'}'),
                      Text(loc.cannotDo, style: LegalTheme.ibm(size: 12, color: LegalTheme.danger)),
                    ],
                  ),
                ),
                _Section(
                  title: loc.special,
                  complete: j.whatsSpecial.isNotEmpty,
                  loc: loc,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final s in j.whatsSpecial) Text('· $s')],
                  ),
                ),
                _Section(
                  title: loc.risks,
                  complete: j.internalRisks.isNotEmpty,
                  loc: loc,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.cannotDo, style: LegalTheme.ibm(size: 11, color: LegalTheme.muted)),
                      for (final r in j.internalRisks) Text('· $r'),
                    ],
                  ),
                ),
                _Section(
                  title: loc.inspection,
                  complete: sections[8].complete,
                  loc: loc,
                  child: Column(
                    children: [
                      for (final i in j.inspection)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(i.label)),
                              Text(labelCond(loc, i.condition), style: LegalTheme.ibm(size: 12, weight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                _Section(
                  title: loc.voice,
                  complete: j.voice.any((v) => v.transcriptionConfirmed),
                  loc: loc,
                  child: Column(
                    children: [
                      for (final n in j.voice)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          color: LegalTheme.surfaceLow,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.transcriptionConfirmed ? loc.complete : loc.transcription,
                                style: LegalTheme.ibm(
                                  size: 11,
                                  weight: FontWeight.w800,
                                  color: n.transcriptionConfirmed ? LegalTheme.success : LegalTheme.warning,
                                ),
                              ),
                              Text(n.transcription ?? n.body),
                              if (!n.transcriptionConfirmed && !j.isLocked)
                                TextButton(
                                  onPressed: () => ws.confirmTranscription(j.id, n.id),
                                  child: Text(loc.confirmTx),
                                ),
                            ],
                          ),
                        ),
                      if (!j.isLocked) ...[
                        TextField(
                          controller: _voice,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: loc.addVoice,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            onPressed: () {
                              if (_voice.text.trim().isEmpty) return;
                              ws.addVoice(j.id, _voice.text.trim());
                              _voice.clear();
                            },
                            child: Text(loc.addVoice),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _Conflicts(j: j, loc: loc, ws: ws),
                const SizedBox(height: 12),
                _Corrections(j: j, loc: loc, ws: ws, corr: _corr),
                const SizedBox(height: 12),
                _Messages(j: j, loc: loc, ws: ws, msg: _msg, ch: _ch, onCh: (v) => setState(() => _ch = v)),
                const SizedBox(height: 12),
                _Review(j: j, loc: loc, ws: ws),
                const SizedBox(height: 12),
                _Versions(j: j, loc: loc),
                const SizedBox(height: 12),
                _Audit(j: j, loc: loc),
                const SizedBox(height: 12),
                SelectableText(ws.reportText(j), style: LegalTheme.mono(size: 11)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: j.isLocked || j.status == FieldReportStatus.submitted
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!ws.canSubmit(j))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(loc.cannotSubmit, style: LegalTheme.ibm(size: 12, color: LegalTheme.warning)),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: ws.canSubmit(j)
                            ? () {
                                ws.submit(j.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.submit)));
                                }
                              }
                            : null,
                        style: FilledButton.styleFrom(backgroundColor: LegalTheme.primary),
                        child: Text(loc.submit),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

double _distanceM(FieldJob j) {
  final lat2 = j.arrivalLat ?? j.lat + 0.0012;
  final lng2 = j.arrivalLng ?? j.lng - 0.0008;
  const r = 6371000.0;
  final dLat = (lat2 - j.lat) * math.pi / 180;
  final dLng = (lng2 - j.lng) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(j.lat * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a));
}

class _Header extends StatelessWidget {
  const _Header({required this.j, required this.loc, required this.sync});
  final FieldJob j;
  final FieldStrings loc;
  final SyncState sync;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark ? LegalTheme.darkSurface : LegalTheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
          child: Row(
            children: [
              IconButton(onPressed: () => context.go('/field/work'), icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(j.propertyId, style: LegalTheme.mono(size: 16, weight: FontWeight.w800, color: LegalTheme.primary)),
                    Text('${j.requestNumber} · ${j.address}', maxLines: 1, overflow: TextOverflow.ellipsis, style: LegalTheme.ibm(size: 11, color: LegalTheme.muted)),
                  ],
                ),
              ),
              LegalStatusChip(label: labelSync(loc, sync), tone: LegalTone.neutral),
              const SizedBox(width: 6),
              LegalStatusChip(label: labelSt(loc, j.status), tone: toneSt(j.status)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.j, required this.loc, required this.pct, required this.sections, required this.ws});
  final FieldJob j;
  final FieldStrings loc;
  final int pct;
  final List<FieldSectionScore> sections;
  final FieldWorkspaceController ws;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      color: Theme.of(context).brightness == Brightness.dark ? LegalTheme.darkSurface : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${loc.progress} · $pct٪', style: LegalTheme.ibm(size: 13, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: pct / 100, minHeight: 6, color: LegalTheme.primary, backgroundColor: LegalTheme.softBlue),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in sections)
                Text(
                  '${sectionName(loc, s.id)} ${s.done}/${s.total}',
                  style: LegalTheme.ibm(size: 11, color: s.complete ? LegalTheme.success : LegalTheme.warning, weight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color, required this.border});
  final String text;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, border: Border.all(color: border), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: LegalTheme.ibm(size: 12, weight: FontWeight.w700, color: LegalTheme.navy)),
    );
  }
}

class _Quality extends StatelessWidget {
  const _Quality({required this.j, required this.loc, required this.ws});
  final FieldJob j;
  final FieldStrings loc;
  final FieldWorkspaceController ws;

  @override
  Widget build(BuildContext context) {
    final q = ws.qualityPercent(j);
    final v = ws.verifiedShare(j);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.quality, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
          Text('$q٪ · ${loc.complete} $v٪ · ${loc.unverified} ${100 - v}٪', style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
        ],
      ),
    );
  }
}

class _Streams extends StatelessWidget {
  const _Streams({required this.j, required this.loc});
  final FieldJob j;
  final FieldStrings loc;

  @override
  Widget build(BuildContext context) {
    Widget row(String k, StreamStatus s) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(child: Text(k, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted))),
              Text(labelStream(loc, s), style: LegalTheme.ibm(size: 12, weight: FontWeight.w700)),
            ],
          ),
        );
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.streams, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          row(loc.infoStream, StreamStatus.inProgress),
          row(loc.photography, j.photoStream),
          row(loc.floorPlan, j.planStream),
          row(loc.publishing, j.publishStream),
        ],
      ),
    );
  }
}

class _Brief extends StatelessWidget {
  const _Brief({required this.j, required this.loc});
  final FieldJob j;
  final FieldStrings loc;

  @override
  Widget build(BuildContext context) {
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 120, child: Text(k, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted))),
              Expanded(child: Text(v, style: LegalTheme.ibm(size: 13, weight: FontWeight.w600))),
            ],
          ),
        );
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(j.propertyId, style: LegalTheme.ibm(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          row(loc.employeeId, j.requestNumber),
          row(loc.assigned, '${j.assignedName} · ${j.assignedId}'),
          row(loc.publisher, j.publisher),
          row(loc.photography, j.photographer),
          row(loc.floorPlan, j.floorPlanEngineer),
          row(loc.visit, fmtWhen(j.visitAt)),
          row(loc.instructions, j.specialInstructions),
        ],
      ),
    );
  }
}

class _Arrival extends StatelessWidget {
  const _Arrival({required this.j, required this.loc, required this.ws, required this.dist});
  final FieldJob j;
  final FieldStrings loc;
  final FieldWorkspaceController ws;
  final double dist;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.visit, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            height: 110,
            width: double.infinity,
            alignment: Alignment.center,
            color: LegalTheme.softBlue,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(loc.mapHint, textAlign: TextAlign.center, style: LegalTheme.ibm(size: 12)),
            ),
          ),
          const SizedBox(height: 8),
          Text('${loc.targetGps}: ${j.lat.toStringAsFixed(5)}, ${j.lng.toStringAsFixed(5)}', style: LegalTheme.mono(size: 12)),
          Text(
            '${loc.currentGps}: ${(j.arrivalLat ?? j.lat + 0.0012).toStringAsFixed(5)}, ${(j.arrivalLng ?? j.lng - 0.0008).toStringAsFixed(5)}',
            style: LegalTheme.mono(size: 12),
          ),
          Text('${loc.distance}: ${dist.toStringAsFixed(0)} م', style: LegalTheme.ibm(size: 13, weight: FontWeight.w700)),
          if (j.arrivalAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('${loc.arrivalAt}: ${fmtWhen(j.arrivalAt!)}', style: LegalTheme.ibm(size: 12, color: LegalTheme.success, weight: FontWeight.w700)),
            )
          else if (!j.isLocked)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => ws.confirmArrival(j.id),
                  style: FilledButton.styleFrom(backgroundColor: LegalTheme.primary),
                  child: Text(loc.confirmArrival),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.complete, required this.loc, required this.child});
  final String title;
  final bool complete;
  final FieldStrings loc;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: _card(
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 4),
            title: Row(
              children: [
                Expanded(child: Text(title, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800))),
                Text(complete ? loc.complete : loc.missing, style: LegalTheme.ibm(size: 11, weight: FontWeight.w700, color: complete ? LegalTheme.success : LegalTheme.warning)),
              ],
            ),
            children: [child],
          ),
        ),
      ),
    );
  }
}

class _Conflicts extends StatelessWidget {
  const _Conflicts({required this.j, required this.loc, required this.ws});
  final FieldJob j;
  final FieldStrings loc;
  final FieldWorkspaceController ws;

  @override
  Widget build(BuildContext context) {
    final open = j.conflicts.where((c) => !c.resolved).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? LegalTheme.darkSurface : Colors.white,
        border: Border.all(color: LegalTheme.danger),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.conflict, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800, color: LegalTheme.danger)),
          if (open.isEmpty && j.conflicts.isEmpty) Text(loc.complete, style: LegalTheme.ibm(size: 13)),
          for (final c in j.conflicts) ...[
            const SizedBox(height: 8),
            Text(c.field, style: LegalTheme.ibm(size: 13, weight: FontWeight.w700)),
            Text('${c.left}  |  ${c.right}', style: LegalTheme.ibm(size: 12)),
            if (!c.resolved && !j.isLocked)
              TextButton(
                onPressed: () => ws.resolveConflict(j.id, c.id, 'اعتماد القياس الميداني'),
                child: Text(loc.resolve),
              )
            else if (c.resolved)
              Text(c.resolution ?? loc.complete, style: LegalTheme.ibm(size: 12, color: LegalTheme.success)),
          ],
        ],
      ),
    );
  }
}

class _Corrections extends StatelessWidget {
  const _Corrections({required this.j, required this.loc, required this.ws, required this.corr});
  final FieldJob j;
  final FieldStrings loc;
  final FieldWorkspaceController ws;
  final TextEditingController corr;

  @override
  Widget build(BuildContext context) {
    if (j.corrections.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      color: LegalTheme.warningSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.correction, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
          for (final c in j.corrections) ...[
            const SizedBox(height: 8),
            Text('${c.field}\n${c.reason}\n${c.requestedBy} · ${fmtWhen(c.at)} · ${labelPri(loc, c.priority)}', style: LegalTheme.ibm(size: 12)),
            if (c.response == null && !j.isLocked) ...[
              TextField(
                controller: corr,
                decoration: InputDecoration(isDense: true, hintText: loc.correction, border: OutlineInputBorder(borderRadius: BorderRadius.circular(4))),
              ),
              TextButton(
                onPressed: () {
                  if (corr.text.trim().isEmpty) return;
                  ws.respondCorrection(j.id, c.id, corr.text.trim());
                  corr.clear();
                },
                child: Text(loc.send),
              ),
            ] else if (c.response != null)
              Text(c.response!, style: LegalTheme.ibm(size: 12, color: LegalTheme.success)),
          ],
        ],
      ),
    );
  }
}

class _Messages extends StatelessWidget {
  const _Messages({
    required this.j,
    required this.loc,
    required this.ws,
    required this.msg,
    required this.ch,
    required this.onCh,
  });
  final FieldJob j;
  final FieldStrings loc;
  final FieldWorkspaceController ws;
  final TextEditingController msg;
  final FieldChannel ch;
  final ValueChanged<FieldChannel> onCh;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.navMsg, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
          for (final m in j.messages)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${m.author} · ${fmtWhen(m.at)}\n${m.body}', style: LegalTheme.ibm(size: 12)),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final c in FieldChannel.values)
                ChoiceChip(label: Text(c.name), selected: ch == c, onSelected: (_) => onCh(c)),
            ],
          ),
          TextField(controller: msg, decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)))),
          TextButton(
            onPressed: () {
              if (msg.text.trim().isEmpty) return;
              ws.addMessage(j.id, ch, msg.text.trim());
              msg.clear();
            },
            child: Text(loc.send),
          ),
        ],
      ),
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.j, required this.loc, required this.ws});
  final FieldJob j;
  final FieldStrings loc;
  final FieldWorkspaceController ws;

  @override
  Widget build(BuildContext context) {
    final s = ws.sections(j);
    final missing = s.where((x) => !x.complete).length;
    final conflicts = j.conflicts.where((c) => !c.resolved).length;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.reviewTitle, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
          Text(
            '${loc.progress} ${ws.completionPercent(j)}٪ · ${loc.missing} $missing · ${loc.conflict} $conflicts · ${loc.rooms} ${j.rooms.length} · ${loc.photoRef} ${j.rooms.where((r) => r.photoRef != null).length}',
            style: LegalTheme.ibm(size: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Versions extends StatelessWidget {
  const _Versions({required this.j, required this.loc});
  final FieldJob j;
  final FieldStrings loc;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.versions, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
          for (final v in j.versions)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('v${v.number} · ${v.by} · ${fmtWhen(v.at)} · ${labelSt(loc, v.status)}\n${v.reason}', style: LegalTheme.ibm(size: 12)),
            ),
        ],
      ),
    );
  }
}

class _Audit extends StatelessWidget {
  const _Audit({required this.j, required this.loc});
  final FieldJob j;
  final FieldStrings loc;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.audit, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
          for (final e in j.audit.reversed.take(14))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${fmtWhen(e.at)} · ${e.action}\n${e.employeeId} · ${e.propertyId} · ${e.requestId}', style: LegalTheme.mono(size: 11)),
            ),
        ],
      ),
    );
  }
}

Widget _card({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: LegalTheme.outline),
      borderRadius: BorderRadius.circular(4),
    ),
    child: child,
  );
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Expanded(child: Text(k, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted))),
        Text(v, style: LegalTheme.ibm(size: 13, weight: FontWeight.w700)),
      ],
    ),
  );
}
