import '../features/employee/core/domain/employee_models.dart';
import '../features/employee/core/domain/employee_permissions.dart';
import '../features/employee/publishing/domain/publisher_ops_models.dart';
import '../features/employee/publishing/domain/publishing_models.dart';

/// Local publisher (publishing dept) preview seed.
/// Credentials: [code] / [secret].
abstract final class PublisherSeed {
  static const String code = 'PUB001';
  static const String secret = '123456';
  static const String token = 'seed-publisher-token';
  static const String employeeId = 'seed-publisher-001';

  /// Session-created assets (create request flow).
  static final List<PropertyAsset> _live = [];

  static bool matches(String employeeCode, String secretCode) {
    return employeeCode.trim().toUpperCase() == code &&
        secretCode == secret;
  }

  static bool isSeedToken(String? t) => t == token;

  static EmployeeAccount account() {
    return EmployeeAccount(
      id: employeeId,
      employeeCode: code,
      fullName: 'نور الكاظم',
      jobTitle: 'Property Publisher',
      countryCode: 'IQ',
      branchCode: 'BGH',
      employmentStatus: 'active',
      department: const EmployeeDepartment(
        id: 'dept-publishing',
        code: 'publishing',
        nameEn: 'Publishing',
        nameAr: 'النشر',
      ),
      role: const EmployeeRole(
        id: 'role-publisher',
        code: 'publisher',
        nameEn: 'Property Publisher',
        nameAr: 'ناشر عقارات',
      ),
      permissions: {
        EmployeePermission.publishingView,
        EmployeePermission.publishingCreate,
        EmployeePermission.publishingAssign,
        EmployeePermission.publishingEdit,
        EmployeePermission.publishingReview,
        EmployeePermission.publishingPublish,
        EmployeePermission.informationView,
        EmployeePermission.informationEdit,
        EmployeePermission.informationSubmit,
        EmployeePermission.mediaView,
        EmployeePermission.mediaUpload,
        EmployeePermission.mediaSubmit,
        EmployeePermission.engineeringView,
        EmployeePermission.engineeringEdit,
        EmployeePermission.engineeringSubmit,
        EmployeePermission.propertiesView,
        EmployeePermission.propertiesAssign,
        EmployeePermission.propertiesPublishRequest,
        EmployeePermission.propertyRead,
        EmployeePermission.propertyEdit,
        EmployeePermission.propertyPublish,
        EmployeePermission.messagesView,
        EmployeePermission.messagesSend,
        EmployeePermission.searchGlobal,
        EmployeePermission.reportsView,
      },
    );
  }

  static EmployeeSession session() {
    return EmployeeSession(token: token, employee: account());
  }

  static List<PropertyAsset> allAssets() => [..._live, ...assets()];

  static void registerLive(PropertyAsset asset) {
    _live.insert(0, asset);
  }

  static OfficeLookupResult? lookupOffice(String code) {
    final c = code.trim().toUpperCase().replaceAll(' ', '');
    final map = {
      'OFF001': const OfficeLookupResult(
        code: 'OFF001',
        name: 'مكتب مدار — الكرادة',
        id: 'seed-office-001',
        ownerName: 'حسين العبودي',
        region: 'Baghdad · Karrada',
        status: 'Active',
      ),
      'OFC-88421': const OfficeLookupResult(
        code: 'OFC-88421',
        name: 'Al-Rafidain Realty',
        id: 'seed-office-002',
        ownerName: 'سارة عبد الكريم',
        region: 'Baghdad · Mansour',
        status: 'Active',
      ),
      'OFC-1024': const OfficeLookupResult(
        code: 'OFC-1024',
        name: 'Jadriya Partners',
        id: 'seed-office-003',
        ownerName: 'ليث المنصور',
        region: 'Baghdad · Jadriya',
        status: 'Active',
      ),
    };
    return map[c];
  }

  static UserLookupResult? lookupUser({String? phone, String? userId}) {
    final users = [
      const UserLookupResult(
        id: 'USR-10021',
        name: 'أحمد الراشدي',
        phone: '+9647701112233',
        location: 'Baghdad',
      ),
      const UserLookupResult(
        id: 'USR-10044',
        name: 'مريم خليل',
        phone: '+9647803334455',
        location: 'Baghdad · Karrada',
      ),
      const UserLookupResult(
        id: 'USR-10088',
        name: 'نور الساعدي',
        phone: '+9647502223344',
        location: 'Baghdad · Mansour',
      ),
    ];
    if (userId != null && userId.trim().isNotEmpty) {
      final id = userId.trim().toUpperCase();
      for (final u in users) {
        if (u.id == id) return u;
      }
    }
    if (phone != null && phone.trim().isNotEmpty) {
      final p = phone.replaceAll(RegExp(r'[^\d+]'), '');
      for (final u in users) {
        final up = u.phone.replaceAll(RegExp(r'[^\d+]'), '');
        if (up.endsWith(p) || p.endsWith(up) || up == p) return u;
      }
    }
    return null;
  }

  static String nextPublicId() {
    final n = 48000000 + (DateTime.now().millisecondsSinceEpoch % 9999999);
    return n.toString().padLeft(8, '0').substring(0, 8);
  }

  static List<PropertyAsset> assets() {
    return [
      PropertyAsset.fromMap({
        'id': 'pa-1',
        'public_property_id': '88421011',
        'title': 'The Opus Tower Residences',
        'pipeline_status': 'ready_for_publication',
        'market_status': 'active',
        'property_type': 'apartment',
        'transaction_type': 'sale',
        'owner_name': 'مريم خليل',
        'owner_phone': '+9647701112233',
        'city': 'بغداد',
        'address_text': 'Downtown Commercial Hub, Block B',
        'asking_price': 2450000,
        'currency_code': 'USD',
        'cover_image_url':
            'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=600',
        'information_pct': 100,
        'photography_pct': 100,
        'three_d_pct': 80,
        'floor_plan_pct': 100,
        'is_published': false,
        'priority': 'high',
        'updated_at': DateTime.now().toIso8601String(),
      }),
      PropertyAsset.fromMap({
        'id': 'pa-2',
        'public_property_id': '88421022',
        'title': 'Horizon Executive Suites',
        'pipeline_status': 'photography',
        'market_status': 'pending',
        'property_type': 'commercial',
        'transaction_type': 'rent',
        'owner_name': 'حسين العبودي',
        'owner_phone': '+9647901234567',
        'city': 'بغداد',
        'address_text': 'Financial District, Level 42',
        'asking_price': 185000,
        'currency_code': 'USD',
        'cover_image_url':
            'https://images.unsplash.com/photo-1497366216548-37526070297c?w=600',
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
        'title': 'Logistics Park Alpha',
        'pipeline_status': 'published',
        'market_status': 'sold',
        'property_type': 'commercial',
        'transaction_type': 'sale',
        'owner_name': 'ليث المنصور',
        'owner_phone': '+9647502223344',
        'city': 'بغداد',
        'address_text': 'North Industrial Zone, Plot 7',
        'asking_price': 5200000,
        'currency_code': 'USD',
        'cover_image_url':
            'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=600',
        'information_pct': 100,
        'photography_pct': 100,
        'three_d_pct': 100,
        'floor_plan_pct': 100,
        'is_published': true,
        'published_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        'updated_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      }),
      PropertyAsset.fromMap({
        'id': 'pa-4',
        'public_property_id': '88421044',
        'title': 'Jadriya Riverside Villa',
        'pipeline_status': 'ready_for_publication',
        'market_status': 'active',
        'property_type': 'villa',
        'transaction_type': 'sale',
        'owner_name': 'سارة عبد الكريم',
        'owner_phone': '+9647803334455',
        'city': 'بغداد',
        'address_text': 'الجادرية، بغداد',
        'asking_price': 980000,
        'currency_code': 'USD',
        'cover_image_url':
            'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600',
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
      PropertyAsset.fromMap({
        'id': 'pa-5',
        'public_property_id': '88421055',
        'title': 'Zayouna Commercial Plot',
        'pipeline_status': 'request_created',
        'market_status': 'pending',
        'property_type': 'commercial',
        'transaction_type': 'sale',
        'owner_name': 'شركة الرافدين',
        'owner_phone': '+9647709998877',
        'city': 'بغداد',
        'address_text': 'زيونة، بغداد',
        'asking_price': 640000,
        'currency_code': 'USD',
        'cover_image_url':
            'https://images.unsplash.com/photo-1486406149798-0bffdeec1d4e?w=600',
        'information_pct': 0,
        'photography_pct': 0,
        'three_d_pct': 0,
        'floor_plan_pct': 0,
        'is_published': false,
        'priority': 'normal',
        'updated_at': DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
      }),
    ];
  }

  static List<Map<String, dynamic>> timeline(String assetId) {
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
      {
        'id': 'ev-3',
        'property_asset_id': assetId,
        'event_type': 'status_update',
        'note': 'تحديث حالة خط الأنابيب',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 4))
            .toIso8601String(),
      },
    ];
  }

  static List<Map<String, dynamic>> notifications() {
    return [
      {
        'id': 'pub-n1',
        'title': 'طلب نشر جديد',
        'body': 'عقار زيونة بانتظار التعيين.',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        'read': false,
      },
      {
        'id': 'pub-n2',
        'title': 'جاهز للنشر',
        'body': 'شقة الجادرية وصلت لمرحلة ready_for_publication.',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 5))
            .toIso8601String(),
        'read': true,
      },
    ];
  }

  static List<Map<String, dynamic>> messages() {
    return [
      {
        'id': 'pub-m1',
        'title': 'فريق المعلومات',
        'department_code': 'publishing',
        'last_message_at': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      },
      {
        'id': 'pub-m2',
        'title': 'فريق التصوير',
        'department_code': 'publishing',
        'last_message_at': DateTime.now()
            .subtract(const Duration(hours: 6))
            .toIso8601String(),
      },
    ];
  }
}
