import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../providers/office_auth_notifier.dart';

class OfficeSupportScreen extends StatefulWidget {
  const OfficeSupportScreen({super.key});

  @override
  State<OfficeSupportScreen> createState() => _OfficeSupportScreenState();
}

class _OfficeSupportScreenState extends State<OfficeSupportScreen> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<OfficeAuthNotifier>().repository;
    setState(() => _loading = true);
    final list = await repo.listSupportTickets();
    if (!mounted) return;
    setState(() {
      _tickets = list;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final loc = AppLocalizations.of(context);
    final repo = context.read<OfficeAuthNotifier>().repository;
    setState(() => _busy = true);
    final ok = await repo.createSupportTicket(
      subject: _subjectCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.officeActionFailed)),
      );
      return;
    }
    _subjectCtrl.clear();
    _bodyCtrl.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: Text(loc.officeSupport)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(loc.officeOpenTicket, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _subjectCtrl,
            decoration: InputDecoration(
              labelText: loc.officeTicketSubject,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: loc.officeTicketBody,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy || _subjectCtrl.text.trim().isEmpty
                ? null
                : _create,
            child: Text(loc.officeSubmitTicket),
          ),
          const SizedBox(height: 28),
          Text(loc.officeYourTickets, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_tickets.isEmpty)
            Text(loc.officeNoTickets)
          else
            ..._tickets.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  title: Text(t['subject']?.toString() ?? ''),
                  subtitle: Text(
                    '${loc.officeStatus}: ${t['status'] ?? ''} · '
                    '${t['assigned_team'] ?? 'office_management'}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
