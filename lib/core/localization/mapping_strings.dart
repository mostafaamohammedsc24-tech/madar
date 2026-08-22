import '../localization/app_localizations.dart';

class MappingStrings {
  const MappingStrings(this.lang);
  final AppLanguage lang;
  factory MappingStrings.of(AppLocalizations loc) => MappingStrings(loc.language);

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
  String get dept => _t(en: 'Property Engineering', ar: 'هندسة العقارات', ku: 'ئەندازیاری موڵک');
  String get role => _t(en: 'Floor Plan Engineer', ar: 'مهندس المخططات', ku: 'ئەندازیاری نەخشە');
  String get notInfo => _t(
        en: 'Not the Information, Photography, or Publishing employee. This workspace prepares the engineering layer only.',
        ar: 'ليست مساحة موظف المعلومات أو التصوير أو النشر. هذه المساحة تُعد الطبقة الهندسية فقط.',
        ku: 'شوێنی کارمەندی زانیاری، وێنەگرتن یان بڵاوکردنەوە نییە. تەنها چینە ئەندازیارییەکە ئامادە دەکات.',
      );
  String get notPublish => _t(
        en: 'The engineer cannot publish the public listing. Submit engineering data to the Publishing Employee.',
        ar: 'لا يمكن للمهندس نشر البطاقة العامة. يُسلَّم العمل الهندسي لموظف النشر.',
        ku: 'ئەندازیار ناتوانێت لیستی گشتی بڵاوبکاتەوە. داتا بۆ کارمەندی بڵاوکردنەوە دەنێردرێت.',
      );

  String get loginTitle => _t(en: 'Floor Plan Engineer sign-in', ar: 'دخول مهندس المخططات', ku: 'چوونەژوورەوەی ئەندازیاری نەخشە');
  String get loginSubtitle => _t(
        en: 'Property mapping credentials. Separate from publishing, photography, and information roles.',
        ar: 'بيانات مهندس المخططات المكانية. منفصلة عن النشر والتصوير والمعلومات.',
        ku: 'ناسنامەی نەخشەی موڵک. جیاوازە لە بڵاوکردنەوە و وێنە و زانیاری.',
      );
  String get employeeId => _t(en: 'Employee ID', ar: 'رقم الموظف', ku: 'ناسنامەی کارمەند');
  String get employeeHint => _t(en: 'e.g. MAP-0042', ar: 'مثال: MAP-0042', ku: 'نموونە: MAP-0042');
  String get secret => _t(en: 'Access code', ar: 'رمز الدخول', ku: 'کۆدی دەستگەیشتن');
  String get signIn => _t(en: 'Sign in', ar: 'دخول', ku: 'چوونەژوورەوە');
  String get invalid => _t(en: 'Invalid employee ID or access code.', ar: 'رقم الموظف أو رمز الدخول غير صحيح.', ku: 'ناسنامە یان کۆد هەڵەیە.');
  String get enterMapping => _t(en: 'Enter Floor Plan Engineer workspace', ar: 'دخول مساحة مهندس المخططات', ku: 'چوونە ناو ئەندازیاری نەخشە');

  String get navWork => _t(en: 'Work', ar: 'العمل', ku: 'کار');
  String get navProps => _t(en: 'My Properties', ar: 'عقاراتي', ku: 'موڵکەکانم');
  String get navPlans => _t(en: 'Floor Plans', ar: 'المخططات', ku: 'نەخشەکان');
  String get nav3d => _t(en: '3D Connections', ar: 'ربط ثلاثي الأبعاد', ku: 'پەیوەندی ٣د');
  String get navMeas => _t(en: 'Measurements', ar: 'القياسات', ku: 'پێوانەکان');
  String get navReview => _t(en: 'Review', ar: 'المراجعة', ku: 'پێداچوونەوە');
  String get navArchive => _t(en: 'Archive', ar: 'الأرشيف', ku: 'ئەرشیف');
  String get navMsg => _t(en: 'Messages', ar: 'الرسائل', ku: 'نامەکان');
  String get navProfile => _t(en: 'Profile', ar: 'الملف', ku: 'پرۆفایل');

  String get workQ => _t(en: 'What property needs my work right now?', ar: 'أي عقار يحتاج عملي الآن؟', ku: 'کام موڵک ئێستا پێویستی بە کارم هەیە؟');
  String get noActions => _t(en: 'No floor-plan requests require your attention.', ar: 'لا توجد طلبات مخططات تتطلب انتباهك.', ku: 'هیچ داوای نەخشەیەک پێویستی بە سەرنجت نییە.');
  String get searchHint => _t(en: 'Property ID, request number, address', ar: 'معرف العقار، رقم الطلب، العنوان', ku: 'ناسنامەی موڵک، ژمارەی داوا، ناونیشان');
  String get requiredAction => _t(en: 'Required action', ar: 'الإجراء المطلوب', ku: 'کرداری پێویست');
  String get status => _t(en: 'Status', ar: 'الحالة', ku: 'دۆخ');
  String get priority => _t(en: 'Priority', ar: 'الأولوية', ku: 'گرنگی');
  String get all => _t(en: 'All', ar: 'الكل', ku: 'هەموو');
  String get propertyId => _t(en: 'Property ID', ar: 'معرف العقار', ku: 'ناسنامەی موڵک');
  String get requestNo => _t(en: 'Request number', ar: 'رقم الطلب', ku: 'ژمارەی داوا');
  String get address => _t(en: 'Address', ar: 'العنوان', ku: 'ناونیشان');
  String get publisher => _t(en: 'Publishing employee', ar: 'موظف النشر', ku: 'کارمەندی بڵاوکردنەوە');
  String get infoEmp => _t(en: 'Information employee', ar: 'موظف المعلومات', ku: 'کارمەندی زانیاری');
  String get photoEmp => _t(en: 'Photography employee', ar: 'موظف التصوير', ku: 'کارمەندی وێنەگرتن');
  String get assigned => _t(en: 'Assigned engineer', ar: 'المهندس المعيَّن', ku: 'ئەندازیاری دیاریکراو');
  String get deadline => _t(en: 'Deadline', ar: 'الموعد', ku: 'دوا وادە');
  String get country => _t(en: 'Country', ar: 'الدولة', ku: 'وڵات');
  String get city => _t(en: 'City', ar: 'المدينة', ku: 'شار');
  String get type => _t(en: 'Property type', ar: 'نوع العقار', ku: 'جۆری موڵک');
  String get floors => _t(en: 'Floors', ar: 'الطوابق', ku: 'نهۆمەکان');
  String get rooms => _t(en: 'Rooms', ar: 'الغرف', ku: 'ژوورەکان');
  String get area => _t(en: 'Area', ar: 'المساحة', ku: 'ڕووبەر');
  String get canvas => _t(en: 'Floor-plan canvas', ar: 'لوحة المخطط', ku: 'کەنڤاسی نەخشە');
  String get validation => _t(en: 'Floor plan validation', ar: 'التحقق الهندسي', ku: 'پشتڕاستی ئەندازیاری');
  String get submit => _t(en: 'Submit to Publishing Employee', ar: 'تسليم لموظف النشر', ku: 'ناردن بۆ بڵاوکردنەوە');
  String get cannotSubmit => _t(en: 'Cannot submit while mandatory checks fail.', ar: 'لا يمكن التسليم قبل استيفاء الفحوصات الإلزامية.', ku: 'ناتوانرێت بنێردرێت تا پشکنینەکان تەواو بن.');
  String get report => _t(en: 'Measurement report', ar: 'تقرير القياسات', ku: 'ڕاپۆرتی پێوانە');
  String get versions => _t(en: 'Versions', ar: 'الإصدارات', ku: 'وەشانەکان');
  String get correction => _t(en: 'Correction request', ar: 'طلب تصحيح', ku: 'داوای چاکسازی');
  String get notes => _t(en: 'Internal engineering notes', ar: 'ملاحظات هندسية داخلية', ku: 'تێبینی ئەندازیاری ناوخۆیی');
  String get notPublicNotes => _t(en: 'These notes never appear on the public listing.', ar: 'هذه الملاحظات لا تظهر في البطاقة العامة.', ku: 'ئەم تێبینیانە لە لیستی گشتی دەرناکەون.');
  String get photos => _t(en: 'Photographs', ar: 'الصور', ku: 'وێنەکان');
  String get tour => _t(en: '3D tour points', ar: 'نقاط الجولة الثلاثية', ku: 'خاڵەکانی گەشتی ٣د');
  String get connections => _t(en: 'Room connections', ar: 'ارتباطات الغرف', ku: 'پەیوەندی ژوورەکان');
  String get site => _t(en: 'Site / orientation', ar: 'الموقع والاتجاه', ku: 'شوێن و ئاراستە');
  String get metric => _t(en: 'Metric units only (m, m², cm, mm).', ar: 'الوحدات مترية فقط (م، م²، سم، مم).', ku: 'تەنها یەکەی مەتری (م، م²).');
  String get calcArea => _t(en: 'Calculated area', ar: 'المساحة المحسوبة', ku: 'ڕووبەری حسابکراو');
  String get measArea => _t(en: 'Measured area', ar: 'المساحة المقاسة', ku: 'ڕووبەری پێوراو');
  String get diff => _t(en: 'Difference', ar: 'الفرق', ku: 'جیاوازی');
  String get reviewMeas => _t(en: 'Measurement requires review.', ar: 'القياس يتطلب مراجعة.', ku: 'پێوانە پێویستی بە پێداچوونەوەیە.');
  String get source => _t(en: 'Source drawing', ar: 'الرسم المصدر', ku: 'وێنەی سەرچاوە');
  String get preserve => _t(en: 'Original source file is preserved and never overwritten.', ar: 'يُحفظ ملف المصدر الأصلي ولا يُستبدل.', ku: 'فایلی سەرچاوە هەرگیز ناگۆڕدرێت.');
  String get grid => _t(en: 'Grid', ar: 'الشبكة', ku: 'تۆڕ');
  String get snapGrid => _t(en: 'Snap', ar: 'محاذاة', ku: 'نۆرە');
  String get undo => _t(en: 'Undo', ar: 'تراجع', ku: 'پاشگەز');
  String get redo => _t(en: 'Redo', ar: 'إعادة', ku: 'دووبارە');
  String get fit => _t(en: 'Fit', ar: 'ملاءمة', ku: 'گونجاندن');
  String get addRoom => _t(en: 'Add room', ar: 'إضافة غرفة', ku: 'زیادکردنی ژوور');
  String get select => _t(en: 'Select', ar: 'تحديد', ku: 'هەڵبژاردن');
  String get signOut => _t(en: 'Sign out', ar: 'خروج', ku: 'چوونەدەرەوە');
  String get dark => _t(en: 'Dark mode', ar: 'الوضع الداكن', ku: 'دۆخی تاریک');
  String get language => _t(en: 'Language', ar: 'اللغة', ku: 'زمان');
  String get notifications => _t(en: 'Notifications', ar: 'الإشعارات', ku: 'ئاگادارکردنەوە');
  String get session => _t(en: 'Session', ar: 'الجلسة', ku: 'دانیشتن');
  String get save => _t(en: 'Save', ar: 'حفظ', ku: 'پاشەکەوت');
  String get send => _t(en: 'Send', ar: 'إرسال', ku: 'ناردن');
  String get close => _t(en: 'Close', ar: 'إغلاق', ku: 'داخستن');
  String get cancel => _t(en: 'Cancel', ar: 'إلغاء', ku: 'هەڵوەشاندنەوە');
  String get audit => _t(en: 'Audit trail', ar: 'سجل التدقيق', ku: 'شوێنپێی وردبینی');
  String get length => _t(en: 'Length (m)', ar: 'الطول (م)', ku: 'درێژی (م)');
  String get width => _t(en: 'Width (m)', ar: 'العرض (م)', ku: 'پانی (م)');
  String get height => _t(en: 'Ceiling height (m)', ar: 'ارتفاع السقف (م)', ku: 'بەرزی سقف (م)');
  String get north => _t(en: 'North', ar: 'الشمال', ku: 'باکوور');
  String get entrance => _t(en: 'Main entrance', ar: 'المدخل الرئيسي', ku: 'دەروازەی سەرەکی');
  String get street => _t(en: 'Street', ar: 'الشارع', ku: 'شەقام');
  String get land => _t(en: 'Land area', ar: 'مساحة الأرض', ku: 'ڕووبەری زەوی');
  String get built => _t(en: 'Total built area', ar: 'إجمالي مساحة البناء', ku: 'کۆی ڕووبەری بینا');
  String get usable => _t(en: 'Usable area', ar: 'المساحة الصافية', ku: 'ڕووبەری بەکارهێنراو');
  String get footprint => _t(en: 'Building footprint', ar: 'مسقط البناء', ku: 'پێی بینا');
  String get setbacks => _t(en: 'Setbacks', ar: 'الارتدادات', ku: 'پاشکەوتەکان');
  String get wall => _t(en: 'Walls', ar: 'الجدران', ku: 'دیوارەکان');
  String get doors => _t(en: 'Doors', ar: 'الأبواب', ku: 'دەرگاکان');
  String get windows => _t(en: 'Windows', ar: 'النوافذ', ku: 'پەنجەرەکان');
  String get stairs => _t(en: 'Stairs', ar: 'السلالم', ku: 'پهله‌کان');
  String get points => _t(en: 'Interactive points', ar: 'نقاط تفاعلية', ku: 'خاڵی کارلێک');
  String get structures => _t(en: 'Structures', ar: 'المنشآت', ku: 'بیناکان');
  String get unit => _t(en: 'Unit', ar: 'الوحدة', ku: 'یەکە');
  String get buildingPlan => _t(en: 'Building floor plan (not a unit plan)', ar: 'مخطط المبنى (وليس مخطط الوحدة)', ku: 'نەخشەی بینا (نەک یەکە)');
  String get passed => _t(en: 'passed', ar: 'ناجحة', ku: 'سەرکەوتوو');
  String get warning => _t(en: 'warning', ar: 'تنبيه', ku: 'ئاگاداری');
  String get failed => _t(en: 'failed', ar: 'فاشلة', ku: 'شکست');
  String get synced => _t(en: 'Synced', ar: 'متزامن', ku: 'هاوکات');
  String get saving => _t(en: 'Saving', ar: 'جارٍ الحفظ', ku: 'پاشەکەوتکردن');
  String get saved => _t(en: 'Saved', ar: 'محفوظ', ku: 'پاشەکەوتکراو');
  String get offline => _t(en: 'Offline', ar: 'غير متصل', ku: 'ئۆفلاین');
  String get permissions => _t(en: 'Permissions', ar: 'الصلاحيات', ku: 'مۆڵەتەکان');
  String get canDo => _t(
        en: 'Create and validate floor plans, rooms, metric dimensions, photo/3D connections, versions, and submit to publishing.',
        ar: 'إنشاء والتحقق من المخططات والغرف والأبعاد المترية وربط الصور والجولة، والإصدارات، والتسليم للنشر.',
        ku: 'دروستکردن و پشتڕاستی نەخشە، ژوور، پێوانەی مەتری، وێنە/٣د، وەشان، ناردن بۆ بڵاوکردنەوە.',
      );
  String get cannotDo => _t(
        en: 'Cannot publish the public listing, overwrite source files, or edit the information/photography reports.',
        ar: 'لا يمكن نشر البطاقة العامة، أو استبدال ملفات المصدر، أو تعديل تقارير المعلومات/التصوير.',
        ku: 'ناتوانێت لیستی گشتی بڵاوبکاتەوە، فایلی سەرچاوە بسڕێتەوە، یان ڕاپۆرتی زانیاری/وێنە بگۆڕێت.',
      );
  String get overview => _t(en: 'Property overview', ar: 'نظرة العقار', ku: 'گشتی موڵک');
  String get openRecord => _t(en: 'Open property record', ar: 'فتح سجل العقار', ku: 'کردنەوەی تۆماری موڵک');
  String get bedrooms => _t(en: 'Bedrooms', ar: 'غرف النوم', ku: 'ژووری نووستن');
  String get bathrooms => _t(en: 'Bathrooms', ar: 'الحمامات', ku: 'حەمامەکان');
  String get respond => _t(en: 'Add response', ar: 'إضافة رد', ku: 'وەڵام');
  String get connect => _t(en: 'Connect', ar: 'ربط', ku: 'پەیوەندیکردن');
}
