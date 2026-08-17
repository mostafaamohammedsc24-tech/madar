import '../localization/app_localizations.dart';

/// The 18 Iraqi governorates, localized for search filters.
class IraqGovernorate {
  const IraqGovernorate({
    required this.id,
    required this.en,
    required this.ar,
    required this.ku,
  });

  final String id;
  final String en;
  final String ar;
  final String ku;

  String name(AppLanguage language) {
    switch (language) {
      case AppLanguage.arabic:
        return ar;
      case AppLanguage.kurdish:
        return ku;
      case AppLanguage.english:
        return en;
    }
  }

  bool matches(String haystack) {
    final h = haystack.toLowerCase();
    return h.contains(en.toLowerCase()) ||
        haystack.contains(ar) ||
        haystack.contains(ku) ||
        h.contains(id);
  }
}

abstract final class IraqGovernorates {
  static const all = [
    IraqGovernorate(id: 'baghdad', en: 'Baghdad', ar: 'بغداد', ku: 'بەغدا'),
    IraqGovernorate(id: 'basra', en: 'Basra', ar: 'البصرة', ku: 'بەسرە'),
    IraqGovernorate(id: 'nineveh', en: 'Nineveh', ar: 'نينوى', ku: 'نەینەوا'),
    IraqGovernorate(id: 'erbil', en: 'Erbil', ar: 'أربيل', ku: 'هەولێر'),
    IraqGovernorate(id: 'sulaymaniyah', en: 'Sulaymaniyah', ar: 'السليمانية', ku: 'سلێمانی'),
    IraqGovernorate(id: 'duhok', en: 'Duhok', ar: 'دهوك', ku: 'دهۆک'),
    IraqGovernorate(id: 'kirkuk', en: 'Kirkuk', ar: 'كركوك', ku: 'کەرکووک'),
    IraqGovernorate(id: 'anbar', en: 'Anbar', ar: 'الأنبار', ku: 'ئەنبار'),
    IraqGovernorate(id: 'najaf', en: 'Najaf', ar: 'النجف', ku: 'نەجەف'),
    IraqGovernorate(id: 'karbala', en: 'Karbala', ar: 'كربلاء', ku: 'کەربەلا'),
    IraqGovernorate(id: 'babil', en: 'Babil', ar: 'بابل', ku: 'بابل'),
    IraqGovernorate(id: 'wasit', en: 'Wasit', ar: 'واسط', ku: 'واسط'),
    IraqGovernorate(id: 'diyala', en: 'Diyala', ar: 'ديالى', ku: 'دیالە'),
    IraqGovernorate(id: 'saladin', en: 'Saladin', ar: 'صلاح الدين', ku: 'سەلاحەدین'),
    IraqGovernorate(id: 'dhi_qar', en: 'Dhi Qar', ar: 'ذي قار', ku: 'زی قار'),
    IraqGovernorate(id: 'maysan', en: 'Maysan', ar: 'ميسان', ku: 'مەیسان'),
    IraqGovernorate(id: 'muthanna', en: 'Muthanna', ar: 'المثنى', ku: 'موسەننا'),
    IraqGovernorate(id: 'qadisiyyah', en: 'Al-Qadisiyyah', ar: 'القادسية', ku: 'قادسیە'),
  ];

  static IraqGovernorate? byId(String id) {
    for (final g in all) {
      if (g.id == id) return g;
    }
    return null;
  }
}
