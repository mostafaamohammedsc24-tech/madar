import '../localization/app_localizations.dart';

class PhotoStrings {
  const PhotoStrings(this.lang);
  final AppLanguage lang;
  factory PhotoStrings.of(AppLocalizations loc) => PhotoStrings(loc.language);
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
  String get dept => _t(en: 'Property Photography', ar: 'تصوير العقارات', ku: 'وێنەگرتنی موڵک');
  String get role => _t(en: 'Photography Employee', ar: 'موظف التصوير', ku: 'کارمەندی وێنەگرتن');
  String get notOthers => _t(
        en: 'Not information, floor-plan, publishing, sales, or legal. Capture and deliver the media package only.',
        ar: 'ليست مساحة المعلومات أو المخططات أو النشر أو المبيعات أو القانون. التصوير وتسليم حزمة الوسائط فقط.',
        ku: 'زانیاری، نەخشە، بڵاوکردنەوە، فرۆشتن یان یاسا نییە.',
      );
  String get notPublish => _t(en: 'Cannot publish the listing or change price/legal data. Submit media to Publishing.', ar: 'لا يمكن نشر البطاقة أو تعديل السعر/القانون. تُسلَّم الوسائط لموظف النشر.', ku: 'ناتوانێت بڵاوبکاتەوە.');
  String get loginTitle => _t(en: 'Photography sign-in', ar: 'دخول موظف التصوير', ku: 'چوونەژوورەوەی وێنەگرتن');
  String get loginSubtitle => _t(en: 'Field photography credentials.', ar: 'بيانات مصوّر العقارات الميداني.', ku: 'ناسنامەی وێنەگر.');
  String get employeeId => _t(en: 'Employee ID', ar: 'رقم الموظف', ku: 'ناسنامە');
  String get employeeHint => _t(en: 'e.g. PHO-015', ar: 'مثال: PHO-015', ku: 'نموونە: PHO-015');
  String get secret => _t(en: 'Access code', ar: 'رمز الدخول', ku: 'کۆد');
  String get signIn => _t(en: 'Sign in', ar: 'دخول', ku: 'چوونەژوورەوە');
  String get invalid => _t(en: 'Invalid credentials.', ar: 'بيانات الدخول غير صحيحة.', ku: 'هەڵەیە.');
  String get enterPhoto => _t(en: 'Enter Photography workspace', ar: 'دخول مساحة التصوير', ku: 'چوونە ناو وێنەگرتن');
  String get navWork => _t(en: 'Work', ar: 'العمل', ku: 'کار');
  String get navAssign => _t(en: 'Assignments', ar: 'التكليفات', ku: 'ئەرکەکان');
  String get navMedia => _t(en: 'Media', ar: 'الوسائط', ku: 'میدیا');
  String get navTours => _t(en: '3D Tours', ar: 'الجولات ثلاثية الأبعاد', ku: 'گەشتی ٣د');
  String get navMsg => _t(en: 'Messages', ar: 'الرسائل', ku: 'نامەکان');
  String get navArchive => _t(en: 'Archive', ar: 'الأرشيف', ku: 'ئەرشیف');
  String get navProfile => _t(en: 'Profile', ar: 'الملف', ku: 'پرۆفایل');
  String get workQ => _t(en: 'Which properties do I photograph now?', ar: 'أي عقارات أصوّرها الآن؟', ku: 'کام موڵک وێنە بگرم؟');
  String get noActions => _t(en: 'No photography assignments need attention.', ar: 'لا توجد تكليفات تصوير تتطلب انتباهك.', ku: 'هیچ ئەرکێک نییە.');
  String get searchHint => _t(en: 'Property ID, request, address', ar: 'معرف العقار، الطلب، العنوان', ku: 'ناسنامە، داوا، ناونیشان');
  String get requiredAction => _t(en: 'Required action', ar: 'الإجراء المطلوب', ku: 'کرداری پێویست');
  String get all => _t(en: 'All', ar: 'الكل', ku: 'هەموو');
  String get start => _t(en: 'Start photography', ar: 'بدء التصوير', ku: 'دەستپێکردنی وێنە');
  String get confirmArrival => _t(en: 'Confirm arrival', ar: 'تأكيد الوصول', ku: 'پشتڕاستی گەیشتن');
  String get capture => _t(en: 'Capture', ar: 'التقاط', ku: 'گرتن');
  String get accept => _t(en: 'Accept', ar: 'قبول', ku: 'قبوڵ');
  String get retake => _t(en: 'Retake', ar: 'إعادة التقاط', ku: 'دووبارە');
  String get nextRoom => _t(en: 'Next room', ar: 'الغرفة التالية', ku: 'ژووری داهاتوو');
  String get missing => _t(en: 'Missing', ar: 'ناقص', ku: 'کەم');
  String get complete => _t(en: 'Complete', ar: 'مكتمل', ku: 'تەواو');
  String get review => _t(en: 'Review recommended', ar: 'مراجعة موصى بها', ku: 'پێداچوونەوە');
  String get duplicate => _t(en: 'Possible duplicate', ar: 'تكرار محتمل', ku: 'دووبارە');
  String get keep => _t(en: 'Keep', ar: 'إبقاء', ku: 'بهێڵەوە');
  String get markInternal => _t(en: 'Mark internal', ar: 'تعليم كداخلي', ku: 'ناوخۆیی');
  String get submit => _t(en: 'Submit media package', ar: 'تسليم حزمة الوسائط', ku: 'ناردنی میدیا');
  String get cannotSubmit => _t(en: 'Confirm arrival, finish required shots, resolve corrections and failed uploads first.', ar: 'أكد الوصول وأكمل اللقطات المطلوبة وحل التصحيحات والرفع الفاشل أولاً.', ku: 'گەیشتن و وێنە و چاکسازی تەواو بکە.');
  String get streams => _t(en: 'Other workstreams', ar: 'مسارات العمل الأخرى', ku: 'ڕێڕەوەکانی تر');
  String get information => _t(en: 'Information', ar: 'المعلومات', ku: 'زانیاری');
  String get floorPlan => _t(en: 'Floor plan', ar: 'المخطط', ku: 'نەخشە');
  String get publishing => _t(en: 'Publishing', ar: 'النشر', ku: 'بڵاوکردنەوە');
  String get photography => _t(en: 'Photography', ar: 'التصوير', ku: 'وێنەگرتن');
  String get publisher => _t(en: 'Publisher', ar: 'موظف النشر', ku: 'بڵاوکەرەوە');
  String get assigned => _t(en: 'Assigned', ar: 'المعيَّن', ku: 'دیاریکراو');
  String get visit => _t(en: 'Visit', ar: 'الزيارة', ku: 'سەردان');
  String get instructions => _t(en: 'Special instructions', ar: 'تعليمات خاصة', ku: 'ڕێنمایی');
  String get rooms => _t(en: 'Rooms', ar: 'الغرف', ku: 'ژوورەکان');
  String get gallery => _t(en: 'Gallery', ar: 'المعرض', ku: 'گەلەری');
  String get tour3d => _t(en: '3D tour', ar: 'الجولة ثلاثية الأبعاد', ku: 'گەشتی ٣د');
  String get pano => _t(en: '360°', ar: '٣٦٠°', ku: '٣٦٠°');
  String get uploads => _t(en: 'Upload center', ar: 'مركز الرفع', ku: 'بارکردن');
  String get package => _t(en: 'Media package', ar: 'حزمة الوسائط', ku: 'پاکێجی میدیا');
  String get story => _t(en: 'Property story', ar: 'تسلسل العرض', ku: 'چیرۆک');
  String get correction => _t(en: 'Correction request', ar: 'طلب تصحيح', ku: 'چاکسازی');
  String get audit => _t(en: 'Audit', ar: 'التدقيق', ku: 'وردبینی');
  String get signOut => _t(en: 'Sign out', ar: 'خروج', ku: 'دەرچوون');
  String get dark => _t(en: 'Dark mode', ar: 'الوضع الداكن', ku: 'تاریک');
  String get language => _t(en: 'Language', ar: 'اللغة', ku: 'زمان');
  String get notifications => _t(en: 'Notifications', ar: 'الإشعارات', ku: 'ئاگاداری');
  String get session => _t(en: 'Session', ar: 'الجلسة', ku: 'دانیشتن');
  String get send => _t(en: 'Send', ar: 'إرسال', ku: 'ناردن');
  String get save => _t(en: 'Saved', ar: 'محفوظ', ku: 'پاشەکەوت');
  String get saving => _t(en: 'Saving', ar: 'جارٍ الحفظ', ku: 'پاشەکەوت دەکرێت');
  String get offline => _t(en: 'Offline — queued locally', ar: 'بدون اتصال — في قائمة الانتظار', ku: 'ئۆفلاین');
  String get synced => _t(en: 'Synced', ar: 'متزامن', ku: 'هاوکات');
  String get mapHint => _t(en: 'Property pin and current GPS. Confirm arrival before capture.', ar: 'دبوس العقار والموقع الحالي. أكّد الوصول قبل التصوير.', ku: 'GPS و گەیشتن.');
  String get distance => _t(en: 'Distance', ar: 'المسافة', ku: 'دووری');
  String get addPoint => _t(en: 'Add 3D point', ar: 'إضافة نقطة ثلاثية الأبعاد', ku: 'خاڵی ٣د');
  String get addPano => _t(en: 'Capture 360°', ar: 'التقاط ٣٦٠°', ku: '٣٦٠ بگرە');
  String get coverage => _t(en: '3D coverage', ar: 'تغطية الجولة', ku: 'داپۆشینی ٣د');
  String get photos => _t(en: 'Photos', ar: 'الصور', ku: 'وێنەکان');
  String get required => _t(en: 'Required', ar: 'مطلوب', ku: 'پێویست');
  String get publicMedia => _t(en: 'Public suggestion', ar: 'اقتراح عام', ku: 'گشتی');
  String get internalMedia => _t(en: 'Internal', ar: 'داخلي', ku: 'ناوخۆیی');
  String get canDo => _t(en: 'Photograph, classify, capture 3D/360°, quality-check, and submit the media package.', ar: 'التصوير والتصنيف والجولة/٣٦٠° ومراجعة الجودة وتسليم الحزمة.', ku: 'وێنە، پۆلێن، ٣د، کوالێتی.');
  String get cannotDo => _t(en: 'Cannot publish listings, change measurements, or set Madar price.', ar: 'لا يمكن نشر العقارات أو تعديل القياسات أو تحديد سعر مدار.', ku: 'بڵاوکردنەوە یان نرخ ناكرێت.');
  String get nowNeed => _t(en: 'What I need now', ar: 'ما أحتاجه الآن', ku: 'ئێستا پێویستە');
}
