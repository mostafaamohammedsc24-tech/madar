/// Open-ended content language for property text (not limited to app UI langs).
class ContentLanguage {
  const ContentLanguage(this.code, {this.englishName});

  /// BCP-47-ish lowercase code: ar, en, ku, tr, fa, fr, ...
  final String code;
  final String? englishName;

  static const arabic = ContentLanguage('ar', englishName: 'Arabic');
  static const english = ContentLanguage('en', englishName: 'English');
  static const kurdish = ContentLanguage('ku', englishName: 'Kurdish');
  static const turkish = ContentLanguage('tr', englishName: 'Turkish');
  static const persian = ContentLanguage('fa', englishName: 'Persian');
  static const french = ContentLanguage('fr', englishName: 'French');
  static const unknown = ContentLanguage('und', englishName: 'Unknown');

  String get normalized => code.toLowerCase().trim();

  bool matches(ContentLanguage other) => normalized == other.normalized;

  /// True when script/UI direction is typically RTL.
  bool get isRtl {
    const rtl = {'ar', 'ku', 'fa', 'ur', 'he', 'ps', 'sd'};
    return rtl.contains(normalized);
  }

  static ContentLanguage parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return unknown;
    final c = raw.trim().toLowerCase();
    switch (c) {
      case 'ar':
      case 'arabic':
      case 'ara':
        return arabic;
      case 'en':
      case 'english':
      case 'eng':
        return english;
      case 'ku':
      case 'ckb':
      case 'kmr':
      case 'kurdish':
        return kurdish;
      case 'tr':
      case 'turkish':
        return turkish;
      case 'fa':
      case 'persian':
      case 'farsi':
        return persian;
      case 'fr':
      case 'french':
        return french;
      default:
        return ContentLanguage(c.split('-').first);
    }
  }

  String displayName(String localeCode) {
    // Prefer englishName; callers may localize known codes via AppLocalizations.
    return englishName ?? code.toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      other is ContentLanguage && other.normalized == normalized;

  @override
  int get hashCode => normalized.hashCode;

  @override
  String toString() => normalized;
}
