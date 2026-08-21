import '../features/office/domain/models/office_models.dart';
import '../features/office/domain/enums/office_enums.dart';

/// Local office preview seed so the office portal can be explored without
/// live Supabase office credentials. Credentials: [code] / [secret].
abstract final class OfficeSeed {
  static const String code = 'OFF001';
  static const String displayCode = 'OFF-2048';
  static const String secret = '123456';
  static const String token = 'seed-office-token';
  static const String officeId = 'seed-office-001';

  /// Mutable seed conversation threads (Found Buyer + chat send).
  static final List<OfficeConversation> _extraConversations = [];
  static final Map<String, List<OfficeMessage>> _extraMessages = {};
  static final List<OfficeReferral> _extraReferrals = [];

  static bool matches(String officeCode, String secretCode) {
    final c = officeCode.trim().toUpperCase().replaceAll(' ', '');
    return (c == code || c == displayCode || c == 'OFF2048') &&
        secretCode == secret;
  }

  static bool isSeedToken(String? token) => token == OfficeSeed.token;

  static OfficeAccount account() {
    return const OfficeAccount(
      id: officeId,
      officeCode: displayCode,
      name: 'مركز مدار بغداد',
      countryCode: 'IQ',
      currencyCode: 'IQD',
      address: 'شارع النضال، الكرادة، بغداد',
      phone: '+9647901234567',
      managerName: 'حسين العبودي',
      licenseNumber: 'IQ-OFF-88421',
      status: OfficeStatus.active,
    );
  }

  static OfficeSession session() {
    return OfficeSession(token: token, office: account());
  }

  static OfficeSalesSummary salesSummary() {
    return const OfficeSalesSummary(
      salesThisMonth: 7,
      completed: 3,
      inProgress: 2,
      awaitingParties: 2,
    );
  }

  /// Discoverable listings for the office map/home (Baghdad area).
  static List<Map<String, dynamic>> discoverableProperties() {
    return [
      _listing(
        id: 'seed-prop-001',
        title: 'شقة فاخرة — الكرادة',
        address: 'الكرادة، بغداد',
        city: 'بغداد',
        district: 'الكرادة',
        price: 185000,
        area: 145,
        beds: 3,
        baths: 2,
        type: 'apartment',
        listing: 'sale',
        lat: 33.3020,
        lng: 44.4250,
        image:
            'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
        featured: true,
      ),
      _listing(
        id: 'seed-prop-002',
        title: 'فيلا حديثة — المنصور',
        address: 'المنصور، بغداد',
        city: 'بغداد',
        district: 'المنصور',
        price: 420000,
        area: 380,
        beds: 5,
        baths: 4,
        type: 'villa',
        listing: 'sale',
        lat: 33.3152,
        lng: 44.3661,
        image:
            'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
        featured: true,
      ),
      _listing(
        id: 'seed-prop-003',
        title: 'شقة للإيجار — الجادرية',
        address: 'الجادرية، بغداد',
        city: 'بغداد',
        district: 'الجادرية',
        price: 850,
        area: 120,
        beds: 2,
        baths: 2,
        type: 'apartment',
        listing: 'rent',
        lat: 33.2780,
        lng: 44.3880,
        image:
            'https://images.unsplash.com/photo-1560448204-e02f11c3be0e?w=800',
      ),
      _listing(
        id: 'seed-prop-004',
        title: 'أرض سكنية — زيونة',
        address: 'زيونة، بغداد',
        city: 'بغداد',
        district: 'زيونة',
        price: 210000,
        area: 250,
        beds: 0,
        baths: 0,
        type: 'land',
        listing: 'sale',
        lat: 33.3400,
        lng: 44.4500,
        image:
            'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800',
      ),
      _listing(
        id: 'seed-prop-005',
        title: 'محل تجاري — الكرادة خارج',
        address: 'الكرادة خارج، بغداد',
        city: 'بغداد',
        district: 'الكرادة',
        price: 160000,
        area: 86,
        beds: 0,
        baths: 1,
        type: 'commercial',
        listing: 'sale',
        lat: 33.2985,
        lng: 44.4320,
        image:
            'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
      ),
    ];
  }

  static List<Map<String, dynamic>> assignedProperties() {
    return discoverableProperties().take(3).map((p) {
      return {
        'id': 'assigned-${p['id']}',
        'office_id': officeId,
        'property_id': p['id'],
        'status': 'active',
        'updated_at': DateTime.now().toIso8601String(),
        'properties_v3': p,
      };
    }).toList();
  }

  static List<Map<String, dynamic>> transactions() {
    return [
      {
        'id': 'seed-txn-001',
        'transaction_number': 'IQ-BGD-SALE-2026-000041',
        'property_id': 'seed-prop-001',
        'property_address_snapshot': 'الكرادة، بغداد',
        'transaction_type': 'sale',
        'country_code': 'IQ',
        'total_amount': 185000.0,
        'currency_code': 'USD',
        'lifecycle_state': 'in_progress',
        'status': 'in_progress',
        'created_by_office_id': officeId,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
        'buyer_name': 'أحمد الراشدي',
        'seller_name': 'نور الساعدي',
        'buyer_phone': '+9647701112233',
        'seller_phone': '+9647709998877',
      },
      {
        'id': 'seed-txn-002',
        'transaction_number': 'IQ-BGD-RENT-2026-000014',
        'property_id': 'seed-prop-003',
        'property_address_snapshot': 'الجادرية، بغداد',
        'transaction_type': 'rent',
        'country_code': 'IQ',
        'total_amount': 850.0,
        'currency_code': 'USD',
        'lifecycle_state': 'waiting_for_parties',
        'status': 'waiting_for_parties',
        'created_by_office_id': officeId,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        'buyer_name': 'ليث المنصور',
        'seller_name': 'شركة الرافدين',
        'buyer_phone': '+9647502223344',
        'seller_phone': '+9647505556677',
      },
      {
        'id': 'seed-txn-003',
        'transaction_number': 'IQ-BGD-SALE-2026-000038',
        'property_id': 'seed-prop-002',
        'property_address_snapshot': 'المنصور، بغداد',
        'transaction_type': 'sale',
        'country_code': 'IQ',
        'total_amount': 420000.0,
        'currency_code': 'USD',
        'lifecycle_state': 'completed',
        'status': 'completed',
        'created_by_office_id': officeId,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 12))
            .toIso8601String(),
        'buyer_name': 'سارة عبد الكريم',
        'seller_name': 'حسين العبودي',
        'buyer_phone': '+9647803334455',
        'seller_phone': '+9647901234567',
      },
    ];
  }

  static List<OfficeReferral> referrals() {
    return [
      OfficeReferral(
        id: 'seed-ref-001',
        officeId: officeId,
        propertyId: 'seed-prop-001',
        status: OfficeReferralStatus.neu,
        buyerPhone: '+9647701112233',
        message: 'لدي مشتري مهتم بشقة الكرادة.',
        conversationId: 'seed-conv-001',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      OfficeReferral(
        id: 'seed-ref-002',
        officeId: officeId,
        propertyId: 'seed-prop-002',
        status: OfficeReferralStatus.contacting,
        buyerPhone: '+9647803334455',
        message: 'طلب معاينة فيلا المنصور.',
        conversationId: 'seed-conv-002',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ..._extraReferrals,
    ];
  }

  static List<OfficeConversation> conversations() {
    return [
      OfficeConversation(
        id: 'seed-conv-001',
        officeId: officeId,
        teamKey: 'office_management',
        title: 'مشتري — شقة الكرادة',
        propertyId: 'seed-prop-001',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      OfficeConversation(
        id: 'seed-conv-002',
        officeId: officeId,
        teamKey: 'sales',
        title: 'معاينة — فيلا المنصور',
        propertyId: 'seed-prop-002',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      ..._extraConversations,
    ];
  }

  static List<OfficeMessage> messagesFor(String conversationId) {
    if (_extraMessages.containsKey(conversationId)) {
      return List<OfficeMessage>.from(_extraMessages[conversationId]!);
    }
    return [
      OfficeMessage(
        id: 'm1',
        conversationId: conversationId,
        senderSide: 'office',
        messageType: 'text',
        body: 'مرحباً، لدينا عميل مهتم بهذا العقار.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      OfficeMessage(
        id: 'm2',
        conversationId: conversationId,
        senderSide: 'madar',
        messageType: 'text',
        body: 'تم استلام الطلب. سنراجع التفاصيل ونعود إليكم.',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      OfficeMessage(
        id: 'm3',
        conversationId: conversationId,
        senderSide: 'office',
        messageType: 'text',
        body: 'هل يمكن جدولة معاينة غداً بعد العصر؟',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  static void appendSeedMessage({
    required String conversationId,
    required String body,
  }) {
    final list = _extraMessages.putIfAbsent(
      conversationId,
      () => List<OfficeMessage>.from(messagesFor(conversationId)),
    );
    // If we just copied defaults into extras, fine; then append.
    if (!_extraMessages.containsKey(conversationId)) {
      // unreachable due to putIfAbsent
    }
    // Ensure we don't double-seed defaults every time: only seed once.
    list.add(
      OfficeMessage(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        senderSide: 'office',
        messageType: 'text',
        body: body,
        createdAt: DateTime.now(),
      ),
    );
  }

  static OfficeReferral createFoundBuyer({
    required String propertyId,
    String? buyerPhone,
    String? message,
  }) {
    final convId = 'seed-conv-fb-${DateTime.now().millisecondsSinceEpoch}';
    final refId = 'seed-ref-fb-${DateTime.now().millisecondsSinceEpoch}';
    final conv = OfficeConversation(
      id: convId,
      officeId: officeId,
      teamKey: 'office_management',
      title: 'وجدت مشتريًا — #$propertyId',
      propertyId: propertyId,
      lastMessageAt: DateTime.now(),
    );
    _extraConversations.insert(0, conv);
    final body = message ??
        'لدينا مشتري مهتم بهذا العقار. الهاتف: ${buyerPhone ?? '—'}';
    _extraMessages[convId] = [
      OfficeMessage(
        id: 'fb-1',
        conversationId: convId,
        senderSide: 'office',
        messageType: 'property_card',
        body: body,
        propertyId: propertyId,
        createdAt: DateTime.now(),
      ),
      OfficeMessage(
        id: 'fb-2',
        conversationId: convId,
        senderSide: 'office',
        messageType: 'text',
        body: body,
        propertyId: propertyId,
        createdAt: DateTime.now(),
      ),
      OfficeMessage(
        id: 'fb-3',
        conversationId: convId,
        senderSide: 'madar',
        messageType: 'text',
        body: 'تم استلام طلب المشتري. فريق إدارة المكاتب سيتابع معكم.',
        createdAt: DateTime.now().add(const Duration(seconds: 1)),
      ),
    ];
    final referral = OfficeReferral(
      id: refId,
      officeId: officeId,
      propertyId: propertyId,
      status: OfficeReferralStatus.neu,
      buyerPhone: buyerPhone,
      message: body,
      conversationId: convId,
      createdAt: DateTime.now(),
    );
    _extraReferrals.insert(0, referral);
    return referral;
  }

  static List<Map<String, dynamic>> notifications() {
    return [
      {
        'id': 'seed-n1',
        'title': 'صفقة جديدة قيد الانتظار',
        'body': 'بانتظار رفع باركود المشتري لصفقة الكرادة.',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
        'read': false,
      },
      {
        'id': 'seed-n2',
        'title': 'إحالة مشتري',
        'body': 'تم فتح محادثة إدارة لمشتري شقة الكرادة.',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 6))
            .toIso8601String(),
        'read': true,
      },
    ];
  }

  static Map<String, dynamic> _listing({
    required String id,
    required String title,
    required String address,
    required String city,
    required String district,
    required double price,
    required double area,
    required int beds,
    required int baths,
    required String type,
    required String listing,
    required double lat,
    required double lng,
    required String image,
    bool featured = false,
  }) {
    return {
      'id': id,
      'title': title,
      'title_ar': title,
      'address_text': address,
      'city': city,
      'district': district,
      'asking_price_usd': price,
      'asking_price': price,
      'currency_code': 'USD',
      'built_up_area_sqm': area,
      'area': area,
      'bedrooms': beds,
      'bathrooms': baths,
      'property_type': type,
      'listing_type': listing,
      'latitude': lat,
      'longitude': lng,
      'is_verified': true,
      'is_featured': featured,
      'description': title,
      'property_media_v3': [
        {'media_url': image},
      ],
      'property_features_v3': [
        {'feature_name': 'موقف سيارات'},
        {'feature_name': 'تكييف'},
      ],
    };
  }
}
