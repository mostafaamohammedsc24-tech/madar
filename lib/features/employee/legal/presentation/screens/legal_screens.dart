import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/legal_repository.dart';

class ContractListScreen extends StatefulWidget {
  const ContractListScreen({super.key, this.statusFilter});

  final String? statusFilter;

  @override
  State<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends State<ContractListScreen> {
  late LegalRepository _repo;
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = LegalRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listContracts(status: widget.statusFilter);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _newFromTemplate() async {
    final templates = await _repo.listTemplates();
    if (!mounted || templates.isEmpty) return;
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          const ListTile(title: Text('Contract template')),
          ...templates.map(
            (t) => ListTile(
              title: Text(t['name_en']?.toString() ?? ''),
              subtitle: Text(t['code']?.toString() ?? ''),
              onTap: () => Navigator.pop(ctx, t),
            ),
          ),
        ],
      ),
    );
    if (selected == null) return;
    final id = await _repo.createContractFromTemplate(
      templateId: selected['id'].toString(),
    );
    if (!mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create contract')),
      );
      return;
    }
    context.push('/employee/legal/contracts/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contracts'),
        actions: [
          IconButton(onPressed: _newFromTemplate, icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final c = _items[i];
                  return ListTile(
                    title: Text(c['version_label']?.toString() ?? 'Contract'),
                    subtitle: Text(
                      '${c['status']} · v${c['version_no']}',
                    ),
                    onTap: () =>
                        context.push('/employee/legal/contracts/${c['id']}'),
                  );
                },
              ),
            ),
    );
  }
}

class ContractWorkspaceScreen extends StatefulWidget {
  const ContractWorkspaceScreen({super.key, required this.contractId});

  final String contractId;

  @override
  State<ContractWorkspaceScreen> createState() =>
      _ContractWorkspaceScreenState();
}

class _ContractWorkspaceScreenState extends State<ContractWorkspaceScreen> {
  late LegalRepository _repo;
  final _body = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  Map<String, dynamic>? _contract;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = LegalRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _repo.listContracts();
    final found = all.cast<Map<String, dynamic>?>().firstWhere(
          (c) => c?['id']?.toString() == widget.contractId,
          orElse: () => null,
        );
    if (!mounted) return;
    setState(() {
      _contract = found;
      _body.text = found?['body_text']?.toString() ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final ok = await _repo.saveDraft(widget.contractId, _body.text);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Version saved' : 'Save failed')),
    );
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final c = _contract;
    return Scaffold(
      appBar: AppBar(
        title: Text(c?['version_label']?.toString() ?? 'Contract'),
        actions: [
          TextButton(onPressed: _busy ? null : _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Status: ${c?['status'] ?? '—'} · Version ${c?['version_no']}'),
          const SizedBox(height: 8),
          Text(
            'Variables are filled from transaction data. Edits create immutable versions.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            maxLines: 18,
            decoration: const InputDecoration(
              labelText: 'Contract body',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionLawyerScreen extends StatefulWidget {
  const TransactionLawyerScreen({super.key});

  @override
  State<TransactionLawyerScreen> createState() =>
      _TransactionLawyerScreenState();
}

class _TransactionLawyerScreenState extends State<TransactionLawyerScreen> {
  late LegalRepository _repo;
  bool _loading = true;
  List<Map<String, dynamic>> _txs = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = LegalRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listManagedTransactions();
    if (!mounted) return;
    setState(() {
      _txs = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active transactions')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _txs.length,
              itemBuilder: (context, i) {
                final t = _txs[i];
                return ListTile(
                  title: Text(t['transaction_number']?.toString() ?? t['id']?.toString() ?? ''),
                  subtitle: Text('Status: ${t['status'] ?? '—'}'),
                  trailing: const Icon(Icons.timeline),
                  onTap: () => context.push(
                    '/employee/legal/transactions/${t['id']}',
                  ),
                );
              },
            ),
    );
  }
}

class TransactionTimelineScreen extends StatefulWidget {
  const TransactionTimelineScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  State<TransactionTimelineScreen> createState() =>
      _TransactionTimelineScreenState();
}

class _TransactionTimelineScreenState extends State<TransactionTimelineScreen> {
  late LegalRepository _repo;
  bool _loading = true;
  List<Map<String, dynamic>> _steps = const [];

  static const _defaults = [
    ('identity', 'Identity'),
    ('documents', 'Documents'),
    ('contract', 'Contract'),
    ('escrow', 'Escrow'),
    ('ownership_document', 'Ownership document'),
    ('settlement', 'Settlement'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = LegalRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    var steps = await _repo.listTransactionSteps(widget.transactionId);
    if (steps.isEmpty) {
      // Show canonical timeline until steps are persisted for this deal.
      steps = [
        for (var i = 0; i < _defaults.length; i++)
          {
            'step_key': _defaults[i].$1,
            'label': _defaults[i].$2,
            'status': i == 0 ? 'active' : 'pending',
            'step_order': i,
          },
      ];
    }
    if (!mounted) return;
    setState(() {
      _steps = steps;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _steps.cast<Map<String, dynamic>?>().firstWhere(
          (s) => s?['status'] == 'active',
          orElse: () => null,
        );
    return Scaffold(
      appBar: AppBar(title: Text('TX ${widget.transactionId.substring(0, 8)}…')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (active != null) ...[
                  Text(
                    'Current step',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    active['label']?.toString() ??
                        active['step_key']?.toString() ??
                        '',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ..._steps.map((s) {
                  final status = s['status']?.toString() ?? 'pending';
                  final icon = status == 'completed'
                      ? Icons.check_circle
                      : (status == 'active'
                          ? Icons.radio_button_checked
                          : (status == 'skipped'
                              ? Icons.skip_next
                              : Icons.radio_button_unchecked));
                  return ListTile(
                    leading: Icon(icon),
                    title: Text(
                      s['label']?.toString() ??
                          (s['step_key']?.toString() ?? '').replaceAll('_', ' '),
                    ),
                    subtitle: Text(status),
                  );
                }),
              ],
            ),
    );
  }
}

class OwnershipTransfersScreen extends StatefulWidget {
  const OwnershipTransfersScreen({super.key});

  @override
  State<OwnershipTransfersScreen> createState() =>
      _OwnershipTransfersScreenState();
}

class _OwnershipTransfersScreenState extends State<OwnershipTransfersScreen> {
  late LegalRepository _repo;
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = LegalRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listOwnershipTransfers();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ownership transfers')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final o = _items[i];
                return ListTile(
                  title: Text(o['government_office']?.toString() ?? 'Transfer'),
                  subtitle: Text(
                    '${o['reference_number'] ?? ''} · ${o['location_text'] ?? ''}',
                  ),
                );
              },
            ),
    );
  }
}
