import 'package:flutter/material.dart';

// Supported locales
enum AppLanguage { english, arabic, kurdish }

class AppLocalizations {
  final AppLanguage language;

  const AppLocalizations(this.language);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(AppLanguage.arabic);
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
  String get propertiesFound =>
      _t(en: 'Properties Found', ar: 'عقار موجود', ku: 'خانووبەرە دۆزراوەکان');
  String get zoomToSeeProperties => _t(
    en: 'Zoom to see the properties',
    ar: 'كبّر الخريطة لرؤية العقارات',
    ku: 'زووم بکە بۆ بینینی خانووبەرەکان',
  );
  String resultsCountLabel(int count) => _t(
    en: '$count properties found',
    ar: '$count عقار موجود',
    ku: '$count خانووبەرە دۆزرایەوە',
  );
  String get swipeForMore => _t(
    en: 'Swipe for more listings',
    ar: 'اسحب لعرض المزيد',
    ku: 'ڕابکێشە بۆ زیاتر',
  );
  String get sortHomesForYou =>
      _t(en: 'Homes for You', ar: 'مقترحة لك', ku: 'پێشنیار بۆ تۆ');
  String get sortPriceLowHigh => _t(
    en: 'Price: low to high',
    ar: 'السعر: من الأقل للأعلى',
    ku: 'نرخ: کەم بۆ زۆر',
  );
  String get sortPriceHighLow => _t(
    en: 'Price: high to low',
    ar: 'السعر: من الأعلى للأقل',
    ku: 'نرخ: زۆر بۆ کەم',
  );
  String get sortAreaLarge =>
      _t(en: 'Largest area', ar: 'الأكبر مساحة', ku: 'گەورەترین ڕووبەر');
  String get sortNewest => _t(en: 'Newest', ar: 'الأحدث', ku: 'نوێترین');
  String get saveSearch =>
      _t(en: 'Save search', ar: 'حفظ البحث', ku: 'پاشەکەوتی گەڕان');
  String get aiPicksForYou => _t(
    en: 'AI picks for you',
    ar: 'مقترح لك بواسطة الذكاء الاصطناعي',
    ku: 'پێشنیاری AI بۆ تۆ',
  );
  String get backToMap => _t(en: 'Map', ar: 'الخريطة', ku: 'نەخشە');
  String get nearLandmarkResults =>
      _t(en: 'Properties near', ar: 'عقارات قرب', ku: 'خانووبەرە نزیک');
  String get areaResultsIn =>
      _t(en: 'Results in', ar: 'النتائج داخل', ku: 'ئەنجامەکان لە');
  String get similarProperties => _t(
    en: 'Similar properties',
    ar: 'عقارات مشابهة',
    ku: 'خانووبەرەی هاوشێوە',
  );
  String get minBathrooms => _t(
    en: 'Min. bathrooms',
    ar: 'حمامات (الحد الأدنى)',
    ku: 'کەمترین ئاوخانە',
  );
  String get featuresLabel =>
      _t(en: 'Features', ar: 'المميزات', ku: 'تایبەتمەندییەکان');
  String get nearbyLabel => _t(en: 'Nearby', ar: 'قريب من', ku: 'نزیک لە');
  String get builderCompanyLabel => _t(
    en: 'Builder / contractor',
    ar: 'الشركة / المقاول الباني',
    ku: 'کۆمپانیای بیناساز',
  );
  String get builderCompanyHint => _t(
    en: 'e.g. Al-Rasheed Construction',
    ar: 'مثال: شركة الرشيد للإعمار',
    ku: 'نموونە: کۆمپانیای ڕەشید',
  );
  String get yearBuiltLabel => _t(
    en: 'Year built (min.)',
    ar: 'سنة البناء (الأقدم)',
    ku: 'ساڵی بیناسازی',
  );
  String get verifiedOnly =>
      _t(en: 'Verified only', ar: 'الموثقة فقط', ku: 'تەنها پشتڕاستکراوەکان');
  String get clearAreaFilter =>
      _t(en: 'Clear area', ar: 'إزالة تحديد المنطقة', ku: 'سنوور لاببە');
  String get openListing =>
      _t(en: 'View listing', ar: 'عرض العقار', ku: 'بینینی خانووبەرە');
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
  String get apartment => _t(en: 'Apartment', ar: 'شقة', ku: 'شوقە');
  String get villaType => _t(en: 'Villa', ar: 'فيلا', ku: 'ڤیلا');
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
  String get verified => _t(en: 'Guaranteed', ar: 'مضمون', ku: 'دڵنیاکراو');
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
  String get contactSalesShort => _t(
    en: 'Contact',
    ar: 'تواصل',
    ku: 'پەیوەندی',
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
      _t(en: 'Add property +', ar: 'إضافة عقار +', ku: 'زیادکردنی خانووبەرە +');
  String get underReview =>
      _t(en: 'Under Review', ar: 'قيد التدقيق', ku: 'لەژێر پێداچوونەوەدایە');
  String get submittedRequests => _t(
    en: 'Submitted Requests',
    ar: 'الطلبات المقدمة',
    ku: 'داواکاری نێردراوەکان',
  );
  String get partnerAdTag =>
      _t(en: 'Madar Partner', ar: 'شريك مدار', ku: 'هاوبەشی مەدار');
  String get adMovingTitle => _t(
    en: 'Furniture moving',
    ar: 'خدمة نقل الأثاث',
    ku: 'گواستنەوەی کەلوپەل',
  );
  String get adMovingSubtitle => _t(
    en: 'Safe professional relocation for your home or office.',
    ar: 'نقل احترافي وآمن لمنزلك أو مكتبك.',
    ku: 'گواستنەوەی پیشەیی و سەلامەت بۆ ماڵ یان ئۆفیس.',
  );
  String get adStagingTitle => _t(
    en: 'Property styling & fit-out',
    ar: 'تجميل وتجهيز عقاري',
    ku: 'جوانکردن و ئامادەکردنی خانووبەرە',
  );
  String get adStagingSubtitle => _t(
    en: 'Interior finishing that lifts listing value before photos.',
    ar: 'تشطيبات داخلية ترفع قيمة إعلانك قبل التصوير.',
    ku: 'تەواوکاری ناوەوە کە نرخی لیستەکەت بەرز دەکاتەوە.',
  );
  String get adWarrantyTitle => _t(
    en: 'Warranty & maintenance',
    ar: 'ضمان وصيانة',
    ku: 'گەرەنتی و چاککردنەوە',
  );
  String get adWarrantySubtitle => _t(
    en: 'Coverage and upkeep so your asset stays protected.',
    ar: 'تغطية وصيانة تحمي أصلَك على مدار السنة.',
    ku: 'پاراستن و چاککردنەوە بۆ ئەوەی موڵکەکەت بمێنێت.',
  );
  String get addPropertySheetTitle =>
      _t(en: 'Add a property', ar: 'إضافة عقار', ku: 'زیادکردنی خانووبەرە');
  String get addPropertySheetHint => _t(
    en: 'Share location, a photo, and a contact number. Sales will call you.',
    ar: 'أرسل الموقع والصورة ورقم التواصل، وسيتصل بك فريق المبيعات.',
    ku: 'شوێن، وێنە و ژمارەی پەیوەندی بنێرە، فرۆشتن پەیوەندیت پێوە دەکات.',
  );
  String get propertyLocationLabel =>
      _t(en: 'Property location', ar: 'موقع العقار', ku: 'شوێنی خانووبەرە');
  String get useCurrentLocation => _t(
    en: 'Use my current location',
    ar: 'استخدام موقعي الحالي',
    ku: 'شوێنی ئێستام بەکاربهێنە',
  );
  String get locationCaptured =>
      _t(en: 'Location captured', ar: 'تم تحديد الموقع', ku: 'شوێن تۆمارکرا');
  String get enterAddressManually => _t(
    en: 'Or enter the address',
    ar: 'أو أدخل العنوان يدوياً',
    ku: 'یان ناونیشان بنووسە',
  );
  String get addressHint => _t(
    en: 'e.g. Karrada, near Al-Nidhal Street',
    ar: 'مثال: الكرادة، بالقرب من شارع النضال',
    ku: 'نموونە: کەرادە، نزیک شەقامی نیدال',
  );
  String get propertyPhotoLabel =>
      _t(en: 'Property photo', ar: 'صورة العقار', ku: 'وێنەی خانووبەرە');
  String get addPropertyPhoto =>
      _t(en: 'Add a photo', ar: 'إضافة صورة للعقار', ku: 'وێنەیەک زیاد بکە');
  String get takePhoto =>
      _t(en: 'Take photo', ar: 'التقاط صورة', ku: 'وێنە بگرە');
  String get chooseFromGallery => _t(
    en: 'Choose from gallery',
    ar: 'اختيار من المعرض',
    ku: 'لە گەلەری هەڵبژێرە',
  );
  String get contactNumberLabel =>
      _t(en: 'Contact number', ar: 'رقم للتواصل', ku: 'ژمارەی پەیوەندی');
  String get submitPropertyRequest =>
      _t(en: 'Submit', ar: 'إرسال', ku: 'ناردن');
  String get propertyRequestSent => _t(
    en: 'Submitted. Your listing is under review.',
    ar: 'تم الإرسال. عقارك الآن قيد التدقيق.',
    ku: 'نێردرا. لیستەکەت لەژێر پێداچوونەوەدایە.',
  );
  String get locationRequired => _t(
    en: 'Add a location or address',
    ar: 'يرجى تحديد الموقع أو إدخال العنوان',
    ku: 'شوێن یان ناونیشان زیاد بکە',
  );
  String get photoRequired => _t(
    en: 'Add a property photo',
    ar: 'يرجى إضافة صورة للعقار',
    ku: 'وێنەی خانووبەرە زیاد بکە',
  );
  String get phoneRequired => _t(
    en: 'Enter a valid phone number',
    ar: 'أدخل رقم هاتف صحيح',
    ku: 'ژمارەیەکی دروست بنووسە',
  );
  String get locationDisabled => _t(
    en: 'Location services are off',
    ar: 'خدمة الموقع غير مفعّلة',
    ku: 'خزمەتگوزاری شوێن ناکارایە',
  );
  String get locationDenied => _t(
    en: 'Location permission denied',
    ar: 'تم رفض إذن الموقع',
    ku: 'مۆڵەتی شوێن ڕەتکرایەوە',
  );
  String get locationFailed => _t(
    en: 'Could not read location',
    ar: 'تعذّر الحصول على الموقع',
    ku: 'نەتوانرا شوێن بخوێنرێتەوە',
  );
  String get noPropertiesYet => _t(
    en: 'No properties yet',
    ar: 'لا توجد عقارات بعد',
    ku: 'هێشتا خانووبەرە نییە',
  );
  String get noPropertiesHint => _t(
    en: 'Add your first property and our sales team will follow up.',
    ar: 'أضف عقارك الأول وسيتواصل معك فريق المبيعات.',
    ku: 'یەکەم خانووبەرە زیاد بکە و تیمی فرۆشتن پەیوەندیت پێوە دەکات.',
  );
  String get marketValue =>
      _t(en: 'Market value', ar: 'القيمة السوقية', ku: 'نرخی بازاڕ');
  String get priceInsightsTitle => _t(
    en: 'What could raise your price',
    ar: 'ماذا يمكن أن يزيد من سعر عقارك',
    ku: 'چی دەتوانێت نرخی خانووبەرەکەت بەرز بکاتەوە',
  );
  String get priceInsightPhotos => _t(
    en: 'Pro photography can lift offers by up to 8%.',
    ar: 'التصوير الاحترافي يمكن أن يرفع العروض حتى 8٪.',
    ku: 'وێنەگرتنی پیشەیی دەتوانێت ئۆفەر تا 8٪ بەرز بکاتەوە.',
  );
  String get priceInsightKitchen => _t(
    en: 'A kitchen and facade refresh increases local demand.',
    ar: 'تجديد المطبخ والواجهة يزيد الطلب في منطقتك.',
    ku: 'نوێکردنەوەی چێشتخانە و ڕوکار داواکاری ناوچەکە زیاد دەکات.',
  );
  String get priceInsightDeed => _t(
    en: 'A complete title deed speeds the sale and supports a higher price.',
    ar: 'توثيق سند الملكية الكامل يسرّع البيع ويدعم سعراً أعلى.',
    ku: 'سەندی خاوەنداری تەواو فرۆشتن خێراتر دەکات و نرخ بەرزتر دەکات.',
  );
  String get managedByCompany => _t(
    en: 'Managed by Madar',
    ar: 'يُدار بواسطة مدار',
    ku: 'لەلایەن مەدارەوە بەڕێوەدەبرێت',
  );
  String get monthlyIncome =>
      _t(en: 'Your monthly income', ar: 'المكسب الشهري', ku: 'داهاتی مانگانە');
  String get managementFee => _t(
    en: 'Fixed company management fee',
    ar: 'رسوم إدارة الشركة الثابتة',
    ku: 'کرێی جێگیری بەڕێوەبردنی کۆمپانیا',
  );
  String get statusActiveLabel => _t(en: 'Active', ar: 'نشط', ku: 'چالاک');
  String get statusPendingLabel =>
      _t(en: 'Pending', ar: 'معلق', ku: 'چاوەڕوان');
  String get ownedListingCount =>
      _t(en: 'Your listings', ar: 'عقاراتك', ku: 'لیستەکانت');
  String get gpsLocationFallback =>
      _t(en: 'GPS location', ar: 'موقع GPS', ku: 'شوێنی GPS');

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
  String get authBrandName => _t(en: 'مدار', ar: 'مدار', ku: 'مدار');
  String get authBrandTagline => _t(en: 'عقارات', ar: 'عقارات', ku: 'عقارات');
  String get authDesktopTagline => _t(
    en: 'Discover, compare, and close property deals with confidence.',
    ar: 'اكتشف العقارات وقارنها وأتمم صفقاتك بثقة.',
    ku: 'خانووبەرە بدۆزەرەوە، بەراورد بکە و مامەڵەکانت بە متمانە تەواو بکە.',
  );
  String get authDesktopFeatureMap => _t(
    en: 'Interactive maps with smart search and area filters',
    ar: 'خرائط تفاعلية مع بحث ذكي وتصفية حسب المنطقة',
    ku: 'نەخشەی کارلێکدار لەگەڵ گەڕانی زیرەک و فلتەری ناوچە',
  );
  String get authDesktopFeatureVerified => _t(
    en: 'Verified listings and secure transactions',
    ar: 'إعلانات موثقة ومعاملات آمنة',
    ku: 'لیستی پشتڕاستکراو و مامەڵەی پارێزراو',
  );
  String get authDesktopFeatureLanguages => _t(
    en: 'Arabic, English, and Kurdish — built for Iraq',
    ar: 'العربية والإنجليزية والكردية — مصمم للعراق',
    ku: 'عەرەبی، ئینگلیزی و کوردی — دروستکراو بۆ عێراق',
  );
  String get authDesktopFooter => _t(
    en: 'Premium real estate platform for buyers, sellers, and professionals.',
    ar: 'منصة عقارية متميزة للمشترين والبائعين والمحترفين.',
    ku: 'پلاتفۆرمی خانووبەرەی پریمیۆم بۆ کڕیار، فرۆشیار و پیشەییەکان.',
  );
  String get authWelcome => _t(en: 'Welcome', ar: 'مرحباً بك', ku: 'بەخێربێیت');
  String get authPhoneTitle =>
      _t(en: 'Login', ar: 'تسجيل الدخول', ku: 'چوونەژوورەوە');
  String get authPhoneSubtitle => _t(
    en: 'Choose your country and enter your mobile number. We will send you a verification code.',
    ar: 'اختر بلدك وأدخل رقم هاتفك المحمول، وسنرسل لك رمز التحقق',
    ku: 'وڵاتەکەت هەڵبژێرە و ژمارەی مۆبایل بنووسە، کۆدی پشتڕاستکردنەوە دەنێرین.',
  );
  String get authContinue =>
      _t(en: 'Login', ar: 'تسجيل الدخول', ku: 'چوونەژوورەوە');
  String get authCountryField => _t(en: 'Country', ar: 'البلد', ku: 'وڵات');
  String get authPhoneField =>
      _t(en: 'Your phone number', ar: 'رقم هاتفك', ku: 'ژمارەی تەلەفۆنەکەت');
  String get authAgreePrivacy => _t(
    en: 'I agree to the Privacy Policy and Terms of Use',
    ar: 'أوافق على سياسة الخصوصية وشروط الاستخدام',
    ku: 'ڕەزامەندم لەسەر سیاسەتی تایبەتمەندی و مەرجەکانی بەکارهێنان',
  );
  String get staffOfficeEntry => _t(
    en: 'Staff & office login',
    ar: 'دخول الموظفين والمكاتب',
    ku: 'چوونەژوورەوەی کارمەند و ئۆفیس',
  );
  String get authSelectCountry =>
      _t(en: 'Select country', ar: 'اختر الدولة', ku: 'وڵات هەڵبژێرە');
  String get authOtpTitle =>
      _t(en: 'Login', ar: 'تسجيل الدخول', ku: 'چوونەژوورەوە');
  String authOtpSubtitle(String phone) => _t(
    en: 'A verification code was sent via SMS!',
    ar: 'تم إرسال رمز التحقق عبر SMS!',
    ku: 'کۆدی پشتڕاستکردنەوە بە SMS نێردرا!',
  );
  String get authVerifyContinue =>
      _t(en: 'Login', ar: 'تسجيل الدخول', ku: 'چوونەژوورەوە');
  String get authResendOtp =>
      _t(en: 'Send again', ar: 'أرسل مرة أخرى', ku: 'دووبارە بنێرە');
  String authResendIn(int seconds) => _t(
    en: 'Resend in ${seconds}s',
    ar: 'إعادة الإرسال خلال ${seconds} ث',
    ku: 'دووبارە ناردن لە ${seconds} چ',
  );
  String get authChangePhone =>
      _t(en: 'Change number', ar: 'تغيير الرقم', ku: 'گۆڕینی ژمارە');
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
  String get authLocationCardTitle =>
      _t(en: 'Nearby properties', ar: 'عقارات قريبة', ku: 'خانووبەرەی نزیک');
  String get authLocationCardDescription => _t(
    en: 'Your location helps us show relevant listings, map results, and distance-based search.',
    ar: 'موقعك يساعدنا في عرض الإعلانات المناسبة ونتائج الخريطة والبحث حسب المسافة.',
    ku: 'شوێنەکەت یارمەتیمان دەدات لیست و نەخشە و گەڕان بەپێی دووری پیشان بدەین.',
  );
  String get authAllowLocation =>
      _t(en: 'Allow location', ar: 'السماح بالموقع', ku: 'ڕێگەدان بە شوێن');
  String get authNotNow => _t(en: 'Not now', ar: 'ليس الآن', ku: 'ئێستا نا');
  String get authFaceTitle => _t(
    en: 'Get ready to complete face recognition',
    ar: 'استعد لإتمام ميزة التعرف على الوجه',
    ku: 'ئامادە بە بۆ تەواوکردنی ناسینەوەی ڕووخسار',
  );
  String get authFaceSubtitle => _t(
    en: 'Please place your face inside the frame and press the capture button.',
    ar: 'الرجاء وضع الوجه داخل إطار الصورة والضغط على زر الالتقاط',
    ku: 'تکایە ڕووخسارت بخەرە ناو چوارچێوەکە و دوگمەی وێنەگرتن لێبدە.',
  );
  String get authFaceCardTitle => _t(
    en: 'Face verification',
    ar: 'التحقق بالوجه',
    ku: 'پشتڕاستکردنەوەی ڕووخسار',
  );
  String get authFaceCardDescription => _t(
    en: 'Please place your face inside the frame and press the capture button.',
    ar: 'الرجاء وضع الوجه داخل إطار الصورة والضغط على زر الالتقاط',
    ku: 'تکایە ڕووخسارت بخەرە ناو چوارچێوەکە و دوگمەی وێنەگرتن لێبدە.',
  );
  String get authSetupFaceVerification =>
      _t(en: 'Start', ar: 'أبدأ', ku: 'دەستپێبکە');
  String get authSkipForNow =>
      _t(en: 'Skip for now', ar: 'تخطي الآن', ku: 'فعلاً بەجێبهێڵە');
  String get authLogoutConfirm => _t(
    en: 'Are you sure you want to logout?',
    ar: 'هل تريد تسجيل الخروج؟',
    ku: 'دڵنیایت دەتەوێت بچیتە دەرەوە؟',
  );

  // ─── Region Setup ─────────────────────────────────────────────────────────
  String get authRegionTitle =>
      _t(en: 'Choose your country', ar: 'اختر دولتك', ku: 'وڵاتەکەت هەڵبژێرە');
  String get authRegionSubtitle => _t(
    en: 'Select the country you want to browse properties in.',
    ar: 'اختر الدولة التي تريد استعراض العقارات فيها.',
    ku: 'ئەو وڵاتە هەڵبژێرە کە دەتەوێت خانووبەرەی تێدا ببینیت.',
  );
  String get authRegionCountry => _t(en: 'Country', ar: 'الدولة', ku: 'وڵات');
  String get authRegionLanguage => _t(en: 'Language', ar: 'اللغة', ku: 'زمان');
  String get authRegionCurrency => _t(en: 'Currency', ar: 'العملة', ku: 'دراو');
  String get authRegionConfirm =>
      _t(en: 'Continue', ar: 'متابعة', ku: 'بەردەوامبوون');
  String get authRegionDetectedHint => _t(
    en: 'You can change these anytime from Profile settings.',
    ar: 'يمكنك تغييرها في أي وقت من إعدادات الملف الشخصي.',
    ku: 'دەتوانیت لە هەر کاتێک لە ڕێکخستنەکانی پرۆفایل بیگۆڕیت.',
  );

  // ─── Profile Settings ─────────────────────────────────────────────────────
  String get settingsCountry => _t(en: 'Country', ar: 'الدولة', ku: 'وڵات');
  String get settingsCurrency => _t(en: 'Currency', ar: 'العملة', ku: 'دراو');
  String get settingsChangeCountry =>
      _t(en: 'Change country', ar: 'تغيير الدولة', ku: 'گۆڕینی وڵات');
  String get settingsChangeCurrency =>
      _t(en: 'Change currency', ar: 'تغيير العملة', ku: 'گۆڕینی دراو');
  String get activeCountryTitle =>
      _t(en: 'Active Country', ar: 'الدولة النشطة', ku: 'وڵاتی چالاک');
  String get switchMarketContext => _t(
    en: 'Switch your market context',
    ar: 'بدّل سياق السوق',
    ku: 'ناوچەی بازاڕ بگۆڕە',
  );
  String get mapType => _t(en: 'Map Type', ar: 'نوع الخريطة', ku: 'جۆری نەخشە');
  String get drawArea =>
      _t(en: 'Draw Area', ar: 'رسم منطقة', ku: 'کێشانی ناوچە');
  String get cancelDraw =>
      _t(en: 'Cancel Draw', ar: 'إلغاء الرسم', ku: 'هەڵوەشاندنەوەی کێشان');
  String areaLabel(String label, int count) => _t(
    en: 'Area: $label — $count properties',
    ar: 'منطقة: $label — $count عقار',
    ku: 'ناوچە: $label — $count خانووبەرە',
  );

  // ─── Search / Map extended ────────────────────────────────────────────────
  String get searchSaved =>
      _t(en: 'Search saved', ar: 'تم حفظ البحث', ku: 'گەڕان پاشەکەوت کرا');
  String get loadingProperties => _t(
    en: 'Loading properties...',
    ar: 'جاري تحميل العقارات...',
    ku: 'بارکردنی خانووبەرەکان...',
  );
  String get done => _t(en: 'Done', ar: 'تم', ku: 'تەواو');
  String get aiPicks =>
      _t(en: 'AI Picks', ar: 'توصيات الذكاء الاصطناعي', ku: 'پێشنیاری ئەی ئای');
  String get resetAll =>
      _t(en: 'Reset All', ar: 'إعادة تعيين', ku: 'ڕیسێتی هەموو');
  String get city => _t(en: 'City', ar: 'المدينة', ku: 'شار');
  String get savedSearchesTitle => _t(
    en: 'Saved Searches',
    ar: 'البحوث المحفوظة',
    ku: 'گەڕانە پاشەکەوتکراوەکان',
  );
  String savedCount(int count) =>
      _t(en: '$count saved', ar: '$count محفوظ', ku: '$count پاشەکەوتکراو');
  String get clearAll =>
      _t(en: 'Clear All', ar: 'مسح الكل', ku: 'سڕینەوەی هەموو');
  String get recent => _t(en: 'Recent', ar: 'السجل الأخير', ku: 'دوایین');
  String get savedTab => _t(en: 'Saved', ar: 'المحفوظة', ku: 'پاشەکەوتکراو');
  String get searchFilterHistory => _t(
    en: 'Search & Filter History',
    ar: 'سجل البحث والتصفية',
    ku: 'مێژووی گەڕان و فلتەر',
  );
  String resultsCount(int count) =>
      _t(en: '$count results', ar: '$count نتيجة', ku: '$count ئەنجام');
  String get mapTypeStandard => _t(en: 'Standard', ar: 'عادي', ku: 'ستاندارد');
  String get mapTypeSatellite =>
      _t(en: 'Satellite', ar: 'قمر صناعي', ku: 'مانگی دەستکرد');
  String get mapTypeTerrain => _t(en: 'Terrain', ar: 'تضاريس', ku: 'زەوی');
  String get mapTypeHybrid => _t(en: 'Hybrid', ar: 'هجين', ku: 'هایبرید');
  String timeAgoMinutes(int n) =>
      _t(en: '${n}m ago', ar: '$n دقيقة', ku: '$n خولەک لەمەوبەر');
  String timeAgoHours(int n) =>
      _t(en: '${n}h ago', ar: '$n ساعة', ku: '$n کاتژمێر لەمەوبەر');
  String timeAgoDays(int n) =>
      _t(en: '${n}d ago', ar: '$n يوم', ku: '$n ڕۆژ لەمەوبەر');

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

  String propertyTypeName(String key) {
    final normalized = key.trim().toLowerCase().replaceAll('-', '_');
    switch (normalized) {
      case 'apartment':
      case 'flat':
      case 'residential':
      case 'condo':
      case 'condominium':
        return apartment;
      case 'villa':
      case 'house':
      case 'detached':
        return villaType;
      case 'land':
      case 'plot':
        return land;
      case 'commercial':
      case 'office':
      case 'retail':
      case 'shop':
      case 'store':
        return commercial;
      case 'building':
      case 'multi_family':
      case 'multifamily':
        return buildingType;
      case 'agricultural':
      case 'farm':
        return agriculturalType;
      case 'sale':
        return forSale;
      case 'rent':
        return forRent;
      case 'mortgage':
        return mortgage;
      case 'investment':
        return investment;
      default:
        // Title-case English leftovers from legacy data
        if (RegExp(r'^[a-z_]+$').hasMatch(normalized)) return key;
        return key;
    }
  }

  String featureName(String key) {
    switch (key.toLowerCase()) {
      case 'furnished':
        return featureFurnished;
      case 'parking':
        return featureParking;
      case 'elevator':
        return featureElevator;
      case 'garden':
        return featureGarden;
      case 'pool':
        return featurePool;
      case 'generator':
        return featureGenerator;
      case 'balcony':
        return featureBalcony;
      case 'security':
        return featureSecurity;
      default:
        return key;
    }
  }

  String nearbyName(String key) {
    switch (key.toLowerCase()) {
      case 'schools':
        return nearbySchoolsFilter;
      case 'hospital':
        return nearbyHospital;
      case 'mall':
        return nearbyMall;
      case 'transit':
        return nearbyTransit;
      case 'mosque':
        return nearbyMosque;
      case 'park':
        return nearbyPark;
      default:
        return key;
    }
  }

  String get buildingType => _t(en: 'Building', ar: 'عمارة', ku: 'بینا');
  String get agriculturalType =>
      _t(en: 'Agricultural', ar: 'زراعي', ku: 'کشتوکاڵی');
  String get featureFurnished =>
      _t(en: 'Furnished', ar: 'مفروش', ku: 'ڕەختکراو');
  String get featureParking =>
      _t(en: 'Parking', ar: 'موقف سيارة', ku: 'پارکینگ');
  String get featureElevator => _t(en: 'Elevator', ar: 'مصعد', ku: 'ئەسانسۆر');
  String get featureGarden => _t(en: 'Garden', ar: 'حديقة', ku: 'باخچە');
  String get featurePool => _t(en: 'Pool', ar: 'مسبح', ku: 'مەلەوانگە');
  String get featureGenerator =>
      _t(en: 'Generator', ar: 'مولد', ku: 'جێنەرەیتەر');
  String get featureBalcony => _t(en: 'Balcony', ar: 'شرفة', ku: 'باڵکۆن');
  String get featureSecurity => _t(en: 'Security', ar: 'حراسة', ku: 'پاراستن');
  String get nearbySchoolsFilter =>
      _t(en: 'Schools', ar: 'مدارس', ku: 'قوتابخانە');
  String get nearbyHospital =>
      _t(en: 'Hospital', ar: 'مستشفى', ku: 'نەخۆشخانە');
  String get nearbyMall => _t(en: 'Mall', ar: 'مول', ku: 'مۆڵ');
  String get nearbyTransit => _t(en: 'Transit', ar: 'مواصلات', ku: 'گواستنەوە');
  String get nearbyMosque => _t(en: 'Mosque', ar: 'جامع', ku: 'مزگەوت');
  String get nearbyPark => _t(en: 'Park', ar: 'حديقة عامة', ku: 'پارک');
  String get allGovernorates =>
      _t(en: 'All governorates', ar: 'كل المحافظات', ku: 'هەموو پارێزگاکان');
  String get governorateLabel =>
      _t(en: 'Governorate', ar: 'المحافظة', ku: 'پارێزگا');
  String get searchHint => _t(
    en: 'Search: area, price, school, mall…',
    ar: 'ابحث: منطقة، سعر، مدرسة، مول…',
    ku: 'بگەڕێ: ناوچە، نرخ، قوتابخانە، مۆڵ…',
  );
  String get voiceListening =>
      _t(en: 'Listening…', ar: 'جاري الاستماع…', ku: 'گوێگرتن…');
  String get voiceNotAvailable => _t(
    en: 'Voice search is not available on this device.',
    ar: 'البحث الصوتي غير متاح على هذا الجهاز.',
    ku: 'گەڕانی دەنگی لەم ئامێرە بەردەست نییە.',
  );
  String get enterBarcodeManually =>
      _t(en: 'Enter barcode', ar: 'أدخل رمز العملية', ku: 'بارکۆد بنووسە');
  String get joinDeal =>
      _t(en: 'Join deal', ar: 'الانضمام للعملية', ku: 'بچۆ مامەڵە');
  String get txIdentityHint => _t(
    en: 'Confirm your identity with national ID and face verification.',
    ar: 'أكد هويتك بالبطاقة الوطنية والتحقق بالوجه.',
    ku: 'ناسنامەکەت بە کارتی نیشتمانی و ڕووخسار پشتڕاست بکەوە.',
  );
  String get txDocumentsHint => _t(
    en: 'Upload the documents requested by the lawyer for your side.',
    ar: 'ارفع المستمسكات التي يطلبها المحامي لطرفك.',
    ku: 'ئەو بەڵگەنامانە بار بکە کە پارێزەر داوای دەکات.',
  );
  String get txContractHint => _t(
    en: 'Download the sale contract PDF, upload the signed copy, then verify with OTP, face, and e-signature.',
    ar: 'حمّل عقد البيع PDF ثم ارفعه بعد التوقيع، ثم تحقق برمز OTP والوجه والتوقيع الإلكتروني.',
    ku: 'PDF ی گرێبەست دابەزێنە، پاشان بار بکە، دواتر OTP و ڕووخسار و واژۆ.',
  );
  String get txEscrowHint => _t(
    en: 'Deposit the required amount into Madar escrow at Bank of Baghdad. Funds release when the deed is issued in the buyer name — or, for agricultural homes, after move-in with buyer and lawyer approval.',
    ar: 'أودع المبلغ في حساب الضمان لدى مصرف بغداد. يُحوَّل المال عند صدور السند باسم المشتري — أو للزراعي بعد الانتقال بموافقة المشتري والمحامي.',
    ku: 'بڕە پارەکە لە حسابی مسۆگەری بانکی بەغدا دابنێ.',
  );
  String get txDeedHint => _t(
    en: 'Upload the ownership deed. Skipped for agricultural properties.',
    ar: 'ارفع سند الملكية. تُتخطى إذا كان العقار زراعياً.',
    ku: 'سەندی خاوەندارێتی بار بکە. بۆ کشتوکاڵی تێپەڕ دەبێت.',
  );
  String get txSettlementHint => _t(
    en: '1% correspondence fee from each party (2% total, editable by finance), 300,000 IQD from each party, taxes, then remainder to the seller with a full receipt.',
    ar: '1% مكاتبة من كل طرف (2% للمجموع، قابلة للتعديل من المالية) و300 ألف من كل طرف ثم الضرائب وباقي المبلغ للبائع مع وصل كامل.',
    ku: '1% لە هەر لایەک، 300 هەزار دینار لە هەر لایەک، باج، پاشان ماوەکە بۆ فرۆشیار.',
  );
  String get confirmIdentity => _t(
    en: 'Confirm identity',
    ar: 'تأكيد الهوية',
    ku: 'پشتڕاستکردنەوەی ناسنامە',
  );
  String get downloadContractPdf => _t(
    en: 'Download contract PDF',
    ar: 'تنزيل عقد البيع PDF',
    ku: 'PDF ی گرێبەست دابەزێنە',
  );
  String get uploadSignedContract => _t(
    en: 'Upload signed contract',
    ar: 'رفع العقد الموقع',
    ku: 'گرێبەستی واژۆکراو بار بکە',
  );
  String get verifyOtpFaceSign => _t(
    en: 'OTP, face, then sign',
    ar: 'رمز التحقق ثم الوجه ثم التوقيع',
    ku: 'OTP، ڕووخسار، واژۆ',
  );
  String get confirmDeposit => _t(
    en: 'Confirm I deposited',
    ar: 'أكدت الإيداع',
    ku: 'دانان پشتڕاست دەکەم',
  );
  String get uploadDeed =>
      _t(en: 'Upload deed', ar: 'رفع السند', ku: 'سەند بار بکە');
  String get viewReceipt =>
      _t(en: 'View receipt', ar: 'عرض الوصل', ku: 'پسوڵە ببینە');
  String get lawyersTeam =>
      _t(en: 'Lawyers team', ar: 'فريق المحامين', ku: 'تیمی پارێزەران');
  String get waitingForOtherPartyAction => _t(
    en: 'Waiting for the other party to complete this step.',
    ar: 'بانتظار إكمال الطرف الآخر لهذه الخطوة.',
    ku: 'چاوەڕێی لایەنی دیکە دەکەین.',
  );
  String get iAmBuyer =>
      _t(en: 'I am the buyer', ar: 'أنا المشتري', ku: 'من کڕیارم');
  String get iAmSeller =>
      _t(en: 'I am the seller', ar: 'أنا البائع', ku: 'من فرۆشیارم');
  String get enterOtpCode =>
      _t(en: 'Enter OTP', ar: 'أدخل رمز التحقق', ku: 'OTP بنووسە');
  String get verifyFaceCta =>
      _t(en: 'Verify face', ar: 'التحقق من الوجه', ku: 'ڕووخسار پشتڕاست بکە');
  String get drawSignature =>
      _t(en: 'Sign here', ar: 'وقّع هنا', ku: 'لێرە واژۆ بکە');
  String get sendSignature =>
      _t(en: 'Send signature', ar: 'إرسال التوقيع', ku: 'واژۆ بنێرە');
  String get nationalIdDoc =>
      _t(en: 'National ID', ar: 'البطاقة الوطنية', ku: 'کارتی نیشتمانی');
  String get proofOfFundsDoc => _t(
    en: 'Proof of funds',
    ar: 'إثبات مصدر المال',
    ku: 'سەلماندنی سەرچاوەی پارە',
  );
  String get propertyDeedDoc =>
      _t(en: 'Property deed', ar: 'سند المنزل', ku: 'سەندی خانوو');
  String get addRequiredDocument => _t(
    en: 'Add a required document',
    ar: 'إضافة مستمسك مطلوب',
    ku: 'بەڵگەنامەی پێویست زیاد بکە',
  );
  String get escrowBankBaghdad => _t(
    en: 'Madar escrow — Bank of Baghdad',
    ar: 'حساب الضمان — مصرف بغداد',
    ku: 'حسابی مسۆگەری — بانکی بەغدا',
  );
  String get depositAmountLabel =>
      _t(en: 'Amount to deposit', ar: 'المبلغ الواجب إيداعه', ku: 'بڕی دانان');
  String get correspondenceFeeLabel => _t(
    en: 'Correspondence fee (1% each party)',
    ar: 'رسوم المكاتبة (1% لكل طرف)',
    ku: 'کرێی نامەنووسی (1% هەر لایەک)',
  );
  String get stampFeeLabel => _t(
    en: 'Office fee 300,000 IQD each',
    ar: 'رسوم المكتب 300 ألف لكل طرف',
    ku: 'کرێی ئۆفیس 300 هەزار بۆ هەر لایەک',
  );
  String get remainderToSeller => _t(
    en: 'Remainder transferred to seller',
    ar: 'المتبقي يُحوَّل لحساب البائع',
    ku: 'ماوەکە دەگوازرێتەوە بۆ فرۆشیار',
  );
  String get furniturePartnerNotice => _t(
    en: 'Buyer and seller numbers plus property details are shared with furniture and moving partners after the contract is signed.',
    ar: 'بعد كتابة العقد تُشارك أرقام المشتري والبائع والعقار تلقائياً مع شركات التجميل العقاري ونقل الأثاث.',
    ku: 'دوای گرێبەست ژمارەکان لەگەڵ کۆمپانیای جوانکاری و گواستنەوە هاوبەش دەکرێن.',
  );
  String get simulateOtherParty => _t(
    en: 'Other party completed this step',
    ar: 'أكمل الطرف الآخر هذه الخطوة',
    ku: 'لایەنی دیکە ئەم هەنگاوەی تەواو کرد',
  );
  String get skipAgriculturalDeed => _t(
    en: 'Deed skipped for agricultural property',
    ar: 'تم تخطي سند الملكية لأن العقار زراعي',
    ku: 'سەند تێپەڕ کرا چونکە کشتوکاڵییە',
  );
  String get fundsReleaseNote => _t(
    en: 'Funds are released when the deed is issued in the buyer name. For agricultural homes, release after move-in with buyer approval and supervising lawyer confirmation.',
    ar: 'يُحوَّل المال عند صدور السند باسم المشتري. للعقار الزراعي: بعد انتقال المشتري بموافقته وتأكيد المحامي المشرف.',
    ku: 'پارەکە دوای سەند بە ناوی کڕیار دەردەچێت. بۆ کشتوکاڵی دوای گواستنەوە.',
  );
  String get barcodeHint => _t(
    en: 'Paste or type the deal barcode',
    ar: 'الصق أو اكتب باركود العملية',
    ku: 'بارکۆدی مامەڵە بنووسە',
  );
  String get lawyersTeamChat => _t(
    en: 'Open lawyers team chat',
    ar: 'فتح محادثة فريق المحامين',
    ku: 'چاتی تیمی پارێزەران بکەرەوە',
  );
  String get receiptIssued =>
      _t(en: 'Receipt issued', ar: 'تم إصدار الوصل', ku: 'پسوڵە دەرچوو');
  String get closeDeal => _t(
    en: 'Close deal successfully',
    ar: 'إغلاق العملية بنجاح',
    ku: 'مامەڵە دابخە',
  );

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
  String get madarUser =>
      _t(en: 'Madar User', ar: 'مستخدم مدار', ku: 'بەکارهێنەری مەدار');
  String get verificationSecurity => _t(
    en: 'Verification & Security',
    ar: 'التحقق والأمان',
    ku: 'پشتڕاستکردنەوە و پاراستن',
  );
  String get phoneNumberLabel =>
      _t(en: 'Phone Number', ar: 'رقم الهاتف', ku: 'ژمارەی تەلەفۆن');
  String get biometricVerification => _t(
    en: 'Biometric Verification',
    ar: 'التحقق البيومتري',
    ku: 'پشتڕاستکردنەوەی بایۆمەتری',
  );
  String get unverified =>
      _t(en: 'Unverified', ar: 'غير موثق', ku: 'پشتڕاستنەکراوە');
  String get changePhone => _t(
    en: 'Change Phone Number',
    ar: 'تغيير رقم الهاتف',
    ku: 'گۆڕینی ژمارەی تەلەفۆن',
  );
  String get notifications =>
      _t(en: 'Notifications', ar: 'الإشعارات', ku: 'ئاگاداریەکان');
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
  String get titleDeeds => _t(en: 'Title Deeds', ar: 'السندات', ku: 'سەندەکان');
  String get favorites => _t(en: 'Favorites', ar: 'المفضلة', ku: 'دڵخوازەکان');
  String get activeAccount =>
      _t(en: 'Active Account', ar: 'حساب نشط', ku: 'هەژماری چالاک');
  String get accountSuspended =>
      _t(en: 'Suspended', ar: 'موقوف', ku: 'هەڵواسراو');
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
  String get msgCustomerSupport =>
      _t(en: 'Customer Support', ar: 'خدمة العملاء', ku: 'پشتگیری کڕیار');
  String get msgSalesTeam =>
      _t(en: 'Sales Team', ar: 'فريق المبيعات', ku: 'تیمی فرۆشتن');
  String get msgClosingTeam => _t(
    en: 'Deal Closing Team',
    ar: 'فريق إغلاق الصفقات',
    ku: 'تیمی داخستنی مامەڵە',
  );
  String get msgAgentLawyer =>
      _t(en: 'Private agent', ar: 'الوكيل الخاص', ku: 'بریکاری تایبەت');
  String get msgAiSub => _t(
    en: 'Powered by AI',
    ar: 'مدعوم بالذكاء الاصطناعي',
    ku: 'پشتگیری لە ئەی ئای',
  );
  String get msgSupportSub =>
      _t(en: 'Available 24/7', ar: 'متاح 24/7', ku: 'بەردەستە 24/7');
  String get msgSalesSub => _t(
    en: 'Property inquiries',
    ar: 'للاستفسار عن العقارات',
    ku: 'پرسیار دەربارەی خانووبەرە',
  );
  String get msgClosingSub =>
      _t(en: 'Close your deals', ar: 'لإتمام صفقاتك', ku: 'مامەڵەکانت دابخە');
  String get msgAgentSub => _t(
    en: 'Send and receive deal barcodes only',
    ar: 'مخصص لاستقبال وإرسال الباركود فقط',
    ku: 'تەنها بۆ ناردن و وەرگرتنی بارکۆد',
  );
  String get voiceNote =>
      _t(en: 'Voice note', ar: 'رسالة صوتية', ku: 'نامەی دەنگی');
  String get recording =>
      _t(en: 'Recording…', ar: 'جاري التسجيل…', ku: 'تۆمارکردن…');
  String get videoLabel => _t(en: 'Video', ar: 'فيديو', ku: 'ڤیدیۆ');
  String get sendBarcode =>
      _t(en: 'Deal barcode', ar: 'باركود الصفقة', ku: 'بارکۆدی مامەڵە');
  String get callsComingSoon => _t(
    en: 'Calls will be available soon',
    ar: 'المكالمات ستكون متاحة قريباً',
    ku: 'پەیوەندییەکان بەم زووانە بەردەست دەبن',
  );
  String get tapToOpenChat => _t(
    en: 'Tap to open chat',
    ar: 'اضغط لفتح المحادثة',
    ku: 'بۆ کردنەوەی گفتوگۆ لێبدە',
  );
  String get agentInputHint => _t(
    en: 'Send a barcode image or code…',
    ar: 'أرسل صورة الباركود أو الرمز…',
    ku: 'وێنەی بارکۆد یان کۆد بنێرە…',
  );

  // ─── Deals / Transactions ───────────────────────────────────────────────────
  String get noActiveDeals => _t(
    en: 'No active deals',
    ar: 'لا توجد صفقات نشطة',
    ku: 'هیچ مامەڵەی چالاک نییە',
  );
  String get verifying =>
      _t(en: 'Verifying...', ar: 'جاري التحقق...', ku: 'پشتڕاستکردنەوە...');
  String get allDealsTitle =>
      _t(en: 'All Deals', ar: 'كل الصفقات', ku: 'هەموو مامەڵەکان');
  String get refresh => _t(en: 'Refresh', ar: 'تحديث', ku: 'نوێکردنەوە');
  String get scanBarcode =>
      _t(en: 'Scan Barcode', ar: 'مسح الباركود', ku: 'پێداچوونەوەی بارکۆد');
  String get barcodeScanTitle => _t(
    en: 'Scan deal code',
    ar: 'مسح رمز الصفقة',
    ku: 'سکانکردنی کۆدی مامەڵە',
  );
  String get barcodeScanSubtitle => _t(
    en: 'Get the barcode from the lawyer or real-estate office and scan it to start your deal.',
    ar: 'احصل على رمز الباركود من الوكيل أو المكتب العقاري وامسحه لبدء صفقتك',
    ku: 'بارکۆدەکە لە پارێزەر یان ئۆفیسی خانووبەرە وەربگرە و سکان بکە بۆ دەستپێکردنی مامەڵەکەت.',
  );
  String get barcodeUploadImage => _t(
    en: 'Upload barcode image',
    ar: 'رفع صورة الباركود',
    ku: 'وێنەی بارکۆد بار بکە',
  );
  String get barcodeHowItWorks =>
      _t(en: 'How it works', ar: 'كيف يعمل؟', ku: 'چۆن کار دەکات؟');
  String get barcodeHowStep1 => _t(
    en: 'The office or company lawyer generates a barcode for this deal.',
    ar: 'يولّد الوكيل/المكتب رمز باركود خاص بالصفقة',
    ku: 'ئۆفیس یان پارێزەر بارکۆدێک بۆ ئەم مامەڵەیە دروست دەکات.',
  );
  String get barcodeHowStep2 => _t(
    en: 'The code is sent to both parties in Madar.',
    ar: 'يرسل الرمز لكلا الطرفين عبر تطبيق مدار',
    ku: 'کۆدەکە بۆ هەردوو لایەن لە مەدار دەنێردرێت.',
  );
  String get barcodeHowStep3 => _t(
    en: 'Both parties upload the code to open the live deal.',
    ar: 'يرفع كلا الطرفين الرمز لبدء سلسلة الصفقة',
    ku: 'هەردوو لایەن کۆدەکە بار دەکەن بۆ کردنەوەی مامەڵەکە.',
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
  String get imageAttached =>
      _t(en: 'Image attached', ar: 'تم إرفاق صورة', ku: 'وێنە هاوپێچ کرا');
  String get noImage => _t(en: 'No image', ar: 'بدون صورة', ku: 'بێ وێنە');

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
  String propertyCountShort(int count) =>
      _t(en: '$count Properties', ar: '$count عقار', ku: '$count خانووبەرە');

  // ─── Property Intelligence Report ─────────────────────────────────────────
  String get propertyReport =>
      _t(en: 'Property Report', ar: 'تقرير العقار', ku: 'ڕاپۆرتی خانووبەرە');
  String get askAiAboutProperty => _t(
    en: 'Ask AI about this property',
    ar: 'اسأل الذكاء الاصطناعي عن هذا العقار',
    ku: 'لە ئەی ئای بپرسە دەربارەی ئەم خانووبەرەیە',
  );
  String get askAi => _t(en: 'Ask AI', ar: 'اسأل AI', ku: 'بپرسە لە AI');
  String get contactConnect =>
      _t(en: 'Contact Sales', ar: 'تواصل مع المبيعات', ku: 'پەیوەندی فرۆشتن');
  String get videoTour =>
      _t(en: 'Video Tour', ar: 'جولة فيديو', ku: 'گەشتی ڤیدیۆ');
  String get inPersonTour =>
      _t(en: 'In-person Tour', ar: 'زيارة حضورية', ku: 'سەردانی ڕاستەوخۆ');
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
  String get statusReserved => _t(en: 'Reserved', ar: 'محجوز', ku: 'پارێزراو');
  String get statusUnderReview =>
      _t(en: 'Under Review', ar: 'قيد المراجعة', ku: 'لە ژێر پێداچوونەوە');
  String get statusOffMarket =>
      _t(en: 'Off Market', ar: 'خارج السوق', ku: 'دەرەوەی بازاڕ');
  String get dataVerified => _t(en: 'Verified', ar: 'موثق', ku: 'پشتڕاستکراو');
  String get dataPublisherProvided =>
      _t(en: 'Publisher', ar: 'من الناشر', ku: 'لە بڵاوکەرەوە');
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
  String get tour3d =>
      _t(en: '3D Tour', ar: 'جولة ثلاثية الأبعاد', ku: 'گەشتی سێ ڕەهەندی');
  String get virtualTour =>
      _t(en: 'Virtual Tour', ar: 'جولة افتراضية', ku: 'گەشتی مەجازی');
  String get floorPlan => _t(en: 'Floor Plan', ar: 'المخطط', ku: 'نەخشەی نهۆم');
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
  String get publisher => _t(en: 'Publisher', ar: 'الناشر', ku: 'بڵاوکەرەوە');
  String get scheduleTourTitle =>
      _t(en: 'Schedule a Tour', ar: 'حجز جولة', ku: 'گەشتێک پلان بکە');
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
  String get ownershipContribution =>
      _t(en: 'Toward Ownership', ar: 'نحو التملك', ku: 'بەرەو خاوەنداری');
  String get remainingBalance =>
      _t(en: 'Remaining Balance', ar: 'الرصيد المتبقي', ku: 'باڵانسی ماوە');
  String get months => _t(en: 'months', ar: 'أشهر', ku: 'مانگ');
  String get savedProperty => _t(en: 'Saved', ar: 'محفوظ', ku: 'پاشەکەوتکرا');
  String get unsavedProperty => _t(en: 'Save', ar: 'حفظ', ku: 'پاشەکەوت');
  String get shareProperty => _t(en: 'Share', ar: 'مشاركة', ku: 'هاوبەشکردن');
  String get aiGroundedDisclaimer => _t(
    en: 'Answers are based only on available property data.',
    ar: 'الإجابات تعتمد فقط على بيانات العقار المتاحة.',
    ku: 'وەڵامەکان تەنها لەسەر داتای بەردەستی خانووبەرەن.',
  );
  String get locationHierarchy => _t(en: 'Location', ar: 'الموقع', ku: 'شوێن');
  String get mapSection => _t(en: 'Map', ar: 'الخريطة', ku: 'نەخشە');
  String get mapStreet => _t(en: 'Street', ar: 'شارع', ku: 'شەقام');
  String get mapSatellite =>
      _t(en: 'Satellite', ar: 'قمر صناعي', ku: 'مانگی دەستکرد');
  String get mapTerrain => _t(en: 'Terrain', ar: 'تضاريس', ku: 'ڕەق');
  String get yesLabel => _t(en: 'Yes', ar: 'نعم', ku: 'بەڵێ');
  String get noLabel => _t(en: 'No', ar: 'لا', ku: 'نەخێر');
  String get elevator => _t(en: 'Elevator', ar: 'مصعد', ku: 'ئاسانسۆر');
  String get furnished => _t(en: 'Furnished', ar: 'مفروش', ku: 'فەرشکراو');
  String get balcony => _t(en: 'Balcony', ar: 'شرفة', ku: 'باڵکۆن');
  String get garden => _t(en: 'Garden', ar: 'حديقة', ku: 'باخچە');
  String get pool => _t(en: 'Pool', ar: 'مسبح', ku: 'مەلەوانگە');

  // ─── Property report extended ─────────────────────────────────────────────
  String get moreDetails =>
      _t(en: 'More details', ar: 'المزيد من التفاصيل', ku: 'وردەکاری زیاتر');
  String get viewDetails =>
      _t(en: 'View report', ar: 'عرض التقرير', ku: 'بینینی ڕاپۆرت');
  String get propertyIdLabel =>
      _t(en: 'Property ID', ar: 'رقم العقار', ku: 'ژمارەی خانووبەرە');
  String get listingIdLabel =>
      _t(en: 'Listing ID', ar: 'رقم الإعلان', ku: 'ژمارەی ڕێکلام');
  String get dimensionsSection =>
      _t(en: 'Dimensions', ar: 'الأبعاد', ku: 'قەبارەکان');
  String get constructionSection => _t(
    en: 'Construction',
    ar: 'معلومات البناء',
    ku: 'زانیاری دروستکردن',
  );
  String get builderSection => _t(
    en: 'Builder & Developer',
    ar: 'المقاول والمطور',
    ku: 'بیناس و گەشەپێدەر',
  );
  String get listingInfoSection => _t(
    en: 'Listing Information',
    ar: 'معلومات الإعلان',
    ku: 'زانیاری ڕێکلام',
  );
  String get verificationSection => _t(
    en: 'Verification',
    ar: 'التحقق',
    ku: 'پشتڕاستکردنەوە',
  );
  String get marketAnalyticsSection => _t(
    en: 'Market Analytics',
    ar: 'تحليلات السوق',
    ku: 'شیکاری بازاڕ',
  );
  String get locationIntelligence => _t(
    en: 'Location Intelligence',
    ar: 'ذكاء الموقع',
    ku: 'زیرەکی شوێن',
  );
  String get reportOverview => _t(
    en: 'Property Overview',
    ar: 'نظرة عامة',
    ku: 'پێشبینی گشتی',
  );
  String get compareProperty => _t(
    en: 'Compare',
    ar: 'مقارنة',
    ku: 'بەراورد',
  );
  String get informationUnavailable => _t(
    en: 'Information unavailable',
    ar: 'المعلومات غير متوفرة',
    ku: 'زانیاری بەردەست نییە',
  );
  String get favoriteAdded => _t(
    en: 'Added to favorites',
    ar: 'تمت الإضافة إلى المفضلة',
    ku: 'زیادکرا بۆ دڵخوازەکان',
  );
  String get favoriteRemoved => _t(
    en: 'Removed from favorites',
    ar: 'تمت الإزالة من المفضلة',
    ku: 'لابرا لە دڵخوازەکان',
  );
  String get livingRoom =>
      _t(en: 'Living Room', ar: 'الصالة', ku: 'ژووری دانیشتن');
  String get propertyAreaShort =>
      _t(en: 'Area', ar: 'المساحة', ku: 'ڕووبەر');
  String get kitchen => _t(en: 'Kitchen', ar: 'المطبخ', ku: 'چێشتخانە');
  String get bedroom => _t(en: 'Bedroom', ar: 'غرفة نوم', ku: 'ژووری نوستن');
  String get masterBedroom =>
      _t(en: 'Master Bedroom', ar: 'غرفة النوم الرئيسية', ku: 'ژووری سەرەکی');
  String get garage => _t(en: 'Garage', ar: 'كراج', ku: 'گاراج');
  String get roof => _t(en: 'Roof', ar: 'السطح', ku: 'سەقف');
  String get viewLabel => _t(en: 'View', ar: 'الإطلالة', ku: 'دیمەن');
  String get street => _t(en: 'Street', ar: 'الشارع', ku: 'شەقام');
  String get commercialArea =>
      _t(en: 'Commercial Area', ar: 'منطقة تجارية', ku: 'ناوچەی بازرگانی');
  String get renovationBefore =>
      _t(en: 'Before Renovation', ar: 'قبل التجديد', ku: 'پێش نوێکردنەوە');
  String get renovationAfter =>
      _t(en: 'After Renovation', ar: 'بعد التجديد', ku: 'دوای نوێکردنەوە');
  String get otherLabel => _t(en: 'Other', ar: 'أخرى', ku: 'هیتر');
  String get entrance =>
      _t(en: 'Entrance', ar: 'المدخل', ku: 'دەرگا');
  String get landLength =>
      _t(en: 'Land Length', ar: 'طول الأرض', ku: 'درێژی زەوی');
  String get landWidth =>
      _t(en: 'Land Width', ar: 'عرض الأرض', ku: 'پانی زەوی');
  String get buildingLength =>
      _t(en: 'Building Length', ar: 'طول المبنى', ku: 'درێژی بینا');
  String get buildingWidth =>
      _t(en: 'Building Width', ar: 'عرض المبنى', ku: 'پانی بینا');
  String get frontage =>
      _t(en: 'Frontage', ar: 'واجهة الشارع', ku: 'ڕووی شەقام');
  String get rearWidth =>
      _t(en: 'Rear Width', ar: 'عرض الخلف', ku: 'پانی پشتەوە');
  String get sideLength =>
      _t(en: 'Side Length', ar: 'طول الجانب', ku: 'درێژی لateral');
  String get streetWidth =>
      _t(en: 'Street Width', ar: 'عرض الشارع', ku: 'پانی شەقام');
  String get setback =>
      _t(en: 'Setback', ar: 'ارتداد', ku: 'دوورکەوتن');
  String get buildingHeight =>
      _t(en: 'Building Height', ar: 'ارتفاع المبنى', ku: 'بەرزی بینا');
  String get ceilingHeight =>
      _t(en: 'Ceiling Height', ar: 'ارتفاع السقف', ku: 'بەرزی سقف');
  String get roomArea =>
      _t(en: 'Room Area', ar: 'مساحة الغرفة', ku: 'ڕووبەری ژوور');
  String get latitudeLabel =>
      _t(en: 'Latitude', ar: 'خط العرض', ku: 'پانی');
  String get longitudeLabel =>
      _t(en: 'Longitude', ar: 'خط الطول', ku: 'درێژی');
  String get elevationLabel =>
      _t(en: 'Elevation', ar: 'الارتفاع', ku: 'بەرزی');
  String get provinceLabel =>
      _t(en: 'Province', ar: 'المحافظة', ku: 'پارێزگا');
  String get propertyVerifiedLabel => _t(
    en: 'Property Verified',
    ar: 'العقار موثق',
    ku: 'خانووبەرە پشتڕاستکراوە',
  );
  String get locationVerifiedLabel => _t(
    en: 'Location Verified',
    ar: 'الموقع موثق',
    ku: 'شوێن پشتڕاستکراوە',
  );
  String get informationVerifiedLabel => _t(
    en: 'Information Verified',
    ar: 'المعلومات موثقة',
    ku: 'زانیاری پشتڕاستکراوە',
  );
  String get documentsVerifiedLabel => _t(
    en: 'Documents Verified',
    ar: 'المستندات موثقة',
    ku: 'بەڵگە پشتڕاستکراوە',
  );
  String get photosVerifiedLabel => _t(
    en: 'Photos Verified',
    ar: 'الصور موثقة',
    ku: 'وێنەکان پشتڕاستکراون',
  );
  String get viewsLabel => _t(en: 'Views', ar: 'المشاهدات', ku: 'بینین');
  String get savesLabel => _t(en: 'Saves', ar: 'الحفظ', ku: 'پاشەکەوت');
  String get sharesLabel => _t(en: 'Shares', ar: 'المشاركات', ku: 'هاوبەشکردن');
  String get publishedDateLabel =>
      _t(en: 'Published', ar: 'تاريخ النشر', ku: 'بڵاوکراوەتەوە');
  String get grossRentalYield => _t(
    en: 'Gross Rental Yield',
    ar: 'العائد الإيجاري الإجمالي',
    ku: 'داهاتی کرێی گشتی',
  );
  String get rentalYieldLabel =>
      _t(en: 'Rental Yield', ar: 'العائد الإيجاري', ku: 'داهاتی کرێ');
  String get monthlyRentLabel =>
      _t(en: 'Monthly Rent', ar: 'الإيجار الشهري', ku: 'کرێی مانگانە');
  String get annualRentLabel =>
      _t(en: 'Annual Rent', ar: 'الإيجار السنوي', ku: 'کرێی ساڵانە');
  String get roiLabel => _t(en: 'ROI', ar: 'العائد على الاستثمار', ku: 'ROI');
  String get compareComingSoon => _t(
    en: 'Property comparison will be available soon.',
    ar: 'مقارنة العقارات ستتوفر قريباً.',
    ku: 'بەراوردکردنی خانووبەرە بەم زووانە بەردەست دەبێت.',
  );
  String get linkCopied => _t(
    en: 'Link copied',
    ar: 'تم نسخ الرابط',
    ku: 'بەستەر کۆپی کرا',
  );
  String get companyNameLabel =>
      _t(en: 'Company', ar: 'الشركة', ku: 'کۆمپانیا');
  String get contractorLabel =>
      _t(en: 'Contractor', ar: 'المقاول', ku: 'بیناس');
  String get architectLabel =>
      _t(en: 'Architect', ar: 'المهندس المعماري', ku: 'ئەندازیاری بیناسازی');
  String get developerLabel =>
      _t(en: 'Developer', ar: 'المطور', ku: 'گەشەپێدەر');
  String get projectNameLabel =>
      _t(en: 'Project', ar: 'المشروع', ku: 'پڕۆژە');
  String get constructionStatusLabel => _t(
    en: 'Construction Status',
    ar: 'حالة البناء',
    ku: 'دۆخی دروستکردن',
  );
  String get structureTypeLabel =>
      _t(en: 'Structure Type', ar: 'نوع الهيكل', ku: 'جۆری پێکهاتە');
  String get foundationTypeLabel =>
      _t(en: 'Foundation', ar: 'الأساس', ku: 'بناغە');
  String get roofTypeLabel =>
      _t(en: 'Roof Type', ar: 'نوع السقف', ku: 'جۆری سەقف');
  String get materialLabel =>
      _t(en: 'Material', ar: 'المادة', ku: 'ماددە');
  String get lastMaintenanceLabel => _t(
    en: 'Last Maintenance',
    ar: 'آخر صيانة',
    ku: 'دوایین چاککردنەوە',
  );
  String get lastRenovationLabel => _t(
    en: 'Last Renovation',
    ar: 'آخر تجديد',
    ku: 'دوایین نوێکردنەوە',
  );
  String get averagePriceArea => _t(
    en: 'Average Price in Area',
    ar: 'متوسط السعر في المنطقة',
    ku: 'ناوەندی نرخ لە ناوچە',
  );
  String get daysOnMarketLabel =>
      _t(en: 'Days on Market', ar: 'أيام في السوق', ku: 'ڕۆژ لە بازاڕ');
  String get demandLabel => _t(en: 'Demand', ar: 'الطلب', ku: 'داواکاری');
  String get priceTrendLabel =>
      _t(en: 'Price Trend', ar: 'اتجاه السعر', ku: 'ڕەوتی نرخ');
  String get floodRiskLabel =>
      _t(en: 'Flood Risk', ar: 'خطر الفيضان', ku: 'مەترسی لافتن');
  String get heatRiskLabel =>
      _t(en: 'Heat Risk', ar: 'خطر الحرارة', ku: 'مەترسی گەرمی');
  String get wildfireRiskLabel =>
      _t(en: 'Wildfire Risk', ar: 'خطر الحرائق', ku: 'مەترسی ئاگر');
  String get waterRiskLabel =>
      _t(en: 'Water Risk', ar: 'خطر المياه', ku: 'مەترسی ئاو');
  String get scheduleVisit =>
      _t(en: 'Schedule a Visit', ar: 'حجز زيارة', ku: 'سەردان پلان بکە');
  String get contactSalesTeam => _t(
    en: 'Contact Sales Team',
    ar: 'تواصل مع فريق المبيعات',
    ku: 'پەیوەندی بە تیمی فرۆشتن',
  );
  String get engineeringOfficeLabel => _t(
    en: 'Engineering Office',
    ar: 'المكتب الهندسي',
    ku: 'ئۆفیسی ئەندازیاری',
  );
  String get districtLabel =>
      _t(en: 'District', ar: 'المنطقة', ku: 'ناوچە');
  String get propertyCount =>
      _t(en: 'Listings', ar: 'الإعلانات', ku: 'ڕێکلامەکان');

  // ─── Edit Profile / Messages / Profile copy ───────────────────────────────
  String get editProfileTitle =>
      _t(en: 'Edit Profile', ar: 'تعديل الملف الشخصي', ku: 'دەستکاری پرۆفایل');
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
  String get emailAddress =>
      _t(en: 'Email Address', ar: 'البريد الإلكتروني', ku: 'ناونیشانی ئیمەیل');
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
  String get currentLocation =>
      _t(en: 'Current Location', ar: 'الموقع الحالي', ku: 'شوێنی ئێستا');
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
  String get markAllRead =>
      _t(en: 'Mark all read', ar: 'قراءة الكل', ku: 'هەموو بخوێنەوە');
  String unreadCountLabel(int n) => _t(
    en: '$n unread notifications',
    ar: '$n إشعارات غير مقروءة',
    ku: '$n ئاگاداری نەخوێندراوە',
  );
  String get noNotificationsYet =>
      _t(en: 'No notifications', ar: 'لا توجد إشعارات', ku: 'ئاگاداری نییە');
  String minutesAgo(int m) =>
      _t(en: '${m}m ago', ar: 'منذ ${m}د', ku: '$m خولەک پێش ئێستا');
  String hoursAgo(int h) =>
      _t(en: '${h}h ago', ar: 'منذ ${h}س', ku: '$h کاتژمێر پێش ئێستا');
  String daysAgo(int d) =>
      _t(en: '${d}d ago', ar: 'منذ ${d}ي', ku: '$d ڕۆژ پێش ئێستا');
  String get locationPermissionDenied => _t(
    en: 'Location permission denied',
    ar: 'لم يتم منح إذن الموقع',
    ku: 'مۆڵەتی شوێن ڕەتکرایەوە',
  );
  String get askAboutPropertyOrDeal => _t(
    en: 'Ask me about any property or deal',
    ar: 'اسألني عن أي عقار أو صفقة',
    ku: 'لێم بپرسە دەربارەی هەر خانووبەرە یان مامەڵەیەک',
  );
  String startConversationWith(String name) => _t(
    en: 'Start a conversation with $name',
    ar: 'ابدأ محادثة مع $name',
    ku: 'گفتوگۆ دەست پێبکە لەگەڵ $name',
  );
  String get findApartmentInBaghdad => _t(
    en: 'Find an apartment in Baghdad',
    ar: 'ابحث عن شقة في بغداد',
    ku: 'بگەڕێ بۆ شوقەیەک لە بەغدا',
  );
  String get whatArePropertyPrices => _t(
    en: 'What are property prices?',
    ar: 'ما هي أسعار العقارات؟',
    ku: 'نرخی خانووبەرەکان چین؟',
  );
  String get filterPrices => _t(en: 'Prices', ar: 'الأسعار', ku: 'نرخەکان');
  String get filterTransactions =>
      _t(en: 'Transactions', ar: 'الصفقات', ku: 'مامەڵەکان');
  String get filterAi => _t(en: 'AI', ar: 'الذكاء الاصطناعي', ku: 'ئەی ئای');
  String get genericErrorOccurred =>
      _t(en: 'An error occurred', ar: 'حدث خطأ', ku: 'هەڵەیەک ڕوویدا');

  // ─── Property AI Translation ──────────────────────────────────────────────
  String get languageArabic => _t(en: 'Arabic', ar: 'العربية', ku: 'عەرەبی');
  String get languageEnglish =>
      _t(en: 'English', ar: 'الإنجليزية', ku: 'ئینگلیزی');
  String get languageKurdish => _t(en: 'Kurdish', ar: 'الكردية', ku: 'کوردی');
  String propertyWrittenIn(String languageName) => _t(
    en: 'Property information is in $languageName',
    ar: 'معلومات العقار مكتوبة بـ$languageName',
    ku: 'زانیاری خانووبەرە بە $languageName نووسراوە',
  );
  String translateTo(String languageName) => _t(
    en: 'Translate to $languageName',
    ar: 'ترجمة إلى $languageName',
    ku: 'وەرگێڕان بۆ $languageName',
  );
  String get translatingPropertyInfo => _t(
    en: 'Translating property information...',
    ar: 'جاري ترجمة معلومات العقار...',
    ku: 'زانیاری خانووبەرە وەردەگێڕدرێت...',
  );
  String get originalContent => _t(en: 'Original', ar: 'الأصل', ku: 'ڕەسەن');
  String get translatedContent =>
      _t(en: 'Translated', ar: 'المترجم', ku: 'وەرگێڕدراو');
  String get aiGeneratedTranslation => _t(
    en: 'AI-generated translation',
    ar: 'ترجمة مولدة بالذكاء الاصطناعي',
    ku: 'وەرگێڕانی دروستکراو بە ئەی ئای',
  );
  String get translationFailed => _t(
    en: 'Translation unavailable right now',
    ar: 'الترجمة غير متاحة حالياً',
    ku: 'وەرگێڕان ئێستا بەردەست نییە',
  );
  String get translateEntireProperty => _t(
    en: 'Translate entire property',
    ar: 'ترجمة العقار بالكامل',
    ku: 'وەرگێڕانی تەواوی خانووبەرە',
  );

  // ─── Digital Transaction Center ───────────────────────────────────────────
  String get digitalTransactionCenter => _t(
    en: 'Transaction Center',
    ar: 'مركز العمليات',
    ku: 'ناوەندی مامەڵەکان',
  );
  String get txTabActive => _t(en: 'Active', ar: 'نشطة', ku: 'چالاک');
  String get txTabCompleted =>
      _t(en: 'Completed', ar: 'مكتملة', ku: 'تەواوکراو');
  String get txTabCancelled =>
      _t(en: 'Cancelled', ar: 'ملغاة', ku: 'هەڵوەشێنراو');
  String get txTabOnHold => _t(en: 'On Hold', ar: 'معلقة', ku: 'ڕاگیراو');
  String get uploadTransactionBarcode => _t(
    en: 'Upload transaction barcode',
    ar: 'رفع رمز العملية',
    ku: 'بارکۆدی مامەڵە بار بکە',
  );
  String get noTransactionsInTab => _t(
    en: 'No transactions here yet. Upload a barcode from your Company Lawyer to join a deal.',
    ar: 'لا توجد عمليات هنا بعد. ارفع رمز العملية من محامي الشركة للانضمام.',
    ku: 'هێشتا مامەڵە لێرە نییە. بارکۆد لە پارێزەری کۆمپانیا بار بکە.',
  );
  String get barcodeNotFound => _t(
    en: 'Barcode not found',
    ar: 'الرمز غير موجود',
    ku: 'بارکۆد نەدۆزرایەوە',
  );
  String get barcodeRedeemFailed => _t(
    en: 'Could not verify barcode',
    ar: 'تعذر التحقق من الرمز',
    ku: 'نەتوانرا بارکۆد پشتڕاست بکرێتەوە',
  );
  String get bothPartiesVerified => _t(
    en: 'Both parties verified — transaction activated',
    ar: 'تم التحقق من الطرفين — تم تفعيل العملية',
    ku: 'هەردوو لایەن پشتڕاستکرانەوە — مامەڵە چالاک کرا',
  );
  String get waitingForOtherParty => _t(
    en: 'Waiting for the other party to upload the barcode',
    ar: 'بانتظار رفع الطرف الآخر لرمز العملية',
    ku: 'چاوەڕوانی لایەنی دیکە بۆ بارکردنی بارکۆد',
  );
  String barcodeProgress(int count) => _t(
    en: '$count/2 participants verified',
    ar: '$count/2 أطراف تم التحقق منهم',
    ku: '$count/2 بەشدار پشتڕاستکراونەوە',
  );
  String get selectYourRole => _t(
    en: 'Are you the buyer or the seller?',
    ar: 'هل أنت المشتري أم البائع؟',
    ku: 'تۆ کڕیاریت یان فرۆشیار؟',
  );
  String get roleBuyer => _t(en: 'Buyer', ar: 'المشتري', ku: 'کڕیار');
  String get roleSeller => _t(en: 'Seller', ar: 'البائع', ku: 'فرۆشیار');
  String get txCurrentStep =>
      _t(en: 'Current step', ar: 'المرحلة الحالية', ku: 'هەنگاوی ئێستا');
  String get txProgress => _t(en: 'Progress', ar: 'التقدم', ku: 'پێشکەوتن');
  String get txAuditTimeline => _t(en: 'Activity', ar: 'النشاط', ku: 'چالاکی');
  String get txNoAuditYet => _t(
    en: 'No activity recorded yet',
    ar: 'لا يوجد نشاط مسجل بعد',
    ku: 'هێشتا چالاکی تۆمار نەکراوە',
  );
  String get txBackendEnforcedNote => _t(
    en: 'Stage advances are enforced by the system after required checks — not by UI buttons alone.',
    ar: 'انتقال المراحل يتم من النظام بعد التحقق — وليس عبر الأزرار فقط.',
    ku: 'گواستنەوەی قۆناغەکان لەلایەن سیستەمەوە دوای پشکنین جێبەجێ دەکرێت.',
  );
  String get transactionNotFound => _t(
    en: 'Transaction not found',
    ar: 'العملية غير موجودة',
    ku: 'مامەڵە نەدۆزرایەوە',
  );
  String get stepIdentity =>
      _t(en: 'Identity', ar: 'التحقق من الهوية', ku: 'ناسنامە');
  String get stepDocuments =>
      _t(en: 'Documents', ar: 'المستمسكات', ku: 'بەڵگەنامەکان');
  String get stepContract => _t(en: 'Contract', ar: 'عقد البيع', ku: 'گرێبەست');
  String get stepEscrow =>
      _t(en: 'Escrow deposit', ar: 'الإيداع الضماني', ku: 'پارەدانەی دڵنیایی');
  String get stepDeed =>
      _t(en: 'Ownership deed', ar: 'سند الملكية', ku: 'سەندی خاوەنداری');
  String get stepAgriculturalTransfer => _t(
    en: 'Agricultural transfer',
    ar: 'نقل زراعي خاص',
    ku: 'گواستنەوەی کشتوکاڵی',
  );
  String get stepSettlement =>
      _t(en: 'Settlement', ar: 'التسوية', ku: 'یەکلاکردنەوە');
  String get awaitingDepositConfirmation => _t(
    en: 'Awaiting deposit confirmation',
    ar: 'بانتظار تأكيد الإيداع',
    ku: 'چاوەڕوانی پشتڕاستکردنەوەی پارەدان',
  );
  String get transactionCompleted => _t(
    en: 'Transaction completed successfully',
    ar: 'اكتملت العملية بنجاح',
    ku: 'مامەڵە بە سەرکەوتوویی تەواو بوو',
  );
  String get companyLawyerLabel =>
      _t(en: 'Company Lawyer', ar: 'محامي الشركة', ku: 'پارێزەری کۆمپانیا');

  // ─── Office Portal ────────────────────────────────────────────────────────
  String get partnerEntryPrompt => _t(
    en: 'Partner or team member?',
    ar: 'هل أنت من شركائنا أو فريق العمل؟',
    ku: 'هاوبەش یان ئەندامی تیمیت؟',
  );
  String get officeEntryCta =>
      _t(en: 'Office login', ar: 'دخول المكاتب', ku: 'چوونەژوورەوەی ئۆفیس');
  String get employeeEntryCta =>
      _t(en: 'Staff login', ar: 'دخول الموظفين', ku: 'چوونەژوورەوەی کارمەند');
  String get officeWelcome => _t(
    en: 'Welcome to Madar Offices',
    ar: 'أهلاً بك في مكاتب مدار',
    ku: 'بەخێربێیت بۆ ئۆفیسەکانی مەدار',
  );
  String get officeLoginTitle =>
      _t(en: 'Office login', ar: 'تسجيل المكتب', ku: 'چوونەژوورەوەی ئۆفیس');
  String get officeLoginSubtitle => _t(
    en: 'Sign in with your office code and secret to manage listings.',
    ar: 'سجّل الدخول برمز المكتب والرمز السري لإدارة العقارات.',
    ku: 'بە کۆدی ئۆفیس و نهێنی بچۆ ژوورەوە بۆ بەڕێوەبردنی لیستەکان.',
  );
  String get officeCodeLabel =>
      _t(en: 'Office Code', ar: 'رمز المكتب', ku: 'کۆدی ئۆفیس');
  String get officeCodeHint =>
      _t(en: 'e.g. NHR-001', ar: 'مثال: NHR-001', ku: 'نموونە: NHR-001');
  String get officeSecretLabel =>
      _t(en: 'Password', ar: 'الرمز السري', ku: 'وشەی نهێنی');
  String get officeSecretHint => _t(
    en: 'Enter secret code',
    ar: 'أدخل الرمز السري',
    ku: 'کۆدی نهێنی بنووسە',
  );
  String get officeSignIn => _t(en: 'Enter', ar: 'دخول', ku: 'چوونەژوورەوە');
  String get officeForgotCredentials => _t(
    en: 'Forgot credentials?',
    ar: 'نسيت بيانات الدخول؟',
    ku: 'زانیاریەکانت لەبیرچوو؟',
  );
  String get officeForgotCredentialsHint => _t(
    en: 'Contact Office Management to reset credentials.',
    ar: 'تواصل مع إدارة المكاتب لإعادة تعيين البيانات.',
    ku: 'پەیوەندی بە بەڕێوەبردنی ئۆفیس بکە بۆ نوێکردنەوە.',
  );
  String get officeBackToUserLogin => _t(
    en: 'Back to user login',
    ar: 'العودة لتسجيل دخول المستخدم',
    ku: 'گەڕانەوە بۆ چوونەژوورەوەی بەکارهێنەر',
  );
  String get officeLoginInvalid => _t(
    en: 'Invalid office code or secret.',
    ar: 'رمز المكتب أو الرمز السري غير صحيح.',
    ku: 'کۆدی ئۆفیس یان نهێنی هەڵەیە.',
  );
  String get officeLoginRateLimited => _t(
    en: 'Too many attempts. Try again later.',
    ar: 'محاولات كثيرة. حاول لاحقاً.',
    ku: 'هەوڵی زۆر. دواتر هەوڵ بدەوە.',
  );
  String get officeLoginUnavailable => _t(
    en: 'Login unavailable. Check connection.',
    ar: 'تسجيل الدخول غير متاح. تحقق من الاتصال.',
    ku: 'چوونەژوورەوە بەردەست نییە. پەیوەندی بپشکنە.',
  );
  String get employeePortalTitle =>
      _t(en: 'Staff Portal', ar: 'بوابة الموظفين', ku: 'دەروازەی کارمەندان');
  String get employeePortalSubtitle => _t(
    en: 'Company staff access will be configured separately.',
    ar: 'صلاحيات الموظفين ستُحدد بشكل مستقل لاحقاً.',
    ku: 'دەسەڵاتی کارمەندان دواتر بە جیا ڕێکدەخرێت.',
  );
  String get employeePortalBody => _t(
    en: 'This entry is reserved for Madar employees (lawyers, finance, operations). The staff domain is not available yet.',
    ar: 'هذه النقطة مخصصة لموظفي مدار (المحامون، المالية، العمليات). نظام الموظفين غير متاح بعد.',
    ku: 'ئەم خاڵە بۆ کارمەندانی مەدارە. سیستەمی کارمەندان هێشتا ئامادە نییە.',
  );
  String get officeNavHome => _t(en: 'Home', ar: 'الرئيسية', ku: 'سەرەکی');
  String get officeNavProperties =>
      _t(en: 'Properties', ar: 'العقارات', ku: 'موڵکەکان');
  String get officeNavTransactions =>
      _t(en: 'Deals', ar: 'العمليات', ku: 'مامەڵەکان');
  String get officeNavLeads => _t(en: 'Leads', ar: 'الفرص', ku: 'دەرفەتەکان');
  String get officeNavConversations =>
      _t(en: 'Chats', ar: 'المحادثات', ku: 'گفتوگۆکان');
  String get officeNavMore => _t(en: 'More', ar: 'المزيد', ku: 'زیاتر');
  String get officeSearchHint => _t(
    en: 'Search by area, price, schools, features…',
    ar: 'ابحث بالمنطقة أو السعر أو المدارس أو المواصفات…',
    ku: 'گەڕان بە ناوچە، نرخ، قوتابخانە، تایبەتمەندی…',
  );
  String get officeAiAssistantTitle => _t(
    en: 'Madar AI for Offices',
    ar: 'مدار AI للمكاتب',
    ku: 'مەدار AI بۆ ئۆفیسەکان',
  );
  String get officeAiSearchHint => _t(
    en: 'Describe the client need (budget, district, schools…)',
    ar: 'صف احتياج العميل (ميزانية، حي، مدارس…)',
    ku: 'پێداویستی کڕیار بنووسە (بودجە، ناوچە، قوتابخانە…)',
  );
  String get officeAiPinnedSubtitle => _t(
    en: 'Faster inventory search with suggestion cards',
    ar: 'بحث أسرع في المخزون مع بطاقات اقتراح',
    ku: 'گەڕانی خێراتر لە کۆگا لەگەڵ کارتی پێشنیار',
  );
  String get officeShowOnMap =>
      _t(en: 'Show on map', ar: 'عرض على الخريطة', ku: 'پیشاندان لەسەر نەخشە');
  String get officeAiFabLabel =>
      _t(en: 'AI search', ar: 'بحث ذكي', ku: 'گەڕانی زیر');
  String get officeFilterAll => _t(en: 'All', ar: 'الكل', ku: 'هەموو');
  String get officeFilterSale => _t(en: 'Sale', ar: 'بيع', ku: 'فرۆشتن');
  String get officeFilterRent => _t(en: 'Rent', ar: 'إيجار', ku: 'کرێ');
  String get officeFilterMortgage => _t(en: 'Mortgage', ar: 'رهن', ku: 'ڕەهن');
  String get officeSalesThisMonth => _t(
    en: 'Sales this month',
    ar: 'مبيعات هذا الشهر',
    ku: 'فرۆشتنی ئەم مانگە',
  );
  String get officeStatTotal => _t(en: 'Total', ar: 'الإجمالي', ku: 'کۆ');
  String get officeStatCompleted =>
      _t(en: 'Completed', ar: 'مكتملة', ku: 'تەواو');
  String get officeStatInProgress =>
      _t(en: 'In progress', ar: 'قيد التنفيذ', ku: 'لە جێبەجێکردن');
  String get officeStatAwaiting =>
      _t(en: 'Awaiting', ar: 'بانتظار الأطراف', ku: 'چاوەڕوان');
  String get officeFoundBuyerCta => _t(
    en: 'I found a buyer',
    ar: 'وجدت مشتريًا لهذا العقار',
    ku: 'کڕیارم بۆ ئەم موڵکە دۆزیەوە',
  );
  String get officeFoundBuyerDefaultMessage => _t(
    en: 'I have a buyer interested in this property.',
    ar: 'لدي مشتري مهتم بهذا العقار.',
    ku: 'کڕیارێکم هەیە گرنگی بەم موڵکە دەدات.',
  );
  String get officeViewProperty =>
      _t(en: 'View property', ar: 'عرض العقار', ku: 'بینینی موڵک');
  String get officeLabel => _t(en: 'Office', ar: 'المكتب', ku: 'ئۆفیس');
  String get officeReportProperty => _t(
    en: 'Report a property',
    ar: 'إبلاغ عن عقار جديد',
    ku: 'ڕاپۆرتی موڵکی نوێ',
  );
  String get officeActionFailed => _t(
    en: 'Action failed. Try again.',
    ar: 'فشل الإجراء. حاول مرة أخرى.',
    ku: 'کردار سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.',
  );
  String get officeReferralCreated => _t(
    en: 'Buyer referral created.',
    ar: 'تم إنشاء إحالة المشتري.',
    ku: 'ئاماژەی کڕیار دروستکرا.',
  );
  String get officeNoAssignedProperties => _t(
    en: 'No assigned office properties yet.',
    ar: 'لا توجد عقارات مخصصة للمكتب بعد.',
    ku: 'هێشتا موڵکی تایبەت بە ئۆفیس نییە.',
  );
  String get officePropertyFallback =>
      _t(en: 'Property', ar: 'عقار', ku: 'موڵک');
  String get officeStatus => _t(en: 'Status', ar: 'الحالة', ku: 'دۆخ');
  String get officeBuyerLeads =>
      _t(en: 'Buyer leads', ar: 'عملاء مشترين', ku: 'کڕیارەکان');
  String get officePropertyReports =>
      _t(en: 'Property reports', ar: 'بلاغات العقارات', ku: 'ڕاپۆرتی موڵک');
  String get officeBuyerLead =>
      _t(en: 'Buyer lead', ar: 'فرصة مشتري', ku: 'دەرفەتی کڕیار');
  String get officeNoLeads => _t(
    en: 'No buyer leads yet.',
    ar: 'لا توجد فرص مشترين بعد.',
    ku: 'هێشتا دەرفەتی کڕیار نییە.',
  );
  String get officeNoReports => _t(
    en: 'No property reports yet.',
    ar: 'لا توجد بلاغات بعد.',
    ku: 'هێشتا ڕاپۆرت نییە.',
  );
  String get officeLeadNew => _t(en: 'New', ar: 'جديد', ku: 'نوێ');
  String get officeLeadContacting =>
      _t(en: 'Contacting', ar: 'جارٍ التواصل', ku: 'پەیوەندیکردن');
  String get officeLeadQualified =>
      _t(en: 'Qualified', ar: 'مؤهل', ku: 'شایستە');
  String get officeLeadNegotiating =>
      _t(en: 'Negotiating', ar: 'تفاوض', ku: 'گفتوگۆ');
  String get officeLeadTxCreated => _t(
    en: 'Transaction created',
    ar: 'تم إنشاء عملية',
    ku: 'مامەڵە دروستکرا',
  );
  String get officeLeadCompleted =>
      _t(en: 'Completed', ar: 'مكتمل', ku: 'تەواو');
  String get officeLeadRejected =>
      _t(en: 'Rejected', ar: 'مرفوض', ku: 'ڕەتکراوە');
  String get officeLeadExpired =>
      _t(en: 'Expired', ar: 'منتهي', ku: 'بەسەرچوو');
  String get officeReportUnderReview =>
      _t(en: 'Under review', ar: 'قيد المراجعة', ku: 'لە پێداچوونەوە');
  String get officeReportContactingOwner => _t(
    en: 'Contacting owner',
    ar: 'جارٍ التواصل مع المالك',
    ku: 'پەیوەندی لەگەڵ خاوەن',
  );
  String get officeReportOwnerApproved =>
      _t(en: 'Owner approved', ar: 'وافق المالك', ku: 'خاوەن ڕازی بوو');
  String get officeReportOwnerDeclined =>
      _t(en: 'Owner declined', ar: 'رفض المالك', ku: 'خاوەن ڕەتیکردەوە');
  String get officeNoConversations => _t(
    en: 'No conversations yet. Use “I found a buyer” to start one.',
    ar: 'لا محادثات بعد. استخدم «وجدت مشتريًا» لبدء محادثة.',
    ku: 'هێشتا گفتوگۆ نییە. «کڕیارم دۆزیەوە» بەکاربهێنە.',
  );
  String get officeManagementTeam => _t(
    en: 'Office Management Team',
    ar: 'فريق إدارة المكاتب',
    ku: 'تیمی بەڕێوەبردنی ئۆفیس',
  );
  String get officeMessageHint =>
      _t(en: 'Write a message…', ar: 'اكتب رسالة…', ku: 'نامە بنووسە…');
  String get officeRead => _t(en: 'Read', ar: 'مقروء', ku: 'خوێندراوەتەوە');
  String get officeCreateTransaction =>
      _t(en: 'Create transaction', ar: 'إنشاء عملية', ku: 'دروستکردنی مامەڵە');
  String get officeNoTransactions => _t(
    en: 'No office transactions yet.',
    ar: 'لا توجد عمليات للمكتب بعد.',
    ku: 'هێشتا مامەڵەی ئۆفیس نییە.',
  );
  String get officeSalesHistory =>
      _t(en: 'Sales history', ar: 'سجل العمليات', ku: 'مێژووی مامەڵەکان');
  String get officeTransactionType =>
      _t(en: 'Transaction type', ar: 'نوع العملية', ku: 'جۆری مامەڵە');
  String get officeSellerPhone =>
      _t(en: 'Seller phone', ar: 'هاتف البائع', ku: 'تەلەفۆنی فرۆشیار');
  String get officeBuyerPhone =>
      _t(en: 'Buyer phone', ar: 'هاتف المشتري', ku: 'تەلەفۆنی کڕیار');
  String get officeTransactionValue =>
      _t(en: 'Transaction value', ar: 'قيمة العملية', ku: 'بەهای مامەڵە');
  String get officeGenerateBarcode =>
      _t(en: 'Generate barcode', ar: 'إنشاء الباركود', ku: 'دروستکردنی بارکۆد');
  String get officeTransactionNumber =>
      _t(en: 'Transaction', ar: 'رقم العملية', ku: 'ژمارەی مامەڵە');
  String get officeBarcodesDelivered => _t(
    en: 'Buyer and seller barcodes were sent automatically in Madar.',
    ar: 'تم إرسال باركود المشتري والبائع تلقائياً داخل مدار.',
    ku: 'بارکۆدی کڕیار و فرۆشیار خۆکارانە نێردران.',
  );
  String get officeBuyerBarcode =>
      _t(en: 'Buyer barcode', ar: 'باركود المشتري', ku: 'بارکۆدی کڕیار');
  String get officeSellerBarcode =>
      _t(en: 'Seller barcode', ar: 'باركود البائع', ku: 'بارکۆدی فرۆشیار');
  String get officeBackToTransactions => _t(
    en: 'Back to deals',
    ar: 'العودة للعمليات',
    ku: 'گەڕانەوە بۆ مامەڵەکان',
  );
  String get officeStepBarcode =>
      _t(en: 'Barcode', ar: 'الباركود', ku: 'بارکۆد');
  String get officeLastUpdated =>
      _t(en: 'Last updated', ar: 'آخر تحديث', ku: 'دوایین نوێکردنەوە');
  String get officeCurrentResponsibility => _t(
    en: 'Current responsibility',
    ar: 'المسؤولية الحالية',
    ku: 'بەرپرسیاری ئێستا',
  );
  String get officeProgress => _t(en: 'Progress', ar: 'التقدم', ku: 'پێشکەوتن');
  String get officeMonitorReadOnlyNote => _t(
    en: 'Monitoring only. Lawyer, finance, and bank stages cannot be changed by the office.',
    ar: 'مراقبة فقط. لا يمكن للمكتب تعديل مراحل المحامي أو المالية أو المصرف.',
    ku: 'تەنها چاودێری. ئۆفیس ناتوانێت قۆناغەکانی پارێزەر/ دارایی/ بانک بگۆڕێت.',
  );
  String get officeExpectedCommission => _t(
    en: 'Expected commission',
    ar: 'العمولة المتوقعة',
    ku: 'کۆمیسیۆنی چاوەڕوانکراو',
  );
  String get officeCommissionHint => _t(
    en: 'Share is calculated from company commission rules — not a full internal ledger.',
    ar: 'تُحسب الحصة من قواعد عمولة الشركة — وليست كشفاً محاسبياً داخلياً كاملاً.',
    ku: 'بەشکردن لە ڕێساکانی کۆمپانیا دێت — نەک هەژماری ناوخۆیی تەواو.',
  );
  String get officeFilterThisMonth =>
      _t(en: 'This month', ar: 'هذا الشهر', ku: 'ئەم مانگە');
  String get officeFilterLastMonth =>
      _t(en: 'Last month', ar: 'الشهر الماضي', ku: 'مانگی پێشوو');
  String get officeFilterThisYear =>
      _t(en: 'This year', ar: 'هذه السنة', ku: 'ئەمساڵ');
  String get officeCancelled =>
      _t(en: 'Cancelled', ar: 'ملغاة', ku: 'هەڵوەشاوە');
  String get officePropertyType =>
      _t(en: 'Property type', ar: 'نوع العقار', ku: 'جۆری موڵک');
  String get officeListingType =>
      _t(en: 'Sale / Rent', ar: 'بيع / إيجار', ku: 'فرۆشتن / کرێ');
  String get officeLocation => _t(en: 'Location', ar: 'الموقع', ku: 'شوێن');
  String get officeOwnerPhone =>
      _t(en: 'Phone number', ar: 'رقم الهاتف', ku: 'ژمارەی تەلەفۆن');
  String get officeEstimatedPrice =>
      _t(en: 'Estimated price', ar: 'السعر التقديري', ku: 'نرخی خەمڵێنراو');
  String get officeAdditionalInfo => _t(
    en: 'Additional information',
    ar: 'معلومات إضافية',
    ku: 'زانیاری زیاتر',
  );
  String get officeSendReport =>
      _t(en: 'Send report', ar: 'إرسال البلاغ', ku: 'ناردنی ڕاپۆرت');
  String get officeReportSubmitted => _t(
    en: 'Report submitted — under review.',
    ar: 'تم إرسال البلاغ — قيد المراجعة.',
    ku: 'ڕاپۆرت نێردرا — لە پێداچوونەوەدایە.',
  );
  String get officePerformance =>
      _t(en: 'Office performance', ar: 'أداء المكتب', ku: 'ئەدای ئۆفیس');
  String get officeNotifications =>
      _t(en: 'Notifications', ar: 'الإشعارات', ku: 'ئاگادارییەکان');
  String get officeProfile =>
      _t(en: 'Office profile', ar: 'بيانات المكتب', ku: 'زانیاری ئۆفیس');
  String get officeDocuments =>
      _t(en: 'Documents', ar: 'مستندات المكتب', ku: 'بەڵگەنامەکان');
  String get officeSupport => _t(en: 'Support', ar: 'الدعم', ku: 'پشتگیری');
  String get officeSignOut =>
      _t(en: 'Sign out', ar: 'تسجيل الخروج', ku: 'دەرچوون');
  String get officeNoNotifications => _t(
    en: 'No notifications yet.',
    ar: 'لا إشعارات بعد.',
    ku: 'هێشتا ئاگاداری نییە.',
  );
  String get officePerfProperties =>
      _t(en: 'Properties added', ar: 'عقارات مضافة', ku: 'موڵکی زیادکراو');
  String get officePerfBuyers => _t(
    en: 'Buyers referred',
    ar: 'مشترون أحضرهم المكتب',
    ku: 'کڕیاری هێنراو',
  );
  String get officePerfTransactions =>
      _t(en: 'Transactions', ar: 'العمليات', ku: 'مامەڵەکان');
  String get officePerfCompletion =>
      _t(en: 'Completion rate', ar: 'نسبة الإتمام', ku: 'ڕێژەی تەواوبوون');
  String get officePerfActive =>
      _t(en: 'Active listings', ar: 'عقارات نشطة', ku: 'موڵکی چالاک');
  String get officePerfLeads =>
      _t(en: 'Reports / leads', ar: 'بلاغات / فرص', ku: 'ڕاپۆرت / دەرفەت');
  String get officeName =>
      _t(en: 'Office name', ar: 'اسم المكتب', ku: 'ناوی ئۆفیس');
  String get officeAddress => _t(en: 'Address', ar: 'العنوان', ku: 'ناونیشان');
  String get officePhone => _t(en: 'Phone', ar: 'الهاتف', ku: 'تەلەفۆن');
  String get officeManager => _t(en: 'Manager', ar: 'المدير', ku: 'بەڕێوەبەر');
  String get officeLicense => _t(en: 'License', ar: 'الرخصة', ku: 'مۆڵەت');
  String get officeCountry => _t(en: 'Country', ar: 'الدولة', ku: 'وڵات');
  String get officeCurrency => _t(en: 'Currency', ar: 'العملة', ku: 'دراو');
  String get officeJoined =>
      _t(en: 'Joined', ar: 'تاريخ الانضمام', ku: 'بەرواری بەشداری');
  String get officeProfileReadOnlyNote => _t(
    en: 'Sensitive fields are managed by the company and cannot be edited here.',
    ar: 'البيانات الحساسة تُدار من الشركة ولا يمكن تعديلها من هنا.',
    ku: 'زانیاری هەستیار لەلایەن کۆمپانیا بەڕێوەدەبرێت و لێرە ناگۆڕدرێت.',
  );
  String get officeNoDocuments => _t(
    en: 'No documents shared yet.',
    ar: 'لا مستندات مشاركة بعد.',
    ku: 'هێشتا بەڵگەنامە هاوبەش نەکراوە.',
  );
  String get officeOpenTicket => _t(
    en: 'Open a support ticket',
    ar: 'فتح طلب دعم',
    ku: 'کردنەوەی داوای پشتگیری',
  );
  String get officeTicketSubject =>
      _t(en: 'Subject', ar: 'الموضوع', ku: 'بابەت');
  String get officeTicketBody =>
      _t(en: 'Details', ar: 'التفاصيل', ku: 'وردەکاری');
  String get officeSubmitTicket =>
      _t(en: 'Submit ticket', ar: 'إرسال الطلب', ku: 'ناردنی داوا');
  String get officeYourTickets =>
      _t(en: 'Your tickets', ar: 'طلباتك', ku: 'داواکانت');
  String get officeNoTickets => _t(
    en: 'No support tickets yet.',
    ar: 'لا طلبات دعم بعد.',
    ku: 'هێشتا داوای پشتگیری نییە.',
  );

  // ─── Employee Portal ──────────────────────────────────────────────────────
  String get empWelcome => _t(
    en: 'Welcome to Madar Staff',
    ar: 'أهلاً بك في بوابة الموظفين',
    ku: 'بەخێربێیت بۆ دەروازەی کارمەندان',
  );
  String get empLoginTitle =>
      _t(en: 'Employee login', ar: 'تسجيل الموظف', ku: 'چوونەژوورەوەی کارمەند');
  String get empLoginSubtitle => _t(
    en: 'Use your employee ID and secret code to continue.',
    ar: 'استخدم رقم الموظف والرمز السري للمتابعة.',
    ku: 'ناسنامەی کارمەند و کۆدی نهێنی بەکاربهێنە بۆ بەردەوامبوون.',
  );
  String get empIdLabel =>
      _t(en: 'Job code', ar: 'الرمز الوظيفي', ku: 'کۆدی کار');
  String get empIdHint => _t(
    en: 'SYS-001 or phone 07…',
    ar: 'SYS-001 أو رقم الهاتف 07…',
    ku: 'SYS-001 یان ژمارەی مۆبایل 07…',
  );
  String get empSecretLabel =>
      _t(en: 'Password', ar: 'الرمز السري', ku: 'وشەی نهێنی');
  String get empSecretHint => _t(
    en: 'Enter secret code',
    ar: 'أدخل الرمز السري',
    ku: 'کۆدی نهێنی بنووسە',
  );
  String get empSignIn => _t(en: 'Enter', ar: 'دخول', ku: 'چوونەژوورەوە');
  String get empLoginInvalid => _t(
    en: 'Invalid Employee ID or secret.',
    ar: 'رقم الموظف أو الرمز السري غير صحيح.',
    ku: 'ناسنامە یان نهێنی هەڵەیە.',
  );
  String get empLoginRateLimited => _t(
    en: 'Too many attempts. Try again later.',
    ar: 'محاولات كثيرة. حاول لاحقاً.',
    ku: 'هەوڵی زۆر. دواتر هەوڵبدەوە.',
  );
  String get empLoginUnavailable => _t(
    en: 'Login unavailable. Check connection.',
    ar: 'تسجيل الدخول غير متاح.',
    ku: 'چوونەژوورەوە بەردەست نییە.',
  );
  String get empNavHome => _t(en: 'Home', ar: 'الرئيسية', ku: 'سەرەکی');
  String get empNavWork => _t(en: 'Work', ar: 'العمل', ku: 'کار');
  String get empNavMessages => _t(en: 'Messages', ar: 'الرسائل', ku: 'نامەکان');
  String get empNavFinOps =>
      _t(en: 'Financial ops', ar: 'العمليات المالية', ku: 'کارە داراییەکان');
  String get empNavDeposits =>
      _t(en: 'Deposits', ar: 'الإيداعات', ku: 'پارەدانەکان');
  String get empNavOffices => _t(en: 'Offices', ar: 'المكاتب', ku: 'ئۆفیسەکان');
  String get empNavCommissions =>
      _t(en: 'Commissions', ar: 'العمولات', ku: 'کۆمیسیۆن');
  String get empNavSettlements =>
      _t(en: 'Settlements', ar: 'التسويات', ku: 'یەکلاکردنەوە');
  String get empNavAudit => _t(en: 'Audit', ar: 'سجل التدقيق', ku: 'وردبینی');
  String get empNavNotifications =>
      _t(en: 'Alerts', ar: 'التنبيهات', ku: 'ئاگاداری');
  String get empNavProfile => _t(en: 'Profile', ar: 'الملف', ku: 'پرۆفایل');
  String get empGoodMorning =>
      _t(en: 'Good morning', ar: 'صباح الخير', ku: 'بەیانی باش');
  String get empGoodAfternoon =>
      _t(en: 'Good afternoon', ar: 'مساء الخير', ku: 'دوا نیوەڕۆ باش');
  String get empGoodEvening =>
      _t(en: 'Good evening', ar: 'مساء الخير', ku: 'ئێوارە باش');
  String get empFocusToday =>
      _t(en: 'Focus today', ar: 'ركز اليوم', ku: 'سەرنجی ئەمڕۆ');
  String get empTodaysTasks =>
      _t(en: "Today's tasks", ar: 'مهام اليوم', ku: 'ئەرکەکانی ئەمڕۆ');
  String get empTodaysWork =>
      _t(en: "Today's work", ar: 'عمل اليوم', ku: 'کاری ئەمڕۆ');
  String get empOpenWork =>
      _t(en: 'Open Work', ar: 'افتح العمل', ku: 'کار بکەرەوە');
  String get empWorkTitle => _t(en: 'Work', ar: 'مساحة العمل', ku: 'شوێنی کار');
  String get empWorkSubtitle => _t(
    en: 'Only the queues for your role. Everything else stays out of the way.',
    ar: 'طوابير دورك فقط. باقي النظام بعيد عن الطريق.',
    ku: 'تەنها ڕیزەکانی ڕۆڵەکەت. هەموو شتێکی تر لە ڕێگادا نییە.',
  );
  String get empNoWorkQueues => _t(
    en: 'No work queues for this role yet.',
    ar: 'لا توجد طوابير عمل لهذا الدور بعد.',
    ku: 'هێشتا ڕیزی کار بۆ ئەم ڕۆڵە نییە.',
  );
  String get empNoWorkspace => _t(
    en: 'No workspace assigned. Contact HR.',
    ar: 'لا توجد مساحة عمل. تواصل مع الموارد البشرية.',
    ku: 'هیچ شوێنی کار دیاری نەکراوە. پەیوەندی بە HR بکە.',
  );
  String get empMessagesHint => _t(
    en: 'Conversations tied to your department and assignments.',
    ar: 'محادثات مرتبطة بقسمك ومهامك.',
    ku: 'گفتوگۆکانی بەشی خۆت و ئەرکەکانت.',
  );
  String get empMessagesEmpty => _t(
    en: 'No conversations yet.',
    ar: 'لا محادثات بعد.',
    ku: 'هێشتا گفتوگۆ نییە.',
  );
  String get empConversation =>
      _t(en: 'Conversation', ar: 'محادثة', ku: 'گفتوگۆ');
  String get empReviewAction =>
      _t(en: 'Review', ar: 'مراجعة', ku: 'پێداچوونەوە');
  String get empNavOperations =>
      _t(en: 'Operations', ar: 'العمليات', ku: 'کارەکان');
  String get empNavReceipts =>
      _t(en: 'Receipts', ar: 'الإيصالات', ku: 'وەسڵەکان');
  String get empNavReports =>
      _t(en: 'Reports', ar: 'البلاغات', ku: 'ڕاپۆرتەکان');
  String get empNavPhotography =>
      _t(en: 'Media', ar: 'التصوير', ku: 'وێنەگرتن');
  String get empNavChats => _t(en: 'Chats', ar: 'المحادثات', ku: 'گفتوگۆ');
  String get empFinanceControlCenter => _t(
    en: 'Financial Operations Control Center',
    ar: 'مركز التحكم بالعمليات المالية',
    ku: 'ناوەندی کۆنترۆڵی کارە داراییەکان',
  );
  String get empFinanceControlSubtitle => _t(
    en: 'Live figures from the transaction ledger — not estimates.',
    ar: 'أرقام مباشرة من سجل العمليات — وليست تقديرات.',
    ku: 'ژمارە ڕاستەوخۆ لە تۆماری مامەڵە — نەخەمڵاندن.',
  );
  String get empRangeToday => _t(en: 'Today', ar: 'اليوم', ku: 'ئەمڕۆ');
  String get empRangeWeek =>
      _t(en: 'This week', ar: 'هذا الأسبوع', ku: 'ئەم هەفتەیە');
  String get empRangeMonth =>
      _t(en: 'This month', ar: 'هذا الشهر', ku: 'ئەم مانگە');
  String get empStatTodaysOps =>
      _t(en: "Today's ops", ar: 'عمليات اليوم', ku: 'کارەکانی ئەمڕۆ');
  String get empStatPendingDeposits =>
      _t(en: 'Pending deposits', ar: 'إيداعات معلّقة', ku: 'پارەدانی چاوەڕوان');
  String get empStatConfirmedDeposits =>
      _t(en: 'Confirmed deposits', ar: 'إيداعات مؤكدة', ku: 'پارەدانی پشتڕاست');
  String get empStatUnpaid => _t(en: 'Unpaid', ar: 'غير مدفوعة', ku: 'نەدراو');
  String get empStatOverdue => _t(en: 'Overdue', ar: 'متأخرة', ku: 'دواکەوتوو');
  String get empStatAwaitingSettlement => _t(
    en: 'Awaiting settlement',
    ar: 'بانتظار التسوية',
    ku: 'چاوەڕوانی یەکلاکردنەوە',
  );
  String get empStatOfficeDue =>
      _t(en: 'Office amounts due', ar: 'مستحقات المكاتب', ku: 'قەرزی ئۆفیس');
  String get empStatRevenue =>
      _t(en: 'Company revenue', ar: 'إيرادات الشركة', ku: 'داهاتی کۆمپانیا');
  String get empStatPendingTransfers => _t(
    en: 'Pending transfers',
    ar: 'تحويلات معلّقة',
    ku: 'گواستنەوەی چاوەڕوان',
  );
  String get empOpenFinancialMonitor => _t(
    en: 'Open financial monitor',
    ar: 'فتح مراقبة العمليات المالية',
    ku: 'کردنەوەی چاودێری دارایی',
  );
  String get empSearchTransactions => _t(
    en: 'Search transaction #, phone…',
    ar: 'ابحث برقم العملية أو الهاتف…',
    ku: 'گەڕان بە ژمارە یان تەلەفۆن…',
  );
  String get empEmptyTransactions => _t(
    en: 'No transactions match.',
    ar: 'لا عمليات مطابقة.',
    ku: 'هیچ مامەڵەیەک نییە.',
  );
  String get empSalePrice =>
      _t(en: 'Sale price', ar: 'سعر البيع', ku: 'نرخی فرۆشتن');
  String get empRequiredDeposit =>
      _t(en: 'Required deposit', ar: 'الإيداع المطلوب', ku: 'پارەدانی پێویست');
  String get empDeposited => _t(en: 'Deposited', ar: 'المودع', ku: 'دراو');
  String get empStatus => _t(en: 'Status', ar: 'الحالة', ku: 'دۆخ');
  String get empFinancialTimeline => _t(
    en: 'Financial timeline',
    ar: 'الجدول الزمني المالي',
    ku: 'کاتی دارایی',
  );
  String get empCompanyFees =>
      _t(en: 'Company fees', ar: 'رسوم الشركة', ku: 'کرێی کۆمپانیا');
  String get empTaxes => _t(en: 'Taxes', ar: 'الضرائب', ku: 'باج');
  String get empOfficeCommission =>
      _t(en: 'Office commission', ar: 'عمولة المكتب', ku: 'کۆمیسیۆنی ئۆفیس');
  String get empChangeReason =>
      _t(en: 'Reason for change', ar: 'سبب التعديل', ku: 'هۆکاری گۆڕان');
  String get empSaveFinancials =>
      _t(en: 'Save (audited)', ar: 'حفظ (مع تدقيق)', ku: 'پاشەکەوت (وردبینی)');
  String get empSendPaymentRequest => _t(
    en: 'Send payment request',
    ar: 'إرسال طلب دفع',
    ku: 'ناردنی داوای پارەدان',
  );
  String get empPaymentRequestSent => _t(
    en: 'Payment request sent.',
    ar: 'تم إرسال طلب الدفع.',
    ku: 'داوای پارەدان نێردرا.',
  );
  String get empSaved => _t(en: 'Saved.', ar: 'تم الحفظ.', ku: 'پاشەکەوتکرا.');
  String get empActionFailed => _t(
    en: 'Action failed.',
    ar: 'فشل الإجراء.',
    ku: 'کردار سەرکەوتوو نەبوو.',
  );
  String get empForbidden =>
      _t(en: 'Permission denied.', ar: 'لا تملك الصلاحية.', ku: 'مۆڵەت نییە.');
  String get empCommissionRules =>
      _t(en: 'Commission rules', ar: 'قواعد العمولة', ku: 'ڕێساکانی کۆمیسیۆن');
  String get empCommissionRulesHint => _t(
    en: 'Configurable rules — not hard-coded shares.',
    ar: 'قواعد قابلة للتغيير — وليست نسباً ثابتة في الكود.',
    ku: 'ڕێسای گۆڕاو — نە ڕێژەی جێگیر لە کۆد.',
  );
  String get empFeeEngine =>
      _t(en: 'Fee engine', ar: 'محرك الرسوم', ku: 'مۆتۆری کرێ');
  String get empEmptyRules => _t(
    en: 'No commission rules yet.',
    ar: 'لا قواعد عمولة بعد.',
    ku: 'هێشتا ڕێسا نییە.',
  );
  String get empEmptyFees => _t(
    en: 'No fee definitions yet.',
    ar: 'لا تعريفات رسوم بعد.',
    ku: 'هێشتا پێناسەی کرێ نییە.',
  );
  String get empEmptyOffices =>
      _t(en: 'No offices found.', ar: 'لا مكاتب.', ku: 'ئۆفیس نییە.');
  String get empEmptySettlements => _t(
    en: 'No settlements yet.',
    ar: 'لا تسويات بعد.',
    ku: 'هێشتا یەکلاکردنەوە نییە.',
  );
  String get empEmptyDeposits => _t(
    en: 'No pending deposits.',
    ar: 'لا إيداعات معلّقة.',
    ku: 'پارەدانی چاوەڕوان نییە.',
  );
  String get empTransactions =>
      _t(en: 'Transactions', ar: 'العمليات', ku: 'مامەڵەکان');
  String get empAmountDue => _t(en: 'Amount due', ar: 'المستحق', ku: 'قەرز');
  String get empAmountPaid => _t(en: 'Amount paid', ar: 'المدفوع', ku: 'دراو');
  String get empBankWorkspace => _t(
    en: 'Bank verification workspace',
    ar: 'مساحة عمل التحقق المصرفي',
    ku: 'شوێنی پشتڕاستکردنەوەی بانک',
  );
  String get empBankWorkspaceSubtitle => _t(
    en: 'Verify buyer identity and confirm deposits — no company finance edits.',
    ar: 'تحقق من هوية المشتري وتأكيد الإيداع — دون تعديل مالية الشركة.',
    ku: 'ناسنامەی کڕیار و پشتڕاستکردنی پارەدان — بەبێ دەستکاری دارایی کۆمپانیا.',
  );
  String get empStatTodaysDeposits =>
      _t(en: "Today's deposits", ar: 'إيداعات اليوم', ku: 'پارەدانی ئەمڕۆ');
  String get empStatCompletedDeposits =>
      _t(en: 'Completed deposits', ar: 'إيداعات مكتملة', ku: 'پارەدانی تەواو');
  String get empStatAwaitingOtp =>
      _t(en: 'Awaiting OTP', ar: 'بانتظار OTP', ku: 'چاوەڕوانی OTP');
  String get empStatVerificationRequired => _t(
    en: 'Verification required',
    ar: 'يتطلب التحقق',
    ku: 'پشتڕاستکردنەوە پێویستە',
  );
  String get empOpenBankOperations =>
      _t(en: 'Open operations', ar: 'فتح العمليات', ku: 'کردنەوەی کارەکان');
  String get empBankSearchHint => _t(
    en: 'Transaction #, barcode, buyer phone…',
    ar: 'رقم العملية، باركود، هاتف المشتري…',
    ku: 'ژمارەی مامەڵە، بارکۆد، تەلەفۆنی کڕیار…',
  );
  String get empBuyer => _t(en: 'Buyer', ar: 'المشتري', ku: 'کڕیار');
  String get empSeller => _t(en: 'Seller', ar: 'البائع', ku: 'فرۆشیار');
  String get empVerifyBuyer =>
      _t(en: 'Verify buyer', ar: 'تحقق من المشتري', ku: 'پشتڕاستکردنی کڕیار');
  String get empSendOtp =>
      _t(en: 'Send OTP', ar: 'إرسال OTP', ku: 'ناردنی OTP');
  String get empOtpSent =>
      _t(en: 'OTP sent', ar: 'تم إرسال OTP', ku: 'OTP نێردرا');
  String get empEnterOtp =>
      _t(en: 'Enter OTP', ar: 'أدخل OTP', ku: 'OTP بنووسە');
  String get empConfirmOtp =>
      _t(en: 'Confirm OTP', ar: 'تأكيد OTP', ku: 'پشتڕاستکردنی OTP');
  String get empIdentityConfirmed => _t(
    en: 'Identity confirmed',
    ar: 'تم تأكيد الهوية',
    ku: 'ناسنامە پشتڕاستکرا',
  );
  String get empConfirmDeposit => _t(
    en: 'Confirm deposit',
    ar: 'تأكيد الإيداع',
    ku: 'پشتڕاستکردنی پارەدان',
  );
  String get empActualDeposited =>
      _t(en: 'Actual deposited', ar: 'المبلغ المودع فعلياً', ku: 'بڕی دراو');
  String get empReferenceNumber =>
      _t(en: 'Reference number', ar: 'رقم المرجع', ku: 'ژمارەی سەرچاوە');
  String get empDepositConfirmed => _t(
    en: 'Deposit confirmed',
    ar: 'تم تأكيد الإيداع',
    ku: 'پارەدان پشتڕاستکرا',
  );
  String get empVerifyBeforeDeposit => _t(
    en: 'Verify buyer before confirming deposit.',
    ar: 'تحقق من المشتري قبل تأكيد الإيداع.',
    ku: 'پێش پشتڕاستکردنی پارەدان کڕیار پشتڕاست بکە.',
  );
  String get empEmptyReceipts => _t(
    en: 'No deposit receipts yet.',
    ar: 'لا إيصالات إيداع بعد.',
    ku: 'هێشتا وەسڵ نییە.',
  );
  String get empDepositReceipt =>
      _t(en: 'Deposit receipt', ar: 'إيصال إيداع', ku: 'وەسڵی پارەدان');
  String get empOmWorkspace => _t(
    en: 'Office network control',
    ar: 'إدارة شبكة المكاتب',
    ku: 'بەڕێوەبردنی تۆڕی ئۆفیس',
  );
  String get empOmWorkspaceSubtitle => _t(
    en: 'Bridge between company, offices, properties, and referrals.',
    ar: 'حلقة الوصل بين الشركة والمكاتب والعقارات والإحالات.',
    ku: 'پەیوەندی نێوان کۆمپانیا، ئۆفیس، موڵک و ئاماژەکان.',
  );
  String get empStatActiveOffices =>
      _t(en: 'Active offices', ar: 'مكاتب نشطة', ku: 'ئۆفیسی چالاک');
  String get empStatPendingOfficeRequests =>
      _t(en: 'Pending requests', ar: 'طلبات معلّقة', ku: 'داوای چاوەڕوان');
  String get empStatNewPropertyReports => _t(
    en: 'New property reports',
    ar: 'بلاغات عقارات جديدة',
    ku: 'ڕاپۆرتی موڵکی نوێ',
  );
  String get empStatAwaitingPhotography => _t(
    en: 'Awaiting photography',
    ar: 'بانتظار التصوير',
    ku: 'چاوەڕوانی وێنەگرتن',
  );
  String get empStatActiveOfficeTx => _t(
    en: 'Active office deals',
    ar: 'عمليات مكاتب نشطة',
    ku: 'مامەڵەی چالاکی ئۆفیس',
  );
  String get empManageOffices => _t(
    en: 'Manage offices',
    ar: 'إدارة المكاتب',
    ku: 'بەڕێوەبردنی ئۆفیسەکان',
  );
  String get empAddOffice =>
      _t(en: 'Add office', ar: 'إضافة مكتب', ku: 'زیادکردنی ئۆفیس');
  String get empActivateOffice =>
      _t(en: 'Activate', ar: 'تفعيل', ku: 'چالاککردن');
  String get empSuspendOffice => _t(en: 'Suspend', ar: 'تعليق', ku: 'ڕاگرتن');
  String get empResetSecret =>
      _t(en: 'Reset secret', ar: 'إعادة تعيين الرمز', ku: 'نوێکردنەوەی نهێنی');
  String get empSecretReset =>
      _t(en: 'Secret reset', ar: 'تم إعادة التعيين', ku: 'نهێنی نوێکرایەوە');
  String get empTemporarySecret =>
      _t(en: 'Temporary secret', ar: 'الرمز المؤقت', ku: 'نهێنی کاتی');
  String get empClose => _t(en: 'Close', ar: 'إغلاق', ku: 'داخستن');
  String get empCreateOffice =>
      _t(en: 'Create office', ar: 'إنشاء المكتب', ku: 'دروستکردنی ئۆفیس');
  String get empOfficeCreated =>
      _t(en: 'Office created', ar: 'تم إنشاء المكتب', ku: 'ئۆفیس دروستکرا');
  String get empOfficeCode =>
      _t(en: 'Office code', ar: 'رمز المكتب', ku: 'کۆدی ئۆفیس');
  String get empOfficePendingNote => _t(
    en: 'Office cannot sign in until status is Active.',
    ar: 'لا يمكن للمكتب الدخول قبل أن تصبح حالته Active.',
    ku: 'ئۆفیس ناتوانێت بچێتە ژوورەوە تا دۆخی Active دەبێت.',
  );
  String get empOfficeName =>
      _t(en: 'Office name', ar: 'اسم المكتب', ku: 'ناوی ئۆفیس');
  String get empOwnerName => _t(
    en: 'Owner full name',
    ar: 'اسم المالك الكامل',
    ku: 'ناوی تەواوی خاوەن',
  );
  String get empOwnerPhone =>
      _t(en: 'Owner phone', ar: 'هاتف المالك', ku: 'تەلەفۆنی خاوەن');
  String get empOfficePhone =>
      _t(en: 'Office phone', ar: 'هاتف المكتب', ku: 'تەلەفۆنی ئۆفیس');
  String get empEmail => _t(en: 'Email', ar: 'البريد', ku: 'ئیمەیڵ');
  String get empCountry => _t(en: 'Country', ar: 'الدولة', ku: 'وڵات');
  String get empCity => _t(en: 'City', ar: 'المدينة', ku: 'شار');
  String get empRegion => _t(en: 'Region', ar: 'المنطقة', ku: 'ناوچە');
  String get empAddress => _t(en: 'Address', ar: 'العنوان', ku: 'ناونیشان');
  String get empLicense =>
      _t(en: 'License number', ar: 'رقم الرخصة', ku: 'ژمارەی مۆڵەت');
  String get empPropertyReport =>
      _t(en: 'Property report', ar: 'بلاغ عقار', ku: 'ڕاپۆرتی موڵک');
  String get empRequestPhotography =>
      _t(en: 'Request photography', ar: 'طلب تصوير', ku: 'داوای وێنەگرتن');
  String get empPhotographyRequested => _t(
    en: 'Photography requested',
    ar: 'تم طلب التصوير',
    ku: 'داوای وێنەگرتن نێردرا',
  );
  String get empEmptyPhotography => _t(
    en: 'No photography requests.',
    ar: 'لا طلبات تصوير.',
    ku: 'داوای وێنەگرتن نییە.',
  );
  String get empEmptyChats => _t(
    en: 'No office conversations yet.',
    ar: 'لا محادثات مكاتب بعد.',
    ku: 'هێشتا گفتوگۆ نییە.',
  );
  String get empOfficeChat =>
      _t(en: 'Office conversation', ar: 'محادثة مكتب', ku: 'گفتوگۆی ئۆفیس');
  String get empFullName =>
      _t(en: 'Full name', ar: 'الاسم الكامل', ku: 'ناوی تەواو');
  String get empJobTitle =>
      _t(en: 'Job title', ar: 'المسمى الوظيفي', ku: 'ناونیشانی کار');
  String get empDepartment => _t(en: 'Department', ar: 'القسم', ku: 'بەش');
  String get empRole => _t(en: 'Role', ar: 'الدور', ku: 'ڕۆڵ');
  String get empBranch => _t(en: 'Branch', ar: 'الفرع', ku: 'لق');
  String get empJoined =>
      _t(en: 'Joined', ar: 'تاريخ الالتحاق', ku: 'بەرواری بەشداری');
  String get empLastLogin =>
      _t(en: 'Last login', ar: 'آخر دخول', ku: 'دوایین چوونەژوورەوە');
  String get empPermissions =>
      _t(en: 'Permissions', ar: 'الصلاحيات', ku: 'مۆڵەتەکان');
  String get empProfileReadOnlyNote => _t(
    en: 'Employee ID, department, role, and permissions are managed by administration.',
    ar: 'رقم الموظف والقسم والدور والصلاحيات تُدار إدارياً ولا تُعدّل من هنا.',
    ku: 'ناسنامە، بەش، ڕۆڵ و مۆڵەت لەلایەن بەڕێوەبردنەوە بەڕێوەدەبرێن.',
  );
  String get empSignOut =>
      _t(en: 'Sign out', ar: 'تسجيل الخروج', ku: 'دەرچوون');
  String get empEmptyNotifications => _t(
    en: 'No notifications yet.',
    ar: 'لا إشعارات بعد.',
    ku: 'هێشتا ئاگاداری نییە.',
  );
  String get empGlobalSearchHint => _t(
    en: 'Search transactions, offices… (permission-scoped)',
    ar: 'ابحث عن عمليات أو مكاتب… (حسب الصلاحيات)',
    ku: 'گەڕان بۆ مامەڵە یان ئۆفیس… (بەپێی مۆڵەت)',
  );
  String get empEmptyAudit => _t(
    en: 'No audit entries yet.',
    ar: 'لا سجلات تدقيق بعد.',
    ku: 'هێشتا تۆماری وردبینی نییە.',
  );

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
