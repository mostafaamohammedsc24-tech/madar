import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/ops_repository.dart';
import '../../../../../services/twilio_verify_service.dart';

class ClosingCasesScreen extends StatefulWidget {
  const ClosingCasesScreen({super.key});

  @override
  State<ClosingCasesScreen> createState() => _ClosingCasesScreenState();
}

class _ClosingCasesScreenState extends State<ClosingCasesScreen> {
  late OpsRepository _repo;
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = OpsRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listClosingCases();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final buyer = TextEditingController();
    final seller = TextEditingController();
    final property = TextEditingController();
    final price = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: buyer,
              decoration: const InputDecoration(
                labelText: 'Buyer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: seller,
              decoration: const InputDecoration(
                labelText: 'Seller',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: property,
              decoration: const InputDecoration(
                labelText: 'Property ref / ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: price,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Start closing'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final res = await _repo.createClosingCase(
      buyerName: buyer.text.trim(),
      sellerName: seller.text.trim(),
      propertyRef: property.text.trim(),
      priceText: price.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success ? 'Case ${res.code}' : (res.message ?? 'Failed'),
        ),
      ),
    );
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Closing cases'),
        actions: [
          IconButton(onPressed: _create, icon: const Icon(Icons.add)),
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
                    title: Text(c['case_code']?.toString() ?? ''),
                    subtitle: Text(
                      '${c['buyer_name']} ↔ ${c['seller_name']}\n'
                      '${c['property_ref']} · ${c['status']}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (s) async {
                        await _repo.updateClosingStatus(c['id'].toString(), s);
                        _load();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'verifying', child: Text('Verifying')),
                        PopupMenuItem(value: 'barcode', child: Text('Barcode')),
                        PopupMenuItem(value: 'with_lawyer', child: Text('With lawyer')),
                        PopupMenuItem(value: 'handed_off', child: Text('Handed off')),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  late OpsRepository _repo;
  bool _loading = true;
  String _filter = 'open';
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = OpsRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listTickets(
      status: _filter == 'all' ? null : _filter,
    );
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final subject = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New ticket'),
        content: TextField(
          controller: subject,
          decoration: const InputDecoration(labelText: 'Subject'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true || subject.text.trim().isEmpty) return;
    final res = await _repo.createTicket(subject: subject.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.success ? res.code! : (res.message ?? 'Failed'))),
    );
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support tickets'),
        actions: [
          IconButton(onPressed: _create, icon: const Icon(Icons.add)),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final f in ['open', 'active', 'urgent', 'waiting', 'resolved', 'all'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _filter == f,
                      onSelected: (_) {
                        setState(() => _filter = f);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final t = _items[i];
                        return ListTile(
                          title: Text(t['subject']?.toString() ?? ''),
                          subtitle: Text('${t['ticket_code']} · ${t['status']} · ${t['priority']}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (s) async {
                              await _repo.updateTicketStatus(t['id'].toString(), s);
                              _load();
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'active', child: Text('Active')),
                              PopupMenuItem(value: 'urgent', child: Text('Urgent')),
                              PopupMenuItem(value: 'waiting', child: Text('Waiting')),
                              PopupMenuItem(value: 'resolved', child: Text('Resolved')),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class QualityReviewScreen extends StatefulWidget {
  const QualityReviewScreen({super.key});

  @override
  State<QualityReviewScreen> createState() => _QualityReviewScreenState();
}

class _QualityReviewScreenState extends State<QualityReviewScreen> {
  late OpsRepository _repo;
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = OpsRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listQualityQueue();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _decide(Map<String, dynamic> asset, String decision) async {
    final ok = await _repo.submitQualityReview(
      propertyAssetId: asset['id'].toString(),
      decision: decision,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Review recorded' : 'Review failed')),
    );
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quality review')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final a = _items[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROPERTY #${a['public_property_id']}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text('Status: ${a['pipeline_status']}'),
                          Text(
                            'Info ${a['information_pct']}% · Photo ${a['photography_pct']}% · '
                            '3D ${a['three_d_pct']}% · Plan ${a['floor_plan_pct']}%',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => context.push(
                                  '/employee/publishing/property/${a['id']}',
                                ),
                                child: const Text('Open'),
                              ),
                              FilledButton.tonal(
                                onPressed: () => _decide(a, 'approve'),
                                child: const Text('Approve'),
                              ),
                              OutlinedButton(
                                onPressed: () => _decide(a, 'request_correction'),
                                child: const Text('Correction'),
                              ),
                              TextButton(
                                onPressed: () => _decide(a, 'reject'),
                                child: const Text('Reject'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class ComplianceCasesScreen extends StatefulWidget {
  const ComplianceCasesScreen({super.key});

  @override
  State<ComplianceCasesScreen> createState() => _ComplianceCasesScreenState();
}

class _ComplianceCasesScreenState extends State<ComplianceCasesScreen> {
  late OpsRepository _repo;
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = OpsRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listComplianceCases();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final subject = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Compliance case'),
        content: TextField(
          controller: subject,
          decoration: const InputDecoration(labelText: 'Subject'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open')),
        ],
      ),
    );
    if (ok != true || subject.text.trim().isEmpty) return;
    final res = await _repo.createComplianceCase(subject: subject.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.success ? res.code! : (res.message ?? 'Failed'))),
    );
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance'),
        actions: [
          IconButton(onPressed: _create, icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final c = _items[i];
                return ListTile(
                  title: Text(c['subject']?.toString() ?? ''),
                  subtitle: Text(
                    '${c['case_code']} · ${c['status']} · risk ${c['risk_level']}',
                  ),
                );
              },
            ),
    );
  }
}

class SystemAdminScreen extends StatefulWidget {
  const SystemAdminScreen({super.key});

  @override
  State<SystemAdminScreen> createState() => _SystemAdminScreenState();
}

class _SystemAdminScreenState extends State<SystemAdminScreen> {
  late OpsRepository _repo;
  final _twilio = TwilioVerifyService();
  bool _loading = true;
  bool _twilioEnabled = false;
  String? _serviceSid;
  String _twilioStatus = 'unknown';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = OpsRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cfg = await _repo.loadSystemConfig('twilio.verify');
    final status = await _twilio.status();
    if (!mounted) return;
    final value = cfg?['value'];
    final map = value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
    setState(() {
      _twilioEnabled = map['enabled'] == true;
      _serviceSid = map['service_sid']?.toString();
      _twilioStatus = status.configured
          ? 'Edge credentials OK (${status.authMode})'
          : 'Edge credentials missing';
      _loading = false;
    });
  }

  Future<void> _ensureService() async {
    final res = await _twilio.ensureService();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? 'Service SID: ${res.serviceSid}'
              : (res.message ?? 'Failed'),
        ),
      ),
    );
    if (res.success && res.serviceSid != null) {
      await _repo.setTwilioEnabled(enabled: true, serviceSid: res.serviceSid);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System administration')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Technical configuration only — no contract or finance edits.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text('Twilio Verify SMS', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_twilioStatus),
                Text('Service SID: ${_serviceSid ?? '—'}'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Twilio Verify for OTP'),
                  value: _twilioEnabled,
                  onChanged: (v) async {
                    await _repo.setTwilioEnabled(
                      enabled: v,
                      serviceSid: _serviceSid,
                    );
                    _load();
                  },
                ),
                FilledButton.tonal(
                  onPressed: _ensureService,
                  child: const Text('Create / ensure Madar Verify service'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set secrets on Supabase: TWILIO_API_KEY, TWILIO_API_SECRET, '
                  'TWILIO_VERIFY_SERVICE_SID — never in the Flutter app.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Audit log'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/employee/audit'),
                ),
              ],
            ),
    );
  }
}

class ExecutiveDashboardScreen extends StatefulWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  State<ExecutiveDashboardScreen> createState() =>
      _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState extends State<ExecutiveDashboardScreen> {
  late OpsRepository _repo;
  bool _loading = true;
  Map<String, int> _snap = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = OpsRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await _repo.executiveSnapshot();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Executive overview')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Read-only operational snapshot',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final e in _snap.entries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.key),
                      trailing: Text(
                        '${e.value}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
