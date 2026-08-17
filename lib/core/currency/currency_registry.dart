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

  /// Approximate mid-market units per 1 USD (display conversion only).
  static const Map<String, double> _usdRates = {
    'USD': 1,
    'IQD': 1310,
    'SAR': 3.75,
    'AED': 3.67,
    'KWD': 0.31,
    'QAR': 3.64,
    'BHD': 0.38,
    'OMR': 0.39,
    'JOD': 0.71,
    'EGP': 49,
    'TRY': 34,
    'EUR': 0.92,
    'GBP': 0.78,
  };

  static double convert(double amount, {required String from, required String to}) {
    final src = from.toUpperCase();
    final dst = to.toUpperCase();
    if (src == dst) return amount;
    final fromRate = _usdRates[src] ?? 1;
    final toRate = _usdRates[dst] ?? 1;
    final usd = amount / fromRate;
    return usd * toRate;
  }

  static String formatAmount(double amount, String currencyCode) {
    final currency = findByCode(currencyCode) ?? fallback;
    final digits = currency.decimalDigits;
    final value = amount.round();
    final formatted = _groupDigits(value);
    if (currency.code == 'IQD') {
      return '${currency.symbol} $formatted';
    }
    if (digits == 0) {
      return '${currency.symbol}$formatted';
    }
    return '${currency.symbol}${amount.toStringAsFixed(digits)}';
  }

  static String _groupDigits(int value) {
    final sign = value < 0 ? '-' : '';
    final digits = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buf.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return '$sign$buf';
  }

  static double filterMaxFor(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'IQD':
        return 1000000000000; // 1 trillion
      case 'KWD':
      case 'BHD':
      case 'OMR':
        return 50000000;
      default:
        return 50000000;
    }
  }

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
