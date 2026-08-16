import 'madar_currency.dart';

/// Currency catalog and country → default currency mapping.
class CurrencyRegistry {
  CurrencyRegistry._();

  static const List<MadarCurrency> all = [
    MadarCurrency(code: 'IQD', symbol: 'د.ع', nameEn: 'Iraqi Dinar', nameAr: 'دينار عراقي', nameKu: 'دیناری عێراقی', decimalDigits: 0),
    MadarCurrency(code: 'SAR', symbol: 'ر.س', nameEn: 'Saudi Riyal', nameAr: 'ريال سعودي', nameKu: 'ڕیالی سعودی'),
    MadarCurrency(code: 'AED', symbol: 'د.إ', nameEn: 'UAE Dirham', nameAr: 'درهم إماراتي', nameKu: 'درەهمی ئیمارات'),
    MadarCurrency(code: 'KWD', symbol: 'د.ك', nameEn: 'Kuwaiti Dinar', nameAr: 'دينار كويتي', nameKu: 'دیناری کوێت', decimalDigits: 3),
    MadarCurrency(code: 'QAR', symbol: 'ر.ق', nameEn: 'Qatari Riyal', nameAr: 'ريال قطري', nameKu: 'ڕیالی قەتەر'),
    MadarCurrency(code: 'BHD', symbol: 'د.ب', nameEn: 'Bahraini Dinar', nameAr: 'دينار بحريني', nameKu: 'دیناری بەحرەین', decimalDigits: 3),
    MadarCurrency(code: 'OMR', symbol: 'ر.ع', nameEn: 'Omani Rial', nameAr: 'ريال عماني', nameKu: 'ڕیالی عومان', decimalDigits: 3),
    MadarCurrency(code: 'JOD', symbol: 'د.أ', nameEn: 'Jordanian Dinar', nameAr: 'دينار أردني', nameKu: 'دیناری ئوردن', decimalDigits: 3),
    MadarCurrency(code: 'EGP', symbol: 'ج.م', nameEn: 'Egyptian Pound', nameAr: 'جنيه مصري', nameKu: 'پاوەندی میسر'),
    MadarCurrency(code: 'TRY', symbol: '₺', nameEn: 'Turkish Lira', nameAr: 'ليرة تركية', nameKu: 'لیرەی تورکیا'),
    MadarCurrency(code: 'USD', symbol: '\$', nameEn: 'US Dollar', nameAr: 'دولار أمريكي', nameKu: 'دۆلاری ئەمریکا'),
    MadarCurrency(code: 'EUR', symbol: '€', nameEn: 'Euro', nameAr: 'يورو', nameKu: 'یۆرۆ'),
    MadarCurrency(code: 'GBP', symbol: '£', nameEn: 'British Pound', nameAr: 'جنيه إسترليني', nameKu: 'پاوەندی بەریتانیا'),
  ];

  static MadarCurrency? findByCode(String? code) {
    if (code == null) return null;
    final upper = code.toUpperCase();
    for (final c in all) {
      if (c.code == upper) return c;
    }
    return null;
  }

  static MadarCurrency get fallback => findByCode('USD')!;

  static String defaultCurrencyForCountry(String isoCode) {
    return _countryCurrencyMap[isoCode.toUpperCase()] ?? 'USD';
  }

  static const Map<String, String> _countryCurrencyMap = {
    'IQ': 'IQD',
    'SA': 'SAR',
    'AE': 'AED',
    'JO': 'JOD',
    'KW': 'KWD',
    'QA': 'QAR',
    'BH': 'BHD',
    'OM': 'OMR',
    'EG': 'EGP',
    'TR': 'TRY',
    'US': 'USD',
    'GB': 'GBP',
    'DE': 'EUR',
    'FR': 'EUR',
    'IT': 'EUR',
    'ES': 'EUR',
    'NL': 'EUR',
    'CA': 'CAD',
    'AU': 'AUD',
    'IN': 'INR',
    'PK': 'PKR',
    'LB': 'LBP',
    'SY': 'SYP',
    'YE': 'YER',
    'IR': 'IRR',
    'MA': 'MAD',
    'DZ': 'DZD',
    'TN': 'TND',
    'LY': 'LYD',
    'SD': 'SDG',
  };
}
