import 'package:flutter/foundation.dart';

import '../../employee/publishing/domain/publishing_models.dart';
import '../../office/domain/models/office_models.dart';
import '../../transaction/domain/enums/transaction_enums.dart';
import '../../transaction/domain/models/deal_transaction.dart';
import '../../transaction/domain/workflows/transaction_state_machine.dart';
import '../../../services/office_seed.dart';
import '../../../services/publisher_seed.dart';
import '../domain/deal_workflow_models.dart';

/// In-app orchestrator that connects office deals, party barcodes,
/// publisher assets, and employee role queues into one readable workflow.
///
/// Seed barcodes (always resolvable offline):
/// - BUY-SEED-001 / SEL-SEED-001 … party barcodes for office seed deals
/// - PUB-88421011 … publisher public property ids
class DealWorkflowStore extends ChangeNotifier {
  DealWorkflowStore._();
  static final DealWorkflowStore instance = DealWorkflowStore._();

  final _machine = const TransactionStateMachine();
  final Map<String, TransactionState> _overrides = {};
  final Map<String, _SeedBarcode> _seedBarcodes = {};
  final Map<String, Map<String, dynamic>> _liveDeals = {};
  bool _booted = false;

  void ensureSeeded() {
    if (_booted) return;
    _booted = true;

    // Link office seed transactions to buyer/seller barcodes.
    final txs = OfficeSeed.transactions();
    for (var i = 0; i < txs.length; i++) {
      final tx = txs[i];
      final id = tx['id']?.toString() ?? 'seed-txn-$i';
      final state = TransactionState.fromWire(
        tx['lifecycle_state']?.toString(),
      );
      _overrides[id] = state;

      final buy = 'BUY-SEED-${(i + 1).toString().padLeft(3, '0')}';
      final sel = 'SEL-SEED-${(i + 1).toString().padLeft(3, '0')}';
      _seedBarcodes[buy] = _SeedBarcode(
        code: buy,
        kind: BarcodeKind.buyerDeal,
        transactionId: id,
        partySide: PartySide.buyer,
        label: tx['property_address_snapshot']?.toString() ?? id,
        lifecycleState: state,
        transactionMap: tx,
      );
      _seedBarcodes[sel] = _SeedBarcode(
        code: sel,
        kind: BarcodeKind.sellerDeal,
        transactionId: id,
        partySide: PartySide.seller,
        label: tx['property_address_snapshot']?.toString() ?? id,
        lifecycleState: state,
        transactionMap: tx,
      );
    }

    // Publisher assets → PUB-{public_id}
    for (final asset in PublisherSeed.assets()) {
      final code = 'PUB-${asset.publicPropertyId}';
      _seedBarcodes[code] = _SeedBarcode(
        code: code,
        kind: BarcodeKind.publishingAsset,
        publishingAssetId: asset.id,
        publicPropertyId: asset.publicPropertyId,
        label: asset.addressText ?? asset.publicPropertyId,
      );
      // Also accept raw public id.
      _seedBarcodes[asset.publicPropertyId] = _seedBarcodes[code]!;
    }
  }

  List<DealWorkflowStage> stagesForTransaction(String transactionId) {
    ensureSeeded();
    final state = _overrides[transactionId] ??
        TransactionState.waitingForParties;
    return DealWorkflowBlueprint.stagesFor(state);
  }

  TransactionState stateOf(String transactionId) {
    ensureSeeded();
    return _overrides[transactionId] ?? TransactionState.waitingForParties;
  }

  /// Advance a deal to the next legal lifecycle state and return the new owner.
  ({bool ok, TransactionState? next, WorkflowRoleOwner? owner, String? message})
      advance(String transactionId) {
    ensureSeeded();
    final from = stateOf(transactionId);
    final allowed = _machine.allowedFrom(from);
    // Prefer the "happy path" successor (first non-hold/cancel).
    TransactionState? next;
    for (final candidate in allowed) {
      if (candidate == TransactionState.onHold ||
          candidate == TransactionState.cancelled ||
          candidate == TransactionState.disputed ||
          candidate == TransactionState.expired) {
        continue;
      }
      next = candidate;
      break;
    }
    if (next == null) {
      return (
        ok: false,
        next: null,
        owner: null,
        message: 'no_transition',
      );
    }
    _overrides[transactionId] = next;
    final owner = _ownerFor(next);
    notifyListeners();
    return (ok: true, next: next, owner: owner, message: null);
  }

  WorkflowRoleOwner _ownerFor(TransactionState state) {
    final stages = DealWorkflowBlueprint.stagesFor(state);
    for (final s in stages) {
      if (s.state == state) return s.owner;
    }
    // Match by blueprint key of current state group.
    final key = DealWorkflowBlueprint.stagesFor(state)
        .map((e) => e.key)
        .toSet();
    for (final s in stages) {
      if (key.contains(s.key) && s.state == state) return s.owner;
    }
    return stages.isEmpty ? WorkflowRoleOwner.system : stages.first.owner;
  }

  ResolvedBarcode? resolve(String raw) {
    ensureSeeded();
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) return null;

    final seed = _seedBarcodes[code] ??
        _seedBarcodes[raw.trim()] ??
        _seedBarcodes[code.replaceFirst(RegExp(r'^MADAR:'), '')];
    if (seed != null) {
      return ResolvedBarcode(
        rawCode: seed.code,
        kind: seed.kind,
        transactionId: seed.transactionId,
        partySide: seed.partySide,
        publishingAssetId: seed.publishingAssetId,
        publicPropertyId: seed.publicPropertyId,
        label: seed.label,
        lifecycleState: seed.transactionId != null
            ? stateOf(seed.transactionId!)
            : seed.lifecycleState,
        workflowStages: seed.transactionId != null
            ? stagesForTransaction(seed.transactionId!)
            : const [],
      );
    }

    if (code.startsWith('BUY-') || code.startsWith('SEL-')) {
      return ResolvedBarcode(
        rawCode: code,
        kind: code.startsWith('BUY-')
            ? BarcodeKind.buyerDeal
            : BarcodeKind.sellerDeal,
        partySide:
            code.startsWith('BUY-') ? PartySide.buyer : PartySide.seller,
      );
    }
    if (code.startsWith('PUB-')) {
      return ResolvedBarcode(
        rawCode: code,
        kind: BarcodeKind.publishingAsset,
        publicPropertyId: code.substring(4),
      );
    }
    if (code.startsWith('IQ-')) {
      return ResolvedBarcode(
        rawCode: code,
        kind: BarcodeKind.transactionNumber,
        label: code,
      );
    }
    return null;
  }

  /// Demo deals shown on the workflow board.
  List<Map<String, dynamic>> boardDeals() {
    ensureSeeded();
    final seeded = [
      for (final tx in OfficeSeed.transactions())
        {
          ...tx,
          'lifecycle_state': stateOf(tx['id']!.toString()).wireValue,
          'buyer_barcode': _buyerCodeFor(tx['id']!.toString()),
          'seller_barcode': _sellerCodeFor(tx['id']!.toString()),
          'stages': stagesForTransaction(tx['id']!.toString()),
        },
    ];
    final live = [
      for (final e in _liveDeals.entries)
        {
          ...e.value,
          'lifecycle_state': stateOf(e.key).wireValue,
          'buyer_barcode': _buyerCodeFor(e.key),
          'seller_barcode': _sellerCodeFor(e.key),
          'stages': stagesForTransaction(e.key),
        },
    ];
    return [...live, ...seeded];
  }

  String? _buyerCodeFor(String txId) {
    for (final e in _seedBarcodes.entries) {
      if (e.value.transactionId == txId &&
          e.value.kind == BarcodeKind.buyerDeal) {
        return e.key;
      }
    }
    return null;
  }

  String? _sellerCodeFor(String txId) {
    for (final e in _seedBarcodes.entries) {
      if (e.value.transactionId == txId &&
          e.value.kind == BarcodeKind.sellerDeal) {
        return e.key;
      }
    }
    return null;
  }

  List<PropertyAsset> publishingQueue() {
    ensureSeeded();
    return PublisherSeed.assets();
  }

  OfficeAccount office() {
    ensureSeeded();
    return OfficeSeed.account();
  }

  /// Register a live (non-seed) barcode after office creation so the reader
  /// can open the deal immediately in this session.
  void registerLiveDealBarcodes({
    required String transactionId,
    required String buyerBarcode,
    required String sellerBarcode,
    required Map<String, dynamic> transactionMap,
  }) {
    ensureSeeded();
    _overrides.putIfAbsent(
      transactionId,
      () => TransactionState.waitingForParties,
    );
    _liveDeals[transactionId] = {
      ...transactionMap,
      'id': transactionId,
    };
    _seedBarcodes[buyerBarcode.trim().toUpperCase()] = _SeedBarcode(
      code: buyerBarcode.trim().toUpperCase(),
      kind: BarcodeKind.buyerDeal,
      transactionId: transactionId,
      partySide: PartySide.buyer,
      label: transactionMap['property_address_snapshot']?.toString(),
      lifecycleState: TransactionState.waitingForParties,
      transactionMap: transactionMap,
    );
    _seedBarcodes[sellerBarcode.trim().toUpperCase()] = _SeedBarcode(
      code: sellerBarcode.trim().toUpperCase(),
      kind: BarcodeKind.sellerDeal,
      transactionId: transactionId,
      partySide: PartySide.seller,
      label: transactionMap['property_address_snapshot']?.toString(),
      lifecycleState: TransactionState.waitingForParties,
      transactionMap: transactionMap,
    );
    notifyListeners();
  }

  DealTransaction? seedTransaction(String id) {
    ensureSeeded();
    for (final tx in OfficeSeed.transactions()) {
      if (tx['id']?.toString() == id) {
        final map = Map<String, dynamic>.from(tx);
        map['lifecycle_state'] = stateOf(id).wireValue;
        return DealTransaction.fromMap(map);
      }
    }
    return null;
  }
}

class _SeedBarcode {
  const _SeedBarcode({
    required this.code,
    required this.kind,
    this.transactionId,
    this.partySide,
    this.publishingAssetId,
    this.publicPropertyId,
    this.label,
    this.lifecycleState,
    this.transactionMap,
  });

  final String code;
  final BarcodeKind kind;
  final String? transactionId;
  final PartySide? partySide;
  final String? publishingAssetId;
  final String? publicPropertyId;
  final String? label;
  final TransactionState? lifecycleState;
  final Map<String, dynamic>? transactionMap;
}
