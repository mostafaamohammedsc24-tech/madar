import '../domain/models/legal_models.dart';

/// Authorized clause catalog — identifiers only.
/// Legal wording is supplied by Madar Legal Operations templates, not invented here.
class LegalClauseLibrary {
  static const catalog = <AuthorizedClause>[
    AuthorizedClause(id: 'GEN-SALE-01', category: 'general_sale', titleAr: 'إطار البيع العام', titleEn: 'General sale framework', titleKu: 'چوارچێوەی فرۆشتنی گشتی', templateRef: 'tpl.general_sale.v1'),
    AuthorizedClause(id: 'RES-01', category: 'residential', titleAr: 'بيع سكني', titleEn: 'Residential sale', titleKu: 'فرۆشتنی نیشتەجێ', templateRef: 'tpl.residential.v1'),
    AuthorizedClause(id: 'COM-01', category: 'commercial', titleAr: 'بيع تجاري', titleEn: 'Commercial sale', titleKu: 'فرۆشتنی بازرگانی', templateRef: 'tpl.commercial.v1'),
    AuthorizedClause(id: 'LAND-01', category: 'land', titleAr: 'بيع أرض', titleEn: 'Land sale', titleKu: 'فرۆشتنی زەوی', templateRef: 'tpl.land.v1'),
    AuthorizedClause(id: 'AGR-01', category: 'agricultural', titleAr: 'عقار زراعي', titleEn: 'Agricultural property', titleKu: 'موڵکی کشتوکاڵی', templateRef: 'tpl.agricultural.v1'),
    AuthorizedClause(id: 'INV-01', category: 'investment', titleAr: 'عقار استثماري', titleEn: 'Investment property', titleKu: 'موڵکی وەبەرهێنان', templateRef: 'tpl.investment.v1'),
    AuthorizedClause(id: 'MTG-01', category: 'mortgage', titleAr: 'مرتبط بالرهن', titleEn: 'Mortgage-related', titleKu: 'پەیوەست بە گرەوی', templateRef: 'tpl.mortgage.v1'),
    AuthorizedClause(id: 'RTO-01', category: 'rent_to_own', titleAr: 'إيجار تمليكي مدار', titleEn: 'Madar rent-to-own', titleKu: 'کرێ بۆ خاوەنداری مەدار', templateRef: 'tpl.rent_to_own.v1'),
    AuthorizedClause(id: 'PAY-01', category: 'payment', titleAr: 'شروط الدفع', titleEn: 'Payment terms', titleKu: 'مەرجەکانی پارەدان', templateRef: 'tpl.payment.v1'),
    AuthorizedClause(id: 'ESC-01', category: 'escrow', titleAr: 'شروط الضمان', titleEn: 'Escrow conditions', titleKu: 'مەرجەکانی ئێسکرۆ', templateRef: 'tpl.escrow.v1'),
    AuthorizedClause(id: 'OWN-01', category: 'ownership', titleAr: 'الملكية', titleEn: 'Ownership', titleKu: 'خاوەنداری', templateRef: 'tpl.ownership.v1'),
    AuthorizedClause(id: 'TAX-01', category: 'taxes', titleAr: 'الضرائب', titleEn: 'Taxes', titleKu: 'باج', templateRef: 'tpl.taxes.v1'),
    AuthorizedClause(id: 'DEF-01', category: 'default', titleAr: 'الإخلال', titleEn: 'Default', titleKu: 'سەرپێچی', templateRef: 'tpl.default.v1'),
    AuthorizedClause(id: 'CAN-01', category: 'cancellation', titleAr: 'الإلغاء', titleEn: 'Cancellation', titleKu: 'هەڵوەشاندنەوە', templateRef: 'tpl.cancellation.v1'),
    AuthorizedClause(id: 'SPC-01', category: 'special', titleAr: 'شروط خاصة', titleEn: 'Special conditions', titleKu: 'مەرجی تایبەت', templateRef: 'tpl.special.v1'),
  ];

  static const categoryOrder = [
    'general_sale',
    'residential',
    'commercial',
    'land',
    'agricultural',
    'investment',
    'mortgage',
    'rent_to_own',
    'payment',
    'escrow',
    'ownership',
    'taxes',
    'default',
    'cancellation',
    'special',
  ];

  static String categoryLabel(String key, {required String ar, required String en, required String ku, required String lang}) {
    return lang == 'ar' ? ar : lang == 'ku' ? ku : en;
  }
}

class ContractStructureCatalog {
  static const sectionIds = [
    'header',
    'parties',
    'definitions',
    'property',
    'ownership',
    'price',
    'payment',
    'taxes',
    'fees',
    'escrow',
    'condition',
    'delivery',
    'transfer',
    'buyer_duties',
    'seller_duties',
    'default',
    'cancellation',
    'dispute',
    'special',
    'signatures',
  ];

  static String title(String id, String lang) {
    const ar = {
      'header': 'ترويسة العقد',
      'parties': 'الأطراف',
      'definitions': 'التعريفات',
      'property': 'وصف العقار',
      'ownership': 'الملكية',
      'price': 'ثمن الشراء',
      'payment': 'شروط الدفع',
      'taxes': 'الضرائب',
      'fees': 'الرسوم',
      'escrow': 'شروط الضمان',
      'condition': 'حالة العقار',
      'delivery': 'شروط التسليم',
      'transfer': 'نقل الملكية',
      'buyer_duties': 'التزامات المشتري',
      'seller_duties': 'التزامات البائع',
      'default': 'الإخلال',
      'cancellation': 'الإلغاء',
      'dispute': 'تسوية النزاع',
      'special': 'شروط خاصة',
      'signatures': 'التواقيع',
    };
    const en = {
      'header': 'Contract header',
      'parties': 'Parties',
      'definitions': 'Definitions',
      'property': 'Property description',
      'ownership': 'Ownership',
      'price': 'Purchase price',
      'payment': 'Payment terms',
      'taxes': 'Taxes',
      'fees': 'Fees',
      'escrow': 'Escrow conditions',
      'condition': 'Property condition',
      'delivery': 'Delivery conditions',
      'transfer': 'Ownership transfer',
      'buyer_duties': 'Buyer responsibilities',
      'seller_duties': 'Seller responsibilities',
      'default': 'Default',
      'cancellation': 'Cancellation',
      'dispute': 'Dispute resolution',
      'special': 'Special conditions',
      'signatures': 'Signatures',
    };
    const ku = {
      'header': 'سەرپەڕەی گرێبەست',
      'parties': 'لایەنەکان',
      'definitions': 'پێناسەکان',
      'property': 'وەسفی موڵک',
      'ownership': 'خاوەنداری',
      'price': 'نرخی کڕین',
      'payment': 'مەرجەکانی پارەدان',
      'taxes': 'باج',
      'fees': 'کرێ',
      'escrow': 'مەرجەکانی ئێسکرۆ',
      'condition': 'دۆخی موڵک',
      'delivery': 'مەرجەکانی گەیاندن',
      'transfer': 'گواستنەوەی خاوەنداری',
      'buyer_duties': 'بەرپرسیارێتی کڕیار',
      'seller_duties': 'بەرپرسیارێتی فرۆشیار',
      'default': 'سەرپێچی',
      'cancellation': 'هەڵوەشاندنەوە',
      'dispute': 'چارەسەری ناکۆکی',
      'special': 'مەرجی تایبەت',
      'signatures': 'واژووەکان',
    };
    if (lang == 'ar') return ar[id] ?? id;
    if (lang == 'ku') return ku[id] ?? id;
    return en[id] ?? id;
  }
}
