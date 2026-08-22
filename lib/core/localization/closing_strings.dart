import '../localization/app_localizations.dart';

class ClosingStrings {
  const ClosingStrings(this.lang);
  final AppLanguage lang;
  factory ClosingStrings.of(AppLocalizations loc) => ClosingStrings(loc.language);

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
  String get role => _t(
    en: 'Transaction & Closing Lawyer',
    ar: 'محامي المعاملة والإغلاق',
    ku: 'پارێزەری مامەڵە و داخستن',
  );
  String get notContract => _t(
    en: 'This is not the Contract Lawyer workspace. The contract stage is already completed.',
    ar: 'هذه ليست مساحة محامي العقود. مرحلة العقد مكتملة مسبقاً.',
    ku: 'ئەمە شوێنی پارێزەری گرێبەست نییە. قۆناغی گرێبەست پێشتر تەواو بووە.',
  );
  String get notPublic => _t(
    en: 'Not the public site, user app, office, bank, or finance workspace.',
    ar: 'ليست الموقع العام ولا تطبيق المستخدم ولا المكاتب أو البنك أو المالية.',
    ku: 'ماڵپەڕی گشتی، ئەپی بەکارهێنەر، ئۆفیس، بانک یان دارایی نییە.',
  );
  String get canDo => _t(
    en: 'Manage post-contract procedures, government steps, ownership transfer, document review, monitoring escrow/taxes/settlement, and closing when conditions are met.',
    ar: 'إدارة إجراءات ما بعد العقد، المعاملات الحكومية، نقل الملكية، مراجعة المستندات، متابعة الضمان والضرائب والتسوية، وإغلاق المعاملة عند اكتمال الشروط.',
    ku: 'بەڕێوەبردنی ڕێکارەکانی دوای گرێبەست، حکومەت، گواستنەوەی خاوەنداری، بەڵگەنامە، چاودێری ئێسکرۆ و باج و پێکدادان، داخستن کاتێک مەرجەکان تەواون.',
  );
  String get cannotDo => _t(
    en: 'Cannot draft or edit executed contracts, confirm bank deposits, release escrow, change commissions, manage staff/offices, or publish listings.',
    ar: 'لا يمكن صياغة أو تعديل العقود المنفَّذة، تأكيد الإيداعات البنكية، تحرير الضمان، تعديل العمولات، إدارة الموظفين/المكاتب، أو نشر العقارات.',
    ku: 'ناتوانێت گرێبەستی جێبەجێکراو بگۆڕێت، پارەدانی بانک پشتڕاست بکاتەوە، ئێسکرۆ ئازاد بکات، کۆمیسیون بگۆڕێت، کارمەند/ئۆفیس بەڕێوەببات یان موڵک بڵاوبکاتەوە.',
  );

  String get loginTitle => _t(en: 'Closing Lawyer sign-in', ar: 'دخول محامي الإغلاق', ku: 'چوونەژوورەوەی پارێزەری داخستن');
  String get loginSubtitle => _t(
    en: 'Transaction & Closing Lawyer credentials. Separate from Contract Lawyer login.',
    ar: 'بيانات محامي المعاملة والإغلاق. منفصلة عن دخول محامي العقود.',
    ku: 'ناسنامەی پارێزەری مامەڵە و داخستن. جیاوازە لە پارێزەری گرێبەست.',
  );
  String get employeeId => _t(en: 'Employee ID', ar: 'رقم الموظف', ku: 'ناسنامەی کارمەند');
  String get employeeHint => _t(en: 'e.g. LAW-0087', ar: 'مثال: LAW-0087', ku: 'نموونە: LAW-0087');
  String get secret => _t(en: 'Access code', ar: 'رمز الدخول', ku: 'کۆدی دەستگەیشتن');
  String get signIn => _t(en: 'Sign in', ar: 'دخول', ku: 'چوونەژوورەوە');
  String get invalid => _t(en: 'Invalid employee ID or access code.', ar: 'رقم الموظف أو رمز الدخول غير صحيح.', ku: 'ناسنامە یان کۆد هەڵەیە.');
  String get enterClosing => _t(en: 'Enter Transaction & Closing Lawyer workspace', ar: 'دخول مساحة محامي المعاملة والإغلاق', ku: 'چوونە ناو پارێزەری مامەڵە و داخستن');

  String get navWork => _t(en: 'Work', ar: 'العمل', ku: 'کار');
  String get navTx => _t(en: 'Transactions', ar: 'المعاملات', ku: 'مامەڵەکان');
  String get navFinance => _t(en: 'Financial Status', ar: 'الوضع المالي', ku: 'دۆخی دارایی');
  String get navGov => _t(en: 'Government Procedures', ar: 'الإجراءات الحكومية', ku: 'ڕێکارە حکومییەکان');
  String get navDocs => _t(en: 'Documents', ar: 'المستندات', ku: 'بەڵگەنامەکان');
  String get navMsg => _t(en: 'Messages', ar: 'الرسائل', ku: 'نامەکان');
  String get navArchive => _t(en: 'Archive', ar: 'الأرشيف', ku: 'ئەرشیف');
  String get navProfile => _t(en: 'Profile', ar: 'الملف', ku: 'پرۆفایل');

  String get workQ => _t(en: 'What transaction requires my attention right now?', ar: 'أي معاملة تتطلب انتباهي الآن؟', ku: 'کام مامەڵە ئێستا پێویستی بە سەرنجم هەیە؟');
  String get noActions => _t(en: 'No legal procedures require your attention.', ar: 'لا توجد إجراءات قانونية تتطلب انتباهك.', ku: 'هیچ ڕێکارێکی یاسایی پێویستی بە سەرنجت نییە.');
  String get searchHint => _t(
    en: 'Transaction number, property ID, phone, ID, barcode, address, office, date, status',
    ar: 'رقم المعاملة، معرف العقار، هاتف، هوية، باركود، عنوان، مكتب، تاريخ، حالة',
    ku: 'ژمارەی مامەڵە، ناسنامەی موڵک، تەلەفۆن، بارکۆد، ناونیشان، ئۆفیس، بەروار، دۆخ',
  );
  String get requiredAction => _t(en: 'Required action', ar: 'الإجراء المطلوب', ku: 'کرداری پێویست');
  String get currentStage => _t(en: 'Current stage', ar: 'المرحلة الحالية', ku: 'قۆناغی ئێستا');
  String get responsible => _t(en: 'Responsible department', ar: 'القسم المسؤول', ku: 'بەشی بەرپرس');
  String get lastActivity => _t(en: 'Last activity', ar: 'آخر نشاط', ku: 'دوایین چالاکی');
  String get buyer => _t(en: 'Buyer', ar: 'المشتري', ku: 'کڕیار');
  String get seller => _t(en: 'Seller', ar: 'البائع', ku: 'فرۆشیار');
  String get property => _t(en: 'Property', ar: 'العقار', ku: 'موڵک');
  String get amount => _t(en: 'Amount', ar: 'المبلغ', ku: 'بڕ');
  String get office => _t(en: 'Office', ar: 'المكتب', ku: 'ئۆفیس');
  String get country => _t(en: 'Country', ar: 'الدولة', ku: 'وڵات');
  String get status => _t(en: 'Status', ar: 'الحالة', ku: 'دۆخ');
  String get priority => _t(en: 'Priority', ar: 'الأولوية', ku: 'گرنگی');
  String get filter => _t(en: 'Filter', ar: 'تصفية', ku: 'فلتەر');

  String get priN => _t(en: 'Normal', ar: 'عادي', ku: 'ئاسایی');
  String get priP => _t(en: 'Priority', ar: 'أولوية', ku: 'گرنگ');
  String get priU => _t(en: 'Urgent', ar: 'عاجل', ku: 'فوری');
  String get priB => _t(en: 'Blocked', ar: 'متوقف', ku: 'وەستاو');

  String get digital => _t(en: 'Digital procedures', ar: 'إجراءات رقمية', ku: 'ڕێکاری دیجیتاڵ');
  String get physical => _t(en: 'Physical / government procedures', ar: 'إجراءات حضورية / حكومية', ku: 'ڕێکاری ئامادەبوون / حکومی');

  String get handoff => _t(en: 'Post-contract handoff', ar: 'تسليم ما بعد العقد', ku: 'ڕادەستکردنی دوای گرێبەست');
  String get contractCompleted => _t(en: 'Contract stage completed', ar: 'مرحلة العقد مكتملة', ku: 'قۆناغی گرێبەست تەواو');
  String get assignedHere => _t(en: 'Transaction & Closing Lawyer assigned', ar: 'تم تعيين محامي المعاملة والإغلاق', ku: 'پارێزەری مامەڵە و داخستن دیاریکرا');

  String get escrow => _t(en: 'Escrow', ar: 'الضمان', ku: 'ئێسکرۆ');
  String get bank => _t(en: 'Bank', ar: 'البنك', ku: 'بانک');
  String get bankCannotConfirm => _t(
    en: 'Bank confirmation originates from the banking workflow. This lawyer cannot mark a deposit as confirmed.',
    ar: 'تأكيد البنك يصدر من مسار العمل البنكي. لا يمكن لهذا المحامي تعليم الإيداع كمؤكد.',
    ku: 'پشتڕاستی بانک لە وۆرکفلۆی بانک دێت. ئەم پارێزەرە ناتوانێت پارەدان وەک پشتڕاست نیشان بدات.',
  );
  String get requiredDeposit => _t(en: 'Required deposit', ar: 'الإيداع المطلوب', ku: 'پارەدانی پێویست');
  String get confirmedAmount => _t(en: 'Confirmed amount', ar: 'المبلغ المؤكد', ku: 'بڕی پشتڕاست');
  String get receipt => _t(en: 'Receipt', ar: 'الإيصال', ku: 'وەسڵ');
  String get releaseConditions => _t(en: 'Escrow release conditions', ar: 'شروط تحرير الضمان', ku: 'مەرجەکانی ئازادکردنی ئێسکرۆ');

  String get tax => _t(en: 'Taxes & fees', ar: 'الضرائب والرسوم', ku: 'باج و کرێ');
  String get financeReq => _t(en: 'Request to Financial Department', ar: 'طلب إلى القسم المالي', ku: 'داوا بۆ بەشی دارایی');
  String get cannotChangeFinance => _t(en: 'Financial amounts are controlled by Finance. Adjustments require a request.', ar: 'المبالغ المالية تُدار من المالية. أي تعديل يتطلب طلباً.', ku: 'بڕە داراییەکان لای داراییە. گۆڕانکاری پێویستی بە داوایە.');

  String get gov => _t(en: 'Government procedures', ar: 'الإجراءات الحكومية', ku: 'ڕێکارە حکومییەکان');
  String get transfer => _t(en: 'Ownership transfer', ar: 'نقل الملكية', ku: 'گواستنەوەی خاوەنداری');
  String get attend => _t(en: 'Physical attendance required', ar: 'يلزم الحضور الشخصي', ku: 'ئامادەبوونی کەسی پێویستە');
  String get futureDigital => _t(en: 'Workflow is ready for a future digital transfer. No fake government API.', ar: 'المسار جاهز لنقل رقمي لاحقاً. لا يوجد تكامل حكومي وهمي.', ku: 'وۆرکفلۆ ئامادەیە بۆ گواستنەوەی دیجیتاڵ دواتر. APIی ساختە نییە.');
  String get appointment => _t(en: 'Appointment', ar: 'الموعد', ku: 'کات');
  String get deed => _t(en: 'Ownership document', ar: 'سند الملكية', ku: 'بەڵگەنامەی خاوەنداری');

  String get approve => _t(en: 'Approve', ar: 'اعتماد', ku: 'پەسەند');
  String get reject => _t(en: 'Reject', ar: 'رفض', ku: 'ڕەتکردنەوە');
  String get replace => _t(en: 'Request replacement', ar: 'طلب بدل', ku: 'داواکردنی جێگرەوە');
  String get view => _t(en: 'View', ar: 'عرض', ku: 'بینین');
  String get escalate => _t(en: 'Escalate', ar: 'تصعيد', ku: 'بەرزکردنەوە');
  String get closeTx => _t(en: 'Close transaction', ar: 'إغلاق المعاملة', ku: 'داخستنی مامەڵە');
  String get finalReport => _t(en: 'Final transaction report', ar: 'التقرير النهائي للمعاملة', ku: 'ڕاپۆرتی کۆتایی مامەڵە');
  String get completed => _t(en: 'Transaction completed', ar: 'المعاملة مكتملة', ku: 'مامەڵە تەواو بوو');
  String get internalNotes => _t(en: 'Internal legal notes', ar: 'ملاحظات قانونية داخلية', ku: 'تێبینی یاسایی ناوخۆیی');
  String get customerNotes => _t(en: 'Customer-visible notes', ar: 'ملاحظات ظاهرة للعميل', ku: 'تێبینی بۆ کڕیار');
  String get neverMix => _t(en: 'Internal notes never appear to customers.', ar: 'الملاحظات الداخلية لا تظهر للعملاء أبداً.', ku: 'تێبینی ناوخۆیی هەرگیز پیشانی کڕیار نادرێت.');
  String get audit => _t(en: 'Audit trail', ar: 'سجل التدقيق', ku: 'شوێنپێی وردبینی');
  String get services => _t(en: 'Affiliated services', ar: 'خدمات تابعة', ku: 'خزمەتگوزاری پەیوەست');
  String get signOut => _t(en: 'Sign out', ar: 'خروج', ku: 'چوونەدەرەوە');
  String get dark => _t(en: 'Dark mode', ar: 'الوضع الداكن', ku: 'دۆخی تاریک');
  String get language => _t(en: 'Language', ar: 'اللغة', ku: 'زمان');
  String get notifications => _t(en: 'Notifications', ar: 'الإشعارات', ku: 'ئاگادارکردنەوە');
  String get save => _t(en: 'Save', ar: 'حفظ', ku: 'پاشەکەوت');
  String get send => _t(en: 'Send', ar: 'إرسال', ku: 'ناردن');
  String get cancel => _t(en: 'Cancel', ar: 'إلغاء', ku: 'هەڵوەشاندنەوە');
  String get close => _t(en: 'Close', ar: 'إغلاق', ku: 'داخستن');
  String get session => _t(en: 'Session', ar: 'الجلسة', ku: 'دانیشتن');
  String get approaching => _t(en: 'Approaching deadline', ar: 'موعد قريب', ku: 'دوا وادەی نزیک');
  String get userId => _t(en: 'Madar user ID', ar: 'معرف مستخدم مدار', ku: 'ناسنامەی بەکارهێنەر');
  String get phone => _t(en: 'Phone', ar: 'الهاتف', ku: 'تەلەفۆن');
  String get propertyId => _t(en: 'Property ID', ar: 'معرف العقار', ku: 'ناسنامەی موڵک');
  String get address => _t(en: 'Address', ar: 'العنوان', ku: 'ناونیشان');
  String get openProperty => _t(en: 'Open property record', ar: 'فتح سجل العقار', ku: 'کردنەوەی تۆماری موڵک');
  String get agricultural => _t(en: 'Agricultural workflow', ar: 'مسار العقار الزراعي', ku: 'وۆرکفلۆی کشتوکاڵی');
  String get propertyType => _t(en: 'Property type', ar: 'نوع العقار', ku: 'جۆری موڵک');
  String get area => _t(en: 'Area', ar: 'المساحة', ku: 'ڕووبەر');
  String get ownership => _t(en: 'Ownership', ar: 'الملكية', ku: 'خاوەنداری');
  String get currentOwner => _t(en: 'Current owner', ar: 'المالك الحالي', ku: 'خاوەنی ئێستا');
  String get assigned => _t(en: 'Assigned lawyer', ar: 'المحامي المعيَّن', ku: 'پارێزەری دیاریکراو');
  String get txType => _t(en: 'Transaction type', ar: 'نوع المعاملة', ku: 'جۆری مامەڵە');
  String get identity => _t(en: 'Identity verification', ar: 'التحقق من الهوية', ku: 'پشتڕاستی ناسنامە');
  String get paymentStatus => _t(en: 'Payment status', ar: 'حالة الدفع', ku: 'دۆخی پارەدان');
  String get signatureStatus => _t(en: 'Signature status', ar: 'حالة التوقيع', ku: 'دۆخی واژوو');
  String get transferStatus => _t(en: 'Ownership transfer status', ar: 'حالة نقل الملكية', ku: 'دۆخی گواستنەوە');
  String get docsStatus => _t(en: 'Documents', ar: 'المستندات', ku: 'بەڵگەنامەکان');
  String get waitingWhy => _t(en: 'Waiting because', ar: 'بانتظار بسبب', ku: 'چاوەڕوان لەبەر');
  String get blockedWhy => _t(en: 'Blocked because', ar: 'متوقف بسبب', ku: 'وەستاو لەبەر');
  String get checklist => _t(en: 'Closing conditions', ar: 'شروط الإغلاق', ku: 'مەرجەکانی داخستن');
  String get cannotClose => _t(en: 'Cannot close until every required condition is satisfied.', ar: 'لا يمكن الإغلاق قبل استيفاء كل الشروط المطلوبة.', ku: 'ناتوانرێت دابخرێت تا هەموو مەرجەکان تەواو بن.');
  String get bankEmployee => _t(en: 'Bank employee', ar: 'موظف البنك', ku: 'کارمەندی بانک');
  String get depositDeadline => _t(en: 'Deposit deadline', ar: 'موعد الإيداع', ku: 'دوا وادەی پارەدان');
  String get confirmationTime => _t(en: 'Confirmation time', ar: 'وقت التأكيد', ku: 'کاتی پشتڕاستی');
  String get requestFinanceHint => _t(en: 'Describe the required financial adjustment', ar: 'صف التعديل المالي المطلوب', ku: 'گۆڕانکاری دارایی پێویست بنووسە');
  String get escalateHint => _t(en: 'Escalation reason', ar: 'سبب التصعيد', ku: 'هۆکاری بەرزکردنەوە');
  String get noteHint => _t(en: 'Note', ar: 'ملاحظة', ku: 'تێبینی');
  String get messageHint => _t(en: 'Message — always includes transaction number and property', ar: 'رسالة — تتضمن دائماً رقم المعاملة والعقار', ku: 'نامە — هەمیشە ژمارەی مامەڵە و موڵک لەخۆدەگرێت');
  String get internalChat => _t(en: 'Internal legal team', ar: 'الفريق القانوني الداخلي', ku: 'تیمی یاسایی ناوخۆیی');
  String get customerChat => _t(en: 'Customer communication', ar: 'تواصل العملاء', ku: 'پەیوەندی کڕیار');
  String get zoom => _t(en: 'Zoom', ar: 'تكبير', ku: 'گەورەکردن');
  String get rotate => _t(en: 'Rotate', ar: 'تدوير', ku: 'سوڕاندن');
  String get download => _t(en: 'Download', ar: 'تنزيل', ku: 'داگرتن');
  String get print => _t(en: 'Print', ar: 'طباعة', ku: 'چاپ');
  String get versions => _t(en: 'Versions', ar: 'الإصدارات', ku: 'وەشانەکان');
  String get location => _t(en: 'Location', ar: 'الموقع', ku: 'شوێن');
  String get date => _t(en: 'Date', ar: 'التاريخ', ku: 'بەروار');
  String get time => _t(en: 'Time', ar: 'الوقت', ku: 'کات');
  String get buyerAttend => _t(en: 'Buyer attendance', ar: 'حضور المشتري', ku: 'ئامادەبوونی کڕیار');
  String get sellerAttend => _t(en: 'Seller attendance', ar: 'حضور البائع', ku: 'ئامادەبوونی فرۆشیار');
  String get lawyerAttend => _t(en: 'Lawyer attendance', ar: 'حضور المحامي', ku: 'ئامادەبوونی پارێزەر');
  String get markTransferDone => _t(en: 'Record physical transfer completed', ar: 'تسجيل اكتمال النقل الحضوري', ku: 'تۆمارکردنی تەواوبوونی گواستنەوە');
  String get permissions => _t(en: 'Permissions', ar: 'الصلاحيات', ku: 'مۆڵەتەکان');
  String get allFilter => _t(en: 'All', ar: 'الكل', ku: 'هەموو');
  String get staffHubClosing => _t(en: 'Transaction & Closing Lawyer', ar: 'محامي المعاملة والإغلاق', ku: 'پارێزەری مامەڵە و داخستن');
  String get contractId => _t(en: 'Contract ID', ar: 'معرف العقد', ku: 'ناسنامەی گرێبەست');
  String get executedVersion => _t(en: 'Executed version', ar: 'النسخة المنفَّذة', ku: 'وەشانی جێبەجێکراو');
  String get executionDate => _t(en: 'Execution date', ar: 'تاريخ التنفيذ', ku: 'بەرواری جێبەجێکردن');
  String get contractLawyer => _t(en: 'Contract Lawyer', ar: 'محامي العقود', ku: 'پارێزەری گرێبەست');
  String get receipts => _t(en: 'Official receipts', ar: 'الإيصالات الرسمية', ku: 'وەسڵی فەرمی');
  String get receiptsLocked => _t(en: 'Official receipts cannot be forged or modified.', ar: 'لا يمكن تزوير أو تعديل الإيصالات الرسمية.', ku: 'وەسڵی فەرمی ناتوانرێت بگۆڕدرێت.');
  String get special => _t(en: 'Special conditions', ar: 'شروط خاصة', ku: 'مەرجی تایبەت');
  String get land => _t(en: 'Land information', ar: 'معلومات الأرض', ku: 'زانیاری زەوی');
  String get govInfo => _t(en: 'Government information', ar: 'معلومات حكومية', ku: 'زانیاری حکومی');
  String get propertyStatus => _t(en: 'Property status', ar: 'حالة العقار', ku: 'دۆخی موڵک');
  String get outstanding => _t(en: 'Outstanding', ar: 'المتبقي', ku: 'ماوە');
  String get clearance => _t(en: 'Financial clearance', ar: 'التصفية المالية', ku: 'پاککردنەوەی دارایی');
  String get sellerPayout => _t(en: 'Seller amount', ar: 'مبلغ البائع', ku: 'بڕی فرۆشیار');
  String get companyFees => _t(en: 'Company fees', ar: 'رسوم الشركة', ku: 'کرێی کۆمپانیا');
  String get finalSeller => _t(en: 'Final seller amount', ar: 'صافي البائع', ku: 'بڕی کۆتایی فرۆشیار');
  String get commission => _t(en: 'Commission', ar: 'العمولة', ku: 'کۆمیسیون');
  String get reference => _t(en: 'Reference number', ar: 'الرقم المرجعي', ku: 'ژمارەی سەرچاوە');
  String get expected => _t(en: 'Expected completion', ar: 'الاكتمال المتوقع', ku: 'تەواوبوونی چاوەڕوانکراو');
  String get authority => _t(en: 'Authority', ar: 'الجهة', ku: 'دەسەڵات');
  String get correction => _t(en: 'Required correction', ar: 'التصحيح المطلوب', ku: 'چاکسازی پێویست');
  String get rejectionReason => _t(en: 'Rejection reason', ar: 'سبب الرفض', ku: 'هۆکاری ڕەتکردنەوە');
  String get addInternal => _t(en: 'Add internal note', ar: 'إضافة ملاحظة داخلية', ku: 'زیادکردنی تێبینی ناوخۆیی');
  String get addCustomer => _t(en: 'Add customer note', ar: 'إضافة ملاحظة للعميل', ku: 'زیادکردنی تێبینی بۆ کڕیار');
  String get checkContract => _t(en: 'Contract executed', ar: 'العقد منفَّذ', ku: 'گرێبەست جێبەجێکراو');
  String get checkEscrow => _t(en: 'Escrow confirmed', ar: 'الضمان مؤكد', ku: 'ئێسکرۆ پشتڕاست');
  String get checkTax => _t(en: 'Required taxes paid', ar: 'الضرائب المطلوبة مدفوعة', ku: 'باج دراوە');
  String get checkGov => _t(en: 'Government procedures completed', ar: 'الإجراءات الحكومية مكتملة', ku: 'ڕێکاری حکومی تەواو');
  String get checkTransfer => _t(en: 'Ownership transfer completed', ar: 'نقل الملكية مكتمل', ku: 'گواستنەوە تەواو');
  String get checkDeed => _t(en: 'Ownership document verified', ar: 'سند الملكية موثّق', ku: 'بەڵگەنامە پشتڕاست');
  String get checkSettle => _t(en: 'Financial settlement completed', ar: 'التسوية المالية مكتملة', ku: 'پێکدادانی دارایی تەواو');
  String get checkReceipts => _t(en: 'Required receipts generated', ar: 'الإيصالات المطلوبة صادرة', ku: 'وەسڵەکان دەرچوون');
  String get checkFinal => _t(en: 'Final conditions satisfied', ar: 'الشروط النهائية مستوفاة', ku: 'مەرجە کۆتاییەکان تەواون');
  String get completionDate => _t(en: 'Completion date', ar: 'تاريخ الاكتمال', ku: 'بەرواری تەواوبوون');
  String get finalOwner => _t(en: 'Final property owner', ar: 'المالك النهائي', ku: 'خاوەنی کۆتایی');
  String get numbering => _t(en: 'Country numbering prefix', ar: 'بادئة ترقيم الدولة', ku: 'پێشگری ژمارەدان');
  String get transferMode => _t(en: 'Ownership transfer mode', ar: 'نمط نقل الملكية', ku: 'شێوازی گواستنەوە');
  String get skipDeed => _t(en: 'Ownership document skipped (country / agricultural rule)', ar: 'تم تخطي سند الملكية وفق قاعدة الدولة/الزراعي', ku: 'بەڵگەنامە تێپەڕێنراوە بەپێی یاسا');

  String stage(ClosingTimelineLabel k) {
    switch (k) {
      case ClosingTimelineLabel.identity:
        return _t(en: 'Identity verification', ar: 'التحقق من الهوية', ku: 'پشتڕاستی ناسنامە');
      case ClosingTimelineLabel.documents:
        return _t(en: 'Required documents', ar: 'المستندات المطلوبة', ku: 'بەڵگەنامەی پێویست');
      case ClosingTimelineLabel.contract:
        return _t(en: 'Contract', ar: 'العقد', ku: 'گرێبەست');
      case ClosingTimelineLabel.confirm:
        return _t(en: 'Contract confirmation', ar: 'تأكيد العقد', ku: 'پشتڕاستی گرێبەست');
      case ClosingTimelineLabel.otp:
        return _t(en: 'OTP verification', ar: 'التحقق بـ OTP', ku: 'OTP');
      case ClosingTimelineLabel.face:
        return _t(en: 'Face verification', ar: 'التحقق من الوجه', ku: 'پشتڕاستی ڕوو');
      case ClosingTimelineLabel.sign:
        return _t(en: 'Electronic signature', ar: 'التوقيع الإلكتروني', ku: 'واژووی ئەلیکترۆنی');
      case ClosingTimelineLabel.escrow:
        return _t(en: 'Escrow deposit', ar: 'إيداع الضمان', ku: 'پارەدانی ئێسکرۆ');
      case ClosingTimelineLabel.tax:
        return _t(en: 'Tax / financial settlement', ar: 'الضرائب / التسوية المالية', ku: 'باج / پێکدادانی دارایی');
      case ClosingTimelineLabel.gov:
        return _t(en: 'Government procedures', ar: 'الإجراءات الحكومية', ku: 'ڕێکاری حکومی');
      case ClosingTimelineLabel.transfer:
        return _t(en: 'Ownership transfer', ar: 'نقل الملكية', ku: 'گواستنەوەی خاوەنداری');
      case ClosingTimelineLabel.deed:
        return _t(en: 'Ownership document', ar: 'سند الملكية', ku: 'بەڵگەنامەی خاوەنداری');
      case ClosingTimelineLabel.settle:
        return _t(en: 'Final settlement', ar: 'التسوية النهائية', ku: 'پێکدادانی کۆتایی');
      case ClosingTimelineLabel.closed:
        return _t(en: 'Transaction closed', ar: 'إغلاق المعاملة', ku: 'داخستنی مامەڵە');
    }
  }
}

enum ClosingTimelineLabel {
  identity,
  documents,
  contract,
  confirm,
  otp,
  face,
  sign,
  escrow,
  tax,
  gov,
  transfer,
  deed,
  settle,
  closed,
}
