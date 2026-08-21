import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/domain/employee_permissions.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/publishing_repository.dart';
import '../../domain/publishing_models.dart';
import '../theme/publisher_tokens.dart';

class PublishingRequestsScreen extends StatefulWidget {
  const PublishingRequestsScreen({super.key, this.assignedOnly = false});

  final bool assignedOnly;

  @override
  State<PublishingRequestsScreen> createState() =>
      _PublishingRequestsScreenState();
}

class _PublishingRequestsScreenState extends State<PublishingRequestsScreen> {
  bool _loading = true;
  List<PropertyAsset> _items = [];
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
    final list = await _repo.listAssets(assignedOnly: widget.assignedOnly);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  void _open(PropertyAsset a) {
    final dept = context
        .read<EmployeeAuthNotifier>()
        .employee
        ?.department
        .departmentCode;
    if (dept == EmployeeDepartmentCode.information) {
      context.push('/employee/information/property/${a.id}');
    } else if (dept == EmployeeDepartmentCode.photography) {
      context.push('/employee/media/property/${a.id}');
    } else if (dept == EmployeeDepartmentCode.engineering) {
      context.push('/employee/engineering/property/${a.id}');
    } else {
      context.push('/employee/publishing/property/${a.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPublisher =
        context.watch<EmployeeAuthNotifier>().employee?.isPublishing == true;

    if (!isPublisher) {
      return _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final a = _items[i];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    title: Text('#${a.publicPropertyId}'),
                    subtitle: Text(
                      '${a.pipelineStatus} · ${a.city ?? ''} · '
                      'Info ${a.informationPct}% · Photo ${a.photographyPct}%',
                    ),
                    onTap: () => _open(a),
                  );
                },
              ),
            );
    }

    return Scaffold(
      backgroundColor: PublisherTokens.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Text(
                    'Requests',
                    style: PublisherTokens.textTheme(
                      Theme.of(context).textTheme,
                    ).titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pipeline requests waiting on publishing handoffs.',
                    style: TextStyle(
                      fontSize: 14,
                      color: PublisherTokens.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        context.push('/employee/publishing/create'),
                    style: FilledButton.styleFrom(
                      backgroundColor: PublisherTokens.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('New publishing request'),
                  ),
                  const SizedBox(height: 16),
                  ..._items.map((a) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: PublisherTokens.card,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => _open(a),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: PublisherTokens.microDepth,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.displayTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: PublisherTokens.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '#${a.publicPropertyId} · ${a.pipelineStatus}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color:
                                              PublisherTokens.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Info ${a.informationPct}% · Photo ${a.photographyPct}% · 3D ${a.threeDPct}% · Plan ${a.floorPlanPct}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color:
                                              PublisherTokens.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: PublisherTokens.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
