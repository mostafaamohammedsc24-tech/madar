import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

class OmCreateOfficeScreen extends StatefulWidget {
  const OmCreateOfficeScreen({super.key});

  @override
  State<OmCreateOfficeScreen> createState() => _OmCreateOfficeScreenState();
}

class _OmCreateOfficeScreenState extends State<OmCreateOfficeScreen> {
  final _name = TextEditingController();
  final _owner = TextEditingController();
  final _ownerPhone = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _address = TextEditingController();
  final _license = TextEditingController();
  String _country = 'IQ';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _owner.dispose();
    _ownerPhone.dispose();
    _phone.dispose();
    _email.dispose();
    _city.dispose();
    _region.dispose();
    _address.dispose();
    _license.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    final repo = context.read<EmployeeAuthNotifier>().repository;
    setState(() => _busy = true);
    final res = await repo.createOffice(
      name: _name.text.trim(),
      ownerFullName: _owner.text.trim(),
      ownerPhone: _ownerPhone.text.trim(),
      officePhone: _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      countryCode: _country,
      city: _city.text.trim(),
      region: _region.text.trim(),
      address: _address.text.trim(),
      licenseNumber: _license.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? loc.empActionFailed)),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.empOfficeCreated),
        content: Text(
          '${loc.empOfficeCode}: ${res.officeCode}\n'
          '${loc.empTemporarySecret}: ${res.secret}\n\n'
          '${loc.empOfficePendingNote}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.empClose),
          ),
        ],
      ),
    );
    if (mounted) context.go('/employee/om/offices');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(loc.empAddOffice, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: loc.empOfficeName,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _owner,
          decoration: InputDecoration(
            labelText: loc.empOwnerName,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ownerPhone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: loc.empOwnerPhone,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: loc.empOfficePhone,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          decoration: InputDecoration(
            labelText: loc.empEmail,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _country,
          items: const [
            DropdownMenuItem(value: 'IQ', child: Text('IQ')),
          ],
          onChanged: (v) => setState(() => _country = v ?? 'IQ'),
          decoration: InputDecoration(
            labelText: loc.empCountry,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _city,
          decoration: InputDecoration(
            labelText: loc.empCity,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _region,
          decoration: InputDecoration(
            labelText: loc.empRegion,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _address,
          decoration: InputDecoration(
            labelText: loc.empAddress,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _license,
          decoration: InputDecoration(
            labelText: loc.empLicense,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy || _name.text.trim().isEmpty ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.empCreateOffice),
        ),
      ],
    );
  }
}
