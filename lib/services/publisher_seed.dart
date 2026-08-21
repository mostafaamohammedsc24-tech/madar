import '../features/employee/core/domain/employee_models.dart';
import '../features/employee/core/domain/employee_permissions.dart';
import '../features/employee/publishing/domain/publishing_models.dart';

/// Local publisher (publishing dept) preview seed.
/// Credentials: [code] / [secret].
abstract final class PublisherSeed {
  static const String code = 'PUB001';
  static const String secret = '123456';
  static const String token = 'seed-publisher-token';
  static const String employeeId = 'seed-publisher-001';

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
      jobTitle: 'ناشر عقارات',
      countryCode: 'IQ',
      branchCode: 'BGH',
      department: const EmployeeDepartment(
        id: 'dept-publishing',
        code: 'publishing',
        nameEn: 'Publishing',
        nameAr: 'النشر',
      ),
      role: const EmployeeRole(
        id: 'role-publisher',
        code: 'publisher',
        nameEn: 'Publisher',
        nameAr: 'ناشر',
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

  static List<PropertyAsset> assets() {
    return [
      PropertyAsset.fromMap({
        'id': 'pa-1',
        'public_property_id': '88421011',
        'pipeline_status': 'information_collection',
        'property_type': 'apartment',
        'transaction_type': 'sale',
        'owner_name': 'مريم خليل',
        'owner_phone': '+9647701112233',
        'city': 'بغداد',
        'address_text': 'الكرادة، بغداد',
        'information_pct': 40,
        'photography_pct': 0,
        'three_d_pct': 0,
        'floor_plan_pct': 0,
        'is_published': false,
        'priority': 'high',
        'updated_at': DateTime.now().toIso8601String(),
      }),
      PropertyAsset.fromMap({
        'id': 'pa-2',
        'public_property_id': '88421022',
        'pipeline_status': 'photography',
        'property_type': 'villa',
        'transaction_type': 'sale',
        'owner_name': 'حسين العبودي',
        'owner_phone': '+9647901234567',
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
        'owner_phone': '+9647502223344',
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
        'owner_phone': '+9647803334455',
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
      PropertyAsset.fromMap({
        'id': 'pa-5',
        'public_property_id': '88421055',
        'pipeline_status': 'request_created',
        'property_type': 'commercial',
        'transaction_type': 'sale',
        'owner_name': 'شركة الرافدين',
        'owner_phone': '+9647709998877',
        'city': 'بغداد',
        'address_text': 'زيونة، بغداد',
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
