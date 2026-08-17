import '../../../core/demo/demo_mode.dart';

/// In-memory party progress so buyer/seller can actually act in the deal UI.
class PartyDealProgress {
  PartyDealProgress();

  bool buyerBarcode = false;
  bool sellerBarcode = false;
  bool buyerIdentity = false;
  bool sellerIdentity = false;
  bool buyerDocs = false;
  bool sellerDocs = false;
  bool contractSent = false;
  bool buyerContractUploaded = false;
  bool sellerContractUploaded = false;
  bool buyerOtp = false;
  bool sellerOtp = false;
  bool buyerFace = false;
  bool sellerFace = false;
  bool buyerSigned = false;
  bool sellerSigned = false;
  bool escrowAmountSet = true;
  bool bankDepositConfirmed = false;
  bool buyerMoveInApproved = false;
  bool lawyerReleaseApproved = false;
  bool deedUploaded = false;
  bool settlementClosed = false;

  final List<String> lawyerDocFields = [
    'national_id',
    'proof_of_funds',
  ];
  final Set<String> buyerUploadedDocs = {};
  final Set<String> sellerUploadedDocs = {};
  final List<Map<String, String>> receipts = [];
  String? buyerSignature;
  String? sellerSignature;

  bool get bothIdentity => buyerIdentity && sellerIdentity;
  bool get bothDocs => buyerDocs && sellerDocs;
  bool get bothContracts => buyerContractUploaded && sellerContractUploaded;
  bool get bothSigned => buyerSigned && sellerSigned;

  int get currentStage {
    if (settlementClosed) return 6;
    if (!bothIdentity) return 1;
    if (!bothDocs) return 2;
    if (!bothSigned) return 3;
    if (!bankDepositConfirmed) return 4;
    if (!deedUploaded && !skipDeed) return 5;
    return 6;
  }

  bool skipDeed = false;
}

abstract final class PartyDealStore {
  static final Map<String, PartyDealProgress> _items = {};

  static PartyDealProgress of(String transactionId) {
    return _items.putIfAbsent(transactionId, PartyDealProgress.new);
  }

  static void seedIfNeeded(String transactionId, {required bool agricultural}) {
    final p = of(transactionId);
    p.skipDeed = agricultural;
    if (!DemoMode.enabled) return;
    if (transactionId == 'demo_txn_001') {
      p.buyerIdentity = true;
      p.sellerIdentity = true;
      p.buyerDocs = true;
      p.sellerDocs = true;
      p.contractSent = true;
      p.buyerContractUploaded = true;
      p.sellerContractUploaded = true;
      p.buyerOtp = true;
      p.sellerOtp = true;
      p.buyerFace = true;
      p.sellerFace = true;
      p.buyerSigned = true;
      p.sellerSigned = true;
    }
  }
}
