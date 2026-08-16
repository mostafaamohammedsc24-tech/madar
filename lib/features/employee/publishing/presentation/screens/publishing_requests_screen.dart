import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/domain/employee_permissions.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/publishing_repository.dart';
import '../../domain/publishing_models.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  title: Text('#${a.publicPropertyId}'),
                  subtitle: Text(
                    '${a.pipelineStatus} · ${a.city ?? ''} · '
                    'Info ${a.informationPct}% · Photo ${a.photographyPct}% · '
                    '3D ${a.threeDPct}% · Plan ${a.floorPlanPct}%',
                  ),
                  onTap: () {
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
                  },
                );
              },
            ),
          );
  }
}
