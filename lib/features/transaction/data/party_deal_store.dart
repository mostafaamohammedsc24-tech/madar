import '../domain/enums/transaction_enums.dart';

enum DocReviewStatus { missing, underReview, approved }

/// In-memory party progress so buyer/seller can actually act in the deal UI.
class PartyDealProgress {
  PartyDealProgress();

  /// Role assigned by the office/agent barcode — not chosen by the user.
  PartySide? mySide;

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
  final Map<String, DocReviewStatus> buyerDocStatus = {};
  final Map<String, DocReviewStatus> sellerDocStatus = {};
  final Set<String> buyerUploadedDocs = {};
  final Set<String> sellerUploadedDocs = {};
  final List<Map<String, String>> receipts = [];
  String? buyerSignature;
  String? sellerSignature;

  bool get isBuyer => mySide != PartySide.seller;

  bool get myIdentityDone => isBuyer ? buyerIdentity : sellerIdentity;

  bool get bothIdentity => buyerIdentity && sellerIdentity;
  bool get bothDocs => buyerDocs && sellerDocs;
  bool get bothContracts => buyerContractUploaded && sellerContractUploaded;
  bool get bothSigned => buyerSigned && sellerSigned;

  DocReviewStatus docStatusFor(String field, {required bool asBuyer}) {
    final map = asBuyer ? buyerDocStatus : sellerDocStatus;
    return map[field] ?? DocReviewStatus.missing;
  }

  void markDocUnderReview(String field, {required bool asBuyer}) {
    final map = asBuyer ? buyerDocStatus : sellerDocStatus;
    map[field] = DocReviewStatus.underReview;
    final uploaded = asBuyer ? buyerUploadedDocs : sellerUploadedDocs;
    uploaded.add(field);
  }

  void markDocApproved(String field, {required bool asBuyer}) {
    final map = asBuyer ? buyerDocStatus : sellerDocStatus;
    map[field] = DocReviewStatus.approved;
    final uploaded = asBuyer ? buyerUploadedDocs : sellerUploadedDocs;
    uploaded.add(field);
    _syncDocsFlag(asBuyer: asBuyer);
  }

  void _syncDocsFlag({required bool asBuyer}) {
    final map = asBuyer ? buyerDocStatus : sellerDocStatus;
    final allApproved = lawyerDocFields.every(
      (f) => map[f] == DocReviewStatus.approved,
    );
    if (asBuyer) {
      buyerDocs = allApproved;
    } else {
      sellerDocs = allApproved;
    }
  }

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
  }
}
