/// ISO 4217 currency representation.
class MadarCurrency {
  const MadarCurrency({
    required this.code,
    required this.symbol,
    required this.nameEn,
    this.nameAr,
    this.nameKu,
    this.decimalDigits = 2,
  });

  final String code;
  final String symbol;
  final String nameEn;
  final String? nameAr;
  final String? nameKu;
  final int decimalDigits;

  String localizedName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return nameAr ?? nameEn;
      case 'ku':
        return nameKu ?? nameAr ?? nameEn;
      default:
        return nameEn;
    }
  }
}
