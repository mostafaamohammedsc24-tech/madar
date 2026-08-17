/// Supported country for phone authentication.
class AuthCountry {
  const AuthCountry({
    required this.isoCode,
    required this.nameEn,
    required this.nameAr,
    required this.nameKu,
    required this.dialCode,
    required this.phonePlaceholder,
    this.minPhoneLength = 7,
    this.maxPhoneLength = 12,
  });

  final String isoCode;
  final String nameEn;
  final String nameAr;
  final String nameKu;
  final String dialCode;
  final String phonePlaceholder;
  final int minPhoneLength;
  final int maxPhoneLength;

  String localizedName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return nameAr;
      case 'ku':
        return nameKu;
      default:
        return nameEn;
    }
  }

  String get e164Prefix => dialCode.startsWith('+') ? dialCode : '+$dialCode';
}

/// Curated list for Middle East and common international numbers.
const List<AuthCountry> authCountries = [
  AuthCountry(
    isoCode: 'IQ',
    nameEn: 'Iraq',
    nameAr: 'العراق',
    nameKu: 'عێراق',
    dialCode: '+964',
    phonePlaceholder: '7XX XXX XXXX',
  ),
  AuthCountry(
    isoCode: 'SA',
    nameEn: 'Saudi Arabia',
    nameAr: 'السعودية',
    nameKu: 'سعودیە',
    dialCode: '+966',
    phonePlaceholder: '5X XXX XXXX',
  ),
  AuthCountry(
    isoCode: 'AE',
    nameEn: 'United Arab Emirates',
    nameAr: 'الإمارات',
    nameKu: 'ئیمارات',
    dialCode: '+971',
    phonePlaceholder: '5X XXX XXXX',
  ),
  AuthCountry(
    isoCode: 'JO',
    nameEn: 'Jordan',
    nameAr: 'الأردن',
    nameKu: 'ئوردن',
    dialCode: '+962',
    phonePlaceholder: '7X XXX XXXX',
  ),
  AuthCountry(
    isoCode: 'KW',
    nameEn: 'Kuwait',
    nameAr: 'الكويت',
    nameKu: 'کوێت',
    dialCode: '+965',
    phonePlaceholder: 'XXXX XXXX',
  ),
  AuthCountry(
    isoCode: 'QA',
    nameEn: 'Qatar',
    nameAr: 'قطر',
    nameKu: 'قەتەر',
    dialCode: '+974',
    phonePlaceholder: 'XXXX XXXX',
  ),
  AuthCountry(
    isoCode: 'BH',
    nameEn: 'Bahrain',
    nameAr: 'البحرين',
    nameKu: 'بەحرەین',
    dialCode: '+973',
    phonePlaceholder: 'XXXX XXXX',
  ),
  AuthCountry(
    isoCode: 'OM',
    nameEn: 'Oman',
    nameAr: 'عُمان',
    nameKu: 'عومان',
    dialCode: '+968',
    phonePlaceholder: 'XXXX XXXX',
  ),
  AuthCountry(
    isoCode: 'LB',
    nameEn: 'Lebanon',
    nameAr: 'لبنان',
    nameKu: 'لوبنان',
    dialCode: '+961',
    phonePlaceholder: 'XX XXX XXX',
  ),
  AuthCountry(
    isoCode: 'EG',
    nameEn: 'Egypt',
    nameAr: 'مصر',
    nameKu: 'میسر',
    dialCode: '+20',
    phonePlaceholder: '1XX XXX XXXX',
  ),
  AuthCountry(
    isoCode: 'TR',
    nameEn: 'Turkey',
    nameAr: 'تركيا',
    nameKu: 'تورکیا',
    dialCode: '+90',
    phonePlaceholder: '5XX XXX XXXX',
  ),
  AuthCountry(
    isoCode: 'US',
    nameEn: 'United States',
    nameAr: 'الولايات المتحدة',
    nameKu: 'ئەمریکا',
    dialCode: '+1',
    phonePlaceholder: 'XXX XXX XXXX',
  ),
  AuthCountry(
    isoCode: 'GB',
    nameEn: 'United Kingdom',
    nameAr: 'المملكة المتحدة',
    nameKu: 'شانشینی یەکگرتوو',
    dialCode: '+44',
    phonePlaceholder: '7XXX XXXXXX',
  ),
  AuthCountry(
    isoCode: 'DE',
    nameEn: 'Germany',
    nameAr: 'ألمانيا',
    nameKu: 'ئەڵمانیا',
    dialCode: '+49',
    phonePlaceholder: '1XX XXXXXXX',
  ),
  AuthCountry(
    isoCode: 'FR',
    nameEn: 'France',
    nameAr: 'فرنسا',
    nameKu: 'فەڕانسە',
    dialCode: '+33',
    phonePlaceholder: '6 XX XX XX XX',
  ),
];

AuthCountry authCountryByIso(String isoCode) {
  return authCountries.firstWhere(
    (c) => c.isoCode == isoCode,
    orElse: () => authCountries.first,
  );
}
