import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/office_models.dart';
import '../providers/office_auth_notifier.dart';

class OfficeCreateTransactionScreen extends StatefulWidget {
  const OfficeCreateTransactionScreen({super.key});

  @override
  State<OfficeCreateTransactionScreen> createState() =>
      _OfficeCreateTransactionScreenState();
}

class _OfficeCreateTransactionScreenState
    extends State<OfficeCreateTransactionScreen> {
  final _buyerCtrl = TextEditingController();
  final _sellerCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _type = 'sale';
  bool _busy = false;
  OfficeBarcodeCreateResult? _result;

  static const _types = [
    'sale',
    'rent',
    'mortgage',
    'land',
    'commercial',
    'agricultural',
    'investment',
    'other',
  ];

  @override
  void dispose() {
    _buyerCtrl.dispose();
    _sellerCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final loc = AppLocalizations.of(context);
    final repo = context.read<OfficeAuthNotifier>().repository;
    setState(() => _busy = true);
    final result = await repo.createTransactionWithBarcodes(
      transactionType: _type,
      buyerPhone: _buyerCtrl.text.trim(),
      sellerPhone: _sellerCtrl.text.trim(),
      salePrice: double.tryParse(_priceCtrl.text.trim()),
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _busy = false;
    });
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? loc.officeActionFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: Text(loc.officeCreateTransaction)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(loc.officeTransactionType, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _type,
            items: _types
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? 'sale'),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sellerCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: loc.officeSellerPhone,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _buyerCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: loc.officeBuyerPhone,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: loc.officeTransactionValue,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ||
                    _buyerCtrl.text.trim().isEmpty ||
                    _sellerCtrl.text.trim().isEmpty
                ? null
                : _generate,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(loc.officeGenerateBarcode),
          ),
          if (_result?.success == true) ...[
            const SizedBox(height: 28),
            Text(
              '${loc.officeTransactionNumber}: ${_result!.transactionNumber}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              loc.officeBarcodesDelivered,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _QrBlock(
              label: loc.officeBuyerBarcode,
              data: _result!.buyerBarcode ?? '',
            ),
            const SizedBox(height: 16),
            _QrBlock(
              label: loc.officeSellerBarcode,
              data: _result!.sellerBarcode ?? '',
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => context.go('/office/transactions'),
              child: Text(loc.officeBackToTransactions),
            ),
          ],
        ],
      ),
    );
  }
}

class _QrBlock extends StatelessWidget {
  const _QrBlock({required this.label, required this.data});

  final String label;
  final String data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          if (data.isNotEmpty)
            QrImageView(
              data: data,
              size: 160,
              backgroundColor: Colors.white,
            ),
          const SizedBox(height: 8),
          SelectableText(
            data,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
