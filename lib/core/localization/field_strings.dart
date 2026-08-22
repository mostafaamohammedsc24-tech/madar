import '../localization/app_localizations.dart';

class FieldStrings {
  const FieldStrings(this.lang);
  final AppLanguage lang;
  factory FieldStrings.of(AppLocalizations loc) => FieldStrings(loc.language);
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
  String get dept => _t(en: 'Property Intelligence', ar: 'استخبارات العقار', ku: 'زانیاری موڵک');
  String get role => _t(en: 'Field Information Employee', ar: 'موظف المعلومات الميداني', ku: 'کارمەندی زانیاری مەیدانی');
  String get notOthers => _t(
        en: 'Not photography, floor-plan engineering, publishing, sales, or legal. Collect and verify facts only.',
        ar: 'ليست مساحة التصوير أو المخططات أو النشر أو المبيعات أو القانون. جمع الحقائق والتحقق منها فقط.',
        ku: 'وێنە، نەخشە، بڵاوکردنەوە، فرۆشتن یان یاسا نییە. تەنها کۆکردنەوە و پشتڕاستی ڕاستییەکان.',
      );
  String get notPublish => _t(en: 'Cannot publish the public listing. Submit the report to the Publishing Employee.', ar: 'لا يمكن نشر البطاقة العامة. يُسلَّم التقرير لموظف النشر.', ku: 'ناتوانێت لیستی گشتی بڵاوبکاتەوە.');
  String get loginTitle => _t(en: 'Field Information sign-in', ar: 'دخول موظف المعلومات', ku: 'چوونەژوورەوەی زانیاری');
  String get loginSubtitle => _t(en: 'Field survey credentials.', ar: 'بيانات موظف المسح الميداني.', ku: 'ناسنامەی پشکنینی مەیدانی.');
  String get employeeId => _t(en: 'Employee ID', ar: 'رقم الموظف', ku: 'ناسنامە');
  String get employeeHint => _t(en: 'e.g. INF-0020', ar: 'مثال: INF-0020', ku: 'نموونە: INF-0020');
  String get secret => _t(en: 'Access code', ar: 'رمز الدخول', ku: 'کۆد');
  String get signIn => _t(en: 'Sign in', ar: 'دخول', ku: 'چوونەژوورەوە');
  String get invalid => _t(en: 'Invalid credentials.', ar: 'بيانات الدخول غير صحيحة.', ku: 'هەڵەیە.');
  String get enterField => _t(en: 'Enter Field Information workspace', ar: 'دخول مساحة المعلومات الميدانية', ku: 'چوونە ناو زانیاری مەیدانی');
  String get navWork => _t(en: 'Work', ar: 'العمل', ku: 'کار');
  String get navAssign => _t(en: 'My Assignments', ar: 'تكليفاتي', ku: 'ئەرکەکانم');
  String get navProps => _t(en: 'Properties', ar: 'العقارات', ku: 'موڵکەکان');
  String get navReports => _t(en: 'Reports', ar: 'التقارير', ku: 'ڕاپۆرتەکان');
  String get navMsg => _t(en: 'Messages', ar: 'الرسائل', ku: 'نامەکان');
  String get navArchive => _t(en: 'Archive', ar: 'الأرشيف', ku: 'ئەرشیف');
  String get navProfile => _t(en: 'Profile', ar: 'الملف', ku: 'پرۆفایل');
  String get workQ => _t(en: 'Which properties do I need to inspect?', ar: 'أي عقارات يجب أن أعاينها؟', ku: 'کام موڵک پێویستی بە پشکنین هەیە؟');
  String get noActions => _t(en: 'No inspections require your attention.', ar: 'لا توجد معاينات تتطلب انتباهك.', ku: 'هیچ پشکنینێک نییە.');
  String get searchHint => _t(en: 'Property ID, request, address', ar: 'معرف العقار، الطلب، العنوان', ku: 'ناسنامە، داوا، ناونیشان');
  String get requiredAction => _t(en: 'Required action', ar: 'الإجراء المطلوب', ku: 'کرداری پێویست');
  String get all => _t(en: 'All', ar: 'الكل', ku: 'هەموو');
  String get start => _t(en: 'Start inspection', ar: 'بدء المعاينة', ku: 'دەستپێکردنی پشکنین');
  String get confirmArrival => _t(en: 'Confirm arrival', ar: 'تأكيد الوصول', ku: 'پشتڕاستی گەیشتن');
  String get gps => _t(en: 'GPS', ar: 'الموقع', ku: 'GPS');
  String get distance => _t(en: 'Distance', ar: 'المسافة', ku: 'دووری');
  String get progress => _t(en: 'Report completion', ar: 'اكتمال التقرير', ku: 'تەواوبوونی ڕاپۆرت');
  String get quality => _t(en: 'Data quality', ar: 'جودة البيانات', ku: 'کوالێتی داتا');
  String get conflict => _t(en: 'DATA CONFLICT', ar: 'تعارض بيانات', ku: 'ناکۆکی داتا');
  String get submit => _t(en: 'Submit property report', ar: 'تسليم تقرير العقار', ku: 'ناردنی ڕاپۆرت');
  String get cannotSubmit => _t(en: 'Resolve arrival, measurements, rooms, and conflicts first.', ar: 'أكمل الوصول والقياسات والغرف والتعارضات أولاً.', ku: 'گەیشتن و پێوانە و ژوور و ناکۆکی تەواو بکە.');
  String get metric => _t(en: 'Metric only (m, m²).', ar: 'وحدات مترية فقط (م، م²).', ku: 'تەنها مەتری.');
  String get observed => _t(en: 'Observed fact', ar: 'واقعة مشاهدة', ku: 'ڕاستی بینراو');
  String get owner => _t(en: 'Owner-provided', ar: 'من المالك', ku: 'لە خاوەن');
  String get estimated => _t(en: 'Estimated', ar: 'تقدير', ku: 'خەمڵاندن');
  String get unverified => _t(en: 'Unverified', ar: 'غير موثّق', ku: 'پشتڕاست‌نەکراو');
  String get transcription => _t(en: 'AI transcription — confirm', ar: 'تفريغ آلي — يحتاج تأكيداً', ku: 'نووسینی ئۆتۆماتیکی');
  String get confirmTx => _t(en: 'Confirm transcription', ar: 'تأكيد التفريغ', ku: 'پشتڕاستی نووسین');
  String get streams => _t(en: 'Other workstreams', ar: 'مسارات العمل الأخرى', ku: 'ڕێڕەوەکانی تر');
  String get photography => _t(en: 'Photography', ar: 'التصوير', ku: 'وێنەگرتن');
  String get floorPlan => _t(en: 'Floor plan', ar: 'المخطط', ku: 'نەخشە');
  String get publishing => _t(en: 'Publishing', ar: 'النشر', ku: 'بڵاوکردنەوە');
  String get rooms => _t(en: 'Rooms', ar: 'الغرف', ku: 'ژوورەکان');
  String get land => _t(en: 'Land', ar: 'الأرض', ku: 'زەوی');
  String get building => _t(en: 'Building', ar: 'المبنى', ku: 'بینا');
  String get nearby => _t(en: 'Nearby places', ar: 'الأماكن القريبة', ku: 'شوێنی نزیک');
  String get development => _t(en: 'Future development', ar: 'التطوير المستقبلي', ku: 'گەشەپێدانی داهاتوو');
  String get special => _t(en: "What's special", ar: 'ما يميز العقار', ku: 'تایبەتمەندی');
  String get risks => _t(en: 'Internal risks', ar: 'مخاطر داخلية', ku: 'مەترسی ناوخۆیی');
  String get inspection => _t(en: 'Inspection', ar: 'المعاينة', ku: 'پشکنین');
  String get voice => _t(en: 'Voice notes', ar: 'ملاحظات صوتية', ku: 'تێبینی دەنگی');
  String get versions => _t(en: 'Versions', ar: 'الإصدارات', ku: 'وەشان');
  String get correction => _t(en: 'Correction request', ar: 'طلب تصحيح', ku: 'چاکسازی');
  String get audit => _t(en: 'Audit', ar: 'التدقيق', ku: 'وردبینی');
  String get signOut => _t(en: 'Sign out', ar: 'خروج', ku: 'دەرچوون');
  String get dark => _t(en: 'Dark mode', ar: 'الوضع الداكن', ku: 'تاریک');
  String get language => _t(en: 'Language', ar: 'اللغة', ku: 'زمان');
  String get notifications => _t(en: 'Notifications', ar: 'الإشعارات', ku: 'ئاگاداری');
  String get session => _t(en: 'Session', ar: 'الجلسة', ku: 'دانیشتن');
  String get send => _t(en: 'Send', ar: 'إرسال', ku: 'ناردن');
  String get save => _t(en: 'Saved', ar: 'محفوظ', ku: 'پاشەکەوت');
  String get missing => _t(en: 'Missing', ar: 'ناقص', ku: 'کەم');
  String get complete => _t(en: 'Complete', ar: 'مكتمل', ku: 'تەواو');
  String get review => _t(en: 'Needs review', ar: 'يحتاج مراجعة', ku: 'پێداچوونەوە');
  String get addRoom => _t(en: 'Add room', ar: 'إضافة غرفة', ku: 'ژوور زیادبکە');
  String get resolve => _t(en: 'Flag / resolve', ar: 'تعليم / حل', ku: 'چارەسەر');
  String get report => _t(en: 'Property report', ar: 'تقرير العقار', ku: 'ڕاپۆرتی موڵک');
  String get canDo => _t(en: 'Collect, measure, inspect, verify, and submit factual property intelligence.', ar: 'جمع وقياس ومعاينة والتحقق وتسليم استخبارات العقار الوقائعية.', ku: 'کۆکردنەوە، پێوانە، پشکنین، پشتڕاستی.');
  String get cannotDo => _t(en: 'Cannot publish listings, take over photography/floor plans, or set Madar list price.', ar: 'لا يمكن نشر العقارات أو تولّي التصوير/المخططات أو تحديد سعر مدار.', ku: 'بڵاوکردنەوە یان نرخ دانان ناكرێت.');
  String get publisher => _t(en: 'Publisher', ar: 'موظف النشر', ku: 'بڵاوکەرەوە');
  String get assigned => _t(en: 'Assigned', ar: 'المعيَّن', ku: 'دیاریکراو');
  String get visit => _t(en: 'Visit', ar: 'الزيارة', ku: 'سەردان');
  String get origin => _t(en: 'Source', ar: 'المصدر', ku: 'سەرچاوە');
  String get rumor => _t(en: 'Not a verified fact', ar: 'ليست واقعة موثّقة', ku: 'ڕاستی پشتڕاست نییە');
  String get saving => _t(en: 'Saving', ar: 'جارٍ الحفظ', ku: 'پاشەکەوت دەکرێت');
  String get offline => _t(en: 'Offline — saved locally', ar: 'بدون اتصال — محفوظ محلياً', ku: 'ئۆفلاین — ناوخۆیی');
  String get synced => _t(en: 'Synced', ar: 'متزامن', ku: 'هاوکات');
  String get instructions => _t(en: 'Special instructions', ar: 'تعليمات خاصة', ku: 'ڕێنمایی تایبەت');
  String get infoStream => _t(en: 'Information', ar: 'المعلومات', ku: 'زانیاری');
  String get mapHint => _t(en: 'Property pin, current GPS, streets, nearby places.', ar: 'دبوس العقار، الموقع الحالي، الشارع، الأماكن القريبة.', ku: 'نیشانەی موڵک و GPS.');
  String get measuredArea => _t(en: 'Measured built area (m²)', ar: 'مساحة البناء المقاسة (م²)', ku: 'ڕووبەری پێوانەکراو');
  String get ownerArea => _t(en: 'Owner-claimed area (m²)', ar: 'مساحة يدّعيها المالك (م²)', ku: 'ڕووبەری خاوەن');
  String get photoRef => _t(en: 'Photo ref', ar: 'مرجع صورة', ku: 'سەرچاوەی وێنە');
  String get addVoice => _t(en: 'Add field note', ar: 'إضافة ملاحظة ميدانية', ku: 'تێبینی زیادبکە');
  String get arrivalAt => _t(en: 'Arrival', ar: 'وقت الوصول', ku: 'گەیشتن');
  String get targetGps => _t(en: 'Target coordinates', ar: 'الإحداثيات المستهدفة', ku: 'ئامانج');
  String get currentGps => _t(en: 'Current GPS', ar: 'الموقع الحالي', ku: 'GPS ئێستا');
  String get identity => _t(en: 'Identity', ar: 'هوية العقار', ku: 'ناسنامە');
  String get location => _t(en: 'Location', ar: 'الموقع الدقيق', ku: 'شوێن');
  String get utilities => _t(en: 'Utilities', ar: 'المرافق', ku: 'خزمەتگوزاری');
  String get neighborhood => _t(en: 'Neighborhood', ar: 'الحي', ku: 'گەڕەک');
  String get interior => _t(en: 'Interior', ar: 'الداخل', ku: 'ناوخۆ');
  String get exterior => _t(en: 'Exterior', ar: 'الخارج', ku: 'دەرەوە');
  String get construction => _t(en: 'Construction', ar: 'الإنشاء', ku: 'بیناسازی');
  String get investment => _t(en: 'Investment context', ar: 'السياق الاستثماري', ku: 'وەبەرهێنان');
  String get notes => _t(en: 'Notes', ar: 'الملاحظات', ku: 'تێبینی');
  String get reviewTitle => _t(en: 'Review before submit', ar: 'المراجعة قبل التسليم', ku: 'پێداچوونەوە');
  String get observation => _t(en: 'Field observation — not an official rating.', ar: 'ملاحظة ميدانية — ليست تصنيفاً رسمياً.', ku: 'تێبینی مەیدانی.');
}
