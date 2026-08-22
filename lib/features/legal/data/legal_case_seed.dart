import '../domain/enums/legal_enums.dart';
import '../domain/models/legal_models.dart';
import 'legal_clause_library.dart';

/// Assigned contract-stage cases for this lawyer. Not dashboard statistics.
class LegalCaseSeed {
  static const lawyerName = 'سارة العبيدي';
  static const lawyerId = 'LAW-0042';

  static List<LegalContractSection> _populatedSections(LegalCase c) {
    String slot(String template) => template
        .replaceAll('{BUYER}', c.buyer.name)
        .replaceAll('{SELLER}', c.seller.name)
        .replaceAll('{PROPERTY_ID}', c.propertyId)
        .replaceAll('{ADDRESS}', c.propertyAddress)
        .replaceAll('{PRICE}', c.authorizedAmount)
        .replaceAll('{TX}', c.transactionNumber)
        .replaceAll('{CTR}', c.contractNumber);

    return ContractStructureCatalog.sectionIds.map((id) {
      final title = ContractStructureCatalog.title(id, 'ar');
      final body = switch (id) {
        'header' =>
          slot('مدار — عقد رقم {CTR}\nمعاملة {TX}\nالنسخة مسودة. النص النهائي من القالب المعتمد.'),
        'parties' =>
          slot('المشتري: {BUYER}\nالبائع: {SELLER}\nتُستكمل البيانات من السجل الموثّق دون إعادة إدخال يدوي.'),
        'property' =>
          slot('العقار {PROPERTY_ID}\nالعنوان: {ADDRESS}'),
        'price' =>
          slot('ثمن الشراء المعتمد في المعاملة: {PRICE}'),
        'signatures' =>
          'مناطق التوقيع الإلكتروني — المشتري / البائع. لا تُفعَّل إلا بعد التأكيد وOTP والتحقق من الهوية.',
        _ =>
          'بند [$id] — $title\nيُدرج النص من القالب القانوني المعتمد (لا يُنشأ نص قانوني داخل التطبيق).',
      };
      return LegalContractSection(id: id, title: title, body: body);
    }).toList();
  }

  static LegalParty _buyer({
    required String name,
    required String uid,
    required String phone,
    VerificationWatch identity = VerificationWatch.verified,
    LegalDocumentStatus docs = LegalDocumentStatus.approved,
    VerificationWatch otp = VerificationWatch.pending,
    VerificationWatch face = VerificationWatch.pending,
    SignatureWatch sign = SignatureWatch.pending,
    PartyConfirmation conf = PartyConfirmation.pending,
  }) {
    return LegalParty(
      side: 'buyer',
      name: name,
      madarUserId: uid,
      phone: phone,
      country: 'IQ',
      nationalIdMasked: '•••• 4821',
      identityStatus: identity,
      documentStatus: docs,
      otpStatus: otp,
      faceStatus: face,
      signatureStatus: sign,
      confirmation: conf,
    );
  }

  static LegalParty _seller({
    required String name,
    required String uid,
    required String phone,
    VerificationWatch identity = VerificationWatch.verified,
    LegalDocumentStatus docs = LegalDocumentStatus.approved,
    VerificationWatch otp = VerificationWatch.pending,
    VerificationWatch face = VerificationWatch.pending,
    SignatureWatch sign = SignatureWatch.pending,
    PartyConfirmation conf = PartyConfirmation.pending,
  }) {
    return LegalParty(
      side: 'seller',
      name: name,
      madarUserId: uid,
      phone: phone,
      country: 'IQ',
      nationalIdMasked: '•••• 1193',
      identityStatus: identity,
      documentStatus: docs,
      otpStatus: otp,
      faceStatus: face,
      signatureStatus: sign,
      confirmation: conf,
    );
  }

  static LegalDocumentReq doc({
    required String id,
    required String name,
    required String party,
    required LegalDocumentStatus status,
    bool required = true,
    DateTime? deadline,
    List<LegalDocVersion>? versions,
    String? notes,
  }) {
    return LegalDocumentReq(
      id: id,
      name: name,
      party: party,
      required: required,
      status: status,
      deadline: deadline,
      notes: notes,
      versions: versions ??
          [
            if (status != LegalDocumentStatus.required &&
                status != LegalDocumentStatus.requested)
              LegalDocVersion(
                version: 1,
                status: status,
                createdAt: DateTime(2026, 8, 18, 10),
                previewLabel: name,
              ),
          ],
    );
  }

  static LegalAuditEvent audit(String tx, String action, String result, DateTime at) {
    return LegalAuditEvent(
      id: '$tx-$action-${at.millisecondsSinceEpoch}',
      action: action,
      result: result,
      lawyerId: lawyerId,
      at: at,
      transactionNumber: tx,
    );
  }

  static List<LegalCase> assignedQueue() {
    final now = DateTime(2026, 8, 21, 22, 10);

    LegalCase base({
      required String tx,
      required String type,
      required String propertyId,
      required String address,
      required String ptype,
      required LegalContractStage stage,
      required LegalWorkAction action,
      required LegalPriority priority,
      required LegalParty buyer,
      required LegalParty seller,
      required List<LegalDocumentReq> documents,
      String status = 'نشطة — مرحلة العقد',
      String? special,
      RentToOwnTerms? rto,
      DateTime? deadline,
      List<LegalContractVersion> contracts = const [],
      LegalReviewChecks? review,
      bool handoff = false,
      String? handoffTarget,
    }) {
      var c = LegalCase(
        id: tx,
        transactionNumber: tx,
        contractNumber: tx.replaceFirst('MAD', 'CTR'),
        transactionType: type,
        propertyId: propertyId,
        propertyAddress: address,
        propertyType: ptype,
        area: '210 م²',
        price: '185,000,000 IQD',
        authorizedAmount: '185,000,000 IQD',
        ownershipInfo: 'سند ملكية باسم البائع — قيد المراجعة القانونية',
        officeName: 'مكتب النهرين — بغداد',
        assignedLawyer: lawyerName,
        lawyerEmployeeId: lawyerId,
        stage: stage,
        statusLabel: status,
        priority: priority,
        requiredAction: action,
        lastActivity: now.subtract(const Duration(hours: 2)),
        buyer: buyer,
        seller: seller,
        documents: documents,
        contracts: contracts,
        audit: [
          audit(tx, 'transaction_opened', 'opened', now.subtract(const Duration(days: 2))),
        ],
        barcode: 'BC-$tx',
        specialLegalConditions: special,
        rentToOwn: rto,
        review: review ?? const LegalReviewChecks(),
        deadline: deadline,
        handoffComplete: handoff,
        handoffTarget: handoffTarget,
      );
      if (contracts.isEmpty &&
          stage.index >= LegalContractStage.contractPreparation.index) {
        final sections = _populatedSections(c);
        c = c.copyWith(
          contracts: [
            LegalContractVersion(
              version: 1,
              status: ContractVersionStatus.draft,
              createdBy: lawyerId,
              createdAt: now.subtract(const Duration(hours: 5)),
              modifiedBy: lawyerId,
              modifiedAt: now.subtract(const Duration(hours: 1)),
              changeNotes: 'مسودة أولى من القالب المعتمد',
              sections: sections,
            ),
          ],
        );
      }
      return c;
    }

    return [
      base(
        tx: 'MAD-2026-000481',
        type: 'بيع سكني',
        propertyId: 'PR-IQ-BGD-88421',
        address: 'الكرادة، شارع 42، بغداد',
        ptype: 'شقة سكنية',
        stage: LegalContractStage.contractPreparation,
        action: LegalWorkAction.prepareContract,
        priority: LegalPriority.priority,
        buyer: _buyer(name: 'أحمد علي', uid: 'USR-B-19021', phone: '+964 770 111 2048'),
        seller: _seller(name: 'محمد حسن', uid: 'USR-S-44102', phone: '+964 750 222 8811'),
        documents: [
          doc(id: 'd1', name: 'الهوية الوطنية', party: 'buyer', status: LegalDocumentStatus.approved),
          doc(id: 'd2', name: 'الهوية الوطنية', party: 'seller', status: LegalDocumentStatus.approved),
          doc(id: 'd3', name: 'سند الملكية', party: 'seller', status: LegalDocumentStatus.underReview),
          doc(id: 'd4', name: 'إثبات القدرة المالية', party: 'buyer', status: LegalDocumentStatus.approved),
        ],
        special: 'لا رهن قائم. موافقة الورثة غير مطلوبة.',
        deadline: now.add(const Duration(hours: 18)),
        review: const LegalReviewChecks(
          buyerIdentity: true,
          sellerIdentity: true,
          propertyOwnership: true,
          propertyInformation: true,
          requiredDocuments: false,
          transactionPrice: true,
          paymentTerms: true,
          specialConditions: true,
          additionalLegal: true,
        ),
      ),
      base(
        tx: 'MAD-2026-000502',
        type: 'بيع سكني',
        propertyId: 'PR-IQ-BGD-11920',
        address: 'المنصور، comm. 9، بغداد',
        ptype: 'منزل',
        stage: LegalContractStage.identityVerification,
        action: LegalWorkAction.reviewTransaction,
        priority: LegalPriority.normal,
        buyer: _buyer(
          name: 'ليلى كريم',
          uid: 'USR-B-22011',
          phone: '+964 780 333 4401',
          identity: VerificationWatch.pending,
          docs: LegalDocumentStatus.required,
        ),
        seller: _seller(
          name: 'حسين جابر',
          uid: 'USR-S-33012',
          phone: '+964 770 555 0199',
          identity: VerificationWatch.verified,
          docs: LegalDocumentStatus.uploaded,
        ),
        documents: [
          doc(id: 'e1', name: 'الهوية الوطنية', party: 'buyer', status: LegalDocumentStatus.required),
          doc(id: 'e2', name: 'الهوية الوطنية', party: 'seller', status: LegalDocumentStatus.uploaded),
        ],
        deadline: now.add(const Duration(days: 2)),
      ),
      base(
        tx: 'MAD-2026-000510',
        type: 'بيع تجاري',
        propertyId: 'PR-IQ-BGD-55210',
        address: 'الجادرية، مجمع الأعمال',
        ptype: 'تجاري',
        stage: LegalContractStage.requiredDocuments,
        action: LegalWorkAction.reviewDocuments,
        priority: LegalPriority.priority,
        buyer: _buyer(name: 'شركة الأفق', uid: 'USR-B-8001', phone: '+964 771 200 3000', docs: LegalDocumentStatus.underReview),
        seller: _seller(name: 'خالد الماجد', uid: 'USR-S-8002', phone: '+964 750 900 1122'),
        documents: [
          doc(id: 'f1', name: 'الهوية الوطنية', party: 'seller', status: LegalDocumentStatus.approved),
          doc(
            id: 'f2',
            name: 'سند الملكية',
            party: 'seller',
            status: LegalDocumentStatus.underReview,
            versions: [
              LegalDocVersion(version: 1, status: LegalDocumentStatus.rejected, createdAt: DateTime(2026, 8, 15), rejectionReason: 'مستند الملكية غير مكتمل.'),
              LegalDocVersion(version: 2, status: LegalDocumentStatus.underReview, createdAt: DateTime(2026, 8, 20), previewLabel: 'سند الملكية'),
            ],
          ),
          doc(id: 'f3', name: 'سجل تجاري', party: 'buyer', status: LegalDocumentStatus.uploaded),
        ],
        deadline: now.add(const Duration(hours: 6)),
      ),
      base(
        tx: 'MAD-2026-000522',
        type: 'بيع أرض',
        propertyId: 'PR-IQ-NJF-1022',
        address: 'النجف، طريق كربلاء',
        ptype: 'أرض',
        stage: LegalContractStage.requiredDocuments,
        action: LegalWorkAction.missingDocuments,
        priority: LegalPriority.urgent,
        buyer: _buyer(name: 'علي رضا', uid: 'USR-B-661', phone: '+964 760 111 0002', docs: LegalDocumentStatus.requested),
        seller: _seller(name: 'وئام عباس', uid: 'USR-S-662', phone: '+964 770 222 0003', docs: LegalDocumentStatus.approved),
        documents: [
          doc(id: 'g1', name: 'الهوية الوطنية', party: 'buyer', status: LegalDocumentStatus.requested, deadline: now.add(const Duration(hours: 10))),
          doc(id: 'g2', name: 'وثيقة الملكية', party: 'seller', status: LegalDocumentStatus.approved),
          doc(id: 'g3', name: 'وكالة قانونية', party: 'seller', status: LegalDocumentStatus.required, required: false),
        ],
        deadline: now.add(const Duration(hours: 10)),
      ),
      base(
        tx: 'MAD-2026-000540',
        type: 'إيجار تمليكي',
        propertyId: 'PR-IQ-BGD-77001',
        address: 'زيونة، مجمع النخيل',
        ptype: 'شقة — إيجار تمليكي',
        stage: LegalContractStage.contractConfirmation,
        action: LegalWorkAction.awaitBuyerConfirmation,
        priority: LegalPriority.normal,
        buyer: _buyer(name: 'نور قاسم', uid: 'USR-B-901', phone: '+964 781 444 2211', conf: PartyConfirmation.viewed),
        seller: _seller(name: 'عمار سعد', uid: 'USR-S-902', phone: '+964 751 333 0099', conf: PartyConfirmation.confirmed),
        documents: [
          doc(id: 'h1', name: 'الهوية الوطنية', party: 'buyer', status: LegalDocumentStatus.approved),
          doc(id: 'h2', name: 'الهوية الوطنية', party: 'seller', status: LegalDocumentStatus.approved),
          doc(id: 'h3', name: 'سند الملكية', party: 'seller', status: LegalDocumentStatus.approved),
        ],
        rto: const RentToOwnTerms(
          propertyPrice: '210,000,000 IQD',
          monthlyPayment: '1,250,000 IQD',
          agreedMonthly: '1,250,000 IQD',
          durationMonths: 84,
          ownershipTransferCondition: 'وفق إطار الإيجار التمليكي المعتمد لدى مدار',
          scheduleSummary: 'جدول الدفع من القالب المعتمد — غير مضمّن كنص قانوني داخل التطبيق',
          initialPayment: '15,000,000 IQD',
        ),
        review: const LegalReviewChecks(
          buyerIdentity: true,
          sellerIdentity: true,
          propertyOwnership: true,
          propertyInformation: true,
          requiredDocuments: true,
          transactionPrice: true,
          paymentTerms: true,
          specialConditions: true,
          additionalLegal: true,
        ),
      ),
      base(
        tx: 'MAD-2026-000551',
        type: 'بيع سكني',
        propertyId: 'PR-IQ-BGD-33008',
        address: 'الحارثية، شارع الأميرات',
        ptype: 'فيلا',
        stage: LegalContractStage.otpVerification,
        action: LegalWorkAction.otpPending,
        priority: LegalPriority.normal,
        buyer: _buyer(name: 'ياسر نعيم', uid: 'USR-B-441', phone: '+964 770 808 1212', otp: VerificationWatch.verified, conf: PartyConfirmation.confirmed),
        seller: _seller(name: 'هدى فاضل', uid: 'USR-S-442', phone: '+964 750 606 3434', otp: VerificationWatch.pending, conf: PartyConfirmation.confirmed),
        documents: [
          doc(id: 'i1', name: 'الهوية الوطنية', party: 'buyer', status: LegalDocumentStatus.approved),
          doc(id: 'i2', name: 'الهوية الوطنية', party: 'seller', status: LegalDocumentStatus.approved),
          doc(id: 'i3', name: 'سند الملكية', party: 'seller', status: LegalDocumentStatus.approved),
        ],
      ),
      base(
        tx: 'MAD-2026-000560',
        type: 'بيع زراعي',
        propertyId: 'PR-IQ-BBL-220',
        address: 'بابل، ناحية السدة',
        ptype: 'زراعي',
        stage: LegalContractStage.faceVerification,
        action: LegalWorkAction.facePending,
        priority: LegalPriority.priority,
        buyer: _buyer(name: 'قاسم عودة', uid: 'USR-B-771', phone: '+964 780 121 4545', otp: VerificationWatch.verified, face: VerificationWatch.pending, conf: PartyConfirmation.confirmed),
        seller: _seller(name: 'منى جليل', uid: 'USR-S-772', phone: '+964 770 212 5656', otp: VerificationWatch.verified, face: VerificationWatch.verified, conf: PartyConfirmation.confirmed),
        documents: [
          doc(id: 'j1', name: 'الهوية الوطنية', party: 'buyer', status: LegalDocumentStatus.approved),
          doc(id: 'j2', name: 'وثائق زراعية', party: 'seller', status: LegalDocumentStatus.approved),
        ],
      ),
      base(
        tx: 'MAD-2026-000571',
        type: 'بيع سكني',
        propertyId: 'PR-IQ-BGD-99110',
        address: 'الدورة، حي الميكانيك',
        ptype: 'شقة',
        stage: LegalContractStage.electronicSignature,
        action: LegalWorkAction.signaturePending,
        priority: LegalPriority.normal,
        buyer: _buyer(name: 'سامي درويش', uid: 'USR-B-611', phone: '+964 771 909 1010', otp: VerificationWatch.verified, face: VerificationWatch.verified, conf: PartyConfirmation.confirmed, sign: SignatureWatch.signed),
        seller: _seller(name: 'إيمان طه', uid: 'USR-S-612', phone: '+964 750 808 2020', otp: VerificationWatch.verified, face: VerificationWatch.verified, conf: PartyConfirmation.confirmed, sign: SignatureWatch.pending),
        documents: [
          doc(id: 'k1', name: 'الهوية الوطنية', party: 'buyer', status: LegalDocumentStatus.approved),
          doc(id: 'k2', name: 'الهوية الوطنية', party: 'seller', status: LegalDocumentStatus.approved),
          doc(id: 'k3', name: 'سند الملكية', party: 'seller', status: LegalDocumentStatus.approved),
        ],
      ),
      base(
        tx: 'MAD-2026-000580',
        type: 'بيع سكني',
        propertyId: 'PR-IQ-BGD-10002',
        address: 'العامرية، مجمع السلام',
        ptype: 'شقة',
        stage: LegalContractStage.electronicSignature,
        action: LegalWorkAction.readyToExecute,
        priority: LegalPriority.priority,
        buyer: _buyer(name: 'باسم راضي', uid: 'USR-B-201', phone: '+964 770 101 3030', otp: VerificationWatch.verified, face: VerificationWatch.verified, conf: PartyConfirmation.confirmed, sign: SignatureWatch.signed),
        seller: _seller(name: 'رنا كاظم', uid: 'USR-S-202', phone: '+964 781 202 4040', otp: VerificationWatch.verified, face: VerificationWatch.verified, conf: PartyConfirmation.confirmed, sign: SignatureWatch.signed),
        documents: [
          doc(id: 'l1', name: 'الهوية الوطنية', party: 'buyer', status: LegalDocumentStatus.approved),
          doc(id: 'l2', name: 'الهوية الوطنية', party: 'seller', status: LegalDocumentStatus.approved),
          doc(id: 'l3', name: 'سند الملكية', party: 'seller', status: LegalDocumentStatus.approved),
        ],
      ),
      base(
        tx: 'MAD-2026-000590',
        type: 'بيع تجاري',
        propertyId: 'PR-IQ-BGD-666',
        address: 'الشورجة، عقار متنازع عليه جزئياً',
        ptype: 'تجاري',
        stage: LegalContractStage.requiredDocuments,
        action: LegalWorkAction.urgentIssue,
        priority: LegalPriority.urgent,
        buyer: _buyer(name: 'مؤسسة الرافدين', uid: 'USR-B-999', phone: '+964 770 000 1111', docs: LegalDocumentStatus.rejected),
        seller: _seller(name: 'عبدالله ناجي', uid: 'USR-S-998', phone: '+964 750 000 2222'),
        documents: [
          doc(
            id: 'm1',
            name: 'سند الملكية',
            party: 'seller',
            status: LegalDocumentStatus.rejected,
            versions: [
              LegalDocVersion(
                version: 1,
                status: LegalDocumentStatus.rejected,
                createdAt: DateTime(2026, 8, 19),
                rejectionReason: 'مستند الملكية لا يطابق المعلومات المسجلة.',
              ),
            ],
            notes: 'تعارض حدود مع معاملة مجاورة — يتطلب مراجعة قانونية عاجلة.',
          ),
        ],
        deadline: now.add(const Duration(hours: 3)),
      ),
      base(
        tx: 'MAD-2026-000401',
        type: 'بيع سكني',
        propertyId: 'PR-IQ-BGD-010',
        address: 'الكاظمية، شارع الإمام',
        ptype: 'شقة',
        stage: LegalContractStage.nextDepartment,
        action: LegalWorkAction.handoff,
        priority: LegalPriority.normal,
        status: 'مرحلة العقد مكتملة',
        buyer: _buyer(name: 'فادي سلمان', uid: 'USR-B-010', phone: '+964 770 010 0101', otp: VerificationWatch.verified, face: VerificationWatch.verified, conf: PartyConfirmation.confirmed, sign: SignatureWatch.signed),
        seller: _seller(name: 'سناء مهدي', uid: 'USR-S-011', phone: '+964 750 011 0111', otp: VerificationWatch.verified, face: VerificationWatch.verified, conf: PartyConfirmation.confirmed, sign: SignatureWatch.signed),
        documents: [
          doc(id: 'n1', name: 'الهوية الوطنية', party: 'buyer', status: LegalDocumentStatus.approved),
          doc(id: 'n2', name: 'سند الملكية', party: 'seller', status: LegalDocumentStatus.approved),
        ],
        handoff: true,
        handoffTarget: 'closing',
      ),
    ];
  }
}
