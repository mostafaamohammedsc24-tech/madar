import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/sales_repository.dart';

class SalesLeadsScreen extends StatefulWidget {
  const SalesLeadsScreen({super.key});

  @override
  State<SalesLeadsScreen> createState() => _SalesLeadsScreenState();
}

class _SalesLeadsScreenState extends State<SalesLeadsScreen> {
  late SalesRepository _repo;
  bool _loading = true;
  List<Map<String, dynamic>> _leads = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = SalesRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listLeads();
    if (!mounted) return;
    setState(() {
      _leads = list;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    var type = 'buyer';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New lead', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'buyer', child: Text('Buyer')),
                  DropdownMenuItem(value: 'seller', child: Text('Seller')),
                  DropdownMenuItem(value: 'renter', child: Text('Renter')),
                ],
                onChanged: (v) => setModal(() => type = v ?? type),
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty || phone.text.trim().isEmpty) {
      return;
    }
    final res = await _repo.createLead(
      fullName: name.text.trim(),
      phone: phone.text.trim(),
      leadType: type,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? 'Lead ${res.leadCode} created'
              : (res.message ?? 'Failed'),
        ),
      ),
    );
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        actions: [
          IconButton(onPressed: _create, icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _leads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final l = _leads[i];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    title: Text(l['full_name']?.toString() ?? ''),
                    subtitle: Text(
                      '${l['lead_code']} · ${l['lead_type']} · ${l['status']}',
                    ),
                    trailing: Text(l['phone']?.toString() ?? ''),
                    onTap: () async {
                      final next = await showModalBottomSheet<String>(
                        context: context,
                        builder: (ctx) => ListView(
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              title: Text(l['full_name']?.toString() ?? ''),
                              subtitle: Text(l['status']?.toString() ?? ''),
                            ),
                            for (final s in const [
                              'contacted',
                              'qualified',
                              'viewing',
                              'negotiating',
                              'ready_for_closing',
                              'lost',
                            ])
                              ListTile(
                                title: Text('Mark $s'),
                                onTap: () => Navigator.pop(ctx, s),
                              ),
                            ListTile(
                              title: const Text('Create publishing request'),
                              onTap: () {
                                Navigator.pop(ctx);
                                context.push('/employee/publishing/create');
                              },
                            ),
                          ],
                        ),
                      );
                      if (next != null) {
                        await _repo.updateLeadStatus(l['id'].toString(), next);
                        _load();
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}

class SalesFollowUpsScreen extends StatefulWidget {
  const SalesFollowUpsScreen({super.key});

  @override
  State<SalesFollowUpsScreen> createState() => _SalesFollowUpsScreenState();
}

class _SalesFollowUpsScreenState extends State<SalesFollowUpsScreen> {
  late SalesRepository _repo;
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = SalesRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listFollowUpsToday();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's follow-ups")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final f = _items[i];
                  final lead = f['sales_leads'] as Map?;
                  return ListTile(
                    title: Text(lead?['full_name']?.toString() ?? 'Lead'),
                    subtitle: Text(f['notes']?.toString() ?? f['channel']?.toString() ?? ''),
                    trailing: Text(
                      (f['due_at']?.toString() ?? '').split('T').last.split('.').first,
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class SalesDealsScreen extends StatefulWidget {
  const SalesDealsScreen({super.key});

  @override
  State<SalesDealsScreen> createState() => _SalesDealsScreenState();
}

class _SalesDealsScreenState extends State<SalesDealsScreen> {
  late SalesRepository _repo;
  bool _loading = true;
  List<Map<String, dynamic>> _leads = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = SalesRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listLeads(status: 'ready_for_closing');
    if (!mounted) return;
    setState(() {
      _leads = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ready for closing')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _leads.length,
              itemBuilder: (context, i) {
                final l = _leads[i];
                return ListTile(
                  title: Text(l['full_name']?.toString() ?? ''),
                  subtitle: const Text(
                    'Handoff to Closing → Lawyer → Finance / Bank',
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () async {
                      await _repo.updateLeadStatus(
                        l['id'].toString(),
                        'converted',
                      );
                      _load();
                    },
                    child: const Text('Hand off'),
                  ),
                );
              },
            ),
    );
  }
}
