import '../core/demo/demo_mode.dart';
import '../features/employee/core/domain/employee_models.dart';
import '../features/employee/core/domain/employee_permissions.dart';
import '../features/office/domain/enums/office_enums.dart';
import '../features/office/domain/models/office_models.dart';
import '../features/employee/publishing/domain/publishing_models.dart';
import 'property_catalog_demo.dart';

/// In-memory seed used when DEMO_ENTER_USER_UI is on and Supabase is empty.
abstract final class AppDemoSeed {
  static const officeId = 'demo-office-001';
  static const employeeId = 'demo-employee-001';
  static const userId = 'demo-user-local';

  static OfficeAccount officeAccount() {
    return const OfficeAccount(
      id: officeId,
      officeCode: DemoMode.officeCode,
      name: 'مكتب مدار — الكرادة',
      countryCode: 'IQ',
      currencyCode: 'IQD',
      address: 'شارع النضال، الكرادة، بغداد',
      phone: '+9647901234567',
      managerName: 'حسين العبودي',
      licenseNumber: 'IQ-OFF-88421',
    );
  }

  static EmployeeAccount employeeAccount() {
    return EmployeeAccount(
      id: employeeId,
      employeeCode: DemoMode.employeeCode,
      fullName: 'سارة عبد الكريم',
      jobTitle: 'مستشارة مبيعات',
      countryCode: 'IQ',
      branchCode: 'BGH',
      department: const EmployeeDepartment(
        id: 'dept-sales',
        code: 'sales',
        nameEn: 'Sales',
        nameAr: 'المبيعات',
      ),
      role: const EmployeeRole(
        id: 'role-sales',
        code: 'sales_advisor',
        nameEn: 'Sales Advisor',
        nameAr: 'مستشار مبيعات',
      ),
      permissions: {
        EmployeePermission.salesLeadsView,
        EmployeePermission.salesLeadsEdit,
        EmployeePermission.salesClientsView,
        EmployeePermission.salesHandoff,
        EmployeePermission.salesPropertyRequest,
        EmployeePermission.messagesView,
        EmployeePermission.messagesSend,
        EmployeePermission.propertyRead,
        EmployeePermission.publishingView,
        EmployeePermission.transactionsView,
        EmployeePermission.searchGlobal,
      },
    );
  }

  static Map<String, dynamic> userProfile() {
    return {
      'id': userId,
      'display_name': 'أحمد الراشدي',
      'first_name': 'أحمد',
      'last_name': 'الراشدي',
      'phone': '+9647901234567',
      'phone_e164': '+9647901234567',
      'account_status': 'active',
      'identity_verification_status': 'verified',
      'phone_verified': true,
      'country_code': 'IQ',
      'preferred_language': 'ar',
      'preferred_currency': 'IQD',
      'profile_photo_url':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    };
  }

  static List<Map<String, dynamic>> favoriteProperties() {
    final listings = PropertyCatalogDemo.listings().take(4).toList();
    return [
      for (final p in listings)
        {
          'property_id': p.id,
          'properties_v3': {
            'id': p.id,
            'title': p.title,
            'address': p.address,
            'asking_price_usd': p.price,
            'asking_price': p.price,
            'property_media_v3': [
              {'media_url': p.imageUrl},
            ],
            ...p.rawData,
          },
        },
    ];
  }

  static List<Map<String, dynamic>> savedSearches() {
    return [
      {
        'id': 'ss-1',
        'query': 'شقق في الكرادة',
        'filters': {'city': 'بغداد', 'type': 'apartment'},
        'saved_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
      {
        'id': 'ss-2',
        'query': 'فيلا المنصور',
        'filters': {'city': 'بغداد', 'type': 'villa'},
        'saved_at': DateTime.now()
            .subtract(const Duration(days: 4))
            .toIso8601String(),
      },
      {
        'id': 'ss-3',
        'query': 'إيجار قرب جامعة بغداد',
        'filters': {'city': 'بغداد', 'listingType': 'rent'},
        'saved_at': DateTime.now()
            .subtract(const Duration(days: 8))
            .toIso8601String(),
      },
    ];
  }

  static List<Map<String, dynamic>> userNotifications() {
    return [
      {
        'id': 'un-1',
        'title': 'انخفاض سعر في المنصور',
        'body': 'فيلا في المنصور انخفض سعرها — الآن 405,000\$',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 20))
            .toIso8601String(),
        'is_read': false,
      },
      {
        'id': 'un-2',
        'title': 'تطابق جديد لبحثك',
        'body': '3 شقق في الكرادة تطابق بحثك المحفوظ',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        'is_read': false,
      },
      {
        'id': 'un-3',
        'title': 'تحديث الصفقة',
        'body': 'الصفقة MADAR-IQ-2026-001 في مرحلة الإيداع الضماني',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 6))
            .toIso8601String(),
        'is_read': true,
      },
    ];
  }

  static List<Map<String, dynamic>> userTransactions() {
    return [
      {
        'id': 'demo_txn_001',
        'transaction_number': 'IQ-BGD-SALE-2026-000001',
        'reference_number': 'IQ-BGD-SALE-2026-000001',
        'property_id': 'prop_001',
        'property_address_snapshot': 'شارع النضال، الكرادة، بغداد',
        'transaction_type': 'sale',
        'country_code': 'IQ',
        'total_amount': 242350000.0,
        'currency_code': 'IQD',
        'lifecycle_state': 'escrow_pending',
        'status': 'escrow_pending',
        'current_step_key': 'escrow',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 16))
            .toIso8601String(),
        'buyer_name': 'أحمد الراشدي',
        'seller_name': 'مريم خليل',
        'buyer_phone': '+9647901234567',
        'seller_phone': '+9647907654321',
        'buyer_barcode_uploaded': true,
        'seller_barcode_uploaded': true,
        'buyer_identity_verified': true,
        'seller_identity_verified': true,
        'buyer_signed_contract': true,
        'seller_signed_contract': true,
        'barcode_code': 'IQ-BGD-SALE-2026-000001',
      },
      {
        'id': 'demo_txn_002',
        'transaction_number': 'IQ-BGD-RENT-2026-000014',
        'reference_number': 'IQ-BGD-RENT-2026-000014',
        'property_address_snapshot': 'زيونة، بغداد',
        'transaction_type': 'rent',
        'country_code': 'IQ',
        'total_amount': 3668000.0,
        'currency_code': 'IQD',
        'lifecycle_state': 'waiting_for_parties',
        'status': 'waiting_for_parties',
        'current_step_key': 'identity',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 3))
            .toIso8601String(),
        'buyer_name': 'ليث المنصور',
        'seller_name': 'شركة الرافدين',
        'buyer_phone': '+9647701112233',
        'seller_phone': '+9647709998877',
        'buyer_barcode_uploaded': false,
        'seller_barcode_uploaded': false,
        'barcode_code': 'IQ-BGD-RENT-2026-000014',
      },
      {
        'id': 'demo_txn_003',
        'transaction_number': 'IQ-BGD-AGRI-2026-000008',
        'reference_number': 'IQ-BGD-AGRI-2026-000008',
        'property_id': 'prop_015',
        'property_address_snapshot': 'اليوسفية، بغداد',
        'transaction_type': 'agricultural',
        'country_code': 'IQ',
        'total_amount': 288200000.0,
        'currency_code': 'IQD',
        'lifecycle_state': 'parties_verified',
        'status': 'parties_verified',
        'current_step_key': 'identity',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 5))
            .toIso8601String(),
        'buyer_name': 'حسين العبودي',
        'seller_name': 'فلاح اليوسفية',
        'buyer_phone': '+9647502223344',
        'seller_phone': '+9647505556677',
        'buyer_barcode_uploaded': true,
        'seller_barcode_uploaded': true,
        'barcode_code': 'IQ-BGD-AGRI-2026-000008',
      },
    ];
  }

  static Map<String, dynamic>? demoBarcode(String code) {
    final normalized = code.trim().toUpperCase();
    String? forcedRole;
    var lookup = normalized;
    if (normalized.startsWith('BUY-')) {
      forcedRole = 'buyer';
      lookup = normalized.substring(4);
    } else if (normalized.startsWith('SEL-') || normalized.startsWith('SELL-')) {
      forcedRole = 'seller';
      lookup = normalized.startsWith('SELL-')
          ? normalized.substring(5)
          : normalized.substring(4);
    }

    for (final tx in userTransactions()) {
      final bc = (tx['barcode_code'] ?? tx['transaction_number'])
          .toString()
          .toUpperCase();
      if (bc == normalized || bc == lookup || 'BUY-$bc' == normalized || 'SEL-$bc' == normalized) {
        return {
          'id': 'barcode-${tx['id']}-${forcedRole ?? 'party'}',
          'barcode_code': normalized,
          'participant_role': forcedRole,
          'transaction_id': tx['id'],
          'buyer_phone': tx['buyer_phone'],
          'seller_phone': tx['seller_phone'],
          'transactions': tx,
          'buyer_redeemed_at': tx['buyer_barcode_uploaded'] == true
              ? DateTime.now().toIso8601String()
              : null,
          'seller_redeemed_at': tx['seller_barcode_uploaded'] == true
              ? DateTime.now().toIso8601String()
              : null,
        };
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> userProperties() {
    return [
      {
        'id': 'mine-1',
        'title': 'شقتي في الجادرية',
        'title_ar': 'شقتي في الجادرية',
        'title_en': 'My apartment in Jadiriya',
        'title_ku': 'شوقەکەم لە جادریە',
        'address': 'الجادرية، بغداد',
        'address_ar': 'الجادرية، بغداد',
        'address_en': 'Jadiriya, Baghdad',
        'address_ku': 'جادریە، بەغدا',
        'asking_price_usd': 210000,
        'status': 'active',
        'listing_type': 'sale',
        'area': 145,
        'bedrooms': 3,
        'property_type': 'apartment',
        'insights': ['photos', 'kitchen'],
        'imageUrl':
            'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
      },
      {
        'id': 'mine-2',
        'title': 'محل تجاري — زيونة',
        'title_ar': 'محل تجاري — زيونة',
        'title_en': 'Retail unit — Zayouna',
        'title_ku': 'فرۆشگای بازرگانی — زیوونە',
        'address': 'زيونة، بغداد',
        'address_ar': 'زيونة، بغداد',
        'address_en': 'Zayouna, Baghdad',
        'address_ku': 'زیوونە، بەغدا',
        'asking_price_usd': 160000,
        'status': 'active',
        'listing_type': 'managed',
        'monthly_income_usd': 850,
        'management_fee_usd': 120,
        'area': 86,
        'bedrooms': 0,
        'property_type': 'commercial',
        'imageUrl':
            'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
      },
    ];
  }

  static List<Map<String, dynamic>> propertySubmissions() {
    return [
      {
        'id': 'sub-1',
        'title': 'فيلا الحارثية',
        'title_ar': 'فيلا الحارثية',
        'title_en': 'Harthiya villa',
        'title_ku': 'ڤێلای حارسیە',
        'address': 'الحارثية، بغداد',
        'address_ar': 'الحارثية، بغداد',
        'address_en': 'Harthiya, Baghdad',
        'address_ku': 'حارسیە، بەغدا',
        'property_type': 'villa',
        'status': 'under_review',
        'listing_type': 'sale',
        'asking_price_usd': 380000,
        'area': 320,
        'bedrooms': 5,
        'insights': ['deed'],
        'imageUrl':
            'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
      },
    ];
  }

  static List<Map<String, dynamic>> messagesFor(String conversationId) {
    switch (conversationId) {
      case 'support':
        return [
          {
            'content': 'مرحباً، كيف يمكنني مساعدتك اليوم؟',
            'sender_type': 'support',
            'created_at': DateTime.now()
                .subtract(const Duration(hours: 5))
                .toIso8601String(),
          },
          {
            'content': 'أريد معرفة حالة طلبي لنشر العقار.',
            'sender_type': 'user',
            'created_at': DateTime.now()
                .subtract(const Duration(hours: 4))
                .toIso8601String(),
          },
          {
            'content':
                'طلبك قيد المراجعة من فريق المعلومات. سنخبرك خلال 24 ساعة.',
            'sender_type': 'support',
            'created_at': DateTime.now()
                .subtract(const Duration(hours: 3))
                .toIso8601String(),
          },
        ];
      case 'sales':
        return [
          {
            'content': 'شاهدنا اهتمامك بشقة الكرادة. هل تفضّل معاينة غداً؟',
            'sender_type': 'sales',
            'created_at': DateTime.now()
                .subtract(const Duration(hours: 8))
                .toIso8601String(),
          },
          {
            'content': 'نعم، بعد العصر مناسب.',
            'sender_type': 'user',
            'created_at': DateTime.now()
                .subtract(const Duration(hours: 7))
                .toIso8601String(),
          },
        ];
      case 'closing':
        return [
          {
            'content': 'تم تجهيز مسودة العقد. راجعها قبل التوقيع.',
            'sender_type': 'closing',
            'created_at': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
          },
        ];
      case 'agent':
        return [
          {
            'content': 'المستمسكات جاهزة للنقل بعد تأكيد الإيداع.',
            'sender_type': 'agent',
            'created_at': DateTime.now()
                .subtract(const Duration(days: 2))
                .toIso8601String(),
          },
        ];
      default:
        return [];
    }
  }

  static List<OfficeReferral> officeReferrals() {
    return [
      OfficeReferral(
        id: 'ref-1',
        officeId: officeId,
        propertyId: 'prop_001',
        status: OfficeReferralStatus.negotiating,
        buyerPhone: '+9647701112233',
        message: 'مشتري جاهز لمعاينة شقة الكرادة',
        conversationId: 'oc-1',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      OfficeReferral(
        id: 'ref-2',
        officeId: officeId,
        propertyId: 'prop_002',
        status: OfficeReferralStatus.qualified,
        buyerPhone: '+9647509988776',
        message: 'مهتم بفيلا المنصور',
        conversationId: 'oc-2',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      OfficeReferral(
        id: 'ref-3',
        officeId: officeId,
        propertyId: 'prop_005',
        status: OfficeReferralStatus.neu,
        buyerPhone: '+9647812345678',
        message: 'طلب تمويل لتاون هاوس الجادرية',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  static List<OfficePropertyReport> officeReports() {
    return [
      OfficePropertyReport(
        id: 'or-1',
        officeId: officeId,
        status: OfficeReportStatus.underReview,
        propertyType: 'apartment',
        listingType: 'sale',
        addressText: 'الكرادة خارج، بغداد',
        ownerPhone: '+9647905551122',
        estimatedPrice: 165000,
        notes: 'شقة جديدة قرب المستشفى',
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      ),
      OfficePropertyReport(
        id: 'or-2',
        officeId: officeId,
        status: OfficeReportStatus.contactingOwner,
        propertyType: 'villa',
        listingType: 'sale',
        addressText: 'المنصور، بغداد',
        ownerPhone: '+9647702223344',
        estimatedPrice: 390000,
        notes: 'فيلا مع حديقة',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  static List<OfficeConversation> officeConversations() {
    return [
      OfficeConversation(
        id: 'oc-1',
        officeId: officeId,
        teamKey: 'office_management',
        propertyId: 'prop_001',
        referralId: 'ref-1',
        title: 'مشتري — شقة الكرادة',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 40)),
      ),
      OfficeConversation(
        id: 'oc-2',
        officeId: officeId,
        teamKey: 'sales',
        propertyId: 'prop_002',
        referralId: 'ref-2',
        title: 'فيلا المنصور — تفاوض',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }

  static List<OfficeMessage> officeMessages(String conversationId) {
    return [
      OfficeMessage(
        id: 'om-1',
        conversationId: conversationId,
        senderSide: 'office',
        messageType: 'text',
        body: 'لدينا مشتري جاد لهذا العقار.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      OfficeMessage(
        id: 'om-2',
        conversationId: conversationId,
        senderSide: 'madar',
        messageType: 'text',
        body: 'تم استلام الإحالة. فريق المبيعات سيتابع خلال ساعة.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  static OfficeSalesSummary officeSalesSummary() {
    return const OfficeSalesSummary(
      salesThisMonth: 7,
      completed: 3,
      inProgress: 3,
      awaitingParties: 1,
    );
  }

  static List<Map<String, dynamic>> officeTransactions() {
    return userTransactions()
        .map((t) => {...t, 'created_by_office_id': officeId})
        .toList();
  }

  static List<Map<String, dynamic>> officeAssignedProperties() {
    return [
      for (final p in PropertyCatalogDemo.listings().take(6))
        {
          'property_id': p.id,
          'status': p.isFeatured ? 'active' : 'pending_review',
          'updated_at': DateTime.now().toIso8601String(),
        },
    ];
  }

  static Map<String, dynamic>? propertyById(String id) {
    for (final p in PropertyCatalogDemo.listings()) {
      if (p.id == id) {
        return {
          ...p.rawData,
          'id': p.id,
          'title': p.title,
          'address': p.address,
          'asking_price': p.price,
          'asking_price_usd': p.price,
          'property_media_v3': [
            {'media_url': p.imageUrl},
          ],
        };
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> officeNotifications() {
    return [
      {
        'id': 'on-1',
        'title': 'إحالة جديدة',
        'body': 'مشتري مهتم بشقة الكرادة',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 25))
            .toIso8601String(),
        'read_at': null,
      },
      {
        'id': 'on-2',
        'title': 'تحديث صفقة',
        'body': 'MADAR-IQ-2026-001 بانتظار الإيداع',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 4))
            .toIso8601String(),
        'read_at': DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
      },
    ];
  }

  static List<Map<String, dynamic>> officeDocuments() {
    return [
      {
        'id': 'od-1',
        'title': 'عقد بيع — شقة الكرادة',
        'document_type': 'sale_contract',
      },
      {
        'id': 'od-2',
        'title': 'هوية المالك — فيلا المنصور',
        'document_type': 'identity',
      },
      {
        'id': 'od-3',
        'title': 'سند العقار — الجادرية',
        'document_type': 'title_deed',
      },
    ];
  }

  static List<Map<String, dynamic>> employeeNotifications() {
    return [
      {
        'id': 'en-1',
        'title': 'متابعة اليوم',
        'body': 'لديك 3 متابعات مع عملاء الكرادة',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 15))
            .toIso8601String(),
        'read_at': null,
      },
      {
        'id': 'en-2',
        'title': 'عميل جاهز للإغلاق',
        'body': 'ليث المنصور أكمل المستمسكات',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
        'read_at': null,
      },
      {
        'id': 'en-3',
        'title': 'طلب نشر جديد',
        'body': 'مكتب الكرادة أرسل عقاراً جديداً',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 9))
            .toIso8601String(),
        'read_at': DateTime.now().toIso8601String(),
      },
    ];
  }

  static List<Map<String, dynamic>> employeeConversations() {
    return [
      {
        'id': 'ec-1',
        'title': 'فريق المبيعات — بغداد',
        'department_code': 'sales',
        'created_by_employee_id': employeeId,
        'last_message_at': DateTime.now()
            .subtract(const Duration(minutes: 50))
            .toIso8601String(),
      },
      {
        'id': 'ec-2',
        'title': 'إغلاق صفقة الكرادة',
        'department_code': 'closing',
        'created_by_employee_id': employeeId,
        'last_message_at': DateTime.now()
            .subtract(const Duration(hours: 6))
            .toIso8601String(),
      },
    ];
  }

  static List<Map<String, dynamic>> salesLeads() {
    return [
      {
        'id': 'lead-1',
        'full_name': 'ليث المنصور',
        'phone': '+9647701112233',
        'status': 'negotiating',
        'lead_type': 'buyer',
        'preferred_area': 'الكرادة',
        'budget_text': '180-220 ألف دولار',
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'lead-2',
        'full_name': 'هدى الجبوري',
        'phone': '+9647509988776',
        'status': 'contacted',
        'lead_type': 'buyer',
        'preferred_area': 'المنصور',
        'budget_text': '350-450 ألف دولار',
        'updated_at': DateTime.now()
            .subtract(const Duration(hours: 5))
            .toIso8601String(),
      },
      {
        'id': 'lead-3',
        'full_name': 'شركة النور',
        'phone': '+9647812345678',
        'status': 'ready_for_closing',
        'lead_type': 'tenant',
        'preferred_area': 'زيونة',
        'budget_text': '2,500\$ / شهر',
        'updated_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
      {
        'id': 'lead-4',
        'full_name': 'علي كاظم',
        'phone': '+9647904445566',
        'status': 'new',
        'lead_type': 'buyer',
        'preferred_area': 'الجادرية',
        'budget_text': 'حتى 280 ألف',
        'updated_at': DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
      },
    ];
  }

  static List<Map<String, dynamic>> salesFollowUps() {
    return [
      {
        'id': 'fu-1',
        'due_at': DateTime.now()
            .add(const Duration(hours: 2))
            .toIso8601String(),
        'note': 'اتصال لمعاينة الكرادة',
        'sales_leads': {'full_name': 'ليث المنصور'},
      },
      {
        'id': 'fu-2',
        'due_at': DateTime.now()
            .add(const Duration(hours: 5))
            .toIso8601String(),
        'note': 'إرسال صور فيلا المنصور',
        'sales_leads': {'full_name': 'هدى الجبوري'},
      },
    ];
  }

  static List<PropertyAsset> publishingAssets() {
    return [
      PropertyAsset.fromMap({
        'id': 'pa-1',
        'public_property_id': '88421011',
        'pipeline_status': 'information_collection',
        'property_type': 'apartment',
        'transaction_type': 'sale',
        'owner_name': 'مريم خليل',
        'city': 'بغداد',
        'address_text': 'الكرادة، بغداد',
        'information_pct': 40,
        'photography_pct': 0,
        'three_d_pct': 0,
        'floor_plan_pct': 0,
        'is_published': false,
        'updated_at': DateTime.now().toIso8601String(),
      }),
      PropertyAsset.fromMap({
        'id': 'pa-2',
        'public_property_id': '88421022',
        'pipeline_status': 'photography',
        'property_type': 'villa',
        'transaction_type': 'sale',
        'owner_name': 'حسين العبودي',
        'city': 'بغداد',
        'address_text': 'المنصور، بغداد',
        'information_pct': 100,
        'photography_pct': 60,
        'three_d_pct': 20,
        'floor_plan_pct': 0,
        'is_published': false,
        'updated_at': DateTime.now()
            .subtract(const Duration(hours: 8))
            .toIso8601String(),
      }),
      PropertyAsset.fromMap({
        'id': 'pa-3',
        'public_property_id': '88421033',
        'pipeline_status': 'ready_for_publication',
        'property_type': 'apartment',
        'transaction_type': 'rent',
        'owner_name': 'ليث المنصور',
        'city': 'بغداد',
        'address_text': 'الجادرية، بغداد',
        'information_pct': 100,
        'photography_pct': 100,
        'three_d_pct': 100,
        'floor_plan_pct': 100,
        'is_published': false,
        'updated_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      }),
      PropertyAsset.fromMap({
        'id': 'pa-4',
        'public_property_id': '88421044',
        'pipeline_status': 'published',
        'property_type': 'villa',
        'transaction_type': 'sale',
        'owner_name': 'سارة عبد الكريم',
        'city': 'بغداد',
        'address_text': 'الجادرية، بغداد',
        'information_pct': 100,
        'photography_pct': 100,
        'three_d_pct': 100,
        'floor_plan_pct': 100,
        'is_published': true,
        'published_at': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }),
    ];
  }

  static List<Map<String, dynamic>> publishingTimeline(String assetId) {
    return [
      {
        'id': 'ev-1',
        'property_asset_id': assetId,
        'event_type': 'request_created',
        'note': 'تم إنشاء طلب النشر',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 3))
            .toIso8601String(),
      },
      {
        'id': 'ev-2',
        'property_asset_id': assetId,
        'event_type': 'information_started',
        'note': 'بدأ جمع المعلومات الميدانية',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
    ];
  }
}
