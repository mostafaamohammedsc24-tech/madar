import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../features/authentication/routing/auth_globals.dart';
import '../../../../presentation/transactions_screen/widgets/barcode_upload_widget.dart';
import '../../../../services/supabase_service.dart';
import '../../data/party_deal_store.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/enums/transaction_enums.dart';
import '../../domain/models/deal_transaction.dart';
import '../../domain/workflows/transaction_workflow.dart';
import 'transaction_detail_screen.dart';

/// Digital Transaction Center — user-facing deals home.
/// Does not fake stage completion; backend gates drive progress.
class TransactionCenterScreen extends StatefulWidget {
  const TransactionCenterScreen({super.key});

  @override
  State<TransactionCenterScreen> createState() =>
      _TransactionCenterScreenState();
}

class _TransactionCenterScreenState extends State<TransactionCenterScreen>
    with SingleTickerProviderStateMixin {
  final _repo = TransactionRepository();
  final _barcodeCtrl = TextEditingController();
  late TabController _tabs;
  bool _loading = true;
  List<DealTransaction> _items = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listForCurrentUser();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  List<DealTransaction> _bucket(TransactionListBucket b) =>
      _items.where((t) => t.listBucket == b).toList();

  Future<void> _openBarcodeScanner() async {
    setState(() => _scanning = true);
    await BarcodeUploadWidget.show(
      context,
      onUpload: () {
        final typed = _barcodeCtrl.text.trim();
        if (typed.isNotEmpty) {
          _handleBarcode(typed);
        }
      },
      onBarcodeScanned: (code) {
        _handleBarcode(code);
      },
    );
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _handleBarcode(String code) async {
    final loc = AppLocalizations.of(context);
    final phone = userAuthNotifier.state.fullPhoneNumber;

    // Peek barcode to infer party side
    final peek = await SupabaseService.instance.getTransactionByBarcode(code);
    if (peek == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.barcodeNotFound)));
      return;
    }

    final userId = SupabaseService.instance.currentUser?.id ?? '';
    final side = _repo.inferPartySide(
      barcodeRow: peek,
      userId: userId,
      userPhone: phone,
    );

    if (side == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.barcodeRoleFromOfficeOnly)),
      );
      return;
    }

    final result = await _repo.redeemBarcode(
      barcodeCode: code,
      partySide: side,
    );

    if (!mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.barcodeRedeemFailed)));
      return;
    }

    if (result.transaction != null) {
      final progress = PartyDealStore.of(result.transaction!.id);
      progress.mySide = side;
      if (side == PartySide.buyer) {
        progress.buyerBarcode = true;
      } else {
        progress.sellerBarcode = true;
      }
    }

    await _load();

    if (result.bothPartiesVerified) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.bothPartiesVerified)));
    } else if (result.waitingForOtherParty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.waitingForOtherParty)));
    }

    if (result.transaction != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(
            transactionId: result.transaction!.id,
            initial: result.transaction,
          ),
        ),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.digitalTransactionCenter,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _barcodeCtrl,
                      decoration: InputDecoration(
                        hintText: loc.barcodeHint,
                        prefixIcon: const Icon(Icons.qr_code_2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) _handleBarcode(v.trim());
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final v = _barcodeCtrl.text.trim();
                      if (v.isNotEmpty) _handleBarcode(v);
                    },
                    child: Text(loc.joinDeal),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabs: [
                Tab(text: loc.txTabActive),
                Tab(text: loc.txTabCompleted),
                Tab(text: loc.txTabCancelled),
                Tab(text: loc.txTabOnHold),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _list(_bucket(TransactionListBucket.active), loc),
                        _list(_bucket(TransactionListBucket.completed), loc),
                        _list(_bucket(TransactionListBucket.cancelled), loc),
                        _list(_bucket(TransactionListBucket.onHold), loc),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanning ? null : _openBarcodeScanner,
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(loc.uploadTransactionBarcode),
      ),
    );
  }

  Widget _list(List<DealTransaction> items, AppLocalizations loc) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                loc.noTransactionsInTab,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _openBarcodeScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(loc.uploadTransactionBarcode),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final tx = items[i];
          final workflow = _repo.workflowFor(tx);
          return _TransactionCard(
            tx: tx,
            workflow: workflow,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TransactionDetailScreen(
                    transactionId: tx.id,
                    initial: tx,
                  ),
                ),
              );
              await _load();
            },
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.tx,
    required this.workflow,
    required this.onTap,
  });

  final DealTransaction tx;
  final TransactionWorkflowDefinition workflow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final step = tx.progressStepIndex;
    final stepTitle = step < workflow.steps.length
        ? _stepLabel(loc, workflow.steps[step].key)
        : loc.txCurrentStep;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tx.transactionNumber,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StateChip(state: tx.state),
                ],
              ),
              if (tx.propertyAddressSnapshot != null) ...[
                const SizedBox(height: 6),
                Text(
                  tx.propertyAddressSnapshot!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Text(
                '${loc.txCurrentStep}: $stepTitle',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: tx.progressFraction,
                  minHeight: 6,
                ),
              ),
              if (tx.state == TransactionState.waitingForParties) ...[
                const SizedBox(height: 8),
                Text(
                  loc.barcodeProgress(tx.barcodeProgressCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _stepLabel(AppLocalizations loc, String key) {
    switch (key) {
      case 'identity':
        return loc.stepIdentity;
      case 'documents':
        return loc.stepDocuments;
      case 'contract':
        return loc.stepContract;
      case 'escrow':
        return loc.stepEscrow;
      case 'deed':
        return loc.stepDeed;
      case 'agricultural_transfer':
        return loc.stepAgriculturalTransfer;
      case 'settlement':
        return loc.stepSettlement;
      default:
        return key;
    }
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});
  final TransactionState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label(loc),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  String _label(AppLocalizations loc) {
    switch (state.listBucket) {
      case TransactionListBucket.active:
        return loc.txTabActive;
      case TransactionListBucket.completed:
        return loc.txTabCompleted;
      case TransactionListBucket.cancelled:
        return loc.txTabCancelled;
      case TransactionListBucket.onHold:
        return loc.txTabOnHold;
    }
  }
}
