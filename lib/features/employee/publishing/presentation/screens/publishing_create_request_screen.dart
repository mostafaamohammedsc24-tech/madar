import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/publishing_repository.dart';
import '../../domain/publisher_ops_models.dart';
import '../theme/publisher_tokens.dart';

/// 3-step create publishing request: source → basics → confirm.
class PublishingCreateRequestScreen extends StatefulWidget {
  const PublishingCreateRequestScreen({super.key});

  @override
  State<PublishingCreateRequestScreen> createState() =>
      _PublishingCreateRequestScreenState();
}

class _PublishingCreateRequestScreenState
    extends State<PublishingCreateRequestScreen> {
  int _step = 0;
  String _sourceKind = 'office'; // office | user
  final _officeCode = TextEditingController(text: 'OFF001');
  final _userPhone = TextEditingController();
  final _userId = TextEditingController();
  final _city = TextEditingController(text: 'بغداد');
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _description = TextEditingController();
  String _type = 'apartment';
  String _tx = 'sale';
  String _priority = 'normal';
  bool _busy = false;
  OfficeLookupResult? _office;
  UserLookupResult? _user;
  String? _lookupError;

  static const _types = [
    'house',
    'apartment',
    'villa',
    'land',
    'agricultural',
    'commercial',
    'shop',
    'office',
    'building',
    'warehouse',
    'farm',
    'investment',
    'mixed_use',
    'compound',
    'other',
  ];

  static const _txs = [
    'sale',
    'rent',
    'mortgage',
    'investment',
    'lease_to_own',
    'other',
  ];

  @override
  void dispose() {
    _officeCode.dispose();
    _userPhone.dispose();
    _userId.dispose();
    _city.dispose();
    _address.dispose();
    _contact.dispose();
    _description.dispose();
    super.dispose();
  }

  PublishingRepository get _repo => PublishingRepository(
        context.read<EmployeeAuthNotifier>().repository,
      );

  void _lookupSource() {
    setState(() {
      _lookupError = null;
      _office = null;
      _user = null;
    });
    if (_sourceKind == 'office') {
      final hit = _repo.lookupOffice(_officeCode.text);
      if (hit == null) {
        setState(() => _lookupError = 'Office not found. Try OFF001 or OFC-88421.');
      } else {
        setState(() => _office = hit);
      }
    } else {
      final hit = _repo.lookupUser(
        phone: _userPhone.text,
        userId: _userId.text,
      );
      if (hit == null) {
        setState(() =>
            _lookupError = 'User not found. Try +9647701112233 or USR-10021.');
      } else {
        setState(() {
          _user = hit;
          if (_contact.text.isEmpty) _contact.text = hit.phone;
        });
      }
    }
  }

  bool get _sourceReady =>
      (_sourceKind == 'office' && _office != null) ||
      (_sourceKind == 'user' && _user != null);

  Future<void> _create() async {
    if (!_sourceReady) return;
    setState(() => _busy = true);
    final ownerName = _sourceKind == 'office'
        ? (_office!.ownerName)
        : (_user!.name);
    final res = await _repo.createRequest(
      propertyType: _type,
      transactionType: _tx,
      source: _sourceKind == 'office' ? 'office' : 'madar_user',
      ownerName: ownerName,
      ownerPhone: _contact.text.trim().isEmpty
          ? (_user?.phone ?? '')
          : _contact.text.trim(),
      officeId: _office?.id,
      reporterLabel: _user?.id,
      city: _city.text.trim(),
      addressText: _address.text.trim(),
      notes: _description.text.trim().isEmpty ? null : _description.text.trim(),
      priority: _priority,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Failed to create request')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Property ID generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Permanent operational identifier:'),
            const SizedBox(height: 12),
            SelectableText(
              res.publicId ?? '',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: PublisherTokens.primary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: res.publicId ?? ''));
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Property ID'),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Open workspace'),
          ),
        ],
      ),
    );
    if (mounted) {
      context.go('/employee/publishing/property/${res.assetId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublisherTokens.background,
      appBar: AppBar(
        title: const Text('Create Publishing Request'),
        backgroundColor: PublisherTokens.card,
        foregroundColor: PublisherTokens.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _StepHeader(step: _step),
          const SizedBox(height: 20),
          if (_step == 0) _buildSourceStep(),
          if (_step == 1) _buildBasicsStep(),
          if (_step == 2) _buildConfirmStep(),
          const SizedBox(height: 24),
          Row(
            children: [
              if (_step > 0)
                OutlinedButton(
                  onPressed: _busy ? null : () => setState(() => _step--),
                  child: const Text('Back'),
                ),
              const Spacer(),
              if (_step < 2)
                FilledButton(
                  onPressed: () {
                    if (_step == 0) {
                      if (!_sourceReady) {
                        _lookupSource();
                        if (!_sourceReady) return;
                      }
                    }
                    setState(() => _step++);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: PublisherTokens.secondary,
                  ),
                  child: const Text('Continue'),
                )
              else
                FilledButton(
                  onPressed: _busy ? null : _create,
                  style: FilledButton.styleFrom(
                    backgroundColor: PublisherTokens.primary,
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create request'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Property source',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Associate this request with an office or a Madar user.',
          style: TextStyle(color: PublisherTokens.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SourceCard(
                selected: _sourceKind == 'office',
                title: 'Office',
                subtitle: 'Enter office code',
                icon: Icons.storefront_outlined,
                onTap: () => setState(() {
                  _sourceKind = 'office';
                  _user = null;
                  _lookupError = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SourceCard(
                selected: _sourceKind == 'user',
                title: 'Madar User',
                subtitle: 'Phone or User ID',
                icon: Icons.person_outline,
                onTap: () => setState(() {
                  _sourceKind = 'user';
                  _office = null;
                  _lookupError = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_sourceKind == 'office') ...[
          TextField(
            controller: _officeCode,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Office code',
              hintText: 'OFC-XXXX or OFF001',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _lookupSource,
            child: const Text('Retrieve office'),
          ),
          if (_office != null) ...[
            const SizedBox(height: 12),
            _InfoBox(
              title: _office!.name,
              rows: [
                ('Office ID', _office!.id),
                ('Code', _office!.code),
                ('Owner', _office!.ownerName),
                ('Region', _office!.region),
                ('Status', _office!.status),
              ],
            ),
          ],
        ] else ...[
          TextField(
            controller: _userPhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'User phone',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userId,
            decoration: const InputDecoration(
              labelText: 'Madar User ID',
              hintText: 'USR-10021',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _lookupSource,
            child: const Text('Retrieve user'),
          ),
          if (_user != null) ...[
            const SizedBox(height: 12),
            _InfoBox(
              title: _user!.name,
              rows: [
                ('User ID', _user!.id),
                ('Phone', _user!.phone),
                ('Location', _user!.location),
              ],
            ),
          ],
        ],
        if (_lookupError != null) ...[
          const SizedBox(height: 12),
          Text(
            _lookupError!,
            style: const TextStyle(color: Color(0xFFBA1A1A)),
          ),
        ],
      ],
    );
  }

  Widget _buildBasicsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Basic property information',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _type,
          items: [
            for (final t in _types)
              DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' '))),
          ],
          onChanged: (v) => setState(() => _type = v ?? 'apartment'),
          decoration: const InputDecoration(
            labelText: 'Property type',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _tx,
          items: [
            for (final t in _txs)
              DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' '))),
          ],
          onChanged: (v) => setState(() => _tx = v ?? 'sale'),
          decoration: const InputDecoration(
            labelText: 'Transaction type',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _city,
          decoration: const InputDecoration(
            labelText: 'City / location',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _address,
          decoration: const InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contact,
          decoration: const InputDecoration(
            labelText: 'Contact number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Initial description',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _priority,
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Low')),
            DropdownMenuItem(value: 'normal', child: Text('Normal')),
            DropdownMenuItem(value: 'high', child: Text('High')),
            DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
          ],
          onChanged: (v) => setState(() => _priority = v ?? 'normal'),
          decoration: const InputDecoration(
            labelText: 'Priority',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Confirm & create',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'An 8-digit Property Publishing ID will be generated permanently.',
          style: TextStyle(color: PublisherTokens.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        _InfoBox(
          title: 'Request summary',
          rows: [
            (
              'Source',
              _sourceKind == 'office'
                  ? 'Office · ${_office?.code ?? '—'}'
                  : 'User · ${_user?.id ?? '—'}'
            ),
            ('Type', _type.replaceAll('_', ' ')),
            ('Transaction', _tx.replaceAll('_', ' ')),
            ('Location', '${_city.text} · ${_address.text}'),
            ('Contact', _contact.text),
            ('Priority', _priority),
          ],
        ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Source', 'Basics', 'Create'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 1,
                color: i <= step
                    ? PublisherTokens.secondary
                    : PublisherTokens.outlineVariant,
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: i <= step
                  ? PublisherTokens.primary
                  : PublisherTokens.surfaceLow,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${i + 1}. ${labels[i]}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: i <= step ? Colors.white : PublisherTokens.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? PublisherTokens.primary.withValues(alpha: 0.06)
          : PublisherTokens.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? PublisherTokens.secondary
                  : const Color(0xFFE2E8F0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected
                    ? PublisherTokens.secondary
                    : PublisherTokens.onSurfaceVariant,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: PublisherTokens.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PublisherTokens.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      r.$1,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PublisherTokens.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
