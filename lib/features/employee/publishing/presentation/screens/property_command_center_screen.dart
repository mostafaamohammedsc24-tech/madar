import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/domain/employee_permissions.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/publishing_repository.dart';
import '../../domain/publisher_ops_models.dart';
import '../../domain/publishing_models.dart';
import '../theme/publisher_tokens.dart';

/// Unified property publishing command center.
class PropertyCommandCenterScreen extends StatefulWidget {
  const PropertyCommandCenterScreen({super.key, required this.propertyAssetId});

  final String propertyAssetId;

  @override
  State<PropertyCommandCenterScreen> createState() =>
      _PropertyCommandCenterScreenState();
}

class _PropertyCommandCenterScreenState
    extends State<PropertyCommandCenterScreen> {
  bool _loading = true;
  PropertyAsset? _asset;
  List<Map<String, dynamic>> _timeline = [];
  List<Map<String, dynamic>> _tags = [];
  int _section = 0;
  String _lang = 'en';
  late PublishingRepository _repo;

  static const _sections = [
    'Overview',
    'Information',
    'Media',
    'Location',
    'Financial',
    'Content',
    'Quality',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = PublishingRepository(
        context.read<EmployeeAuthNotifier>().repository,
      );
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final asset = await _repo.getAsset(widget.propertyAssetId);
    final timeline = await _repo.listTimeline(widget.propertyAssetId);
    final tags = await _repo.listTags(widget.propertyAssetId);
    if (!mounted) return;
    setState(() {
      _asset = asset;
      _timeline = timeline;
      _tags = tags;
      _loading = false;
    });
  }

  Future<void> _publish() async {
    final a = _asset;
    if (a == null) return;
    final gates = _repo.qualityChecklist(a);
    final blockers = gates.where((g) => g.status == 'incomplete').toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          blockers.isEmpty ? 'Ready to publish' : 'Publish with gaps?',
        ),
        content: Text(
          blockers.isEmpty
              ? 'All required information completed.\n\nPublish property #${a.publicPropertyId}?'
              : 'Incomplete: ${blockers.map((b) => b.label).join(', ')}\n\nYou can still publish if operationally approved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await _repo.finalPublish(widget.propertyAssetId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? 'Published successfully · #${a.publicPropertyId}'
              : (res.message ?? 'Cannot publish'),
        ),
      ),
    );
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<EmployeeAuthNotifier>();
    final a = _asset;
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    if (_loading || a == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final missing = missingFor(a);
    final stages = pipelineFor(a);
    final gates = _repo.qualityChecklist(a);

    return Scaffold(
      backgroundColor: PublisherTokens.background,
      body: Column(
        children: [
          _PropertyHeader(
            asset: a,
            missing: missing,
            canPublish: auth.can(EmployeePermission.publishingPublish),
            onCopyId: () {
              Clipboard.setData(ClipboardData(text: a.publicPropertyId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Property ID copied')),
              );
            },
            onPreview: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Preview uses the public property card experience.',
                  ),
                ),
              );
              context.push('/employee/publishing/properties');
            },
            onSave: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Draft saved')),
              );
            },
            onPublish: _publish,
          ),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 200,
                        child: _SectionNav(
                          sections: _sections,
                          selected: _section,
                          onSelect: (i) => setState(() => _section = i),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _SectionBody(
                          section: _section,
                          asset: a,
                          stages: stages,
                          gates: gates,
                          tags: _tags,
                          timeline: _timeline,
                          lang: _lang,
                          onLang: (l) => setState(() => _lang = l),
                          onOpenInfo: () => context.push(
                            '/employee/information/property/${a.id}',
                          ),
                          onOpenMedia: () =>
                              context.push('/employee/media/property/${a.id}'),
                          onOpenPlan: () => context.push(
                            '/employee/engineering/property/${a.id}',
                          ),
                          onContactTeam: (team) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Message $team about #${a.publicPropertyId}',
                                ),
                              ),
                            );
                            context.push('/employee/messages');
                          },
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _sections.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 6),
                          itemBuilder: (context, i) {
                            final sel = i == _section;
                            return ChoiceChip(
                              label: Text(_sections[i]),
                              selected: sel,
                              onSelected: (_) =>
                                  setState(() => _section = i),
                              selectedColor: PublisherTokens.primary,
                              labelStyle: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : PublisherTokens.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              showCheckmark: false,
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: _SectionBody(
                          section: _section,
                          asset: a,
                          stages: stages,
                          gates: gates,
                          tags: _tags,
                          timeline: _timeline,
                          lang: _lang,
                          onLang: (l) => setState(() => _lang = l),
                          onOpenInfo: () => context.push(
                            '/employee/information/property/${a.id}',
                          ),
                          onOpenMedia: () => context.push(
                            '/employee/media/property/${a.id}',
                          ),
                          onOpenPlan: () => context.push(
                            '/employee/engineering/property/${a.id}',
                          ),
                          onContactTeam: (team) {
                            context.push('/employee/messages');
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PropertyHeader extends StatelessWidget {
  const _PropertyHeader({
    required this.asset,
    required this.missing,
    required this.canPublish,
    required this.onCopyId,
    required this.onPreview,
    required this.onSave,
    required this.onPublish,
  });

  final PropertyAsset asset;
  final List<String> missing;
  final bool canPublish;
  final VoidCallback onCopyId;
  final VoidCallback onPreview;
  final VoidCallback onSave;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PublisherTokens.card,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: PublisherTokens.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SelectableText(
                            '#${asset.publicPropertyId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.4,
                              color: PublisherTokens.primary,
                            ),
                          ),
                          IconButton(
                            onPressed: onCopyId,
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: 'Copy Property ID',
                            visualDensity: VisualDensity.compact,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: PublisherTokens.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              asset.pipelineStatus.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: PublisherTokens.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        asset.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        [
                          asset.propertyType ?? '—',
                          asset.transactionType ?? '—',
                          asset.displayAddress,
                          if (asset.source != null) 'Source: ${asset.source}',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: PublisherTokens.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (MediaQuery.sizeOf(context).width >= 720) ...[
                  OutlinedButton(
                    onPressed: onPreview,
                    child: const Text('Preview'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onSave,
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 8),
                  if (canPublish)
                    FilledButton(
                      onPressed: onPublish,
                      style: FilledButton.styleFrom(
                        backgroundColor: PublisherTokens.secondary,
                      ),
                      child: const Text('Publish'),
                    ),
                ],
              ],
            ),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Missing: ${missing.join(' · ')}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF633F0F),
                  ),
                ),
              ),
            ],
            if (MediaQuery.sizeOf(context).width < 720) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPreview,
                      child: const Text('Preview'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSave,
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (canPublish)
                    Expanded(
                      child: FilledButton(
                        onPressed: onPublish,
                        child: const Text('Publish'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionNav extends StatelessWidget {
  const _SectionNav({
    required this.sections,
    required this.selected,
    required this.onSelect,
  });

  final List<String> sections;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      children: [
        for (var i = 0; i < sections.length; i++)
          ListTile(
            dense: true,
            selected: selected == i,
            selectedTileColor: PublisherTokens.primary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            title: Text(
              sections[i],
              style: TextStyle(
                fontWeight: selected == i ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            onTap: () => onSelect(i),
          ),
      ],
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({
    required this.section,
    required this.asset,
    required this.stages,
    required this.gates,
    required this.tags,
    required this.timeline,
    required this.lang,
    required this.onLang,
    required this.onOpenInfo,
    required this.onOpenMedia,
    required this.onOpenPlan,
    required this.onContactTeam,
  });

  final int section;
  final PropertyAsset asset;
  final List<PipelineStageView> stages;
  final List<QualityGate> gates;
  final List<Map<String, dynamic>> tags;
  final List<Map<String, dynamic>> timeline;
  final String lang;
  final ValueChanged<String> onLang;
  final VoidCallback onOpenInfo;
  final VoidCallback onOpenMedia;
  final VoidCallback onOpenPlan;
  final ValueChanged<String> onContactTeam;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case 0:
        return _OverviewSection(
          asset: asset,
          stages: stages,
          onContactTeam: onContactTeam,
          timeline: timeline,
        );
      case 1:
        return _Panel(
          title: 'Information',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pct('Physical report', asset.informationPct),
              const SizedBox(height: 12),
              const Text(
                'Review dimensions, rooms, utilities, materials, and physical characteristics collected by the Information team. Fields adapt by property type.',
                style: TextStyle(color: PublisherTokens.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: onOpenInfo,
                    child: const Text('Open information report'),
                  ),
                  OutlinedButton(
                    onPressed: () => onContactTeam('Information'),
                    child: const Text('Contact Information Team'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _kv('Property type', asset.propertyType ?? 'Not available'),
              _kv('Bedrooms / rooms', 'Not available'),
              _kv('Built area', 'Not available'),
              _kv('Land area', 'Not available'),
              _kv('Construction year', 'Not available'),
            ],
          ),
        );
      case 2:
        return _Panel(
          title: 'Media · Video · 3D · Floor Plan',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pct('Photography', asset.photographyPct),
              _pct('3D tour', asset.threeDPct),
              _pct('Floor plan', asset.floorPlanPct),
              const SizedBox(height: 12),
              if (asset.coverImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      asset.coverImageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                const Text(
                  'No primary image yet.',
                  style: TextStyle(color: PublisherTokens.onSurfaceVariant),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: onOpenMedia,
                    child: const Text('Organize media'),
                  ),
                  OutlinedButton(
                    onPressed: onOpenPlan,
                    child: const Text('Review floor plan'),
                  ),
                  OutlinedButton(
                    onPressed: () => onContactTeam('Photography'),
                    child: const Text('Contact Photography'),
                  ),
                  OutlinedButton(
                    onPressed: () => onContactTeam('Engineering'),
                    child: const Text('Request Floor Plan'),
                  ),
                ],
              ),
            ],
          ),
        );
      case 3:
        return _Panel(
          title: 'Location & neighborhood intelligence',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Address', asset.displayAddress),
              _kv('City', asset.city ?? 'Not available'),
              _kv('Coordinates', asset.latitude == null
                  ? 'Not available'
                  : '${asset.latitude}, ${asset.longitude}'),
              _kv('Nearby schools', 'Not available'),
              _kv('Transit', 'Not available'),
              _kv('Future development', 'Not available'),
              const SizedBox(height: 8),
              const Text(
                'Attach upcoming projects, infrastructure, and investment zones without inventing unavailable data.',
                style: TextStyle(
                  fontSize: 13,
                  color: PublisherTokens.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      case 4:
        return _Panel(
          title: 'Financial · Lease-to-Own · Investment',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('List price', asset.formattedPrice),
              _kv('Price / m²', 'Not available'),
              _kv('Rental value', 'Not available'),
              _kv('Yield', 'Not available'),
              _kv('Lease-to-Own eligible', 'Not available'),
              _kv('Monthly payment range', 'Not available'),
              _kv('Mortgage estimate', 'Not available'),
              const SizedBox(height: 8),
              const Text(
                'Investment indicators show “Not available” until verified data is attached.',
                style: TextStyle(
                  fontSize: 13,
                  color: PublisherTokens.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      case 5:
        return _Panel(
          title: 'Content · Translations · Keywords',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final l in const [
                    ('ar', 'العربية'),
                    ('en', 'English'),
                    ('ku', 'کوردی'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(l.$2),
                        selected: lang == l.$1,
                        onSelected: (_) => onLang(l.$1),
                        showCheckmark: false,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _kv('Short description', 'Not available'),
              _kv('Full description', asset.notes ?? 'Not available'),
              _kv("What's Special", 'Not available'),
              _kv('Neighborhood description', 'Not available'),
              const SizedBox(height: 12),
              const Text(
                'Search keywords',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in tags)
                    Chip(label: Text(t['tag']?.toString() ?? '')),
                  if (tags.isEmpty)
                    const Text(
                      'No keywords yet',
                      style: TextStyle(
                        color: PublisherTokens.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Suggested AI search phrases',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '"${asset.propertyType ?? 'property'} near ${asset.city ?? 'city'}"',
                style: const TextStyle(
                  color: PublisherTokens.onSurfaceVariant,
                ),
              ),
              Text(
                asset.askingPrice == null
                    ? '"family property in ${asset.city ?? 'area'}"'
                    : '"${asset.propertyType ?? 'property'} under ${asset.formattedPrice}"',
                style: const TextStyle(
                  color: PublisherTokens.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      case 6:
      default:
        return _Panel(
          title: 'Quality control & publish readiness',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final g in gates)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    g.status == 'complete'
                        ? Icons.check_circle
                        : g.status == 'warning'
                            ? Icons.warning_amber_rounded
                            : Icons.radio_button_unchecked,
                    color: g.status == 'complete'
                        ? PublisherTokens.secondary
                        : g.status == 'warning'
                            ? PublisherTokens.tertiaryContainer
                            : PublisherTokens.onSurfaceVariant,
                    size: 20,
                  ),
                  title: Text(g.label),
                  subtitle: g.detail == null ? null : Text(g.detail!),
                ),
            ],
          ),
        );
    }
  }

  Widget _pct(String label, int pct) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('$pct%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
            color: PublisherTokens.secondary,
            backgroundColor: PublisherTokens.surfaceHighest,
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              k,
              style: const TextStyle(
                fontSize: 12,
                color: PublisherTokens.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.asset,
    required this.stages,
    required this.onContactTeam,
    required this.timeline,
  });

  final PropertyAsset asset;
  final List<PipelineStageView> stages;
  final ValueChanged<String> onContactTeam;
  final List<Map<String, dynamic>> timeline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Publishing pipeline',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        for (final s in stages)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  s.state == 'complete'
                      ? Icons.check_circle
                      : s.state == 'in_progress'
                          ? Icons.timelapse
                          : s.state == 'waiting'
                              ? Icons.hourglass_empty
                              : Icons.radio_button_unchecked,
                  size: 18,
                  color: s.state == 'complete'
                      ? PublisherTokens.secondary
                      : PublisherTokens.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.label,
                    style: TextStyle(
                      fontWeight: s.state == 'in_progress'
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  s.state.replaceAll('_', ' '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: PublisherTokens.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Completion · ${asset.overallPct}%',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: asset.overallPct / 100,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: PublisherTokens.primary,
          backgroundColor: PublisherTokens.surfaceHighest,
        ),
        const SizedBox(height: 20),
        const Text(
          'Contextual actions',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => onContactTeam('Information'),
              child: const Text('Contact Information'),
            ),
            OutlinedButton(
              onPressed: () => onContactTeam('Photography'),
              child: const Text('Contact Photography'),
            ),
            OutlinedButton(
              onPressed: () => onContactTeam('Engineering'),
              child: const Text('Contact Mapping'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Activity',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (timeline.isEmpty)
          const Text(
            'No events yet',
            style: TextStyle(color: PublisherTokens.onSurfaceVariant),
          )
        else
          for (final e in timeline.take(8))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(e['event_type']?.toString() ?? 'event'),
              subtitle: Text(e['note']?.toString() ?? ''),
              trailing: Text(
                (e['created_at']?.toString() ?? '').split('T').first,
                style: const TextStyle(fontSize: 11),
              ),
            ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
