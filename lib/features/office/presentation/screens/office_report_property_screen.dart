import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../providers/office_auth_notifier.dart';

class OfficeReportPropertyScreen extends StatefulWidget {
  const OfficeReportPropertyScreen({super.key});

  @override
  State<OfficeReportPropertyScreen> createState() =>
      _OfficeReportPropertyScreenState();
}

class _OfficeReportPropertyScreenState
    extends State<OfficeReportPropertyScreen> {
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _propertyType = 'house';
  String _listingType = 'sale';
  bool _busy = false;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    final repo = context.read<OfficeAuthNotifier>().repository;
    setState(() => _busy = true);
    final report = await repo.submitPropertyReport(
      propertyType: _propertyType,
      listingType: _listingType,
      addressText: _locationCtrl.text.trim(),
      ownerPhone: _phoneCtrl.text.trim(),
      estimatedPrice: double.tryParse(_priceCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.officeActionFailed)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.officeReportSubmitted)),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: Text(loc.officeReportProperty)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _propertyType,
            decoration: InputDecoration(
              labelText: loc.officePropertyType,
              border: const OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'house', child: Text('House')),
              DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
              DropdownMenuItem(value: 'land', child: Text('Land')),
              DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
            ],
            onChanged: (v) => setState(() => _propertyType = v ?? 'house'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _listingType,
            decoration: InputDecoration(
              labelText: loc.officeListingType,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'sale', child: Text(loc.officeFilterSale)),
              DropdownMenuItem(value: 'rent', child: Text(loc.officeFilterRent)),
            ],
            onChanged: (v) => setState(() => _listingType = v ?? 'sale'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationCtrl,
            decoration: InputDecoration(
              labelText: loc.officeLocation,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: loc.officeOwnerPhone,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: loc.officeEstimatedPrice,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: loc.officeAdditionalInfo,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy || _locationCtrl.text.trim().isEmpty
                ? null
                : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(loc.officeSendReport),
          ),
        ],
      ),
    );
  }
}
