import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../features/authentication/routing/auth_globals.dart';
import '../../../../presentation/transactions_screen/widgets/barcode_upload_widget.dart';
import '../../../../services/supabase_service.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/enums/transaction_enums.dart';
import '../../domain/models/deal_transaction.dart';
import '../../domain/workflows/transaction_workflow.dart';

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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.85,
        child: BarcodeUploadWidget(
          onUpload: () {},
          onBarcodeScanned: (code) async {
            Navigator.of(ctx).pop();
            await _handleBarcode(code);
          },
        ),
      ),
    );
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _handleBarcode(String code) async {
    final loc = AppLocalizations.of(context);
    final phone = userAuthNotifier.state.fullPhoneNumber;

    // Peek barcode to infer party side
    final peek =
        await SupabaseService.instance.getTransactionByBarcode(code);
    if (peek == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.barcodeNotFound)),
      );
      return;
    }

    final userId = SupabaseService.instance.currentUser?.id ?? '';
    var side = _repo.inferPartySide(
      barcodeRow: peek,
      userId: userId,
      userPhone: phone,
    );

    if (side == null) {
      side = await _askPartySide(loc);
      if (side == null) return;
    }

    final result = await _repo.redeemBarcode(
      barcodeCode: code,
      partySide: side,
    );

    if (!mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.barcodeRedeemFailed)),
      );
      return;
    }

    await _load();

    if (result.bothPartiesVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.bothPartiesVerified)),
      );
    } else if (result.waitingForOtherParty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.waitingForOtherParty)),
      );
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

  Future<PartySide?> _askPartySide(AppLocalizations loc) async {
    return showModalBottomSheet<PartySide>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(loc.selectYourRole)),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(loc.roleBuyer),
              onTap: () => Navigator.pop(ctx, PartySide.buyer),
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(loc.roleSeller),
              onTap: () => Navigator.pop(ctx, PartySide.seller),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
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

/// Simple user-facing transaction detail with timeline.
/// Staff/lawyer actions are not faked here.
class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    this.initial,
  });

  final String transactionId;
  final DealTransaction? initial;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _repo = TransactionRepository();
  DealTransaction? _tx;
  List<TransactionAuditEvent> _audit = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tx = widget.initial;
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final tx = await _repo.getById(widget.transactionId);
    final audit = await _repo.listAudit(widget.transactionId);
    if (!mounted) return;
    setState(() {
      _tx = tx ?? _tx;
      _audit = audit;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tx = _tx;

    return Scaffold(
      appBar: AppBar(
        title: Text(tx?.transactionNumber ?? loc.navDeals),
      ),
      body: _loading && tx == null
          ? const Center(child: CircularProgressIndicator())
          : tx == null
              ? Center(child: Text(loc.transactionNotFound))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      Text(
                        tx.transactionNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _friendlyState(loc, tx.state),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (tx.propertyAddressSnapshot != null) ...[
                        const SizedBox(height: 8),
                        Text(tx.propertyAddressSnapshot!),
                      ],
                      if (tx.salePrice != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${tx.currencyCode} ${tx.salePrice!.round()}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        loc.txProgress,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildSteps(loc, tx),
                      const SizedBox(height: 24),
                      Text(
                        loc.txAuditTimeline,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_audit.isEmpty)
                        Text(
                          loc.txNoAuditYet,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        ..._audit.map(
                          (e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: const Icon(Icons.circle, size: 10),
                            title: Text(e.message),
                            subtitle: Text(
                              e.createdAt.toLocal().toString().split('.').first,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        loc.txBackendEnforcedNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildSteps(AppLocalizations loc, DealTransaction tx) {
    final workflow = _repo.workflowFor(tx);
    final current = tx.progressStepIndex;
    return [
      for (var i = 0; i < workflow.steps.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(
                i < current || tx.state == TransactionState.completed
                    ? Icons.check_circle
                    : i == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                color: i <= current
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _stepLabel(loc, workflow.steps[i].key),
                  style: TextStyle(
                    fontWeight:
                        i == current ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
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

  String _friendlyState(AppLocalizations loc, TransactionState state) {
    switch (state) {
      case TransactionState.waitingForParties:
        return loc.waitingForOtherParty;
      case TransactionState.partiesVerified:
        return loc.bothPartiesVerified;
      case TransactionState.escrowPending:
        return loc.awaitingDepositConfirmation;
      case TransactionState.completed:
        return loc.transactionCompleted;
      case TransactionState.onHold:
        return loc.txTabOnHold;
      default:
        return state.wireValue.replaceAll('_', ' ');
    }
  }
}
