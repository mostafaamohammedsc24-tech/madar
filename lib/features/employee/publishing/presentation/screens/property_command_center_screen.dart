import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/domain/employee_permissions.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/publishing_repository.dart';
import '../../domain/publishing_models.dart';

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
  late PublishingRepository _repo;

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

  Future<void> _assign(String role, String deptCode) async {
    final staff = await _repo.listEmployeesByDepartment(deptCode);
    if (!mounted) return;
    if (staff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No staff available in that department')),
      );
      return;
    }
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          const ListTile(title: Text('Select employee')),
          ...staff.map(
            (e) => ListTile(
              title: Text(e['full_name']?.toString() ?? ''),
              subtitle: Text(e['employee_code']?.toString() ?? ''),
              onTap: () => Navigator.pop(ctx, e),
            ),
          ),
        ],
      ),
    );
    if (selected == null) return;
    final ok = await _repo.assignEmployee(
      propertyAssetId: widget.propertyAssetId,
      employeeId: selected['id'].toString(),
      role: role,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Assigned' : 'Assignment failed')),
    );
    if (ok) _load();
  }

  Future<void> _publish() async {
    final res = await _repo.finalPublish(widget.propertyAssetId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success ? 'Published' : (res.message ?? 'Cannot publish'),
        ),
      ),
    );
    if (res.success) _load();
  }

  Future<void> _addTag() async {
    final ctrl = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add search tag'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (tag == null || tag.isEmpty) return;
    await _repo.addTag(propertyAssetId: widget.propertyAssetId, tag: tag);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<EmployeeAuthNotifier>();
    final a = _asset;

    if (_loading || a == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            'PROPERTY #${a.publicPropertyId}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text('Status: ${a.pipelineStatus.replaceAll('_', ' ')}'),
          Text('Owner: ${a.ownerName ?? '—'} · ${a.ownerPhone ?? ''}'),
          Text('Location: ${a.addressText ?? a.city ?? '—'}'),
          const SizedBox(height: 16),
          _ProgressRow('Information', a.informationPct),
          _ProgressRow('Photography', a.photographyPct),
          _ProgressRow('3D', a.threeDPct),
          _ProgressRow('Floor plan', a.floorPlanPct),
          const SizedBox(height: 8),
          Text(
            a.isPublished ? 'Publishing: Live' : 'Publishing: Locked',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (auth.can(EmployeePermission.publishingAssign)) ...[
                ActionChip(
                  label: const Text('Assign information'),
                  onPressed: () => _assign('information', 'information'),
                ),
                ActionChip(
                  label: const Text('Assign photography'),
                  onPressed: () => _assign('photography', 'photography'),
                ),
                ActionChip(
                  label: const Text('Assign engineering'),
                  onPressed: () => _assign('engineering', 'engineering'),
                ),
              ],
              ActionChip(
                label: const Text('Information'),
                onPressed: () => context.push(
                  '/employee/information/property/${a.id}',
                ),
              ),
              ActionChip(
                label: const Text('Media'),
                onPressed: () =>
                    context.push('/employee/media/property/${a.id}'),
              ),
              ActionChip(
                label: const Text('Floor plan'),
                onPressed: () => context.push(
                  '/employee/engineering/property/${a.id}',
                ),
              ),
              if (auth.can(EmployeePermission.publishingEdit))
                ActionChip(label: const Text('Add tag'), onPressed: _addTag),
              if (auth.can(EmployeePermission.publishingPublish))
                ActionChip(
                  label: const Text('Publish'),
                  onPressed: _publish,
                ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              children: _tags
                  .map((t) => Chip(label: Text(t['tag']?.toString() ?? '')))
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          Text('Activity', style: theme.textTheme.titleMedium),
          ..._timeline.map(
            (e) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(e['event_type']?.toString() ?? ''),
              subtitle: Text('${e['message'] ?? ''}\n${e['created_at'] ?? ''}'),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow(this.label, this.pct);
  final String label;
  final int pct;

  @override
  Widget build(BuildContext context) {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: pct / 100, minHeight: 8),
          ),
        ],
      ),
    );
  }
}
