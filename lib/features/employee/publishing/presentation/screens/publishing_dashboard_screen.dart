import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/publishing_repository.dart';
import '../../domain/publishing_models.dart';

class PublishingDashboardScreen extends StatefulWidget {
  const PublishingDashboardScreen({super.key});

  @override
  State<PublishingDashboardScreen> createState() =>
      _PublishingDashboardScreenState();
}

class _PublishingDashboardScreenState extends State<PublishingDashboardScreen> {
  bool _loading = true;
  PublishingDashboardStats? _stats;
  List<Map<String, dynamic>> _recent = [];

  late final PublishingRepository _repo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = PublishingRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await _repo.dashboardStats();
    final assets = await _repo.listAssets(limit: 8);
    final events = <Map<String, dynamic>>[];
    for (final a in assets.take(3)) {
      events.addAll(await _repo.listTimeline(a.id));
    }
    events.sort((a, b) {
      final da = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _recent = events.take(12).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _stats;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Property Publishing',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pipeline from request to published digital twin',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (s != null)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Tile('New requests', '${s.newRequests}'),
                _Tile('Info pending', '${s.informationPending}'),
                _Tile('Photo pending', '${s.photographyPending}'),
                _Tile('Floor plan', '${s.floorPlanPending}'),
                _Tile('Review', '${s.reviewRequired}'),
                _Tile('Ready', '${s.readyToPublish}'),
                _Tile('Published today', '${s.publishedToday}'),
                _Tile('Needs attention', '${s.needsAttention}'),
              ],
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/employee/publishing/create'),
            icon: const Icon(Icons.add),
            label: const Text('Create publishing request'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.go('/employee/publishing/requests'),
            child: const Text('Open requests'),
          ),
          const SizedBox(height: 24),
          Text('Activity timeline', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_recent.isEmpty)
            Text(
              'No pipeline activity yet.',
              style: theme.textTheme.bodySmall,
            )
          else
            ..._recent.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.timeline, size: 18),
                title: Text(e['event_type']?.toString() ?? ''),
                subtitle: Text(
                  '${e['message'] ?? ''}\n${e['created_at'] ?? ''}',
                ),
                isThreeLine: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = (MediaQuery.sizeOf(context).width - 52) / 2;
    return SizedBox(
      width: w,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
