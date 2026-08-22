import '../enums/legal_enums.dart';

class LegalStaff {
  const LegalStaff({
    required this.id,
    required this.employeeId,
    required this.displayName,
    this.role = 'contract_lawyer',
    this.countryCode = 'IQ',
  });

  final String id;
  final String employeeId;
  final String displayName;
  final String role;
  final String countryCode;
}

class LegalParty {
  const LegalParty({
    required this.side,
    required this.name,
    required this.madarUserId,
    required this.phone,
    required this.country,
    required this.nationalIdMasked,
    this.identityStatus = VerificationWatch.pending,
    this.documentStatus = LegalDocumentStatus.required,
    this.otpStatus = VerificationWatch.pending,
    this.faceStatus = VerificationWatch.pending,
    this.signatureStatus = SignatureWatch.pending,
    this.confirmation = PartyConfirmation.pending,
    this.rejectionReason,
    this.rejectedAt,
    this.faceCapturePath,
  });

  final String side;
  final String name;
  final String madarUserId;
  final String phone;
  final String country;
  final String nationalIdMasked;
  final VerificationWatch identityStatus;
  final LegalDocumentStatus documentStatus;
  final VerificationWatch otpStatus;
  final VerificationWatch faceStatus;
  final SignatureWatch signatureStatus;
  final PartyConfirmation confirmation;
  final String? rejectionReason;
  final DateTime? rejectedAt;
  final String? faceCapturePath;

  LegalParty copyWith({
    VerificationWatch? identityStatus,
    LegalDocumentStatus? documentStatus,
    VerificationWatch? otpStatus,
    VerificationWatch? faceStatus,
    SignatureWatch? signatureStatus,
    PartyConfirmation? confirmation,
    String? rejectionReason,
    DateTime? rejectedAt,
    String? faceCapturePath,
  }) {
    return LegalParty(
      side: side,
      name: name,
      madarUserId: madarUserId,
      phone: phone,
      country: country,
      nationalIdMasked: nationalIdMasked,
      identityStatus: identityStatus ?? this.identityStatus,
      documentStatus: documentStatus ?? this.documentStatus,
      otpStatus: otpStatus ?? this.otpStatus,
      faceStatus: faceStatus ?? this.faceStatus,
      signatureStatus: signatureStatus ?? this.signatureStatus,
      confirmation: confirmation ?? this.confirmation,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      faceCapturePath: faceCapturePath ?? this.faceCapturePath,
    );
  }
}

class LegalDocVersion {
  const LegalDocVersion({
    required this.version,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.previewLabel,
  });

  final int version;
  final LegalDocumentStatus status;
  final DateTime createdAt;
  final String? rejectionReason;
  final String? previewLabel;
}

class LegalDocumentReq {
  const LegalDocumentReq({
    required this.id,
    required this.name,
    required this.party,
    required this.required,
    required this.status,
    this.deadline,
    this.notes,
    this.versions = const [],
  });

  final String id;
  final String name;
  final String party;
  final bool required;
  final LegalDocumentStatus status;
  final DateTime? deadline;
  final String? notes;
  final List<LegalDocVersion> versions;

  LegalDocumentReq copyWith({
    LegalDocumentStatus? status,
    String? notes,
    List<LegalDocVersion>? versions,
    DateTime? deadline,
    bool? required,
  }) {
    return LegalDocumentReq(
      id: id,
      name: name,
      party: party,
      required: required ?? this.required,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      notes: notes ?? this.notes,
      versions: versions ?? this.versions,
    );
  }
}

class LegalContractSection {
  const LegalContractSection({
    required this.id,
    required this.title,
    required this.body,
    this.clauseId,
  });

  final String id;
  final String title;
  final String body;
  final String? clauseId;

  LegalContractSection copyWith({String? body, String? clauseId}) {
    return LegalContractSection(
      id: id,
      title: title,
      body: body ?? this.body,
      clauseId: clauseId ?? this.clauseId,
    );
  }
}

class LegalContractVersion {
  const LegalContractVersion({
    required this.version,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.modifiedBy,
    required this.modifiedAt,
    required this.changeNotes,
    required this.sections,
    this.locked = false,
    this.sentToBuyer = false,
    this.sentToSeller = false,
  });

  final int version;
  final ContractVersionStatus status;
  final String createdBy;
  final DateTime createdAt;
  final String modifiedBy;
  final DateTime modifiedAt;
  final String changeNotes;
  final List<LegalContractSection> sections;
  final bool locked;
  final bool sentToBuyer;
  final bool sentToSeller;

  String get label => 'V$version';

  LegalContractVersion copyWith({
    ContractVersionStatus? status,
    String? modifiedBy,
    DateTime? modifiedAt,
    String? changeNotes,
    List<LegalContractSection>? sections,
    bool? locked,
    bool? sentToBuyer,
    bool? sentToSeller,
  }) {
    return LegalContractVersion(
      version: version,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      changeNotes: changeNotes ?? this.changeNotes,
      sections: sections ?? this.sections,
      locked: locked ?? this.locked,
      sentToBuyer: sentToBuyer ?? this.sentToBuyer,
      sentToSeller: sentToSeller ?? this.sentToSeller,
    );
  }
}

class LegalNote {
  const LegalNote({
    required this.id,
    required this.visibility,
    required this.body,
    required this.author,
    required this.at,
  });

  final String id;
  final LegalNoteVisibility visibility;
  final String body;
  final String author;
  final DateTime at;
}

class LegalChatMessage {
  const LegalChatMessage({
    required this.id,
    required this.channel,
    required this.body,
    required this.author,
    required this.at,
    this.internal = false,
  });

  final String id;
  final LegalMessageChannel channel;
  final String body;
  final String author;
  final DateTime at;
  final bool internal;
}

class LegalAuditEvent {
  const LegalAuditEvent({
    required this.id,
    required this.action,
    required this.result,
    required this.lawyerId,
    required this.at,
    required this.transactionNumber,
  });

  final String id;
  final String action;
  final String result;
  final String lawyerId;
  final DateTime at;
  final String transactionNumber;
}

class LegalNotification {
  const LegalNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.caseId,
    this.read = false,
  });

  final String id;
  final String kind;
  final String title;
  final String body;
  final DateTime at;
  final String? caseId;
  final bool read;
}

class RentToOwnTerms {
  const RentToOwnTerms({
    required this.propertyPrice,
    required this.monthlyPayment,
    required this.agreedMonthly,
    required this.durationMonths,
    required this.ownershipTransferCondition,
    required this.scheduleSummary,
    this.initialPayment,
  });

  final String propertyPrice;
  final String monthlyPayment;
  final String agreedMonthly;
  final int durationMonths;
  final String ownershipTransferCondition;
  final String scheduleSummary;
  final String? initialPayment;
}

class LegalReviewChecks {
  const LegalReviewChecks({
    this.buyerIdentity = false,
    this.sellerIdentity = false,
    this.propertyOwnership = false,
    this.propertyInformation = false,
    this.requiredDocuments = false,
    this.transactionPrice = false,
    this.paymentTerms = false,
    this.specialConditions = false,
    this.additionalLegal = false,
  });

  final bool buyerIdentity;
  final bool sellerIdentity;
  final bool propertyOwnership;
  final bool propertyInformation;
  final bool requiredDocuments;
  final bool transactionPrice;
  final bool paymentTerms;
  final bool specialConditions;
  final bool additionalLegal;

  bool get allRequired =>
      buyerIdentity &&
      sellerIdentity &&
      propertyOwnership &&
      propertyInformation &&
      requiredDocuments &&
      transactionPrice &&
      paymentTerms &&
      specialConditions &&
      additionalLegal;

  LegalReviewChecks copyWith({
    bool? buyerIdentity,
    bool? sellerIdentity,
    bool? propertyOwnership,
    bool? propertyInformation,
    bool? requiredDocuments,
    bool? transactionPrice,
    bool? paymentTerms,
    bool? specialConditions,
    bool? additionalLegal,
  }) {
    return LegalReviewChecks(
      buyerIdentity: buyerIdentity ?? this.buyerIdentity,
      sellerIdentity: sellerIdentity ?? this.sellerIdentity,
      propertyOwnership: propertyOwnership ?? this.propertyOwnership,
      propertyInformation: propertyInformation ?? this.propertyInformation,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      transactionPrice: transactionPrice ?? this.transactionPrice,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      specialConditions: specialConditions ?? this.specialConditions,
      additionalLegal: additionalLegal ?? this.additionalLegal,
    );
  }
}

class LegalCase {
  const LegalCase({
    required this.id,
    required this.transactionNumber,
    required this.contractNumber,
    required this.transactionType,
    required this.propertyId,
    required this.propertyAddress,
    required this.propertyType,
    required this.area,
    required this.price,
    required this.authorizedAmount,
    required this.ownershipInfo,
    required this.officeName,
    required this.assignedLawyer,
    required this.lawyerEmployeeId,
    required this.stage,
    required this.statusLabel,
    required this.priority,
    required this.requiredAction,
    required this.lastActivity,
    required this.buyer,
    required this.seller,
    required this.documents,
    required this.contracts,
    required this.audit,
    this.barcode,
    this.specialLegalConditions,
    this.rentToOwn,
    this.review = const LegalReviewChecks(),
    this.notes = const [],
    this.messages = const [],
    this.handoffComplete = false,
    this.handoffTarget,
    this.deadline,
  });

  final String id;
  final String transactionNumber;
  final String contractNumber;
  final String transactionType;
  final String propertyId;
  final String propertyAddress;
  final String propertyType;
  final String area;
  final String price;
  final String authorizedAmount;
  final String ownershipInfo;
  final String officeName;
  final String assignedLawyer;
  final String lawyerEmployeeId;
  final LegalContractStage stage;
  final String statusLabel;
  final LegalPriority priority;
  final LegalWorkAction requiredAction;
  final DateTime lastActivity;
  final LegalParty buyer;
  final LegalParty seller;
  final List<LegalDocumentReq> documents;
  final List<LegalContractVersion> contracts;
  final List<LegalAuditEvent> audit;
  final String? barcode;
  final String? specialLegalConditions;
  final RentToOwnTerms? rentToOwn;
  final LegalReviewChecks review;
  final List<LegalNote> notes;
  final List<LegalChatMessage> messages;
  final bool handoffComplete;
  final String? handoffTarget;
  final DateTime? deadline;

  LegalContractVersion? get currentContract =>
      contracts.isEmpty ? null : contracts.last;

  LegalCase copyWith({
    LegalContractStage? stage,
    String? statusLabel,
    LegalPriority? priority,
    LegalWorkAction? requiredAction,
    DateTime? lastActivity,
    LegalParty? buyer,
    LegalParty? seller,
    List<LegalDocumentReq>? documents,
    List<LegalContractVersion>? contracts,
    List<LegalAuditEvent>? audit,
    LegalReviewChecks? review,
    List<LegalNote>? notes,
    List<LegalChatMessage>? messages,
    bool? handoffComplete,
    String? handoffTarget,
    String? price,
  }) {
    return LegalCase(
      id: id,
      transactionNumber: transactionNumber,
      contractNumber: contractNumber,
      transactionType: transactionType,
      propertyId: propertyId,
      propertyAddress: propertyAddress,
      propertyType: propertyType,
      area: area,
      price: price ?? this.price,
      authorizedAmount: authorizedAmount,
      ownershipInfo: ownershipInfo,
      officeName: officeName,
      assignedLawyer: assignedLawyer,
      lawyerEmployeeId: lawyerEmployeeId,
      stage: stage ?? this.stage,
      statusLabel: statusLabel ?? this.statusLabel,
      priority: priority ?? this.priority,
      requiredAction: requiredAction ?? this.requiredAction,
      lastActivity: lastActivity ?? this.lastActivity,
      buyer: buyer ?? this.buyer,
      seller: seller ?? this.seller,
      documents: documents ?? this.documents,
      contracts: contracts ?? this.contracts,
      audit: audit ?? this.audit,
      barcode: barcode,
      specialLegalConditions: specialLegalConditions,
      rentToOwn: rentToOwn,
      review: review ?? this.review,
      notes: notes ?? this.notes,
      messages: messages ?? this.messages,
      handoffComplete: handoffComplete ?? this.handoffComplete,
      handoffTarget: handoffTarget ?? this.handoffTarget,
      deadline: deadline,
    );
  }
}

class AuthorizedClause {
  const AuthorizedClause({
    required this.id,
    required this.category,
    required this.titleAr,
    required this.titleEn,
    required this.titleKu,
    required this.templateRef,
  });

  final String id;
  final String category;
  final String titleAr;
  final String titleEn;
  final String titleKu;
  final String templateRef;

  String title(AppLang lang) {
    switch (lang) {
      case AppLang.ar:
        return titleAr;
      case AppLang.ku:
        return titleKu;
      case AppLang.en:
        return titleEn;
    }
  }
}

enum AppLang { ar, en, ku }
