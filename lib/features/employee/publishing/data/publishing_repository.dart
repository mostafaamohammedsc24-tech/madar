import '../../../../services/supabase_service.dart';
import '../../core/data/employee_repository.dart';
import '../../core/domain/employee_permissions.dart';
import '../domain/publishing_models.dart';

class PublishingRepository {
  PublishingRepository(this._employeeRepo, {SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final EmployeeRepository _employeeRepo;
  final SupabaseService _supabase;

  String? get _token => _employeeRepo.sessionToken;
  String? get _employeeId => _employeeRepo.currentEmployee?.id;

  bool can(String p) => _employeeRepo.can(p);

  Future<List<PropertyAsset>> listAssets({
    String? status,
    bool assignedOnly = false,
    int limit = 80,
  }) async {
    try {
      if (assignedOnly && _employeeId != null) {
        final assigns = await _supabase.client
            .from('employee_property_assignments')
            .select('property_asset_id')
            .eq('employee_id', _employeeId!);
        final ids = List<Map<String, dynamic>>.from(assigns)
            .map((e) => e['property_asset_id']?.toString())
            .whereType<String>()
            .toList();
        if (ids.isEmpty) return [];
        final rows = await _supabase.client
            .from('property_assets')
            .select()
            .inFilter('id', ids)
            .order('updated_at', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(rows)
            .map(PropertyAsset.fromMap)
            .toList();
      }

      late final dynamic built;
      if (status != null) {
        built = _supabase.client
            .from('property_assets')
            .select()
            .eq('pipeline_status', status);
      } else {
        built = _supabase.client.from('property_assets').select();
      }
      final rows =
          await built.order('updated_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(rows)
          .map(PropertyAsset.fromMap)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<PropertyAsset?> getAsset(String id) async {
    try {
      final row = await _supabase.client
          .from('property_assets')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return PropertyAsset.fromMap(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<PublishingDashboardStats> dashboardStats() async {
    final all = await listAssets(limit: 200);
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    var publishedToday = 0;
    var needsAttention = 0;
    for (final a in all) {
      if (a.isPublished &&
          a.publishedAt != null &&
          !a.publishedAt!.isBefore(dayStart)) {
        publishedToday++;
      }
      if (const {
        'needs_correction',
        'paused',
        'owner_unavailable',
        'rejected',
      }.contains(a.pipelineStatus)) {
        needsAttention++;
      }
    }
    int count(String s) =>
        all.where((a) => a.pipelineStatus == s).length;

    return PublishingDashboardStats(
      newRequests: count('request_created'),
      informationPending: count('information_collection') + count('assigned'),
      photographyPending: count('photography') + count('three_d_capture'),
      floorPlanPending: count('floor_plan'),
      reviewRequired: count('data_review') +
          count('media_review') +
          count('engineering_review'),
      readyToPublish: count('ready_for_publication'),
      publishedToday: publishedToday,
      needsAttention: needsAttention,
    );
  }

  Future<List<Map<String, dynamic>>> listTimeline(String propertyAssetId) async {
    try {
      final rows = await _supabase.client
          .from('property_pipeline_events')
          .select()
          .eq('property_asset_id', propertyAssetId)
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<({bool success, String? message, String? publicId, String? assetId})>
      createRequest({
    required String propertyType,
    required String transactionType,
    required String source,
    required String ownerName,
    required String ownerPhone,
    String? officeId,
    String? reporterLabel,
    String? city,
    String? addressText,
    double? lat,
    double? lng,
    String? notes,
    String priority = 'normal',
  }) async {
    if (_token == null) {
      return (success: false, message: 'unauthorized', publicId: null, assetId: null);
    }
    try {
      final result = await _supabase.client.rpc(
        'publishing_create_request',
        params: {
          'p_session_token': _token,
          'p_property_type': propertyType,
          'p_transaction_type': transactionType,
          'p_source': source,
          'p_owner_name': ownerName,
          'p_owner_phone': ownerPhone,
          'p_office_id': officeId,
          'p_reporter_label': reporterLabel,
          'p_city': city,
          'p_address_text': addressText,
          'p_latitude': lat,
          'p_longitude': lng,
          'p_notes': notes,
          'p_priority': priority,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
          publicId: null,
          assetId: null,
        );
      }
      return (
        success: true,
        message: null,
        publicId: result['public_property_id']?.toString(),
        assetId: result['property_asset_id']?.toString(),
      );
    } catch (_) {
      return (success: false, message: 'unavailable', publicId: null, assetId: null);
    }
  }

  Future<bool> assignEmployee({
    required String propertyAssetId,
    required String employeeId,
    required String role,
  }) async {
    if (_token == null) return false;
    try {
      final result = await _supabase.client.rpc(
        'publishing_assign_employee',
        params: {
          'p_session_token': _token,
          'p_property_asset_id': propertyAssetId,
          'p_employee_id': employeeId,
          'p_assignment_role': role,
        },
      );
      return result is Map && result['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listEmployeesByDepartment(
    String departmentCode,
  ) async {
    try {
      final dept = await _supabase.client
          .from('employee_departments')
          .select('id')
          .eq('code', departmentCode)
          .maybeSingle();
      if (dept == null) return [];
      final rows = await _supabase.client
          .from('employees')
          .select('id, employee_code, full_name, job_title')
          .eq('department_id', dept['id'])
          .eq('employment_status', 'active');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<bool> transitionStatus({
    required String propertyAssetId,
    required String newStatus,
    String? reason,
  }) async {
    if (_token == null) return false;
    try {
      final result = await _supabase.client.rpc(
        'publishing_transition_status',
        params: {
          'p_session_token': _token,
          'p_property_asset_id': propertyAssetId,
          'p_new_status': newStatus,
          'p_reason': reason,
        },
      );
      return result is Map && result['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<({bool success, String? message})> finalPublish(String propertyAssetId) async {
    if (_token == null) return (success: false, message: 'unauthorized');
    try {
      final result = await _supabase.client.rpc(
        'publishing_final_publish',
        params: {
          'p_session_token': _token,
          'p_property_asset_id': propertyAssetId,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
        );
      }
      return (success: true, message: null);
    } catch (_) {
      return (success: false, message: 'unavailable');
    }
  }

  // ── Information ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> loadInformation(String propertyAssetId) async {
    try {
      final row = await _supabase.client
          .from('property_information')
          .select()
          .eq('property_asset_id', propertyAssetId)
          .maybeSingle();
      return row == null ? null : Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveInformationSection({
    required String propertyAssetId,
    required String sectionKey,
    required Map<String, dynamic> data,
    int? requiredCompleted,
    String? fieldNotes,
  }) async {
    if (!can(EmployeePermission.informationEdit) &&
        !can(EmployeePermission.publishingEdit)) {
      return false;
    }
    try {
      final payload = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (sectionKey.isNotEmpty) {
        payload[sectionKey] = data;
      }
      if (requiredCompleted != null) {
        payload['required_completed'] = requiredCompleted;
      }
      if (fieldNotes != null) {
        payload['field_notes'] = fieldNotes;
      }
      await _supabase.client
          .from('property_information')
          .update(payload)
          .eq('property_asset_id', propertyAssetId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listRooms(String propertyAssetId) async {
    try {
      final rows = await _supabase.client
          .from('property_rooms')
          .select()
          .eq('property_asset_id', propertyAssetId)
          .order('sort_order');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<bool> upsertRoom(PropertyRoomDraft room, String propertyAssetId) async {
    try {
      if (room.id == null) {
        await _supabase.client.from('property_rooms').insert(room.toInsert(propertyAssetId));
      } else {
        await _supabase.client
            .from('property_rooms')
            .update(room.toInsert(propertyAssetId))
            .eq('id', room.id!);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<({bool success, String? message, int? pct})> submitInformationReport({
    required String propertyAssetId,
    required int requiredCompleted,
    int requiredTotal = 92,
  }) async {
    if (_token == null) return (success: false, message: 'unauthorized', pct: null);
    try {
      final result = await _supabase.client.rpc(
        'information_submit_report',
        params: {
          'p_session_token': _token,
          'p_property_asset_id': propertyAssetId,
          'p_required_completed': requiredCompleted,
          'p_required_total': requiredTotal,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
          pct: null,
        );
      }
      return (
        success: true,
        message: null,
        pct: (result['information_pct'] as num?)?.toInt(),
      );
    } catch (_) {
      return (success: false, message: 'unavailable', pct: null);
    }
  }

  Future<String?> startFieldVisit({
    required String propertyAssetId,
    required String visitType,
    double? lat,
    double? lng,
  }) async {
    if (_employeeId == null) return null;
    try {
      final row = await _supabase.client
          .from('field_visits')
          .insert({
            'property_asset_id': propertyAssetId,
            'employee_id': _employeeId,
            'visit_type': visitType,
            'start_latitude': lat,
            'start_longitude': lng,
          })
          .select()
          .single();
      await _supabase.client.from('property_pipeline_events').insert({
        'property_asset_id': propertyAssetId,
        'event_type': 'field_visit_started',
        'message': 'Field visit started ($visitType)',
        'actor_employee_id': _employeeId,
      });
      return row['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  // ── Media ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listMedia(String propertyAssetId) async {
    try {
      final rows = await _supabase.client
          .from('property_media_assets')
          .select()
          .eq('property_asset_id', propertyAssetId)
          .order('sequence_no');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<bool> registerMedia({
    required String propertyAssetId,
    required String category,
    String? roomLabel,
    int sequence = 0,
    String? mediaUrl,
    String? caption,
  }) async {
    if (_employeeId == null) return false;
    if (!can(EmployeePermission.mediaUpload) &&
        !can(EmployeePermission.publishingEdit)) {
      return false;
    }
    try {
      await _supabase.client.from('property_media_assets').insert({
        'property_asset_id': propertyAssetId,
        'category': category,
        'room_label': roomLabel,
        'sequence_no': sequence,
        'media_url': mediaUrl,
        'caption': caption,
        'uploaded_by_employee_id': _employeeId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> list3dPoints(String propertyAssetId) async {
    try {
      final tour = await _ensureTour(propertyAssetId);
      if (tour == null) return [];
      final rows = await _supabase.client
          .from('property_3d_capture_points')
          .select()
          .eq('tour_id', tour)
          .order('sequence_no');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<String?> _ensureTour(String propertyAssetId) async {
    try {
      final existing = await _supabase.client
          .from('property_3d_tours')
          .select('id')
          .eq('property_asset_id', propertyAssetId)
          .maybeSingle();
      if (existing != null) return existing['id']?.toString();
      final row = await _supabase.client
          .from('property_3d_tours')
          .insert({
            'property_asset_id': propertyAssetId,
            'created_by_employee_id': _employeeId,
          })
          .select()
          .single();
      return row['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<bool> add3dPoint({
    required String propertyAssetId,
    required String pointCode,
    required String roomLabel,
    int sequence = 0,
    String? mediaUrl,
  }) async {
    final tour = await _ensureTour(propertyAssetId);
    if (tour == null) return false;
    try {
      await _supabase.client.from('property_3d_capture_points').insert({
        'tour_id': tour,
        'property_asset_id': propertyAssetId,
        'point_code': pointCode,
        'room_label': roomLabel,
        'sequence_no': sequence,
        'media_url': mediaUrl,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<({bool success, String? message})> submitMediaPackage({
    required String propertyAssetId,
    required int photoCount,
    required int threeDPoints,
  }) async {
    if (_token == null) return (success: false, message: 'unauthorized');
    try {
      final result = await _supabase.client.rpc(
        'media_submit_package',
        params: {
          'p_session_token': _token,
          'p_property_asset_id': propertyAssetId,
          'p_photo_count': photoCount,
          'p_three_d_points': threeDPoints,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
        );
      }
      return (success: true, message: null);
    } catch (_) {
      return (success: false, message: 'unavailable');
    }
  }

  // ── Engineering ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> ensureFloorPlan(
    String propertyAssetId, {
    String? scale,
    String? northDirection,
  }) async {
    try {
      final existingRows = await _supabase.client
          .from('floor_plans')
          .select()
          .eq('property_asset_id', propertyAssetId)
          .order('created_at', ascending: false)
          .limit(1);
      final list = List<Map<String, dynamic>>.from(existingRows);
      if (list.isNotEmpty) {
        final id = list.first['id']?.toString();
        if (id != null && (scale != null || northDirection != null)) {
          await _supabase.client.from('floor_plans').update({
            if (scale != null) 'scale': scale,
            if (northDirection != null) 'north_direction': northDirection,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', id);
          return {
            ...list.first,
            if (scale != null) 'scale': scale,
            if (northDirection != null) 'north_direction': northDirection,
          };
        }
        return list.first;
      }
      final row = await _supabase.client
          .from('floor_plans')
          .insert({
            'property_asset_id': propertyAssetId,
            'created_by_employee_id': _employeeId,
            'measurement_unit': 'm',
            if (scale != null) 'scale': scale,
            if (northDirection != null) 'north_direction': northDirection,
          })
          .select()
          .single();
      return Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> listFloors(String floorPlanId) async {
    try {
      final rows = await _supabase.client
          .from('floor_plan_floors')
          .select('*, floor_plan_rooms(*), floor_plan_points(*)')
          .eq('floor_plan_id', floorPlanId)
          .order('sort_order');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<bool> addFloor({
    required String floorPlanId,
    required String floorKey,
    required String floorLabel,
    int sortOrder = 0,
  }) async {
    try {
      await _supabase.client.from('floor_plan_floors').insert({
        'floor_plan_id': floorPlanId,
        'floor_key': floorKey,
        'floor_label': floorLabel,
        'sort_order': sortOrder,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addFloorRoom({
    required String floorId,
    required String roomName,
    double? lengthM,
    double? widthM,
    double? heightM,
    double? customArea,
  }) async {
    try {
      final area = customArea ??
          ((lengthM != null && widthM != null) ? lengthM * widthM : null);
      await _supabase.client.from('floor_plan_rooms').insert({
        'floor_id': floorId,
        'room_name': roomName,
        'length_m': lengthM,
        'width_m': widthM,
        'height_m': heightM,
        'area_m2': area,
        'custom_area': customArea != null,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addFloorPoint({
    required String floorId,
    required String pointLabel,
    String? roomName,
    double? xPct,
    double? yPct,
    String? linked3dPointId,
  }) async {
    try {
      await _supabase.client.from('floor_plan_points').insert({
        'floor_id': floorId,
        'point_label': pointLabel,
        'room_name': roomName,
        'x_pct': xPct,
        'y_pct': yPct,
        'linked_3d_point_id': linked3dPointId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<({bool success, String? message})> submitFloorPlan(
    String floorPlanId,
  ) async {
    if (_token == null) return (success: false, message: 'unauthorized');
    try {
      final result = await _supabase.client.rpc(
        'engineering_submit_floor_plan',
        params: {
          'p_session_token': _token,
          'p_floor_plan_id': floorPlanId,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
        );
      }
      return (success: true, message: null);
    } catch (_) {
      return (success: false, message: 'unavailable');
    }
  }

  Future<bool> addTag({
    required String propertyAssetId,
    required String tag,
    String group = 'feature',
  }) async {
    try {
      await _supabase.client.from('property_tags').insert({
        'property_asset_id': propertyAssetId,
        'tag': tag,
        'tag_group': group,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listTags(String propertyAssetId) async {
    try {
      final rows = await _supabase.client
          .from('property_tags')
          .select()
          .eq('property_asset_id', propertyAssetId);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }
}
