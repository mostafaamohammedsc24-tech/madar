import 'app_localizations.dart';

/// Contract Lawyer workspace copy — ar / en / ku, RTL-aware via locale.
class LegalStrings {
  const LegalStrings(this.lang);
  final AppLanguage lang;

  factory LegalStrings.of(AppLocalizations loc) => LegalStrings(loc.language);

  String _t({required String en, required String ar, required String ku}) {
    switch (lang) {
      case AppLanguage.arabic:
        return ar;
      case AppLanguage.kurdish:
        return ku;
      case AppLanguage.english:
        return en;
    }
  }

  String get brand => _t(en: 'MADAR', ar: 'مدار', ku: 'مەدار');
  String get legalOperations =>
      _t(en: 'Legal Operations', ar: 'العمليات القانونية', ku: 'کارە یاساییەکان');
  String get contractLawyer =>
      _t(en: 'Contract Lawyer', ar: 'محامي العقود', ku: 'پارێزەری گرێبەست');
  String get workspaceTitle => _t(
    en: 'Contract Lawyer Workspace',
    ar: 'مساحة عمل محامي العقود',
    ku: 'شوێنی کاری پارێزەری گرێبەست',
  );
  String get notPublicSite => _t(
    en: 'This is not the public Madar website, user app, office, bank, or finance workspace.',
    ar: 'هذه ليست موقع مدار العام ولا تطبيق المستخدم ولا مساحة المكاتب أو البنك أو المالية.',
    ku: 'ئەمە ماڵپەڕی گشتی مەدار، ئەپی بەکارهێنەر، ئۆفیس، بانک یان دارایی نییە.',
  );
  String get roleBoundary => _t(
    en: 'Scope: legal contract stage only. Deposits, escrow, commissions, listings, offices, and ownership transfer belong to other departments.',
    ar: 'النطاق: مرحلة العقد القانوني فقط. الإيداعات والضمان والعمولات والإعلانات والمكاتب ونقل الملكية تخص أقساماً أخرى.',
    ku: 'مەودا: تەنها قۆناغی گرێبەستی یاسایی. پارەدان، ئێسکرۆ، کۆمیسیون، لیستکردن، ئۆفیس و گواستنەوەی خاوەنداری بۆ بەشەکانی ترن.',
  );

  String get navWork => _t(en: 'Work', ar: 'العمل', ku: 'کار');
  String get navTransactions => _t(en: 'Transactions', ar: 'المعاملات', ku: 'مامەڵەکان');
  String get navContracts => _t(en: 'Contracts', ar: 'العقود', ku: 'گرێبەستەکان');
  String get navDocuments => _t(en: 'Documents', ar: 'المستندات', ku: 'بەڵگەنامەکان');
  String get navMessages => _t(en: 'Messages', ar: 'الرسائل', ku: 'نامەکان');
  String get navArchive => _t(en: 'Archive', ar: 'الأرشيف', ku: 'ئەرشیف');
  String get navProfile => _t(en: 'Profile', ar: 'الملف', ku: 'پرۆفایل');

  String get loginTitle => _t(
    en: 'Legal Operations sign-in',
    ar: 'دخول العمليات القانونية',
    ku: 'چوونەژوورەوەی کارە یاساییەکان',
  );
  String get loginSubtitle => _t(
    en: 'Contract Lawyer credentials. This is not office, finance, or user login.',
    ar: 'بيانات محامي العقود. هذا ليس دخول المكتب أو المالية أو المستخدم.',
    ku: 'ناسنامەی پارێزەری گرێبەست. ئەمە چوونەژوورەوەی ئۆفیس، دارایی یان بەکارهێنەر نییە.',
  );
  String get employeeId => _t(en: 'Employee ID', ar: 'رقم الموظف', ku: 'ناسنامەی کارمەند');
  String get employeeIdHint => _t(en: 'e.g. LAW-0042', ar: 'مثال: LAW-0042', ku: 'نموونە: LAW-0042');
  String get secretCode => _t(en: 'Access code', ar: 'رمز الدخول', ku: 'کۆدی دەستگەیشتن');
  String get signIn => _t(en: 'Sign in', ar: 'دخول', ku: 'چوونەژوورەوە');
  String get loginInvalid => _t(
    en: 'Invalid employee ID or access code.',
    ar: 'رقم الموظف أو رمز الدخول غير صحيح.',
    ku: 'ناسنامە یان کۆدی دەستگەیشتن هەڵەیە.',
  );
  String get sessionLabel => _t(en: 'Session', ar: 'الجلسة', ku: 'دانیشتن');
  String get permissionsLabel => _t(en: 'Access', ar: 'الصلاحيات', ku: 'دەسەڵات');
  String get canDo => _t(
    en: 'Review assigned cases, documents, draft and send contracts, monitor confirmation, OTP, identity, and signatures.',
    ar: 'مراجعة المعاملات والمستندات المسندة، إعداد العقود وإرسالها، ومتابعة التأكيد وOTP والهوية والتوقيع.',
    ku: 'پێداچوونەوەی کەیسەکان و بەڵگەنامەکان، ئامادەکردنی گرێبەست، چاودێری پشتڕاستکردن، OTP، ناسنامە و واژوو.',
  );
  String get cannotDo => _t(
    en: 'Cannot confirm bank deposits, release escrow, change commissions, manage staff or offices, publish listings, or complete ownership transfer.',
    ar: 'لا يمكن تأكيد الإيداعات البنكية أو تحرير الضمان أو تعديل العمولات أو إدارة الموظفين أو المكاتب أو نشر العقارات أو إتمام نقل الملكية.',
    ku: 'ناتوانێت پارەدانی بانک، ئازادکردنی ئێسکرۆ، گۆڕینی کۆمیسیون، بەڕێوەبردنی کارمەند یان ئۆفیس، بڵاوکردنەوەی موڵک یان گواستنەوەی خاوەنداری بکات.',
  );

  String get workQuestion => _t(
    en: 'What requires my attention right now?',
    ar: 'ما الذي يتطلب انتباهي الآن؟',
    ku: 'ئێستا چی پێویستی بە سەرنجم هەیە؟',
  );
  String get noActions => _t(
    en: 'No legal actions require your attention.',
    ar: 'لا توجد إجراءات قانونية تتطلب انتباهك.',
    ku: 'هیچ کرداری یاسایی پێویستی بە سەرنجت نییە.',
  );
  String get requiredAction => _t(en: 'Required action', ar: 'الإجراء المطلوب', ku: 'کرداری پێویست');
  String get lastActivity => _t(en: 'Last activity', ar: 'آخر نشاط', ku: 'دوایین چالاکی');
  String get currentStage => _t(en: 'Current stage', ar: 'المرحلة الحالية', ku: 'قۆناغی ئێستا');
  String get transactionType => _t(en: 'Transaction type', ar: 'نوع المعاملة', ku: 'جۆری مامەڵە');
  String get buyer => _t(en: 'Buyer', ar: 'المشتري', ku: 'کڕیار');
  String get seller => _t(en: 'Seller', ar: 'البائع', ku: 'فرۆشیار');
  String get property => _t(en: 'Property', ar: 'العقار', ku: 'موڵک');
  String get office => _t(en: 'Office', ar: 'المكتب', ku: 'ئۆفیس');
  String get assignedLawyer =>
      _t(en: 'Assigned contract lawyer', ar: 'محامي العقود المعيّن', ku: 'پارێزەری دیاریکراو');
  String get status => _t(en: 'Status', ar: 'الحالة', ku: 'دۆخ');
  String get priority => _t(en: 'Priority', ar: 'الأولوية', ku: 'گرنگی');
  String get filter => _t(en: 'Filter', ar: 'تصفية', ku: 'فلتەر');
  String get searchHint => _t(
    en: 'Transaction number, property ID, phone, ID, barcode, address, office, date, type, status',
    ar: 'رقم المعاملة، معرف العقار، هاتف، هوية، باركود، عنوان، مكتب، تاريخ، نوع، حالة',
    ku: 'ژمارەی مامەڵە، ناسنامەی موڵک، تەلەفۆن، بارکۆد، ناونیشان، ئۆفیس، بەروار، جۆر، دۆخ',
  );
  String get search => _t(en: 'Search', ar: 'بحث', ku: 'گەڕان');

  String get stageIdentity => _t(en: 'Identity verification', ar: 'التحقق من الهوية', ku: 'پشتڕاستکردنەوەی ناسنامە');
  String get stageDocuments => _t(en: 'Required documents', ar: 'المستندات المطلوبة', ku: 'بەڵگەنامەی پێویست');
  String get stagePrep => _t(en: 'Contract preparation', ar: 'تجهيز العقد', ku: 'ئامادەکردنی گرێبەست');
  String get stageConfirm => _t(en: 'Contract confirmation', ar: 'تأكيد العقد', ku: 'پشتڕاستکردنەوەی گرێبەست');
  String get stageOtp => _t(en: 'OTP verification', ar: 'التحقق برمز OTP', ku: 'پشتڕاستکردنەوەی OTP');
  String get stageFace => _t(en: 'Face verification', ar: 'التحقق من الوجه', ku: 'پشتڕاستکردنەوەی ڕوو');
  String get stageSign => _t(en: 'Electronic signature', ar: 'التوقيع الإلكتروني', ku: 'واژووی ئەلیکترۆنی');
  String get stageExecuted => _t(en: 'Contract executed', ar: 'تنفيذ العقد', ku: 'جێبەجێکردنی گرێبەست');
  String get stageNext => _t(en: 'Next department', ar: 'القسم التالي', ku: 'بەشی داهاتوو');

  String get complete => _t(en: 'Complete', ar: 'مكتمل', ku: 'تەواو');
  String get pending => _t(en: 'Pending', ar: 'قيد الانتظار', ku: 'چاوەڕوان');
  String get blocked => _t(en: 'Blocked', ar: 'متوقف', ku: 'وەستاو');
  String get requiresAction => _t(en: 'Requires action', ar: 'يتطلب إجراءً', ku: 'پێویستی بە کردارە');

  String get userId => _t(en: 'Madar user ID', ar: 'معرف مستخدم مدار', ku: 'ناسنامەی بەکارهێنەری مەدار');
  String get phone => _t(en: 'Phone', ar: 'الهاتف', ku: 'تەلەفۆن');
  String get country => _t(en: 'Country', ar: 'الدولة', ku: 'وڵات');
  String get identityStatus => _t(en: 'Identity verification', ar: 'حالة الهوية', ku: 'دۆخی ناسنامە');
  String get documentStatus => _t(en: 'Documents', ar: 'المستندات', ku: 'بەڵگەنامەکان');
  String get otpStatus => _t(en: 'OTP', ar: 'رمز OTP', ku: 'OTP');
  String get faceStatus => _t(en: 'Face verification', ar: 'التحقق من الوجه', ku: 'پشتڕاستکردنەوەی ڕوو');
  String get signatureStatus => _t(en: 'Signature', ar: 'التوقيع', ku: 'واژوو');
  String get otpHidden => _t(
    en: 'OTP codes are never shown to the lawyer.',
    ar: 'لا تُعرض رموز OTP للمحامي مطلقاً.',
    ku: 'کۆدی OTP هەرگیز پیشانی پارێزەر نادرێت.',
  );

  String get propertyId => _t(en: 'Property ID', ar: 'معرف العقار', ku: 'ناسنامەی موڵک');
  String get address => _t(en: 'Address', ar: 'العنوان', ku: 'ناونیشان');
  String get propertyType => _t(en: 'Property type', ar: 'نوع العقار', ku: 'جۆری موڵک');
  String get area => _t(en: 'Area', ar: 'المساحة', ku: 'ڕووبەر');
  String get price => _t(en: 'Price', ar: 'السعر', ku: 'نرخ');
  String get ownership => _t(en: 'Ownership', ar: 'الملكية', ku: 'خاوەنداری');
  String get specialConditions => _t(en: 'Special legal conditions', ar: 'شروط قانونية خاصة', ku: 'مەرجی یاسایی تایبەت');
  String get openProperty => _t(en: 'Open property record', ar: 'فتح سجل العقار', ku: 'کردنەوەی تۆماری موڵک');

  String get requiredDocuments => _t(en: 'Required documents', ar: 'المستندات المطلوبة', ku: 'بەڵگەنامەی پێویست');
  String get addRequirement => _t(en: 'Add requirement', ar: 'إضافة متطلب', ku: 'زیادکردنی پێویستی');
  String get party => _t(en: 'Party', ar: 'الطرف', ku: 'لایەن');
  String get required => _t(en: 'Required', ar: 'إلزامي', ku: 'پێویست');
  String get optional => _t(en: 'Optional', ar: 'اختياري', ku: 'ئارەزوومەندانە');
  String get deadline => _t(en: 'Deadline', ar: 'الموعد النهائي', ku: 'دوا وادە');
  String get notes => _t(en: 'Notes', ar: 'ملاحظات', ku: 'تێبینی');
  String get requestDocument => _t(en: 'Request document', ar: 'طلب مستند', ku: 'داواکردنی بەڵگەنامە');
  String get approve => _t(en: 'Approve', ar: 'اعتماد', ku: 'پەسەند');
  String get reject => _t(en: 'Reject', ar: 'رفض', ku: 'ڕەتکردنەوە');
  String get requestReplacement => _t(en: 'Request replacement', ar: 'طلب بدل', ku: 'داواکردنی جێگرەوە');
  String get internalNote => _t(en: 'Internal note', ar: 'ملاحظة داخلية', ku: 'تێبینی ناوخۆیی');
  String get customerNote => _t(en: 'Customer-visible note', ar: 'ملاحظة ظاهرة للعميل', ku: 'تێبینی بۆ کڕیار');
  String get rejectionReason => _t(en: 'Rejection reason', ar: 'سبب الرفض', ku: 'هۆکاری ڕەتکردنەوە');
  String get versions => _t(en: 'Versions', ar: 'الإصدارات', ku: 'وەشانەکان');
  String get view => _t(en: 'View', ar: 'عرض', ku: 'بینین');
  String get zoom => _t(en: 'Zoom', ar: 'تكبير', ku: 'گەورەکردن');
  String get download => _t(en: 'Download', ar: 'تنزيل', ku: 'داگرتن');
  String get print => _t(en: 'Print', ar: 'طباعة', ku: 'چاپ');

  String get legalReview => _t(en: 'Legal review', ar: 'المراجعة القانونية', ku: 'پێداچوونەوەی یاسایی');
  String get contractBuilder => _t(en: 'Contract builder', ar: 'منشئ العقد', ku: 'دروستکەری گرێبەست');
  String get structure => _t(en: 'Structure', ar: 'الهيكل', ku: 'پێکهاتە');
  String get document => _t(en: 'Document', ar: 'المستند', ku: 'بەڵگەنامە');
  String get clauseLibrary => _t(en: 'Clause library', ar: 'مكتبة البنود', ku: 'کتێبخانەی بڕگەکان');
  String get insertClause => _t(en: 'Insert authorized clause', ar: 'إدراج بند معتمد', ku: 'دانانی بڕگەی ڕێگەپێدراو');
  String get clauseDisclaimer => _t(
    en: 'Wording is controlled by authorized legal personnel. This library lists approved clause identifiers only.',
    ar: 'النص القانوني يُدار من الجهة القانونية المعتمدة. المكتبة تعرض معرفات البنود المعتمدة فقط.',
    ku: 'دەقی یاسایی لەلایەن کەسانی ڕێگەپێدراو کۆنتڕۆڵ دەکرێت. ئەم کتێبخانەیە تەنها ناسنامەی بڕگە پەسەندکراوەکان پیشان دەدات.',
  );
  String get saveDraft => _t(en: 'Save draft', ar: 'حفظ مسودة', ku: 'پاشەکەوتکردنی ڕەشنووس');
  String get compareVersions => _t(en: 'Compare versions', ar: 'مقارنة الإصدارات', ku: 'بەراوردکردنی وەشان');
  String get approveAndSend => _t(en: 'Approve & Send', ar: 'اعتماد وإرسال', ku: 'پەسەند و ناردن');
  String get generatePdf => _t(en: 'Generate official PDF', ar: 'إنشاء ملف PDF الرسمي', ku: 'دروستکردنی PDFی فەرمی');
  String get sentToBuyer => _t(en: 'Sent to buyer', ar: 'أُرسل للمشتري', ku: 'نێردرا بۆ کڕیار');
  String get sentToSeller => _t(en: 'Sent to seller', ar: 'أُرسل للبائع', ku: 'نێردرا بۆ فرۆشیار');
  String get readyToSend => _t(en: 'Ready to send', ar: 'جاهز للإرسال', ku: 'ئامادەیە بۆ ناردن');
  String get validationWarning => _t(en: 'Inconsistencies', ar: 'تعارضات', ku: 'ناڕێکیەکان');
  String get priceMismatch => _t(
    en: 'Property price in the contract differs from the authorized transaction amount.',
    ar: 'سعر العقار في العقد يختلف عن المبلغ المعتمد في المعاملة.',
    ku: 'نرخی موڵک لە گرێبەست جیاوازە لە بڕی ڕێگەپێدراوی مامەڵە.',
  );

  String get rentToOwn => _t(en: 'Rent-to-own', ar: 'إيجار تمليكي', ku: 'کرێ بۆ خاوەنداری');
  String get monthlyPayment => _t(en: 'Monthly payment', ar: 'الدفعة الشهرية', ku: 'پارەدانی مانگانە');
  String get duration => _t(en: 'Contract duration', ar: 'مدة العقد', ku: 'ماوەی گرێبەست');
  String get transferCondition =>
      _t(en: 'Ownership transfer condition', ar: 'شرط نقل الملكية', ku: 'مەرجی گواستنەوەی خاوەنداری');
  String get paymentSchedule => _t(en: 'Payment schedule', ar: 'جدول الدفع', ku: 'خشتەی پارەدان');
  String get initialPayment => _t(en: 'Initial payment', ar: 'الدفعة الأولى', ku: 'پارەدانی سەرەتا');

  String get executedLocked => _t(
    en: 'Executed contract is locked. Corrections require a formal amendment.',
    ar: 'العقد المنفَّذ مقفل. أي تصحيح يتطلب تعديلًا رسميًا.',
    ku: 'گرێبەستی جێبەجێکراو قوفڵ کراوە. چاککردن پێویستی بە دەستکاری فەرمی هەیە.',
  );
  String get amendment => _t(en: 'Amendment', ar: 'تعديل رسمي', ku: 'دەستکاری فەرمی');
  String get stageCompleted => _t(
    en: 'Contract stage completed. Next department has been notified.',
    ar: 'اكتملت مرحلة العقد. تم إشعار القسم التالي.',
    ku: 'قۆناغی گرێبەست تەواو بوو. بەشی داهاتوو ئاگادار کرا.',
  );
  String get handoffClosing =>
      _t(en: 'Closing / Transaction Lawyer', ar: 'محامي الإغلاق / المعاملة', ku: 'پارێزەری داخستن');
  String get handoffFinance => _t(en: 'Financial department', ar: 'القسم المالي', ku: 'بەشی دارایی');

  String get internalChat => _t(en: 'Internal legal team', ar: 'الفريق القانوني الداخلي', ku: 'تیمی یاسایی ناوخۆیی');
  String get customerChat => _t(en: 'Party messages', ar: 'رسائل الأطراف', ku: 'نامەی لایەنەکان');
  String get internalNeverCustomer => _t(
    en: 'Internal notes never appear to customers.',
    ar: 'الملاحظات الداخلية لا تظهر للعملاء أبداً.',
    ku: 'تێبینی ناوخۆیی هەرگیز پیشانی کڕیار نادرێت.',
  );
  String get auditTrail => _t(en: 'Audit trail', ar: 'سجل التدقيق', ku: 'شوێنپێی وردبینی');
  String get notifications => _t(en: 'Notifications', ar: 'الإشعارات', ku: 'ئاگادارکردنەوەکان');
  String get approachingDeadline => _t(en: 'Approaching deadline', ar: 'موعد قريب', ku: 'دوا وادەی نزیک');
  String get signOut => _t(en: 'Sign out', ar: 'تسجيل الخروج', ku: 'چوونەدەرەوە');
  String get darkMode => _t(en: 'Dark mode', ar: 'الوضع الداكن', ku: 'دۆخی تاریک');
  String get language => _t(en: 'Language', ar: 'اللغة', ku: 'زمان');

  String get priNormal => _t(en: 'Normal', ar: 'عادي', ku: 'ئاسایی');
  String get priPriority => _t(en: 'Priority', ar: 'أولوية', ku: 'گرنگ');
  String get priUrgent => _t(en: 'Urgent', ar: 'عاجل', ku: 'فوری');
  String get priBlocked => _t(en: 'Blocked', ar: 'متوقف', ku: 'وەستاو');

  String get actionReviewTx => _t(en: 'Review transaction', ar: 'مراجعة المعاملة', ku: 'پێداچوونەوەی مامەڵە');
  String get actionReviewDocs => _t(en: 'Review documents', ar: 'مراجعة المستندات', ku: 'پێداچوونەوەی بەڵگەنامە');
  String get actionMissing => _t(en: 'Request missing documents', ar: 'طلب مستندات ناقصة', ku: 'داواکردنی بەڵگەنامەی نەماو');
  String get actionPrepare => _t(en: 'Prepare contract', ar: 'إعداد العقد', ku: 'ئامادەکردنی گرێبەست');
  String get actionBuyer => _t(en: 'Awaiting buyer confirmation', ar: 'بانتظار تأكيد المشتري', ku: 'چاوەڕوانی پشتڕاستی کڕیار');
  String get actionSeller => _t(en: 'Awaiting seller confirmation', ar: 'بانتظار تأكيد البائع', ku: 'چاوەڕوانی پشتڕاستی فرۆشیار');
  String get actionOtp => _t(en: 'OTP verification pending', ar: 'التحقق بـ OTP معلّق', ku: 'OTP چاوەڕوانە');
  String get actionFace => _t(en: 'Face verification pending', ar: 'التحقق من الوجه معلّق', ku: 'پشتڕاستی ڕوو چاوەڕوانە');
  String get actionSign => _t(en: 'Electronic signature pending', ar: 'التوقيع الإلكتروني معلّق', ku: 'واژوو چاوەڕوانە');
  String get actionExecute => _t(en: 'Ready to execute', ar: 'جاهز للتنفيذ', ku: 'ئامادەیە بۆ جێبەجێکردن');
  String get actionUrgent => _t(en: 'Urgent legal issue', ar: 'مسألة قانونية عاجلة', ku: 'کێشەی یاسایی فوری');

  String get staffHubTitle => _t(en: 'Madar staff', ar: 'موظفو مدار', ku: 'کارمەندانی مەدار');
  String get staffHubBody => _t(
    en: 'Choose your workspace. Each role is isolated.',
    ar: 'اختر مساحة عملك. كل دور معزول عن الآخر.',
    ku: 'شوێنی کارت هەڵبژێرە. هەر ڕۆڵێک جیاکراوەتەوە.',
  );
  String get enterLegal => _t(en: 'Enter Contract Lawyer workspace', ar: 'دخول مساحة محامي العقود', ku: 'چوونە ناو شوێنی پارێزەری گرێبەست');
  String get financeUnavailable => _t(en: 'Finance workspace is separate and not available here.', ar: 'مساحة المالية منفصلة وغير متاحة هنا.', ku: 'شوێنی دارایی جیاوازە و لێرە بەردەست نییە.');
  String get bankUnavailable => _t(en: 'Bank employee workspace is separate and not available here.', ar: 'مساحة موظف البنك منفصلة وغير متاحة هنا.', ku: 'شوێنی کارمەندی بانک جیاوازە و لێرە بەردەست نییە.');
  String get officeUnavailable => _t(en: 'Office workspace uses Office Login.', ar: 'مساحة المكاتب عبر دخول المكتب.', ku: 'شوێنی ئۆفیس لە ڕێگەی چوونەژوورەوەی ئۆفیسە.');

  String get captureFace => _t(en: 'Capture face photo', ar: 'التقاط صورة الوجه', ku: 'وێنەی ڕوو بگرە');
  String get retakePhoto => _t(en: 'Retake', ar: 'إعادة الالتقاط', ku: 'دووبارە گرتن');
  String get confirmPhoto => _t(en: 'Confirm and continue', ar: 'تأكيد والمتابعة', ku: 'پشتڕاستکردنەوە و بەردەوامبوون');
  String get faceRequired => _t(
    en: 'Face verification is required. A photo is captured and stored for later identity matching. Skip is not available.',
    ar: 'التحقق من الوجه إلزامي. تُلتقط صورة وتُحفظ للمطابقة لاحقاً مع الهوية. لا يمكن التخطي.',
    ku: 'پشتڕاستکردنەوەی ڕوو پێویستە. وێنەیەک دەگیرێت و پاشەکەوت دەکرێت بۆ بەراورد لەگەڵ ناسنامە. تێپەڕاندن نییە.',
  );
  String get faceCaptureFailed => _t(
    en: 'Could not capture a photo. Face verification cannot be skipped.',
    ar: 'تعذر التقاط الصورة. لا يمكن تخطي التحقق من الوجه.',
    ku: 'نەتوانرا وێنە بگیرێت. ناتوانرێت پشتڕاستی ڕوو تێپەڕێنرێت.',
  );

  String get drawSignature => _t(en: 'Draw your signature', ar: 'ارسم توقيعك هنا', ku: 'واژووت لێرە بکێشە');
  String get undoStroke => _t(en: 'Undo', ar: 'تراجع', ku: 'گەڕانەوە');
  String get resign => _t(en: 'Re-sign', ar: 'إعادة التوقيع', ku: 'دووبارە واژوو');
  String get done => _t(en: 'Done', ar: 'تم', ku: 'تەواو');
  String get confirmSignature => _t(en: 'Confirm signature', ar: 'تأكيد التوقيع', ku: 'پشتڕاستکردنەوەی واژوو');
  String get signatureSaved => _t(en: 'Signature saved', ar: 'تم حفظ التوقيع', ku: 'واژوو پاشەکەوت کرا');
  String get signatureDone => _t(en: 'Signature confirmed', ar: 'تم تأكيد التوقيع', ku: 'واژوو پشتڕاست کرا');

  String get next => _t(en: 'Next', ar: 'التالي', ku: 'دواتر');
  String get cancel => _t(en: 'Cancel', ar: 'إلغاء', ku: 'هەڵوەشاندنەوە');
  String get save => _t(en: 'Save', ar: 'حفظ', ku: 'پاشەکەوت');
  String get send => _t(en: 'Send', ar: 'إرسال', ku: 'ناردن');
  String get close => _t(en: 'Close', ar: 'إغلاق', ku: 'داخستن');
  String get version => _t(en: 'Version', ar: 'الإصدار', ku: 'وەشان');
  String get createdBy => _t(en: 'Created by', ar: 'أنشئ بواسطة', ku: 'دروستکراوە لەلایەن');
  String get createdAt => _t(en: 'Created at', ar: 'تاريخ الإنشاء', ku: 'کاتی دروستکردن');
  String get changeNotes => _t(en: 'Change notes', ar: 'ملاحظات التغيير', ku: 'تێبینی گۆڕانکاری');
  String get both => _t(en: 'Both', ar: 'الطرفان', ku: 'هەردوولا');
  String get viewed => _t(en: 'Viewed', ar: 'اطّلع', ku: 'بینرا');
  String get confirmed => _t(en: 'Confirmed', ar: 'مؤكد', ku: 'پشتڕاستکراو');
  String get rejected => _t(en: 'Rejected', ar: 'مرفوض', ku: 'ڕەتکراوە');
  String get verified => _t(en: 'Verified', ar: 'موثّق', ku: 'پشتڕاستکراو');
  String get failed => _t(en: 'Failed', ar: 'فشل', ku: 'شکستی هێنا');
  String get signed => _t(en: 'Signed', ar: 'موقّع', ku: 'واژوو کراو');
  String get locked => _t(en: 'Locked', ar: 'مقفل', ku: 'قفڵکراو');
  String get executed => _t(en: 'Executed', ar: 'منفَّذ', ku: 'جێبەجێکراو');
  String get name => _t(en: 'Name', ar: 'الاسم', ku: 'ناو');
  String get whoRejected => _t(en: 'Who rejected', ar: 'من رفض', ku: 'کێ ڕەتیکردەوە');
  String get when => _t(en: 'When', ar: 'متى', ku: 'کەی');
  String get reason => _t(en: 'Reason', ar: 'السبب', ku: 'هۆکار');
  String get cannotBypass => _t(
    en: 'Verification cannot be bypassed by the lawyer.',
    ar: 'لا يمكن للمحامي تجاوز التحقق.',
    ku: 'پارێزەر ناتوانێت پشتڕاستکردنەوە تێپەڕێنێت.',
  );
}
