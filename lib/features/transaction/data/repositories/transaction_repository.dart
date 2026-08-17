import '../../../../services/supabase_service.dart';
import '../../domain/enums/transaction_enums.dart';
import '../../domain/models/deal_transaction.dart';
import '../../domain/workflows/transaction_workflow.dart';

class TransactionRepository {
  TransactionRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;

  Future<List<DealTransaction>> listForCurrentUser() async {
    final rows = await _supabase.getUserTransactions();
    return rows.map(DealTransaction.fromMap).toList();
  }

  Future<DealTransaction?> getById(String id) async {
    final row = await _supabase.getTransactionById(id);
    if (row == null) return null;
    return DealTransaction.fromMap(row);
  }

  TransactionWorkflowDefinition workflowFor(DealTransaction tx) {
    if (tx.type == DealTransactionType.agricultural) {
      return TransactionWorkflowDefinition.iraqAgriculturalSale();
    }
    return TransactionWorkflowDefinition.iraqResidentialSale();
  }

  /// Dual-party barcode redemption via DB function when available.
  /// Falls back to client-side dual columns if RPC missing.
  Future<BarcodeRedemptionResult> redeemBarcode({
    required String barcodeCode,
    required PartySide partySide,
  }) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) {
      return const BarcodeRedemptionResult(
        success: false,
        transaction: null,
        bothPartiesVerified: false,
        message: 'not_authenticated',
      );
    }

    final side = partySide == PartySide.buyer ? 'buyer' : 'seller';

    try {
      final rpc = await _supabase.client.rpc(
        'redeem_transaction_barcode',
        params: {
          'p_barcode_code': barcodeCode,
          'p_user_id': userId,
          'p_party_side': side,
        },
      );

      if (rpc is Map) {
        final map = Map<String, dynamic>.from(rpc);
        if (map['success'] != true) {
          return BarcodeRedemptionResult(
            success: false,
            transaction: null,
            bothPartiesVerified: false,
            message: map['message']?.toString(),
          );
        }
        final txId = map['transaction_id']?.toString();
        DealTransaction? tx;
        if (txId != null) tx = await getById(txId);
        final both = map['both_parties_verified'] == true;
        return BarcodeRedemptionResult(
          success: true,
          transaction: tx,
          bothPartiesVerified: both,
          waitingForOtherParty: map['waiting_for_other_party'] == true,
          message: both ? 'both_verified' : 'waiting_for_other_party',
        );
      }
    } catch (_) {
      // RPC may not be deployed yet — controlled fallback below.
    }

    return _fallbackRedeem(barcodeCode: barcodeCode, partySide: partySide);
  }

  Future<BarcodeRedemptionResult> _fallbackRedeem({
    required String barcodeCode,
    required PartySide partySide,
  }) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) {
      return const BarcodeRedemptionResult(
        success: false,
        transaction: null,
        bothPartiesVerified: false,
        message: 'not_authenticated',
      );
    }

    final barcodeRow =
        await _supabase.getTransactionByBarcode(barcodeCode);
    if (barcodeRow == null) {
      return const BarcodeRedemptionResult(
        success: false,
        transaction: null,
        bothPartiesVerified: false,
        message: 'barcode_not_found',
      );
    }

    final barcodeId = barcodeRow['id']?.toString();
    final txMap = barcodeRow['transactions'] as Map<String, dynamic>?;
    if (barcodeId == null || txMap == null) {
      return const BarcodeRedemptionResult(
        success: false,
        transaction: null,
        bothPartiesVerified: false,
        message: 'invalid_barcode_payload',
      );
    }

    final txId = txMap['id']?.toString();
    if (txId == null) {
      return const BarcodeRedemptionResult(
        success: false,
        transaction: null,
        bothPartiesVerified: false,
        message: 'missing_transaction',
      );
    }

    final updates = <String, dynamic>{};
    final txUpdates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};

    if (partySide == PartySide.buyer) {
      updates['buyer_redeemed_at'] = DateTime.now().toIso8601String();
      updates['buyer_redeemed_by_user_id'] = userId;
      txUpdates['buyer_barcode_uploaded'] = true;
      txUpdates['buyer_user_id'] = userId;
    } else {
      updates['seller_redeemed_at'] = DateTime.now().toIso8601String();
      updates['seller_redeemed_by_user_id'] = userId;
      txUpdates['seller_barcode_uploaded'] = true;
      txUpdates['seller_user_id'] = userId;
    }

    try {
      await _supabase.client
          .from('transaction_barcodes')
          .update(updates)
          .eq('id', barcodeId);
      await _supabase.client.from('transactions').update(txUpdates).eq('id', txId);

      // Re-read to check both sides
      final refreshed = await getById(txId);
      final both = refreshed?.bothBarcodesUploaded == true;

      if (both) {
        await _supabase.client.from('transactions').update({
          'lifecycle_state': TransactionState.partiesVerified.wireValue,
          'current_step_key': 'identity',
          'buyer_barcode_uploaded': true,
          'seller_barcode_uploaded': true,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', txId);
        await _appendAudit(
          txId,
          'parties_verified',
          'Both parties barcode verified — transaction activated',
        );
      } else {
        await _supabase.client.from('transactions').update({
          'lifecycle_state': TransactionState.waitingForParties.wireValue,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', txId);
        await _appendAudit(
          txId,
          'barcode_uploaded',
          '${partySide.name} barcode uploaded — waiting for other party',
          actorRole: partySide.name,
        );
      }

      final finalTx = await getById(txId);
      return BarcodeRedemptionResult(
        success: true,
        transaction: finalTx,
        bothPartiesVerified: both,
        waitingForOtherParty: !both,
        message: both ? 'both_verified' : 'waiting_for_other_party',
      );
    } catch (e) {
      return BarcodeRedemptionResult(
        success: false,
        transaction: null,
        bothPartiesVerified: false,
        message: 'redeem_failed',
      );
    }
  }

  Future<List<TransactionAuditEvent>> listAudit(String transactionId) async {
    try {
      final rows = await _supabase.client
          .from('transaction_audit_events')
          .select()
          .eq('transaction_id', transactionId)
          .order('created_at', ascending: true);
      return (rows as List)
          .whereType<Map>()
          .map((e) => TransactionAuditEvent.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _appendAudit(
    String transactionId,
    String eventType,
    String message, {
    String? actorRole,
  }) async {
    try {
      await _supabase.client.from('transaction_audit_events').insert({
        'transaction_id': transactionId,
        'event_type': eventType,
        'message': message,
        'actor_user_id': _supabase.currentUser?.id,
        'actor_role': actorRole,
      });
    } catch (_) {
      // Audit table may not exist until migration applied.
    }
  }

  /// Infer party side from phone match / existing linkage when possible.
  PartySide? inferPartySide({
    required Map<String, dynamic> barcodeRow,
    required String userId,
    String? userPhone,
  }) {
    final tx = barcodeRow['transactions'];
    if (tx is! Map) return null;
    final map = Map<String, dynamic>.from(tx);
    if (map['buyer_user_id']?.toString() == userId) return PartySide.buyer;
    if (map['seller_user_id']?.toString() == userId) return PartySide.seller;

    final buyerPhone = map['buyer_phone'] as String? ??
        barcodeRow['buyer_phone'] as String?;
    final sellerPhone = map['seller_phone'] as String? ??
        barcodeRow['seller_phone'] as String?;
    if (userPhone != null && userPhone.isNotEmpty) {
      final normalized = userPhone.replaceAll(RegExp(r'\D'), '');
      if (buyerPhone != null &&
          buyerPhone.replaceAll(RegExp(r'\D'), '').endsWith(
                normalized.length > 8
                    ? normalized.substring(normalized.length - 8)
                    : normalized,
              )) {
        return PartySide.buyer;
      }
      if (sellerPhone != null &&
          sellerPhone.replaceAll(RegExp(r'\D'), '').endsWith(
                normalized.length > 8
                    ? normalized.substring(normalized.length - 8)
                    : normalized,
              )) {
        return PartySide.seller;
      }
    }
    return null;
  }
}
