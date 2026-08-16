import 'package:flutter/material.dart';

// Supported locales
enum AppLanguage { english, arabic, kurdish }

class AppLocalizations {
  final AppLanguage language;

  const AppLocalizations(this.language);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(AppLanguage.english);
  }

  bool get isRTL =>
      language == AppLanguage.arabic || language == AppLanguage.kurdish;

  TextDirection get textDirection =>
      isRTL ? TextDirection.rtl : TextDirection.ltr;

  String get languageCode {
    switch (language) {
      case AppLanguage.arabic:
        return 'ar';
      case AppLanguage.kurdish:
        return 'ku';
      case AppLanguage.english:
        return 'en';
    }
    return 'en';
  }

  // ─── App General ─────────────────────────────────────────────────────────
  String get appName => _t(en: 'Madar', ar: 'مدار', ku: 'مەدار');
  String get appTagline => _t(
    en: 'Your Real Estate Platform',
    ar: 'منصتك العقارية',
    ku: 'پلاتفۆرمی خانووبەرەی تۆ',
  );

  // ─── Navigation ───────────────────────────────────────────────────────────
  String get navSearch => _t(en: 'Search', ar: 'البحث', ku: 'گەڕان');
  String get navDeals => _t(en: 'Deals', ar: 'الصفقات', ku: 'مامەڵەکان');
  String get navProperties =>
      _t(en: 'Properties', ar: 'الأملاك', ku: 'خانووبەرەکان');
  String get navMessages => _t(en: 'Messages', ar: 'الرسائل', ku: 'نامەکان');
  String get navProfile => _t(en: 'Profile', ar: 'الشخصية', ku: 'پرۆفایل');

  // ─── Search Screen ────────────────────────────────────────────────────────
  String get searchHint => _t(
    en: 'Search properties...',
    ar: 'ابحث عن عقارات...',
    ku: 'بگەڕێ بۆ خانووبەرە...',
  );
  String get propertiesFound =>
      _t(en: 'Properties Found', ar: 'عقار موجود', ku: 'خانووبەرە دۆزراوەکان');
  String get suggested => _t(en: 'Suggested', ar: 'مقترح', ku: 'پێشنیار');
  String get featured => _t(en: 'Featured', ar: 'مميز', ku: 'تایبەت');
  String get mostPopular =>
      _t(en: 'Most Popular', ar: 'الأكثر انتشاراً', ku: 'زۆرترین بینراو');
  String get recentlyAdded =>
      _t(en: 'Recently Added', ar: 'المضاف حديثاً', ku: 'تازە زیادکراو');
  String get nearMe => _t(en: 'Near Me', ar: 'بالقرب مني', ku: 'لەتەلی من');
  String get filters => _t(en: 'Filters', ar: 'التصفية', ku: 'فلتەرەکان');
  String get reset => _t(en: 'Reset', ar: 'إعادة تعيين', ku: 'ڕیسێت');
  String get applyFilters =>
      _t(en: 'Apply Filters', ar: 'تطبيق التصفية', ku: 'جێبەجێکردنی فلتەر');
  String get sort => _t(en: 'Sort', ar: 'ترتيب', ku: 'ڕیزکردن');
  String get viewAll => _t(en: 'View All', ar: 'عرض الكل', ku: 'هەموو ببینە');
  String get seeAllProperties => _t(
    en: 'See all properties',
    ar: 'عرض جميع العقارات',
    ku: 'هەموو خانووبەرەکان ببینە',
  );

  // ─── Filter Options ───────────────────────────────────────────────────────
  String get all => _t(en: 'All', ar: 'الكل', ku: 'هەموو');
  String get forSale => _t(en: 'For Sale', ar: 'للبيع', ku: 'بۆ فرۆشتن');
  String get forRent => _t(en: 'For Rent', ar: 'للإيجار', ku: 'بۆ کرێ');
  String get mortgage => _t(en: 'Mortgage', ar: 'رهن', ku: 'گرەوی');
  String get land => _t(en: 'Land', ar: 'أرض', ku: 'زەوی');
  String get commercial => _t(en: 'Commercial', ar: 'تجاري', ku: 'بازرگانی');
  String get investment =>
      _t(en: 'Investment', ar: 'استثمار', ku: 'وەبەرهێنان');
  String get apartment =>
      _t(en: 'Apartment', ar: 'شقة', ku: 'شوقە');
  String get villaType =>
      _t(en: 'Villa', ar: 'فيلا', ku: 'ڤیلا');
  String get listingType =>
      _t(en: 'Listing Type', ar: 'نوع الإعلان', ku: 'جۆری لیستە');
  String get priceRange =>
      _t(en: 'Price Range', ar: 'نطاق السعر', ku: 'ئاستی نرخ');
  String get areaSqm =>
      _t(en: 'Area (m²)', ar: 'المساحة (م²)', ku: 'فراوانی (م²)');
  String get minBedrooms => _t(
    en: 'Min Bedrooms',
    ar: 'الحد الأدنى للغرف',
    ku: 'کەمترین ژووری نووستن',
  );
  String get any => _t(en: 'Any', ar: 'أي', ku: 'هەر');

  // ─── Property Card ────────────────────────────────────────────────────────
  String get verified => _t(en: 'Verified', ar: 'موثق', ku: 'پشتڕاستکراوە');
  String get dailyVisitors =>
      _t(en: 'Daily Visitors', ar: 'الزوار اليومي', ku: 'سەردانکارانی ڕۆژانە');
  String get buildingAge =>
      _t(en: 'Building Age', ar: 'عمر البناء', ku: 'تەمەنی بینا');
  String get years => _t(en: 'yrs', ar: 'سنة', ku: 'ساڵ');
  String get bedrooms => _t(en: 'Beds', ar: 'غرف', ku: 'ژووری نووستن');
  String get bathrooms => _t(en: 'Baths', ar: 'حمامات', ku: 'ئاوخانە');
  String get contactSales => _t(
    en: 'Contact Sales',
    ar: 'تواصل مع المبيعات',
    ku: 'پەیوەندی بکە بە فرۆشتن',
  );
  String get aiConsult =>
      _t(en: 'AI Consult', ar: 'استشارة الذكاء الاصطناعي', ku: 'ئەی ئای ڕاوێژ');
  String get whatsSpecial =>
      _t(en: "What's Special", ar: 'ما يميزه', ku: 'چی تایبەتە');
  String get leaseToOwn =>
      _t(en: 'Lease to Own', ar: 'إيجار تمليكي', ku: 'کرێ بۆ خاوەنداری');
  String get madarEstimate =>
      _t(en: 'Madar Estimate', ar: 'تقدير مدار', ku: 'خەمڵاندنی مەدار');
  String get priceHistory =>
      _t(en: 'Price History', ar: 'تاريخ الأسعار', ku: 'مێژووی نرخ');
  String get taxHistory =>
      _t(en: 'Tax History', ar: 'تاريخ الضرائب', ku: 'مێژووی باج');
  String get homeDetails =>
      _t(en: 'Home Details', ar: 'تفاصيل المنزل', ku: 'وردەکاری خانوو');
  String get neighborhood => _t(en: 'Neighborhood', ar: 'الحي', ku: 'گەڕەک');
  String get nearbySchools =>
      _t(en: 'Nearby Schools', ar: 'المدارس القريبة', ku: 'قوتابخانەی نزیک');
  String get climateRisk =>
      _t(en: 'Climate Risk', ar: 'مخاطر المناخ', ku: 'مەترسی ئاووهەوا');
  String get mortgageCalc =>
      _t(en: 'Mortgage Calculator', ar: 'حاسبة القرض', ku: 'ژمێرەری گرەوی');
  String get scheduleTour =>
      _t(en: 'Schedule a Tour', ar: 'حجز جولة', ku: 'گەشتێک پلان بکە');
  String get perMonth => _t(en: '/mo', ar: '/شهر', ku: '/مانگ');
  String get sqmPrice => _t(
    en: 'Price per m²',
    ar: 'سعر المتر المربع',
    ar2: 'سعر/م²',
    ku: 'نرخی م²',
  );
  String get walkScore =>
      _t(en: 'Walk Score', ar: 'نقاط المشي', ku: 'خاڵی پیاوروی');
  String get transitScore =>
      _t(en: 'Transit Score', ar: 'نقاط النقل', ku: 'خاڵی گواستنەوە');

  // ─── My Properties ────────────────────────────────────────────────────────
  String get myProperties =>
      _t(en: 'My Properties', ar: 'أملاكي', ku: 'خانووبەرەکانم');
  String get addProperty =>
      _t(en: '+ Add Property', ar: '+ إضافة عقار', ku: '+ زیادکردنی خانووبەرە');
  String get underReview =>
      _t(en: 'Under Review', ar: 'قيد التدقيق', ku: 'لەژێر پێداچوونەوەدایە');
  String get submittedRequests => _t(
    en: 'Submitted Requests',
    ar: 'الطلبات المقدمة',
    ku: 'داواکاری نێردراوەکان',
  );

  // ─── Transactions ─────────────────────────────────────────────────────────
  String get transactions =>
      _t(en: 'Transactions', ar: 'الصفقات', ku: 'مامەڵەکان');
  String get uploadBarcode =>
      _t(en: 'Upload Barcode', ar: 'رفع الباركود', ku: 'بارکۆد بارکە');
  String get uploadBarcodeHint => _t(
    en: 'Upload barcode to start a transaction',
    ar: 'ارفع الباركود لبدء صفقة',
    ku: 'بارکۆد بارکە بۆ دەستپێکردنی مامەڵە',
  );

  // ─── Profile ──────────────────────────────────────────────────────────────
  String get profile => _t(en: 'Profile', ar: 'الشخصية', ku: 'پرۆفایل');
  String get darkMode =>
      _t(en: 'Dark Mode', ar: 'الوضع الداكن', ku: 'دارک مۆد');
  String get languageLabel => _t(en: 'Language', ar: 'اللغة', ku: 'زمان');
  String get settings => _t(en: 'Settings', ar: 'الإعدادات', ku: 'ڕێکخستنەکان');
  String get logout => _t(en: 'Logout', ar: 'تسجيل الخروج', ku: 'دەرچوون');

  // ─── Language Names ───────────────────────────────────────────────────────
  String get langEnglish => _t(en: 'English', ar: 'الإنجليزية', ku: 'ئینگلیزی');
  String get langArabic => _t(en: 'Arabic', ar: 'العربية', ku: 'عەرەبی');
  String get langKurdish => _t(en: 'Kurdish', ar: 'الكردية', ku: 'کوردی');

  // ─── Admin Panel ──────────────────────────────────────────────────────────
  String get adminPanel =>
      _t(en: 'Admin Panel', ar: 'لوحة الإدارة', ku: 'پانێلی بەڕێوەبەری');
  String get countryConfig => _t(
    en: 'Country Configuration',
    ar: 'إعدادات الدولة',
    ku: 'ڕێکخستنی وڵات',
  );
  String get staffAssignment =>
      _t(en: 'Staff Assignment', ar: 'تعيين الموظفين', ku: 'دانانی ستاف');
  String get save => _t(en: 'Save', ar: 'حفظ', ku: 'پاشەکەوت');
  String get cancel => _t(en: 'Cancel', ar: 'إلغاء', ku: 'هەڵوەشاندنەوە');
  String get confirm => _t(en: 'Confirm', ar: 'تأكيد', ku: 'پشتڕاستکردنەوە');
  String get edit => _t(en: 'Edit', ar: 'تعديل', ku: 'دەستکاری');
  String get delete => _t(en: 'Delete', ar: 'حذف', ku: 'سڕینەوە');
  String get add => _t(en: 'Add', ar: 'إضافة', ku: 'زیادکردن');
  String get search => _t(en: 'Search', ar: 'بحث', ku: 'گەڕان');

  // ─── Country Config Tabs ──────────────────────────────────────────────────
  String get generalSettings => _t(en: 'General', ar: 'عام', ku: 'گشتی');
  String get feeStructure => _t(en: 'Fees', ar: 'الرسوم', ku: 'کرێکان');
  String get transactionRules => _t(en: 'Rules', ar: 'القواعد', ku: 'ڕێسەکان');
  String get legalDocuments =>
      _t(en: 'Legal Docs', ar: 'المستندات', ku: 'بەڵگەنامەکان');

  // ─── Staff Assignment Tabs ────────────────────────────────────────────────
  String get assignments =>
      _t(en: 'Assignments', ar: 'التعيينات', ku: 'دانانەکان');
  String get staffDirectory => _t(en: 'Staff', ar: 'الموظفون', ku: 'ستافەکان');
  String get taskQueue =>
      _t(en: 'Task Queue', ar: 'قائمة المهام', ku: 'ڕیزی ئەرکەکان');

  // ─── Employee Dashboard ───────────────────────────────────────────────────
  String get employeeDashboard =>
      _t(en: 'Employee Dashboard', ar: 'لوحة الموظف', ku: 'داشبۆردی کارمەند');
  String get myTasks => _t(en: 'My Tasks', ar: 'مهامي', ku: 'ئەرکەکانم');
  String get myDeals => _t(en: 'My Deals', ar: 'صفقاتي', ku: 'مامەڵەکانم');
  String get overview => _t(en: 'Overview', ar: 'نظرة عامة', ku: 'گشتی');
  String get taskStatus =>
      _t(en: 'Task Status', ar: 'حالة المهمة', ku: 'حاڵەتی ئەرک');
  String get pending => _t(en: 'Pending', ar: 'قيد الانتظار', ku: 'چاوەڕوانە');
  String get inProgress => _t(en: 'In Progress', ar: 'جاري', ku: 'بەردەوامە');
  String get completed => _t(en: 'Completed', ar: 'مكتمل', ku: 'تەواوبووە');
  String get priority => _t(en: 'Priority', ar: 'الأولوية', ku: 'پێشینە');
  String get high => _t(en: 'High', ar: 'عالي', ku: 'بەرز');
  String get medium => _t(en: 'Medium', ar: 'متوسط', ku: 'ناوەند');
  String get low => _t(en: 'Low', ar: 'منخفض', ku: 'نزم');
  String get assignedTo =>
      _t(en: 'Assigned To', ar: 'مُعين لـ', ku: 'دراوە بە');
  String get dueDate =>
      _t(en: 'Due Date', ar: 'تاريخ الاستحقاق', ku: 'بەرواری کۆتایی');
  String get workload => _t(en: 'Workload', ar: 'عبء العمل', ku: 'بارگەی کار');
  String get available => _t(en: 'Available', ar: 'متاح', ku: 'بەردەستە');
  String get unavailable =>
      _t(en: 'Unavailable', ar: 'غير متاح', ku: 'بەردەست نییە');
  String get department => _t(en: 'Department', ar: 'القسم', ku: 'بەش');
  String get role => _t(en: 'Role', ar: 'الدور', ku: 'ڕۆڵ');

  // ─── Office Dashboard ─────────────────────────────────────────────────────
  String get officeDashboard =>
      _t(en: 'Office Dashboard', ar: 'لوحة المكتب', ku: 'داشبۆردی ئۆفیس');
  String get newTransaction =>
      _t(en: 'New Transaction', ar: 'صفقة جديدة', ku: 'مامەڵەی نوێ');
  String get totalTransactions =>
      _t(en: 'Total Transactions', ar: 'إجمالي الصفقات', ku: 'کۆی مامەڵەکان');
  String get activeAgents =>
      _t(en: 'Active Agents', ar: 'الوكلاء النشطون', ku: 'نوێنەرانی چالاک');
  String get monthlyRevenue =>
      _t(en: 'Monthly Revenue', ar: 'الإيرادات الشهرية', ku: 'داهاتی مانگانە');
  String get recentTransactions =>
      _t(en: 'Recent Transactions', ar: 'الصفقات الأخيرة', ku: 'مامەڵەی دواین');

  // ─── Agent Dashboard ──────────────────────────────────────────────────────
  String get agentDashboard =>
      _t(en: 'Agent Dashboard', ar: 'لوحة الوكيل', ku: 'داشبۆردی نوێنەر');
  String get generateBarcode =>
      _t(en: 'Generate Barcode', ar: 'إنشاء باركود', ku: 'بارکۆد دروستبکە');
  String get newDeal => _t(en: 'New Deal', ar: 'صفقة جديدة', ku: 'مامەڵەی نوێ');
  String get allDeals =>
      _t(en: 'All Deals', ar: 'كل الصفقات', ku: 'هەموو مامەڵەکان');
  String get contract => _t(en: 'Contract', ar: 'العقد', ku: 'گرێبەست');
  String get sendContract =>
      _t(en: 'Send Contract', ar: 'إرسال العقد', ku: 'گرێبەست بنێرە');

  // ─── Transaction Stages ───────────────────────────────────────────────────
  String get stage => _t(en: 'Stage', ar: 'المرحلة', ku: 'قۆناغ');
  String get identityVerification => _t(
    en: 'Identity Verification',
    ar: 'التحقق من الهوية',
    ku: 'پشتڕاستکردنەوەی ناسنامە',
  );
  String get documentUpload =>
      _t(en: 'Document Upload', ar: 'رفع المستندات', ku: 'بارکردنی بەڵگەنامە');
  String get saleContract =>
      _t(en: 'Sale Contract', ar: 'عقد البيع', ku: 'گرێبەستی فرۆشتن');
  String get escrowDeposit =>
      _t(en: 'Escrow Deposit', ar: 'إيداع الضمان', ku: 'دانانی پارەی گەروی');
  String get titleDeed =>
      _t(en: 'Title Deed', ar: 'سند الملكية', ku: 'سەندی خاوەنداری');
  String get settlement =>
      _t(en: 'Settlement', ar: 'التسوية', ku: 'چارەسەرکردن');

  // ─── Org Hierarchy ────────────────────────────────────────────────────────
  String get orgHierarchy =>
      _t(en: 'Org Hierarchy', ar: 'الهيكل التنظيمي', ku: 'پلەبەندی ڕێکخراو');
  String get directory => _t(en: 'Directory', ar: 'الدليل', ku: 'ڕێنما');
  String get hierarchy =>
      _t(en: 'Hierarchy', ar: 'التسلسل الهرمي', ku: 'پلەبەندی');
  String get chart => _t(en: 'Chart', ar: 'الرسم البياني', ku: 'چارت');
  String get employee => _t(en: 'Employee', ar: 'موظف', ku: 'کارمەند');
  String get employees =>
      _t(en: 'Employees', ar: 'الموظفون', ku: 'کارمەندەکان');
  String get manager => _t(en: 'Manager', ar: 'مدير', ku: 'بەڕێوەبەر');
  String get director => _t(en: 'Director', ar: 'مدير تنفيذي', ku: 'دیرێکتەر');
  String get country => _t(en: 'Country', ar: 'الدولة', ku: 'وڵات');

  // ─── Employee Onboarding ──────────────────────────────────────────────────
  String get onboarding =>
      _t(en: 'Onboarding', ar: 'الإعداد الوظيفي', ku: 'تازەکارکردن');
  String get personalInfo =>
      _t(en: 'Personal Info', ar: 'المعلومات الشخصية', ku: 'زانیاری کەسی');
  String get roleAndDept =>
      _t(en: 'Role & Department', ar: 'الدور والقسم', ku: 'ڕۆڵ و بەش');
  String get documents =>
      _t(en: 'Documents', ar: 'المستندات', ku: 'بەڵگەنامەکان');
  String get review => _t(en: 'Review', ar: 'مراجعة', ku: 'پێداچوونەوە');
  String get submit => _t(en: 'Submit', ar: 'إرسال', ku: 'ناردن');
  String get next => _t(en: 'Next', ar: 'التالي', ku: 'دواتر');
  String get back => _t(en: 'Back', ar: 'رجوع', ku: 'گەڕانەوە');
  String get fullName =>
      _t(en: 'Full Name', ar: 'الاسم الكامل', ku: 'ناوی تەواو');
  String get email => _t(en: 'Email', ar: 'البريد الإلكتروني', ku: 'ئیمەیل');
  String get phone => _t(en: 'Phone', ar: 'الهاتف', ku: 'تەلەفۆن');
  String get employeeCode =>
      _t(en: 'Employee Code', ar: 'رمز الموظف', ku: 'کۆدی کارمەند');
  String get nationalId =>
      _t(en: 'National ID', ar: 'الهوية الوطنية', ku: 'ناسنامەی نیشتمانی');
  String get uploadDocument =>
      _t(en: 'Upload Document', ar: 'رفع المستند', ku: 'بارکردنی بەڵگەنامە');

  // ─── 2FA Verification ─────────────────────────────────────────────────────
  String get twoFaTitle => _t(
    en: 'Identity Verification',
    ar: 'التحقق من الهوية',
    ku: 'پشتڕاستکردنەوەی ناسنامە',
  );
  String get otpVerification => _t(
    en: 'OTP Verification',
    ar: 'التحقق بالرمز',
    ku: 'پشتڕاستکردنەوەی OTP',
  );
  String get faceVerification => _t(
    en: 'Face Verification',
    ar: 'التحقق بالوجه',
    ku: 'پشتڕاستکردنەوەی ڕووخسار',
  );
  String get enterOtp =>
      _t(en: 'Enter OTP Code', ar: 'أدخل رمز التحقق', ku: 'کۆدی OTP بنووسە');
  String get takeSelfie =>
      _t(en: 'Take a Selfie', ar: 'التقط صورة سيلفي', ku: 'سەلفی بکە');
  String get uploadId => _t(
    en: 'Upload National ID',
    ar: 'رفع الهوية الوطنية',
    ku: 'ناسنامەی نیشتمانی بارکە',
  );
  String get verificationComplete => _t(
    en: 'Verification Complete',
    ar: 'اكتمل التحقق',
    ku: 'پشتڕاستکردنەوە تەواوبوو',
  );

  // ─── Analytics ────────────────────────────────────────────────────────────
  String get analytics => _t(en: 'Analytics', ar: 'التحليلات', ku: 'شیکاری');
  String get propertyAnalytics => _t(
    en: 'Property Analytics',
    ar: 'تحليلات العقارات',
    ku: 'شیکاری خانووبەرە',
  );
  String get views => _t(en: 'Views', ar: 'المشاهدات', ku: 'بینینەکان');
  String get inquiries =>
      _t(en: 'Inquiries', ar: 'الاستفسارات', ku: 'پرسیارەکان');
  String get saves => _t(en: 'Saves', ar: 'المحفوظات', ku: 'پاشەکەوتەکان');
  String get conversionRate =>
      _t(en: 'Conversion Rate', ar: 'معدل التحويل', ku: 'ڕێژەی گۆڕانکاری');

  // ─── Ratings & Reviews ────────────────────────────────────────────────────
  String get ratingsReviews => _t(
    en: 'Ratings & Reviews',
    ar: 'التقييمات والمراجعات',
    ku: 'هەڵسەنگاندن و پێداچوونەوەکان',
  );
  String get writeReview =>
      _t(en: 'Write a Review', ar: 'كتابة مراجعة', ku: 'پێداچوونەوە بنووسە');
  String get rating => _t(en: 'Rating', ar: 'التقييم', ku: 'هەڵسەنگاندن');
  String get helpful => _t(en: 'Helpful', ar: 'مفيد', ku: 'بەسوود');

  // ─── Common Actions ───────────────────────────────────────────────────────
  String get loading =>
      _t(en: 'Loading...', ar: 'جاري التحميل...', ku: 'بارکردن...');
  String get error => _t(en: 'Error', ar: 'خطأ', ku: 'هەڵە');
  String get retry =>
      _t(en: 'Retry', ar: 'إعادة المحاولة', ku: 'دووبارە هەوڵبدەرەوە');
  String get noData =>
      _t(en: 'No data available', ar: 'لا توجد بيانات', ku: 'داتا نییە');
  String get success => _t(en: 'Success', ar: 'نجاح', ku: 'سەرکەوتن');
  String get close => _t(en: 'Close', ar: 'إغلاق', ku: 'داخستن');
  String get download => _t(en: 'Download', ar: 'تنزيل', ku: 'داگرتن');
  String get share => _t(en: 'Share', ar: 'مشاركة', ku: 'هاوبەشکردن');
  String get send => _t(en: 'Send', ar: 'إرسال', ku: 'ناردن');
  String get upload => _t(en: 'Upload', ar: 'رفع', ku: 'بارکردن');
  String get generate => _t(en: 'Generate', ar: 'إنشاء', ku: 'دروستکردن');
  String get active => _t(en: 'Active', ar: 'نشط', ku: 'چالاک');
  String get inactive => _t(en: 'Inactive', ar: 'غير نشط', ku: 'ناچالاک');
  String get status => _t(en: 'Status', ar: 'الحالة', ku: 'حاڵەت');
  String get type => _t(en: 'Type', ar: 'النوع', ku: 'جۆر');
  String get date => _t(en: 'Date', ar: 'التاريخ', ku: 'بەروار');
  String get amount => _t(en: 'Amount', ar: 'المبلغ', ku: 'بڕ');
  String get total => _t(en: 'Total', ar: 'الإجمالي', ku: 'کۆ');
  String get name => _t(en: 'Name', ar: 'الاسم', ku: 'ناو');
  String get description => _t(en: 'Description', ar: 'الوصف', ku: 'وەسف');
  String get notes => _t(en: 'Notes', ar: 'ملاحظات', ku: 'تێبینیەکان');
  String get buyer => _t(en: 'Buyer', ar: 'المشتري', ku: 'کڕیار');
  String get seller => _t(en: 'Seller', ar: 'البائع', ku: 'فرۆشیار');
  String get property => _t(en: 'Property', ar: 'العقار', ku: 'خانووبەرە');
  String get price => _t(en: 'Price', ar: 'السعر', ku: 'نرخ');
  String get tax => _t(en: 'Tax', ar: 'الضريبة', ku: 'باج');
  String get fee => _t(en: 'Fee', ar: 'الرسوم', ku: 'کرێ');
  String get receipt => _t(en: 'Receipt', ar: 'الوصل', ku: 'وەسڵ');
  String get payout => _t(en: 'Payout', ar: 'الدفع', ku: 'پارەدان');
  String get escrow => _t(en: 'Escrow', ar: 'الضمان', ku: 'گەروی');
  String get bank => _t(en: 'Bank', ar: 'المصرف', ku: 'بانک');
  String get deposit => _t(en: 'Deposit', ar: 'إيداع', ku: 'دانان');
  String get transfer => _t(en: 'Transfer', ar: 'تحويل', ku: 'گواستنەوە');
  String get signature => _t(en: 'Signature', ar: 'التوقيع', ku: 'واژوو');
  String get sign => _t(en: 'Sign', ar: 'توقيع', ku: 'واژوو کردن');
  String get approved =>
      _t(en: 'Approved', ar: 'موافق عليه', ku: 'پەسەندکراوە');
  String get rejected => _t(en: 'Rejected', ar: 'مرفوض', ku: 'ڕەتکراوەتەوە');
  String get draft => _t(en: 'Draft', ar: 'مسودة', ku: 'پێشنووس');
  String get final_ => _t(en: 'Final', ar: 'نهائي', ku: 'کۆتایی');

  // ─── User Authentication ──────────────────────────────────────────────────
  String get authPhoneTitle => _t(
    en: 'Enter your phone number',
    ar: 'أدخل رقم هاتفك',
    ku: 'ژمارەی تەلەفۆنەکەت بنووسە',
  );
  String get authPhoneSubtitle => _t(
    en: 'We will send you a verification code to confirm your number.',
    ar: 'سنرسل لك رمز تحقق لتأكيد رقمك.',
    ku: 'کۆدێکی پشتڕاستکردنەوە دەنێرین بۆ ژمارەکەت.',
  );
  String get authContinue => _t(en: 'Continue', ar: 'متابعة', ku: 'بەردەوامبوون');
  String get authSelectCountry => _t(
    en: 'Select country',
    ar: 'اختر الدولة',
    ku: 'وڵات هەڵبژێرە',
  );
  String get authOtpTitle => _t(
    en: 'Verify your phone',
    ar: 'تحقق من هاتفك',
    ku: 'تەلەفۆنەکەت پشتڕاست بکەرەوە',
  );
  String authOtpSubtitle(String phone) => _t(
    en: 'Enter the 6-digit code sent to $phone',
    ar: 'أدخل الرمز المكون من 6 أرقام المرسل إلى $phone',
    ku: 'کۆدی 6 ژمارەیی بنووسە کە نێردراوە بۆ $phone',
  );
  String get authVerifyContinue => _t(
    en: 'Continue',
    ar: 'متابعة',
    ku: 'بەردەوامبوون',
  );
  String get authResendOtp => _t(
    en: 'Resend code',
    ar: 'إعادة إرسال الرمز',
    ku: 'دووبارە ناردنی کۆد',
  );
  String authResendIn(int seconds) => _t(
    en: 'Resend in ${seconds}s',
    ar: 'إعادة الإرسال خلال ${seconds} ث',
    ku: 'دووبارە ناردن لە ${seconds} چ',
  );
  String get authChangePhone => _t(
    en: 'Change number',
    ar: 'تغيير الرقم',
    ku: 'گۆڕینی ژمارە',
  );
  String get authLocationTitle => _t(
    en: 'Find properties around you',
    ar: 'اعثر على عقارات حولك',
    ku: 'خانووبەرە بدۆزەرەوە لە دەوروبەرت',
  );
  String get authLocationSubtitle => _t(
    en: 'Allow location access to discover properties near your current location.',
    ar: 'اسمح بالوصول إلى موقعك لاكتشاف العقارات القريبة منك.',
    ku: 'ڕێگە بدە بە شوێن بۆ دۆزینەوەی خانووبەرە لە نزیکت.',
  );
  String get authLocationCardTitle => _t(
    en: 'Nearby properties',
    ar: 'عقارات قريبة',
    ku: 'خانووبەرەی نزیک',
  );
  String get authLocationCardDescription => _t(
    en: 'Your location helps us show relevant listings, map results, and distance-based search.',
    ar: 'موقعك يساعدنا في عرض الإعلانات المناسبة ونتائج الخريطة والبحث حسب المسافة.',
    ku: 'شوێنەکەت یارمەتیمان دەدات لیست و نەخشە و گەڕان بەپێی دووری پیشان بدەین.',
  );
  String get authAllowLocation => _t(
    en: 'Allow location',
    ar: 'السماح بالموقع',
    ku: 'ڕێگەدان بە شوێن',
  );
  String get authNotNow => _t(en: 'Not now', ar: 'ليس الآن', ku: 'ئێستا نا');
  String get authFaceTitle => _t(
    en: 'Secure your account',
    ar: 'أمّن حسابك',
    ku: 'هەژمارەکەت بپارێزە',
  );
  String get authFaceSubtitle => _t(
    en: 'Add an extra layer of security to protect your account.',
    ar: 'أضف طبقة أمان إضافية لحماية حسابك.',
    ku: 'چینێکی زیادەی پاراستن زیاد بکە بۆ هەژمارەکەت.',
  );
  String get authFaceCardTitle => _t(
    en: 'Face verification',
    ar: 'التحقق بالوجه',
    ku: 'پشتڕاستکردنەوەی ڕووخسار',
  );
  String get authFaceCardDescription => _t(
    en: 'Use face verification as two-factor authentication for sensitive actions like transactions.',
    ar: 'استخدم التحقق بالوجه كمصادقة ثنائية للإجراءات الحساسة مثل المعاملات.',
    ku: 'پشتڕاستکردنەوەی ڕووخسار وەک 2FA بۆ کردارە هەستیارەکان وەک مامەڵەکان.',
  );
  String get authSetupFaceVerification => _t(
    en: 'Set up face verification',
    ar: 'إعداد التحقق بالوجه',
    ku: 'ڕێکخستنی پشتڕاستکردنەوەی ڕووخسار',
  );
  String get authSkipForNow => _t(
    en: 'Skip for now',
    ar: 'تخطي الآن',
    ku: 'فعلاً بەجێبهێڵە',
  );
  String get authLogoutConfirm => _t(
    en: 'Are you sure you want to logout?',
    ar: 'هل تريد تسجيل الخروج؟',
    ku: 'دڵنیایت دەتەوێت بچیتە دەرەوە؟',
  );

  // ─── Region Setup ─────────────────────────────────────────────────────────
  String get authRegionTitle => _t(
    en: 'Set your region',
    ar: 'حدد منطقتك',
    ku: 'ناوچەکەت دیاری بکە',
  );
  String get authRegionSubtitle => _t(
    en: 'We detected your location. Confirm or adjust country, language, and currency.',
    ar: 'حددنا موقعك. أكد أو عدّل الدولة واللغة والعملة.',
    ku: 'شوێنەکەت دیاریکرا. وڵات و زمان و دراو پشتڕاست بکەرەوە یان بیگۆڕە.',
  );
  String get authRegionCountry => _t(
    en: 'Country',
    ar: 'الدولة',
    ku: 'وڵات',
  );
  String get authRegionLanguage => _t(
    en: 'Language',
    ar: 'اللغة',
    ku: 'زمان',
  );
  String get authRegionCurrency => _t(
    en: 'Currency',
    ar: 'العملة',
    ku: 'دراو',
  );
  String get authRegionConfirm => _t(
    en: 'Continue',
    ar: 'متابعة',
    ku: 'بەردەوامبوون',
  );
  String get authRegionDetectedHint => _t(
    en: 'You can change these anytime from Profile settings.',
    ar: 'يمكنك تغييرها في أي وقت من إعدادات الملف الشخصي.',
    ku: 'دەتوانیت لە هەر کاتێک لە ڕێکخستنەکانی پرۆفایل بیگۆڕیت.',
  );

  // ─── Profile Settings ─────────────────────────────────────────────────────
  String get settingsCountry => _t(
    en: 'Country',
    ar: 'الدولة',
    ku: 'وڵات',
  );
  String get settingsCurrency => _t(
    en: 'Currency',
    ar: 'العملة',
    ku: 'دراو',
  );
  String get settingsChangeCountry => _t(
    en: 'Change country',
    ar: 'تغيير الدولة',
    ku: 'گۆڕینی وڵات',
  );
  String get settingsChangeCurrency => _t(
    en: 'Change currency',
    ar: 'تغيير العملة',
    ku: 'گۆڕینی دراو',
  );
  String get activeCountryTitle => _t(
    en: 'Active Country',
    ar: 'الدولة النشطة',
    ku: 'وڵاتی چالاک',
  );
  String get switchMarketContext => _t(
    en: 'Switch your market context',
    ar: 'بدّل سياق السوق',
    ku: 'ناوچەی بازاڕ بگۆڕە',
  );
  String get mapType => _t(
    en: 'Map Type',
    ar: 'نوع الخريطة',
    ku: 'جۆری نەخشە',
  );
  String get drawArea => _t(
    en: 'Draw Area',
    ar: 'رسم منطقة',
    ku: 'کێشانی ناوچە',
  );
  String get cancelDraw => _t(
    en: 'Cancel Draw',
    ar: 'إلغاء الرسم',
    ku: 'هەڵوەشاندنەوەی کێشان',
  );
  String areaLabel(String label, int count) => _t(
    en: 'Area: $label — $count properties',
    ar: 'منطقة: $label — $count عقار',
    ku: 'ناوچە: $label — $count خانووبەرە',
  );

  // ─── Search / Map extended ────────────────────────────────────────────────
  String get searchSaved => _t(
    en: 'Search saved',
    ar: 'تم حفظ البحث',
    ku: 'گەڕان پاشەکەوت کرا',
  );
  String get loadingProperties => _t(
    en: 'Loading properties...',
    ar: 'جاري تحميل العقارات...',
    ku: 'بارکردنی خانووبەرەکان...',
  );
  String get done => _t(en: 'Done', ar: 'تم', ku: 'تەواو');
  String get aiPicks => _t(
    en: 'AI Picks',
    ar: 'توصيات الذكاء الاصطناعي',
    ku: 'پێشنیاری ئەی ئای',
  );
  String get resetAll => _t(
    en: 'Reset All',
    ar: 'إعادة تعيين',
    ku: 'ڕیسێتی هەموو',
  );
  String get city => _t(en: 'City', ar: 'المدينة', ku: 'شار');
  String get savedSearchesTitle => _t(
    en: 'Saved Searches',
    ar: 'البحوث المحفوظة',
    ku: 'گەڕانە پاشەکەوتکراوەکان',
  );
  String savedCount(int count) => _t(
    en: '$count saved',
    ar: '$count محفوظ',
    ku: '$count پاشەکەوتکراو',
  );
  String get clearAll => _t(
    en: 'Clear All',
    ar: 'مسح الكل',
    ku: 'سڕینەوەی هەموو',
  );
  String get recent => _t(en: 'Recent', ar: 'السجل الأخير', ku: 'دوایین');
  String get savedTab => _t(en: 'Saved', ar: 'المحفوظة', ku: 'پاشەکەوتکراو');
  String get searchFilterHistory => _t(
    en: 'Search & Filter History',
    ar: 'سجل البحث والتصفية',
    ku: 'مێژووی گەڕان و فلتەر',
  );
  String resultsCount(int count) => _t(
    en: '$count results',
    ar: '$count نتيجة',
    ku: '$count ئەنجام',
  );
  String get mapTypeStandard => _t(
    en: 'Standard',
    ar: 'عادي',
    ku: 'ستاندارد',
  );
  String get mapTypeSatellite => _t(
    en: 'Satellite',
    ar: 'قمر صناعي',
    ku: 'مانگی دەستکرد',
  );
  String get mapTypeTerrain => _t(
    en: 'Terrain',
    ar: 'تضاريس',
    ku: 'زەوی',
  );
  String get mapTypeHybrid => _t(
    en: 'Hybrid',
    ar: 'هجين',
    ku: 'هایبرید',
  );
  String timeAgoMinutes(int n) => _t(
    en: '${n}m ago',
    ar: '$n دقيقة',
    ku: '$n خولەک لەمەوبەر',
  );
  String timeAgoHours(int n) => _t(
    en: '${n}h ago',
    ar: '$n ساعة',
    ku: '$n کاتژمێر لەمەوبەر',
  );
  String timeAgoDays(int n) => _t(
    en: '${n}d ago',
    ar: '$n يوم',
    ku: '$n ڕۆژ لەمەوبەر',
  );

  String filterLabel(String key) {
    switch (key) {
      case 'All':
        return all;
      case 'Sale':
        return forSale;
      case 'Rent':
        return forRent;
      case 'Mortgage':
        return mortgage;
      case 'Land':
        return land;
      case 'Commercial':
        return commercial;
      case 'Investment':
        return investment;
      default:
        return key;
    }
  }

  String mapTypeLabel(String id) {
    switch (id) {
      case 'satellite':
        return mapTypeSatellite;
      case 'terrain':
        return mapTypeTerrain;
      case 'hybrid':
        return mapTypeHybrid;
      default:
        return mapTypeStandard;
    }
  }

  // ─── Profile extended ─────────────────────────────────────────────────────
  String get notSet => _t(en: 'Not set', ar: 'غير محدد', ku: 'دیاری نەکراوە');
  String get madarUser => _t(
    en: 'Madar User',
    ar: 'مستخدم مدار',
    ku: 'بەکارهێنەری مەدار',
  );
  String get verificationSecurity => _t(
    en: 'Verification & Security',
    ar: 'التحقق والأمان',
    ku: 'پشتڕاستکردنەوە و پاراستن',
  );
  String get phoneNumberLabel => _t(
    en: 'Phone Number',
    ar: 'رقم الهاتف',
    ku: 'ژمارەی تەلەفۆن',
  );
  String get biometricVerification => _t(
    en: 'Biometric Verification',
    ar: 'التحقق البيومتري',
    ku: 'پشتڕاستکردنەوەی بایۆمەتری',
  );
  String get unverified => _t(
    en: 'Unverified',
    ar: 'غير موثق',
    ku: 'پشتڕاستنەکراوە',
  );
  String get changePhone => _t(
    en: 'Change Phone Number',
    ar: 'تغيير رقم الهاتف',
    ku: 'گۆڕینی ژمارەی تەلەفۆن',
  );
  String get notifications => _t(
    en: 'Notifications',
    ar: 'الإشعارات',
    ku: 'ئاگاداریەکان',
  );
  String get commissionDashboard => _t(
    en: 'Commission Dashboard',
    ar: 'لوحة العمولات',
    ku: 'داشبۆردی کۆمیشن',
  );
  String get sellerCommissionDashboard => _t(
    en: 'Seller Commission Dashboard',
    ar: 'لوحة عمولات البائع',
    ku: 'داشبۆردی کۆمیشنی فرۆشیار',
  );
  String get documentsArchive => _t(
    en: 'Documents Archive',
    ar: 'أرشيف الوثائق',
    ku: 'ئەرشیفی بەڵگەنامەکان',
  );
  String get contracts => _t(en: 'Contracts', ar: 'العقود', ku: 'گرێبەستەکان');
  String get titleDeeds => _t(
    en: 'Title Deeds',
    ar: 'السندات',
    ku: 'سەندەکان',
  );
  String get favorites => _t(
    en: 'Favorites',
    ar: 'المفضلة',
    ku: 'دڵخوازەکان',
  );
  String get activeAccount => _t(
    en: 'Active Account',
    ar: 'حساب نشط',
    ku: 'هەژماری چالاک',
  );
  String get accountSuspended => _t(
    en: 'Suspended',
    ar: 'موقوف',
    ku: 'هەڵواسراو',
  );
  String get profileSaved => _t(
    en: 'Profile saved',
    ar: 'تم حفظ الملف الشخصي',
    ku: 'پرۆفایل پاشەکەوت کرا',
  );
  String get ok => _t(en: 'OK', ar: 'حسناً', ku: 'باشە');

  // ─── Messages ─────────────────────────────────────────────────────────────
  String get msgAiAssistant => _t(
    en: 'Madar AI Assistant',
    ar: 'مساعد مدار الذكي',
    ku: 'یاریدەدەری ئەی ئای مەدار',
  );
  String get msgCustomerSupport => _t(
    en: 'Customer Support',
    ar: 'خدمة العملاء',
    ku: 'پشتگیری کڕیار',
  );
  String get msgSalesTeam => _t(
    en: 'Sales Team',
    ar: 'فريق المبيعات',
    ku: 'تیمی فرۆشتن',
  );
  String get msgClosingTeam => _t(
    en: 'Deal Closing Team',
    ar: 'فريق إغلاق الصفقات',
    ku: 'تیمی داخستنی مامەڵە',
  );
  String get msgAgentLawyer => _t(
    en: 'Agent / Lawyer',
    ar: 'الوكيل / المحامي',
    ku: 'نوێنەر / پارێزەر',
  );
  String get msgAiSub => _t(
    en: 'Powered by AI',
    ar: 'مدعوم بالذكاء الاصطناعي',
    ku: 'پشتگیری لە ئەی ئای',
  );
  String get msgSupportSub => _t(
    en: 'Available 24/7',
    ar: 'متاح 24/7',
    ku: 'بەردەستە 24/7',
  );
  String get msgSalesSub => _t(
    en: 'Property inquiries',
    ar: 'للاستفسار عن العقارات',
    ku: 'پرسیار دەربارەی خانووبەرە',
  );
  String get msgClosingSub => _t(
    en: 'Close your deals',
    ar: 'لإتمام صفقاتك',
    ku: 'مامەڵەکانت دابخە',
  );
  String get msgAgentSub => _t(
    en: 'Receive transaction code',
    ar: 'لاستلام رمز الصفقة',
    ku: 'وەرگرتنی کۆدی مامەڵە',
  );

  // ─── Deals / Transactions ───────────────────────────────────────────────────
  String get noActiveDeals => _t(
    en: 'No active deals',
    ar: 'لا توجد صفقات نشطة',
    ku: 'هیچ مامەڵەی چالاک نییە',
  );
  String get verifying => _t(
    en: 'Verifying...',
    ar: 'جاري التحقق...',
    ku: 'پشتڕاستکردنەوە...',
  );
  String get allDealsTitle => _t(
    en: 'All Deals',
    ar: 'كل الصفقات',
    ku: 'هەموو مامەڵەکان',
  );
  String get refresh => _t(
    en: 'Refresh',
    ar: 'تحديث',
    ku: 'نوێکردنەوە',
  );
  String get scanBarcode => _t(
    en: 'Scan Barcode',
    ar: 'مسح الباركود',
    ku: 'پێداچوونەوەی بارکۆد',
  );
  String get depositConfirmed => _t(
    en: 'Deposit confirmed',
    ar: 'تم الإيداع والتأكيد',
    ku: 'دانان پشتڕاستکرایەوە',
  );
  String get escrowConfirmedSuccess => _t(
    en: 'Escrow deposit confirmed successfully',
    ar: 'تم تأكيد الإيداع الضماني بنجاح',
    ku: 'دانانی گەروی بە سەرکەوتوویی پشتڕاستکرایەوە',
  );
  String stageCompletedSuccess(int stage) => _t(
    en: 'Stage $stage completed successfully',
    ar: 'تم إكمال المرحلة $stage بنجاح',
    ku: 'قۆناغ $stage بە سەرکەوتوویی تەواوبوو',
  );

  // ─── Add Property ─────────────────────────────────────────────────────────
  String get imageAttached => _t(
    en: 'Image attached',
    ar: 'تم إرفاق صورة',
    ku: 'وێنە هاوپێچ کرا',
  );
  String get noImage => _t(
    en: 'No image',
    ar: 'بدون صورة',
    ku: 'بێ وێنە',
  );

  String get noSearchHistoryYet => _t(
    en: 'No search history yet',
    ar: 'لا يوجد سجل بحث بعد',
    ku: 'هێشتا مێژووی گەڕان نییە',
  );
  String get enterSearchToSave => _t(
    en: 'Enter a search or filter to save',
    ar: 'أدخل بحثاً أو فلتراً لحفظه',
    ku: 'گەڕان یان فلتەر بنووسە بۆ پاشەکەوتکردن',
  );
  String get noSavedSearchesYet => _t(
    en: 'No saved searches yet',
    ar: 'لا توجد عمليات بحث محفوظة بعد',
    ku: 'هێشتا گەڕانی پاشەکەوتکراو نییە',
  );

  String get drawAreaHint => _t(
    en: 'Tap on map to draw selection area',
    ar: 'اضغط على الخريطة لرسم منطقة التحديد',
    ku: 'بۆ کێشانی ناوچە لەسەر نەخشە دەست لێبدە',
  );
  String propertyCountShort(int count) => _t(
    en: '$count Properties',
    ar: '$count عقار',
    ku: '$count خانووبەرە',
  );

  // ─── Property Intelligence Report ─────────────────────────────────────────
  String get propertyReport => _t(
    en: 'Property Report',
    ar: 'تقرير العقار',
    ku: 'ڕاپۆرتی خانووبەرە',
  );
  String get askAiAboutProperty => _t(
    en: 'Ask AI about this property',
    ar: 'اسأل الذكاء الاصطناعي عن هذا العقار',
    ku: 'لە ئەی ئای بپرسە دەربارەی ئەم خانووبەرەیە',
  );
  String get askAi => _t(en: 'Ask AI', ar: 'اسأل AI', ku: 'بپرسە لە AI');
  String get contactConnect => _t(
    en: 'Contact Sales',
    ar: 'تواصل مع المبيعات',
    ku: 'پەیوەندی فرۆشتن',
  );
  String get videoTour => _t(
    en: 'Video Tour',
    ar: 'جولة فيديو',
    ku: 'گەشتی ڤیدیۆ',
  );
  String get inPersonTour => _t(
    en: 'In-person Tour',
    ar: 'زيارة حضورية',
    ku: 'سەردانی ڕاستەوخۆ',
  );
  String get tourRequestSent => _t(
    en: 'Tour request sent to our team',
    ar: 'تم إرسال طلب الجولة لفريقنا',
    ku: 'داواکاری گەشت نێردرا بۆ تیمەکەمان',
  );
  String get inquirySentToSales => _t(
    en: 'Inquiry sent to Sales Team',
    ar: 'تم إرسال الاستفسار لفريق المبيعات',
    ku: 'پرسیار نێردرا بۆ تیمی فرۆشتن',
  );
  String get statusSold => _t(en: 'Sold', ar: 'مباع', ku: 'فرۆشراو');
  String get statusReserved =>
      _t(en: 'Reserved', ar: 'محجوز', ku: 'پارێزراو');
  String get statusUnderReview => _t(
    en: 'Under Review',
    ar: 'قيد المراجعة',
    ku: 'لە ژێر پێداچوونەوە',
  );
  String get statusOffMarket =>
      _t(en: 'Off Market', ar: 'خارج السوق', ku: 'دەرەوەی بازاڕ');
  String get dataVerified =>
      _t(en: 'Verified', ar: 'موثق', ku: 'پشتڕاستکراو');
  String get dataPublisherProvided => _t(
    en: 'Publisher',
    ar: 'من الناشر',
    ku: 'لە بڵاوکەرەوە',
  );
  String get dataEstimated =>
      _t(en: 'Estimated', ar: 'تقديري', ku: 'خەمڵێنراو');
  String get dataExternal =>
      _t(en: 'External', ar: 'مصدر خارجي', ku: 'سەرچاوەی دەرەکی');
  String get dataMockDemo =>
      _t(en: 'Mock / Demo', ar: 'تجريبي', ku: 'نموونە / دیمۆ');
  String get sectionNoDataYet => _t(
    en: 'No data available yet',
    ar: 'لا توجد بيانات بعد',
    ku: 'هێشتا داتا نییە',
  );
  String get factsAndFeatures => _t(
    en: 'Facts & Features',
    ar: 'الحقائق والمميزات',
    ku: 'ڕاستی و تایبەتمەندی',
  );
  String get priceAndValuation => _t(
    en: 'Price & Valuation',
    ar: 'السعر والتقييم',
    ku: 'نرخ و هەڵسەنگاندن',
  );
  String get currentPrice =>
      _t(en: 'Current Price', ar: 'السعر الحالي', ku: 'نرخی ئێستا');
  String get previousPrice =>
      _t(en: 'Previous Price', ar: 'السعر السابق', ku: 'نرخی پێشوو');
  String get estimatedValue =>
      _t(en: 'Estimated Value', ar: 'القيمة التقديرية', ku: 'بەهای خەمڵێنراو');
  String get investmentPotential => _t(
    en: 'Investment Potential',
    ar: 'إمكانية الاستثمار',
    ku: 'توانای وەبەرهێنان',
  );
  String get rentAnalysis =>
      _t(en: 'Rental Analysis', ar: 'تحليل الإيجار', ku: 'شیکاری کرێ');
  String get futureOfArea => _t(
    en: 'Future of the Area',
    ar: 'مستقبل المنطقة',
    ku: 'داهاتووی ناوچەکە',
  );
  String get nearbyInvestmentOpportunities => _t(
    en: 'Nearby Investment Opportunities',
    ar: 'فرص استثمارية قريبة',
    ku: 'دەرفەتی وەبەرهێنانی نزیک',
  );
  String get nearbyPlaces =>
      _t(en: 'Nearby Places', ar: 'أماكن قريبة', ku: 'شوێنە نزیکەکان');
  String get transportationAccess => _t(
    en: 'Transportation & Accessibility',
    ar: 'النقل والوصول',
    ku: 'گواستنەوە و گەیشتن',
  );
  String get infrastructure =>
      _t(en: 'Infrastructure', ar: 'البنية التحتية', ku: 'ژێرخان');
  String get risksEnvironment => _t(
    en: 'Risks & Environment',
    ar: 'المخاطر والبيئة',
    ku: 'مەترسی و ژینگە',
  );
  String get developmentPotential => _t(
    en: 'Development Potential',
    ar: 'إمكانية التطوير',
    ku: 'توانای گەشەپێدان',
  );
  String get renovationImprovements => _t(
    en: 'Renovation & Improvements',
    ar: 'التجديد والتحسينات',
    ku: 'نوێکردنەوە و باشترکردن',
  );
  String get energySustainability => _t(
    en: 'Energy & Sustainability',
    ar: 'الطاقة والاستدامة',
    ku: 'وزە و بەردەوامی',
  );
  String get buildingDetails =>
      _t(en: 'Building Details', ar: 'تفاصيل المبنى', ku: 'وردەکاری بینا');
  String get interior => _t(en: 'Interior', ar: 'داخلي', ku: 'ناوەوە');
  String get exterior => _t(en: 'Exterior', ar: 'خارجي', ku: 'دەرەوە');
  String get utilitiesServices => _t(
    en: 'Utilities & Services',
    ar: 'المرافق والخدمات',
    ku: 'خزمەتگوزاری و سوودمەندی',
  );
  String get lastUpdated =>
      _t(en: 'Last updated', ar: 'آخر تحديث', ku: 'دوایین نوێکردنەوە');
  String get tour3d => _t(en: '3D Tour', ar: 'جولة ثلاثية الأبعاد', ku: 'گەشتی سێ ڕەهەندی');
  String get virtualTour =>
      _t(en: 'Virtual Tour', ar: 'جولة افتراضية', ku: 'گەشتی مەجازی');
  String get floorPlan =>
      _t(en: 'Floor Plan', ar: 'المخطط', ku: 'نەخشەی نهۆم');
  String get builtUpArea =>
      _t(en: 'Built-up Area', ar: 'مساحة البناء', ku: 'ڕووبەری بینا');
  String get landArea =>
      _t(en: 'Land Area', ar: 'مساحة الأرض', ku: 'ڕووبەری زەوی');
  String get livingRooms =>
      _t(en: 'Living Rooms', ar: 'صالات', ku: 'ژووری دانیشتن');
  String get yearBuilt =>
      _t(en: 'Year Built', ar: 'سنة البناء', ku: 'ساڵی دروستکردن');
  String get yearRenovated =>
      _t(en: 'Year Renovated', ar: 'سنة التجديد', ku: 'ساڵی نوێکردنەوە');
  String get parking => _t(en: 'Parking', ar: 'مواقف', ku: 'پارکینگ');
  String get floor => _t(en: 'Floor', ar: 'الطابق', ku: 'نهۆم');
  String get totalFloors =>
      _t(en: 'Total Floors', ar: 'إجمالي الطوابق', ku: 'کۆی نهۆمەکان');
  String get propertyTypeLabel =>
      _t(en: 'Property Type', ar: 'نوع العقار', ku: 'جۆری خانووبەرە');
  String get priceChange =>
      _t(en: 'Price Change', ar: 'تغير السعر', ku: 'گۆڕانی نرخ');
  String get salesHistory =>
      _t(en: 'Sales History', ar: 'تاريخ المبيعات', ku: 'مێژووی فرۆشتن');
  String get publisher =>
      _t(en: 'Publisher', ar: 'الناشر', ku: 'بڵاوکەرەوە');
  String get scheduleTourTitle => _t(
    en: 'Schedule a Tour',
    ar: 'حجز جولة',
    ku: 'گەشتێک پلان بکە',
  );
  String get tourNotesHint => _t(
    en: 'Notes (optional)',
    ar: 'ملاحظات (اختياري)',
    ku: 'تێبینی (ئارەزوومەندانە)',
  );
  String get sendRequest =>
      _t(en: 'Send Request', ar: 'إرسال الطلب', ku: 'ناردنی داواکاری');
  String get rentToOwnCalculator => _t(
    en: 'Rent-to-Own Calculator',
    ar: 'حاسبة الإيجار التمليكي',
    ku: 'ژمێرەری کرێ بۆ خاوەنداری',
  );
  String get initialPayment =>
      _t(en: 'Initial Payment', ar: 'الدفعة الأولى', ku: 'پارەی سەرەتا');
  String get monthlyPayment =>
      _t(en: 'Monthly Payment', ar: 'القسط الشهري', ku: 'پارەدانی مانگانە');
  String get contractDuration =>
      _t(en: 'Contract Duration', ar: 'مدة العقد', ku: 'ماوەی گرێبەست');
  String get ownershipContribution => _t(
    en: 'Toward Ownership',
    ar: 'نحو التملك',
    ku: 'بەرەو خاوەنداری',
  );
  String get remainingBalance => _t(
    en: 'Remaining Balance',
    ar: 'الرصيد المتبقي',
    ku: 'باڵانسی ماوە',
  );
  String get months => _t(en: 'months', ar: 'أشهر', ku: 'مانگ');
  String get savedProperty =>
      _t(en: 'Saved', ar: 'محفوظ', ku: 'پاشەکەوتکرا');
  String get unsavedProperty =>
      _t(en: 'Save', ar: 'حفظ', ku: 'پاشەکەوت');
  String get shareProperty =>
      _t(en: 'Share', ar: 'مشاركة', ku: 'هاوبەشکردن');
  String get aiGroundedDisclaimer => _t(
    en: 'Answers are based only on available property data.',
    ar: 'الإجابات تعتمد فقط على بيانات العقار المتاحة.',
    ku: 'وەڵامەکان تەنها لەسەر داتای بەردەستی خانووبەرەن.',
  );
  String get locationHierarchy =>
      _t(en: 'Location', ar: 'الموقع', ku: 'شوێن');
  String get mapSection => _t(en: 'Map', ar: 'الخريطة', ku: 'نەخشە');
  String get yesLabel => _t(en: 'Yes', ar: 'نعم', ku: 'بەڵێ');
  String get noLabel => _t(en: 'No', ar: 'لا', ku: 'نەخێر');
  String get elevator => _t(en: 'Elevator', ar: 'مصعد', ku: 'ئاسانسۆر');
  String get furnished => _t(en: 'Furnished', ar: 'مفروش', ku: 'فەرشکراو');
  String get balcony => _t(en: 'Balcony', ar: 'شرفة', ku: 'باڵکۆن');
  String get garden => _t(en: 'Garden', ar: 'حديقة', ku: 'باخچە');
  String get pool => _t(en: 'Pool', ar: 'مسبح', ku: 'مەلەوانگە');

  // ─── Edit Profile / Messages / Profile copy ───────────────────────────────
  String get editProfileTitle => _t(
    en: 'Edit Profile',
    ar: 'تعديل الملف الشخصي',
    ku: 'دەستکاری پرۆفایل',
  );
  String get tapToChangePhoto => _t(
    en: 'Tap to change photo',
    ar: 'اضغط لتغيير الصورة',
    ku: 'دەست لێبدە بۆ گۆڕینی وێنە',
  );
  String get firstName =>
      _t(en: 'First Name', ar: 'الاسم الأول', ku: 'ناوی یەکەم');
  String get lastName =>
      _t(en: 'Last Name', ar: 'اسم العائلة', ku: 'ناوی خێزان');
  String get displayName =>
      _t(en: 'Display Name', ar: 'الاسم المعروض', ku: 'ناوی پیشاندان');
  String get contactInformation => _t(
    en: 'Contact Information',
    ar: 'معلومات التواصل',
    ku: 'زانیاری پەیوەندی',
  );
  String get emailAddress => _t(
    en: 'Email Address',
    ar: 'البريد الإلكتروني',
    ku: 'ناونیشانی ئیمەیل',
  );
  String get bio => _t(en: 'Bio', ar: 'نبذة شخصية', ku: 'کورتە');
  String get bioHint => _t(
    en: 'Write something about yourself...',
    ar: 'اكتب نبذة عنك...',
    ku: 'شتێک دەربارەی خۆت بنووسە...',
  );
  String get fieldRequired => _t(
    en: 'This field is required',
    ar: 'هذا الحقل مطلوب',
    ku: 'ئەم خانەیە پێویستە',
  );
  String get failedSendImage => _t(
    en: 'Failed to send image',
    ar: 'فشل إرسال الصورة',
    ku: 'ناردنی وێنە سەرکەوتوو نەبوو',
  );
  String get failedGetLocation => _t(
    en: 'Failed to get location',
    ar: 'فشل الحصول على الموقع',
    ku: 'وەرگرتنی شوێن سەرکەوتوو نەبوو',
  );
  String get imageLabel => _t(en: 'Image', ar: 'صورة', ku: 'وێنە');
  String get cameraLabel => _t(en: 'Camera', ar: 'كاميرا', ku: 'کامێرا');
  String get locationLabel => _t(en: 'Location', ar: 'موقع', ku: 'شوێن');
  String get howDealsWork => _t(
    en: 'How do transactions work?',
    ar: 'كيف تعمل الصفقات؟',
    ku: 'مامەڵەکان چۆن کاردەکەن؟',
  );
  String get currentLocation => _t(
    en: 'Current Location',
    ar: 'الموقع الحالي',
    ku: 'شوێنی ئێستا',
  );
  String get openInMaps =>
      _t(en: 'Open in Maps', ar: 'فتح في الخريطة', ku: 'لە نەخشەدا بکەرەوە');
  String get savingImage => _t(
    en: 'Saving image...',
    ar: 'جاري حفظ الصورة...',
    ku: 'وێنە پاشەکەوت دەکرێت...',
  );
  String get typeYourMessage => _t(
    en: 'Type your message...',
    ar: 'اكتب رسالتك...',
    ku: 'نامەکەت بنووسە...',
  );
  String get noFavoritePropertiesYet => _t(
    en: 'No favorite properties yet',
    ar: 'لا توجد عقارات مفضلة بعد',
    ku: 'هێشتا خانووبەرەی دڵخواز نییە',
  );
  String get allDocumentsContractsDeeds => _t(
    en: 'All Documents, Contracts & Title Deeds',
    ar: 'جميع الوثائق والعقود والسندات',
    ku: 'هەموو بەڵگەنامە و گرێبەست و سندەکان',
  );
  String get tapToViewTransactionDocs => _t(
    en: 'Tap to view and download transaction documents',
    ar: 'اضغط لعرض وتحميل وثائق صفقاتك',
    ku: 'دەست لێبدە بۆ بینین و داگرتنی بەڵگەنامەکانی مامەڵە',
  );
  String get phoneChangeSupportNote => _t(
    en: 'Our support team will contact you to change your phone number.',
    ar: 'سيتم التواصل معك من فريق الدعم لتغيير رقم هاتفك',
    ku: 'تیمی پشتگیری پەیوەندیت پێدەکات بۆ گۆڕینی ژمارەی تەلەفۆن.',
  );
  String get markAllRead => _t(
    en: 'Mark all read',
    ar: 'قراءة الكل',
    ku: 'هەموو بخوێنەوە',
  );
  String unreadCountLabel(int n) => _t(
    en: '$n unread notifications',
    ar: '$n إشعارات غير مقروءة',
    ku: '$n ئاگاداری نەخوێندراوە',
  );
  String get noNotificationsYet => _t(
    en: 'No notifications',
    ar: 'لا توجد إشعارات',
    ku: 'ئاگاداری نییە',
  );
  String minutesAgo(int m) =>
      _t(en: '${m}m ago', ar: 'منذ ${m}د', ku: '$m خولەک پێش ئێستا');
  String hoursAgo(int h) =>
      _t(en: '${h}h ago', ar: 'منذ ${h}س', ku: '$h کاتژمێر پێش ئێستا');
  String daysAgo(int d) =>
      _t(en: '${d}d ago', ar: 'منذ ${d}ي', ku: '$d ڕۆژ پێش ئێستا');

  // ─── Helper ───────────────────────────────────────────────────────────────
  String _t({
    required String en,
    required String ar,
    String? ar2,
    required String ku,
  }) {
    switch (language) {
      case AppLanguage.arabic:
        return ar2 ?? ar;
      case AppLanguage.kurdish:
        return ku;
      case AppLanguage.english:
        return en;
    }
    return en;
  }
}

// ─── Delegate ─────────────────────────────────────────────────────────────────
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  final AppLanguage language;
  const AppLocalizationsDelegate(this.language);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(language);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => old.language != language;
}
