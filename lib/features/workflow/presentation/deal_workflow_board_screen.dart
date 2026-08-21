import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../transaction/domain/enums/transaction_enums.dart';
import '../data/deal_workflow_store.dart';
import '../domain/deal_workflow_models.dart';

/// Cross-role deal pipeline board (office → parties → lawyers → finance → closing → publish).
class DealWorkflowBoardScreen extends StatefulWidget {
  const DealWorkflowBoardScreen({super.key, this.initialDealId});

  final String? initialDealId;

  @override
  State<DealWorkflowBoardScreen> createState() =>
      _DealWorkflowBoardScreenState();
}

class _DealWorkflowBoardScreenState extends State<DealWorkflowBoardScreen> {
  late String? _selectedId;

  @override
  void initState() {
    super.initState();
    DealWorkflowStore.instance.ensureSeeded();
    final deals = DealWorkflowStore.instance.boardDeals();
    final want = widget.initialDealId;
    if (want != null &&
        deals.any((d) => d['id']?.toString() == want)) {
      _selectedId = want;
    } else {
      _selectedId = deals.isEmpty ? null : deals.first['id']?.toString();
    }
  }

  Map<String, dynamic>? get _selected {
    final id = _selectedId;
    if (id == null) return null;
    for (final d in DealWorkflowStore.instance.boardDeals()) {
      if (d['id']?.toString() == id) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final store = DealWorkflowStore.instance;
    final deals = store.boardDeals();
    final selected = _selected;
    final stages = selected == null
        ? <DealWorkflowStage>[]
        : (selected['stages'] as List<DealWorkflowStage>? ??
            store.stagesForTransaction(selected['id']!.toString()));
    final currentState = selected == null
        ? null
        : store.stateOf(selected['id']!.toString());
    String? currentKey;
    if (currentState != null) {
      final blueprint = DealWorkflowBlueprint.stagesFor(currentState);
      for (final s in blueprint) {
        if (s.state == currentState) {
          currentKey = s.key;
          break;
        }
      }
      currentKey ??= blueprint.isEmpty ? null : blueprint.first.key;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Deal workflow'),
        actions: [
          IconButton(
            tooltip: loc.scanBarcode,
            onPressed: () => context.push('/barcode-reader'),
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          Text(
            'One pipeline across office, buyer/seller, lawyers, finance, bank, closing, and publishing.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Deals',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...deals.map((d) {
            final id = d['id']?.toString() ?? '';
            final selectedRow = id == _selectedId;
            return ListTile(
              selected: selectedRow,
              selectedTileColor:
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                d['property_address_snapshot']?.toString() ?? id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${d['transaction_number'] ?? id} · ${d['lifecycle_state']}',
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => setState(() => _selectedId = id),
            );
          }),
          if (selected != null) ...[
            const SizedBox(height: 20),
            Text(
              'Role handoffs',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Buyer ${selected['buyer_barcode'] ?? '—'} · Seller ${selected['seller_barcode'] ?? '—'}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...stages.map((stage) {
              final active = stage.key == currentKey;
              final done = currentState != null &&
                  _isBefore(stage, currentState, stages, currentKey);
              return _StageTile(
                stage: stage,
                active: active,
                done: done,
                onOpen: stage.routeHint == null
                    ? null
                    : () => context.push(stage.routeHint!),
              );
            }),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                final id = selected['id']!.toString();
                final result = store.advance(id);
                if (!mounted) return;
                setState(() {});
                final msg = result.ok
                    ? 'Advanced to ${result.next!.wireValue} · owner ${_ownerLabel(result.owner!)}'
                    : 'Cannot advance (${result.message})';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Advance to next role'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push('/barcode-reader'),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(loc.scanBarcode),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            'Published property barcodes',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...store.publishingQueue().map((asset) {
            final code = 'PUB-${asset.publicPropertyId}';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.qr_code_2),
              title: Text(asset.addressText ?? asset.publicPropertyId),
              subtitle: Text(
                code,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => context.push(
                '/employee/publishing/property/${asset.id}',
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isBefore(
    DealWorkflowStage stage,
    TransactionState current,
    List<DealWorkflowStage> stages,
    String? currentKey,
  ) {
    if (currentKey == null) return false;
    final keys = stages.map((s) => s.key).toList();
    final si = keys.indexOf(stage.key);
    final ci = keys.indexOf(currentKey);
    if (si < 0 || ci < 0) return false;
    return si < ci;
  }

  String _ownerLabel(WorkflowRoleOwner owner) {
    switch (owner) {
      case WorkflowRoleOwner.office:
        return 'Office';
      case WorkflowRoleOwner.buyerSeller:
        return 'Buyer / Seller';
      case WorkflowRoleOwner.publisher:
        return 'Publisher';
      case WorkflowRoleOwner.information:
        return 'Information';
      case WorkflowRoleOwner.photography:
        return 'Photography';
      case WorkflowRoleOwner.engineering:
        return 'Engineering';
      case WorkflowRoleOwner.contractLawyer:
        return 'Contract lawyer';
      case WorkflowRoleOwner.transactionLawyer:
        return 'Transaction lawyer';
      case WorkflowRoleOwner.finance:
        return 'Finance';
      case WorkflowRoleOwner.bank:
        return 'Bank';
      case WorkflowRoleOwner.closing:
        return 'Closing';
      case WorkflowRoleOwner.system:
        return 'System';
    }
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.stage,
    required this.active,
    required this.done,
    this.onOpen,
  });

  final DealWorkflowStage stage;
  final bool active;
  final bool done;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? theme.colorScheme.primary
        : done
            ? theme.colorScheme.tertiary
            : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  done
                      ? Icons.check_circle
                      : active
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                  color: color,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.titleEn,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    _ownerShort(stage.owner),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (stage.subtitleEn != null)
                    Text(
                      stage.subtitleEn!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (onOpen != null)
              Icon(
                Icons.open_in_new,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  String _ownerShort(WorkflowRoleOwner owner) {
    switch (owner) {
      case WorkflowRoleOwner.office:
        return 'Office';
      case WorkflowRoleOwner.buyerSeller:
        return 'Parties';
      case WorkflowRoleOwner.publisher:
        return 'Publisher';
      case WorkflowRoleOwner.information:
        return 'Information';
      case WorkflowRoleOwner.photography:
        return 'Photography';
      case WorkflowRoleOwner.engineering:
        return 'Engineering';
      case WorkflowRoleOwner.contractLawyer:
        return 'Contract lawyer';
      case WorkflowRoleOwner.transactionLawyer:
        return 'Transaction lawyer';
      case WorkflowRoleOwner.finance:
        return 'Finance / Bank';
      case WorkflowRoleOwner.bank:
        return 'Bank';
      case WorkflowRoleOwner.closing:
        return 'Closing';
      case WorkflowRoleOwner.system:
        return 'System';
    }
  }
}
