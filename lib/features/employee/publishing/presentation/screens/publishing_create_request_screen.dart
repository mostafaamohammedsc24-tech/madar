import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/publishing_repository.dart';

class PublishingCreateRequestScreen extends StatefulWidget {
  const PublishingCreateRequestScreen({super.key});

  @override
  State<PublishingCreateRequestScreen> createState() =>
      _PublishingCreateRequestScreenState();
}

class _PublishingCreateRequestScreenState
    extends State<PublishingCreateRequestScreen> {
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _builder = TextEditingController();
  final _notes = TextEditingController();
  String _type = 'house';
  String _tx = 'sale';
  String _source = 'office';
  String _priority = 'normal';
  bool _busy = false;

  @override
  void dispose() {
    _owner.dispose();
    _phone.dispose();
    _city.dispose();
    _address.dispose();
    _builder.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repo = PublishingRepository(
      context.read<EmployeeAuthNotifier>().repository,
    );
    setState(() => _busy = true);
    final builderNote = _builder.text.trim().isEmpty
        ? ''
        : 'Builder company: ${_builder.text.trim()}';
    final combinedNotes = [
      builderNote,
      _notes.text.trim(),
    ].where((s) => s.isNotEmpty).join('\n');
    final res = await repo.createRequest(
      propertyType: _type,
      transactionType: _tx,
      source: _source,
      ownerName: _owner.text.trim(),
      ownerPhone: _phone.text.trim(),
      city: _city.text.trim(),
      addressText: _address.text.trim(),
      notes: combinedNotes.isEmpty ? null : combinedNotes,
      priority: _priority,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Failed')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Property ID generated'),
        content: Text(
          'Property ID: ${res.publicId}\n\n'
          'This 8-digit ID is the central key for information, media, '
          'floor plans, and future user property cards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Create publishing request',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _source,
          items: const [
            DropdownMenuItem(value: 'office', child: Text('Office')),
            DropdownMenuItem(value: 'company', child: Text('Company')),
            DropdownMenuItem(value: 'owner', child: Text('Owner')),
            DropdownMenuItem(value: 'reporter', child: Text('Reporter')),
          ],
          onChanged: (v) => setState(() => _source = v ?? 'office'),
          decoration: const InputDecoration(
            labelText: 'Property source',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _owner,
          decoration: const InputDecoration(
            labelText: 'Owner',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Owner phone',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _type,
          items: const [
            DropdownMenuItem(value: 'house', child: Text('House')),
            DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
            DropdownMenuItem(value: 'land', child: Text('Land')),
            DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
          ],
          onChanged: (v) => setState(() => _type = v ?? 'house'),
          decoration: const InputDecoration(
            labelText: 'Property type',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _tx,
          items: const [
            DropdownMenuItem(value: 'sale', child: Text('Sale')),
            DropdownMenuItem(value: 'rent', child: Text('Rent')),
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
            labelText: 'City',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _address,
          decoration: const InputDecoration(
            labelText: 'Location / address',
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
          ],
          onChanged: (v) => setState(() => _priority = v ?? 'normal'),
          decoration: const InputDecoration(
            labelText: 'Priority',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _builder,
          decoration: const InputDecoration(
            labelText: 'Builder / contractor company',
            hintText: 'e.g. Al-Rasheed Construction',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        SafeArea(
          child: FilledButton(
            onPressed: _busy || _owner.text.trim().isEmpty || _phone.text.trim().isEmpty
                ? null
                : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create request'),
          ),
        ),
      ],
    );
  }
}
