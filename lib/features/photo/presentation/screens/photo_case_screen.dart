import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/photo_strings.dart';
import '../../../legal/presentation/theme/legal_theme.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart' hide labelPriority, labelAction, labelStage, labelDoc, toneForPriority, toneForDoc;
import '../../domain/enums/photo_enums.dart';
import '../../domain/models/photo_models.dart';
import '../providers/photo_workspace_controller.dart';
import '../widgets/photo_labels.dart';

class PhotoCaseScreen extends StatefulWidget {
  const PhotoCaseScreen({required this.jobId, super.key});
  final String jobId;
  @override
  State<PhotoCaseScreen> createState() => _PhotoCaseScreenState();
}

class _PhotoCaseScreenState extends State<PhotoCaseScreen> {
  final _corr = TextEditingController();
  final _msg = TextEditingController();
  PhotoChannel _ch = PhotoChannel.publisher;
  bool _captureOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = context.read<PhotoWorkspaceController>();
      final j = ws.byId(widget.jobId);
      if (j != null) {
        ws.audit(j, 'assignment_opened');
        if (j.rooms.isNotEmpty) ws.selectRoom(j.rooms.first.id);
      }
    });
  }

  @override
  void dispose() {
    _corr.dispose();
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = PhotoStrings.of(AppLocalizations.of(context));
    final ws = context.watch<PhotoWorkspaceController>();
    final j = ws.byId(widget.jobId);
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (j == null) return Scaffold(body: Center(child: Text(loc.noActions)));
    final room = j.rooms.where((r) => r.id == ws.activeRoomId).firstOrNull ?? (j.rooms.isEmpty ? null : j.rooms.first);
    final pct = ws.packagePercent(j);

    if (_captureOpen && room != null) {
      return _CaptureView(
        loc: loc,
        room: room,
        onClose: () => setState(() => _captureOpen = false),
        onShot: (t) => ws.captureShot(j.id, room.id, t),
      );
    }

    return Scaffold(
      backgroundColor: dark ? LegalTheme.darkBg : LegalTheme.paper,
      body: Column(
        children: [
          Material(
            color: dark ? LegalTheme.darkSurface : LegalTheme.surface,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
                child: Row(children: [
                  IconButton(onPressed: () => context.go('/photo/work'), icon: const Icon(Icons.arrow_back)),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(j.propertyId, style: LegalTheme.mono(size: 16, weight: FontWeight.w800, color: LegalTheme.primary)),
                      Text('${j.requestNumber} · ${j.propertyType} · ${j.address}', maxLines: 1, overflow: TextOverflow.ellipsis, style: LegalTheme.ibm(size: 11, color: LegalTheme.muted)),
                    ]),
                  ),
                  LegalStatusChip(label: labelSync(loc, j.sync), tone: LegalTone.neutral),
                  const SizedBox(width: 6),
                  LegalStatusChip(label: labelSt(loc, j.status), tone: toneSt(j.status)),
                ]),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            color: dark ? LegalTheme.darkSurface : Colors.white,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${loc.photography} $pct٪ · ${loc.photos} ${j.donePhotoCount}/${j.requiredPhotoCount} · ${loc.tour3d} ${j.points.length} · ${loc.pano} ${j.panoCount}', style: LegalTheme.ibm(size: 13, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: pct / 100, minHeight: 6, color: LegalTheme.primary, backgroundColor: LegalTheme.softBlue),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
              children: [
                _banner(loc.notPublish, LegalTheme.warningSoft, LegalTheme.warning),
                const SizedBox(height: 8),
                _banner(loc.nowNeed, LegalTheme.activeSoft, LegalTheme.primary),
                const SizedBox(height: 12),
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(loc.streams, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
                  _kv(loc.information, labelStream(loc, j.infoStream)),
                  _kv(loc.floorPlan, labelStream(loc, j.planStream)),
                  _kv(loc.publishing, labelStream(loc, j.publishStream)),
                  _kv(loc.photography, labelAct(loc, j.requiredAction)),
                ])),
                const SizedBox(height: 12),
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(j.propertyId, style: LegalTheme.ibm(size: 16, weight: FontWeight.w800)),
                  _kv(loc.publisher, j.publisher),
                  _kv(loc.information, j.informationOfficer),
                  _kv(loc.floorPlan, j.floorPlanEngineer),
                  _kv(loc.visit, fmtWhen(j.visitAt)),
                  _kv(loc.instructions, j.specialInstructions),
                ])),
                const SizedBox(height: 12),
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(loc.visit, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
                  Container(height: 100, width: double.infinity, color: LegalTheme.softBlue, alignment: Alignment.center, child: Text(loc.mapHint, textAlign: TextAlign.center)),
                  const SizedBox(height: 8),
                  Text('${loc.distance}: 180 م', style: LegalTheme.ibm(size: 13, weight: FontWeight.w700)),
                  if (j.arrivalAt != null)
                    Text('${loc.confirmArrival}: ${fmtWhen(j.arrivalAt!)}', style: LegalTheme.ibm(size: 12, color: LegalTheme.success, weight: FontWeight.w700))
                  else if (!j.isLocked)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(onPressed: () => ws.confirmArrival(j.id), style: FilledButton.styleFrom(backgroundColor: LegalTheme.primary), child: Text(loc.confirmArrival)),
                    ),
                ])),
                const SizedBox(height: 12),
                Text(loc.rooms, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final r in j.rooms)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: ChoiceChip(
                            label: Text('${r.name} ${r.doneShots}/${r.totalShots}'),
                            selected: room?.id == r.id,
                            onSelected: (_) => ws.selectRoom(r.id),
                          ),
                        ),
                    ],
                  ),
                ),
                if (room != null) ...[
                  const SizedBox(height: 10),
                  _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${room.floor} · ${room.name}', style: LegalTheme.ibm(size: 15, weight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    for (final s in room.requiredShots)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Icon(s.done ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: s.done ? LegalTheme.success : LegalTheme.warning),
                          const SizedBox(width: 8),
                          Expanded(child: Text(labelShot(loc, s.type))),
                          if (!s.done && !j.isLocked)
                            TextButton(onPressed: () => ws.captureShot(j.id, room.id, s.type), child: Text(loc.capture)),
                        ]),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: j.isLocked ? null : () => setState(() => _captureOpen = true),
                        style: FilledButton.styleFrom(backgroundColor: LegalTheme.primary),
                        child: Text(loc.capture),
                      ),
                    ),
                  ])),
                ],
                const SizedBox(height: 12),
                Text(loc.gallery, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: [
                    for (final a in j.assets)
                      Container(
                        color: Color(a.color),
                        padding: const EdgeInsets.all(6),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a.label, style: LegalTheme.mono(size: 10, color: Colors.white)),
                          const Spacer(),
                          Text(labelCat(loc, a.category), style: LegalTheme.ibm(size: 10, color: Colors.white)),
                          Text(labelVis(loc, a.visibility), style: LegalTheme.ibm(size: 10, color: Colors.white70)),
                          if (a.qualityWarning != null)
                            Text(loc.review, style: LegalTheme.ibm(size: 10, color: const Color(0xFFFFE082))),
                        ]),
                      ),
                  ],
                ),
                if (j.assets.any((a) => a.qualityWarning != null)) ...[
                  const SizedBox(height: 12),
                  _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(loc.review, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800, color: LegalTheme.warning)),
                    for (final a in j.assets.where((x) => x.qualityWarning != null)) ...[
                      Text('${a.label}: ${a.qualityWarning}', style: LegalTheme.ibm(size: 12)),
                      Row(children: [
                        TextButton(onPressed: () {}, child: Text(loc.keep)),
                        TextButton(onPressed: () => ws.markInternal(j.id, a.id), child: Text(loc.markInternal)),
                      ]),
                    ],
                  ])),
                ],
                const SizedBox(height: 12),
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(loc.uploads, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
                  Text('${j.assets.length} · ${loc.synced} ${j.assets.length - j.queued - j.processing} · ${loc.saving} ${j.processing} · ${loc.offline} ${j.queued} · ${j.failed}'),
                ])),
                const SizedBox(height: 12),
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${loc.tour3d} · ${j.tourName} · ${j.device}', style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
                  Text('${loc.coverage} ${ws.tourPercent(j)}٪', style: LegalTheme.ibm(size: 13)),
                  const SizedBox(height: 8),
                  for (final p in j.points)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('${p.id} → ${p.roomName} · ${p.status}${p.panoId != null ? ' · ${p.panoId}' : ''}${p.photoIds.isNotEmpty ? ' · ${p.photoIds.join(', ')}' : ''}'),
                    ),
                  if (!j.isLocked)
                    Row(children: [
                      OutlinedButton(onPressed: () => ws.addTourPoint(j.id), child: Text(loc.addPoint)),
                      const SizedBox(width: 8),
                      OutlinedButton(onPressed: room == null ? null : () => ws.addPano(j.id, room.id), child: Text(loc.addPano)),
                    ]),
                ])),
                const SizedBox(height: 12),
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(loc.story, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
                  Text(j.story.join('  →  '), style: LegalTheme.ibm(size: 13, height: 1.5)),
                ])),
                const SizedBox(height: 12),
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(loc.package, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
                  Text('${loc.photos} ${j.assets.length} · ${loc.required} ${j.requiredPhotoCount} · ${loc.publicMedia} ${j.publicCount} · ${loc.internalMedia} ${j.internalCount} · ${loc.tour3d} ${j.points.length} · ${loc.pano} ${j.panoCount}'),
                ])),
                if (j.corrections.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    color: LegalTheme.warningSoft,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(loc.correction, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
                      for (final c in j.corrections) ...[
                        Text('${c.room}\n${c.reason}\n${c.requestedBy} · ${fmtWhen(c.at)}', style: LegalTheme.ibm(size: 12)),
                        if (c.response == null && !j.isLocked) ...[
                          TextField(controller: _corr, decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)))),
                          TextButton(onPressed: () { if (_corr.text.trim().isEmpty) return; ws.respondCorrection(j.id, c.id, _corr.text.trim()); _corr.clear(); }, child: Text(loc.send)),
                        ] else if (c.response != null)
                          Text(c.response!, style: LegalTheme.ibm(size: 12, color: LegalTheme.success)),
                      ],
                    ]),
                  ),
                ],
                const SizedBox(height: 12),
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(loc.navMsg, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
                  for (final m in j.messages) Text('${m.author} · ${fmtWhen(m.at)}\n${m.body}', style: LegalTheme.ibm(size: 12)),
                  Wrap(spacing: 6, children: [for (final c in PhotoChannel.values) ChoiceChip(label: Text(c.name), selected: _ch == c, onSelected: (_) => setState(() => _ch = c))]),
                  TextField(controller: _msg, decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)))),
                  TextButton(onPressed: () { if (_msg.text.trim().isEmpty) return; ws.addMessage(j.id, _ch, _msg.text.trim()); _msg.clear(); }, child: Text(loc.send)),
                ])),
                const SizedBox(height: 12),
                _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(loc.audit, style: LegalTheme.ibm(size: 14, weight: FontWeight.w800)),
                  for (final e in j.audit.reversed.take(12)) Text('${fmtWhen(e.at)} · ${e.action} · ${e.employeeId}', style: LegalTheme.mono(size: 11)),
                ])),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: j.isLocked || j.status == PhotoJobStatus.submitted
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (!ws.canSubmit(j)) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(loc.cannotSubmit, style: LegalTheme.ibm(size: 12, color: LegalTheme.warning))),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: ws.canSubmit(j)
                          ? () {
                              ws.submit(j.id);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.submit)));
                            }
                          : null,
                      style: FilledButton.styleFrom(backgroundColor: LegalTheme.primary),
                      child: Text(loc.submit),
                    ),
                  ),
                ]),
              ),
            ),
    );
  }
}

class _CaptureView extends StatelessWidget {
  const _CaptureView({required this.loc, required this.room, required this.onClose, required this.onShot});
  final PhotoStrings loc;
  final PhotoRoom room;
  final VoidCallback onClose;
  final void Function(ShotType) onShot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Colors.white)),
              Expanded(child: Text('${room.floor} · ${room.name}', style: LegalTheme.ibm(size: 16, weight: FontWeight.w700, color: Colors.white))),
            ]),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              color: const Color(0xFF1A2438),
              alignment: Alignment.center,
              child: Text(loc.capture, style: LegalTheme.ibm(size: 18, color: Colors.white70)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              children: [
                for (final s in room.requiredShots.where((x) => !x.done))
                  ActionChip(label: Text(labelShot(loc, s.type)), onPressed: () { onShot(s.type); }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: GestureDetector(
              onTap: () {
                final next = room.requiredShots.where((s) => !s.done).firstOrNull;
                if (next != null) onShot(next.type);
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), color: LegalTheme.primary),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

Widget _banner(String t, Color bg, Color border) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(4)),
      child: Text(t, style: LegalTheme.ibm(size: 12, weight: FontWeight.w700, color: LegalTheme.navy)),
    );

Widget _card(Widget child) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: LegalTheme.outline), borderRadius: BorderRadius.circular(4)),
      child: child,
    );

Widget _kv(String k, String v) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(k, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted))),
        Expanded(child: Text(v, style: LegalTheme.ibm(size: 13, weight: FontWeight.w600))),
      ]),
    );
