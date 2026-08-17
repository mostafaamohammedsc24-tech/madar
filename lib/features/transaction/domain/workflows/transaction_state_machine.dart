import '../enums/transaction_enums.dart';

/// Allowed transitions — backend must enforce the same rules.
class TransactionStateMachine {
  const TransactionStateMachine();

  static const Map<TransactionState, Set<TransactionState>> _edges = {
    TransactionState.created: {
      TransactionState.waitingForParties,
      TransactionState.cancelled,
    },
    TransactionState.waitingForParties: {
      TransactionState.partiesVerified,
      TransactionState.expired,
      TransactionState.cancelled,
      TransactionState.onHold,
    },
    TransactionState.partiesVerified: {
      TransactionState.documentsRequired,
      TransactionState.onHold,
      TransactionState.cancelled,
    },
    TransactionState.documentsRequired: {
      TransactionState.documentsReview,
      TransactionState.onHold,
      TransactionState.cancelled,
    },
    TransactionState.documentsReview: {
      TransactionState.documentsRequired, // rejection → re-upload
      TransactionState.contractDraft,
      TransactionState.onHold,
      TransactionState.cancelled,
    },
    TransactionState.contractDraft: {
      TransactionState.contractPendingSignature,
      TransactionState.onHold,
      TransactionState.cancelled,
    },
    TransactionState.contractPendingSignature: {
      TransactionState.contractExecuted,
      TransactionState.contractDraft,
      TransactionState.onHold,
      TransactionState.cancelled,
    },
    TransactionState.contractExecuted: {
      TransactionState.escrowPending,
      TransactionState.onHold,
      TransactionState.disputed,
    },
    TransactionState.escrowPending: {
      TransactionState.escrowConfirmed,
      TransactionState.onHold,
      TransactionState.disputed,
      TransactionState.cancelled,
    },
    TransactionState.escrowConfirmed: {
      TransactionState.deedPending,
      TransactionState.settlementPending, // agricultural skip path
      TransactionState.onHold,
      TransactionState.disputed,
    },
    TransactionState.deedPending: {
      TransactionState.deedVerified,
      TransactionState.onHold,
      TransactionState.disputed,
    },
    TransactionState.deedVerified: {
      TransactionState.settlementPending,
      TransactionState.onHold,
    },
    TransactionState.settlementPending: {
      TransactionState.settlementCompleted,
      TransactionState.onHold,
      TransactionState.disputed,
    },
    TransactionState.settlementCompleted: {
      TransactionState.completed,
    },
    TransactionState.onHold: {
      // resume depends on prior state — stored as resume_state in DB
      TransactionState.waitingForParties,
      TransactionState.partiesVerified,
      TransactionState.documentsRequired,
      TransactionState.documentsReview,
      TransactionState.contractDraft,
      TransactionState.contractPendingSignature,
      TransactionState.escrowPending,
      TransactionState.deedPending,
      TransactionState.settlementPending,
      TransactionState.cancelled,
      TransactionState.disputed,
    },
    TransactionState.disputed: {
      TransactionState.onHold,
      TransactionState.cancelled,
      TransactionState.rejected,
    },
  };

  bool canTransition(TransactionState from, TransactionState to) {
    if (from == to) return false;
    if (from.isTerminal) return false;
    return _edges[from]?.contains(to) ?? false;
  }

  Set<TransactionState> allowedFrom(TransactionState from) =>
      _edges[from] ?? const {};

  /// Maps high-level user progress steps (1–6) for residential Iraq sale.
  /// Agricultural workflows may remap step 5.
  int userFacingStepIndex(TransactionState state) {
    switch (state) {
      case TransactionState.created:
      case TransactionState.waitingForParties:
      case TransactionState.partiesVerified:
        return 0; // Identity
      case TransactionState.documentsRequired:
      case TransactionState.documentsReview:
        return 1; // Documents
      case TransactionState.contractDraft:
      case TransactionState.contractPendingSignature:
      case TransactionState.contractExecuted:
        return 2; // Contract
      case TransactionState.escrowPending:
      case TransactionState.escrowConfirmed:
        return 3; // Escrow
      case TransactionState.deedPending:
      case TransactionState.deedVerified:
        return 4; // Deed / ownership
      case TransactionState.settlementPending:
      case TransactionState.settlementCompleted:
      case TransactionState.completed:
        return 5; // Settlement
      default:
        return 0;
    }
  }
}
