import '../enums/closing_enums.dart';

class ClosingStaff {
  const ClosingStaff({
    required this.id,
    required this.employeeId,
    required this.displayName,
    this.countryCode = 'IQ',
  });

  final String id;
  final String employeeId;
  final String displayName;
  final String countryCode;
}

class ClosingParty {
  const ClosingParty({
    required this.side,
    required this.name,
    required this.madarUserId,
    required this.phone,
    required this.country,
    required this.identity,
    required this.documents,
    required this.payment,
    required this.signature,
    required this.ownershipTransfer,
  });

  final String side;
  final String name;
  final String madarUserId;
  final String phone;
  final String country;
  final String identity;
  final String documents;
  final String payment;
  final String signature;
  final String ownershipTransfer;
}

class ClosingHandoff {
  const ClosingHandoff({
    required this.contractId,
    required this.executedVersion,
    required this.buyerSigned,
    required this.sellerSigned,
    required this.executedAt,
    required this.contractLawyerId,
    required this.contractLawyerName,
    required this.assignedAt,
  });

  final String contractId;
  final String executedVersion;
  final bool buyerSigned;
  final bool sellerSigned;
  final DateTime executedAt;
  final String contractLawyerId;
  final String contractLawyerName;
  final DateTime assignedAt;
}

class EscrowWatch {
  const EscrowWatch({
    required this.requiredAmount,
    required this.confirmedAmount,
    required this.bankName,
    required this.status,
    required this.transactionNumber,
    this.deadline,
    this.receiptId,
    this.confirmedAt,
    this.bankEmployee,
    this.discrepancyNote,
  });

  final String requiredAmount;
  final String confirmedAmount;
  final String bankName;
  final EscrowWatchStatus status;
  final String transactionNumber;
  final DateTime? deadline;
  final String? receiptId;
  final DateTime? confirmedAt;
  final String? bankEmployee;
  final String? discrepancyNote;

  bool get lawyerMayConfirm => false;

  EscrowWatch copyWith({
    EscrowWatchStatus? status,
    String? confirmedAmount,
    DateTime? confirmedAt,
    String? receiptId,
    String? bankEmployee,
  }) {
    return EscrowWatch(
      requiredAmount: requiredAmount,
      confirmedAmount: confirmedAmount ?? this.confirmedAmount,
      bankName: bankName,
      status: status ?? this.status,
      transactionNumber: transactionNumber,
      deadline: deadline,
      receiptId: receiptId ?? this.receiptId,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      bankEmployee: bankEmployee ?? this.bankEmployee,
      discrepancyNote: discrepancyNote,
    );
  }
}

class FinancialWatch {
  const FinancialWatch({
    required this.propertyTaxes,
    required this.transactionTaxes,
    required this.governmentFees,
    required this.serviceFees,
    required this.commissionStatus,
    required this.outstanding,
    required this.clearance,
    required this.sellerAmount,
    required this.companyFees,
    required this.finalSellerAmount,
    this.taxPaid = false,
    this.settlementComplete = false,
  });

  final String propertyTaxes;
  final String transactionTaxes;
  final String governmentFees;
  final String serviceFees;
  final String commissionStatus;
  final String outstanding;
  final String clearance;
  final String sellerAmount;
  final String companyFees;
  final String finalSellerAmount;
  final bool taxPaid;
  final bool settlementComplete;

  FinancialWatch copyWith({bool? taxPaid, bool? settlementComplete, String? clearance, String? outstanding}) {
    return FinancialWatch(
      propertyTaxes: propertyTaxes,
      transactionTaxes: transactionTaxes,
      governmentFees: governmentFees,
      serviceFees: serviceFees,
      commissionStatus: commissionStatus,
      outstanding: outstanding ?? this.outstanding,
      clearance: clearance ?? this.clearance,
      sellerAmount: sellerAmount,
      companyFees: companyFees,
      finalSellerAmount: finalSellerAmount,
      taxPaid: taxPaid ?? this.taxPaid,
      settlementComplete: settlementComplete ?? this.settlementComplete,
    );
  }
}

class CountryWorkflowPack {
  const CountryWorkflowPack({
    required this.countryCode,
    required this.numberingPrefix,
    required this.ownershipTransferMode,
    required this.skipOwnershipDocument,
    required this.escrowReleaseConditions,
    required this.governmentAuthorities,
  });

  final String countryCode;
  final String numberingPrefix;
  /// physical | digital_ready
  final String ownershipTransferMode;
  final bool skipOwnershipDocument;
  final List<String> escrowReleaseConditions;
  final List<String> governmentAuthorities;

  static CountryWorkflowPack forCountry(String code, {required bool agricultural}) {
    switch (code.toUpperCase()) {
      case 'IQ':
        return CountryWorkflowPack(
          countryCode: 'IQ',
          numberingPrefix: 'MAD',
          ownershipTransferMode: 'physical',
          skipOwnershipDocument: agricultural,
          escrowReleaseConditions: agricultural
              ? const [
                  'physical_relocation_or_handover',
                  'buyer_confirmation',
                  'closing_lawyer_confirmation',
                ]
              : const ['deed_verified', 'buyer_proof_uploaded', 'lawyer_verified'],
          governmentAuthorities: agricultural
              ? const ['مديرية الزراعة', 'دائرة التسجيل العقاري']
              : const ['دائرة التسجيل العقاري', 'هيئة الضرائب'],
        );
      default:
        return CountryWorkflowPack(
          countryCode: code,
          numberingPrefix: 'MAD',
          ownershipTransferMode: 'digital_ready',
          skipOwnershipDocument: false,
          escrowReleaseConditions: const ['escrow_confirmed', 'government_clearance'],
          governmentAuthorities: const ['Land Registry'],
        );
    }
  }
}

class GovProcedure {
  const GovProcedure({
    required this.id,
    required this.name,
    required this.authority,
    required this.status,
    required this.requiredDocuments,
    this.submittedAt,
    this.referenceNumber,
    this.expectedCompletion,
    this.responsible,
    this.notes,
    this.rejectionReason,
    this.correction,
    this.deadline,
  });

  final String id;
  final String name;
  final String authority;
  final GovProcedureStatus status;
  final List<String> requiredDocuments;
  final DateTime? submittedAt;
  final String? referenceNumber;
  final DateTime? expectedCompletion;
  final String? responsible;
  final String? notes;
  final String? rejectionReason;
  final String? correction;
  final DateTime? deadline;

  GovProcedure copyWith({
    GovProcedureStatus? status,
    String? notes,
    String? rejectionReason,
    String? correction,
    String? referenceNumber,
    DateTime? submittedAt,
  }) {
    return GovProcedure(
      id: id,
      name: name,
      authority: authority,
      status: status ?? this.status,
      requiredDocuments: requiredDocuments,
      submittedAt: submittedAt ?? this.submittedAt,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      expectedCompletion: expectedCompletion,
      responsible: responsible,
      notes: notes ?? this.notes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      correction: correction ?? this.correction,
      deadline: deadline,
    );
  }
}

class TransferAppointment {
  const TransferAppointment({
    required this.required,
    required this.authority,
    required this.location,
    this.date,
    this.time,
    this.buyerAttend = false,
    this.sellerAttend = false,
    this.lawyerAttend = false,
    this.status = 'pending',
    this.mode = 'physical',
    this.requiredDocuments = const [],
  });

  final bool required;
  final String authority;
  final String location;
  final DateTime? date;
  final String? time;
  final bool buyerAttend;
  final bool sellerAttend;
  final bool lawyerAttend;
  final String status;
  final String mode;
  final List<String> requiredDocuments;

  TransferAppointment copyWith({
    DateTime? date,
    String? time,
    String? status,
    bool? buyerAttend,
    bool? sellerAttend,
    bool? lawyerAttend,
  }) {
    return TransferAppointment(
      required: required,
      authority: authority,
      location: location,
      date: date ?? this.date,
      time: time ?? this.time,
      buyerAttend: buyerAttend ?? this.buyerAttend,
      sellerAttend: sellerAttend ?? this.sellerAttend,
      lawyerAttend: lawyerAttend ?? this.lawyerAttend,
      status: status ?? this.status,
      mode: mode,
      requiredDocuments: requiredDocuments,
    );
  }
}

class ClosingDocVersion {
  const ClosingDocVersion({
    required this.version,
    required this.status,
    required this.at,
    this.reason,
  });

  final int version;
  final DeedReviewStatus status;
  final DateTime at;
  final String? reason;
}

class ClosingDocument {
  const ClosingDocument({
    required this.id,
    required this.name,
    required this.kind,
    required this.status,
    this.versions = const [],
    this.notes,
  });

  final String id;
  final String name;
  final String kind;
  final DeedReviewStatus status;
  final List<ClosingDocVersion> versions;
  final String? notes;

  ClosingDocument copyWith({
    DeedReviewStatus? status,
    List<ClosingDocVersion>? versions,
    String? notes,
  }) {
    return ClosingDocument(
      id: id,
      name: name,
      kind: kind,
      status: status ?? this.status,
      versions: versions ?? this.versions,
      notes: notes ?? this.notes,
    );
  }
}

class ClosingNote {
  const ClosingNote({
    required this.id,
    required this.internal,
    required this.body,
    required this.author,
    required this.at,
  });

  final String id;
  final bool internal;
  final String body;
  final String author;
  final DateTime at;
}

class ClosingMessage {
  const ClosingMessage({
    required this.id,
    required this.channel,
    required this.body,
    required this.author,
    required this.at,
    this.internal = false,
  });

  final String id;
  final ChannelDept channel;
  final String body;
  final String author;
  final DateTime at;
  final bool internal;
}

class ClosingAudit {
  const ClosingAudit({
    required this.id,
    required this.action,
    required this.result,
    required this.employeeId,
    required this.employeeName,
    required this.at,
    required this.transactionNumber,
  });

  final String id;
  final String action;
  final String result;
  final String employeeId;
  final String employeeName;
  final DateTime at;
  final String transactionNumber;
}

class ClosingReceipt {
  const ClosingReceipt({
    required this.id,
    required this.source,
    required this.label,
    required this.at,
  });

  final String id;
  final String source;
  final String label;
  final DateTime at;
}

class PropertyServiceShare {
  const PropertyServiceShare({
    required this.enabled,
    required this.service,
    required this.sharedFields,
  });

  final bool enabled;
  final String service;
  final List<String> sharedFields;
}

class ClosingCase {
  const ClosingCase({
    required this.id,
    required this.transactionNumber,
    required this.countryCode,
    required this.transactionType,
    required this.propertyId,
    required this.propertyType,
    required this.propertyAddress,
    required this.area,
    required this.amount,
    required this.ownershipInfo,
    required this.currentOwner,
    required this.officeName,
    required this.assignedLawyer,
    required this.lawyerEmployeeId,
    required this.lifecycle,
    required this.timelineStage,
    required this.statusLabel,
    required this.priority,
    required this.requiredAction,
    required this.responsibleDepartment,
    required this.lastActivity,
    required this.buyer,
    required this.seller,
    required this.handoff,
    required this.escrow,
    required this.finance,
    required this.workflow,
    required this.procedures,
    required this.appointment,
    required this.documents,
    this.notes = const [],
    this.messages = const [],
    this.audit = const [],
    this.receipts = const [],
    this.serviceShare,
    this.barcode,
    this.deadline,
    this.blockedReason,
    this.closedAt,
    this.finalOwner,
    this.agricultural = false,
  });

  final String id;
  final String transactionNumber;
  final String countryCode;
  final String transactionType;
  final String propertyId;
  final String propertyType;
  final String propertyAddress;
  final String area;
  final String amount;
  final String ownershipInfo;
  final String currentOwner;
  final String officeName;
  final String assignedLawyer;
  final String lawyerEmployeeId;
  final ClosingLifecycle lifecycle;
  final ClosingTimelineStage timelineStage;
  final String statusLabel;
  final ClosingPriority priority;
  final ClosingWorkAction requiredAction;
  final String responsibleDepartment;
  final DateTime lastActivity;
  final ClosingParty buyer;
  final ClosingParty seller;
  final ClosingHandoff handoff;
  final EscrowWatch escrow;
  final FinancialWatch finance;
  final CountryWorkflowPack workflow;
  final List<GovProcedure> procedures;
  final TransferAppointment appointment;
  final List<ClosingDocument> documents;
  final List<ClosingNote> notes;
  final List<ClosingMessage> messages;
  final List<ClosingAudit> audit;
  final List<ClosingReceipt> receipts;
  final PropertyServiceShare? serviceShare;
  final String? barcode;
  final DateTime? deadline;
  final String? blockedReason;
  final DateTime? closedAt;
  final String? finalOwner;
  final bool agricultural;

  bool get isClosed => lifecycle == ClosingLifecycle.completed;

  ClosingCase copyWith({
    ClosingLifecycle? lifecycle,
    ClosingTimelineStage? timelineStage,
    String? statusLabel,
    ClosingPriority? priority,
    ClosingWorkAction? requiredAction,
    String? responsibleDepartment,
    DateTime? lastActivity,
    EscrowWatch? escrow,
    FinancialWatch? finance,
    List<GovProcedure>? procedures,
    TransferAppointment? appointment,
    List<ClosingDocument>? documents,
    List<ClosingNote>? notes,
    List<ClosingMessage>? messages,
    List<ClosingAudit>? audit,
    List<ClosingReceipt>? receipts,
    String? blockedReason,
    DateTime? closedAt,
    String? finalOwner,
  }) {
    return ClosingCase(
      id: id,
      transactionNumber: transactionNumber,
      countryCode: countryCode,
      transactionType: transactionType,
      propertyId: propertyId,
      propertyType: propertyType,
      propertyAddress: propertyAddress,
      area: area,
      amount: amount,
      ownershipInfo: ownershipInfo,
      currentOwner: currentOwner,
      officeName: officeName,
      assignedLawyer: assignedLawyer,
      lawyerEmployeeId: lawyerEmployeeId,
      lifecycle: lifecycle ?? this.lifecycle,
      timelineStage: timelineStage ?? this.timelineStage,
      statusLabel: statusLabel ?? this.statusLabel,
      priority: priority ?? this.priority,
      requiredAction: requiredAction ?? this.requiredAction,
      responsibleDepartment: responsibleDepartment ?? this.responsibleDepartment,
      lastActivity: lastActivity ?? this.lastActivity,
      buyer: buyer,
      seller: seller,
      handoff: handoff,
      escrow: escrow ?? this.escrow,
      finance: finance ?? this.finance,
      workflow: workflow,
      procedures: procedures ?? this.procedures,
      appointment: appointment ?? this.appointment,
      documents: documents ?? this.documents,
      notes: notes ?? this.notes,
      messages: messages ?? this.messages,
      audit: audit ?? this.audit,
      receipts: receipts ?? this.receipts,
      serviceShare: serviceShare,
      barcode: barcode,
      deadline: deadline,
      blockedReason: blockedReason ?? this.blockedReason,
      closedAt: closedAt ?? this.closedAt,
      finalOwner: finalOwner ?? this.finalOwner,
      agricultural: agricultural,
    );
  }
}
