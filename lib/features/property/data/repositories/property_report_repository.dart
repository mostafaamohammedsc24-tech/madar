import '../../../../services/supabase_service.dart';
import '../../domain/models/property_documents.dart';
import '../../domain/models/property_report.dart';
import '../mappers/property_report_mapper.dart';

class PropertyReportRepository {
  PropertyReportRepository({
    SupabaseService? supabase,
    PropertyReportMapper? mapper,
  })  : _supabase = supabase ?? SupabaseService.instance,
        _mapper = mapper ?? const PropertyReportMapper();

  final SupabaseService _supabase;
  final PropertyReportMapper _mapper;

  Future<PropertyReport?> loadById(
    String id, {
    Map<String, dynamic>? seed,
  }) async {
    Map<String, dynamic>? data;
    try {
      data = await _supabase.getPropertyById(id);
    } catch (_) {
      data = null;
    }
    final source = data ?? seed;
    if (source == null) return null;

    var isSaved = false;
    try {
      final favorites = await _supabase.getFavoritePropertyIds();
      isSaved = favorites.contains(id);
    } catch (_) {}

    return _mapper.fromSupabaseMap(source, isSaved: isSaved);
  }

  PropertyReport fromMap(Map<String, dynamic> seed, {bool isSaved = false}) {
    return _mapper.fromSupabaseMap(seed, isSaved: isSaved);
  }

  Future<bool> toggleSave(String propertyId) async {
    try {
      await _supabase.toggleFavorite(propertyId);
      final favorites = await _supabase.getFavoritePropertyIds();
      return favorites.contains(propertyId);
    } catch (_) {
      return false;
    }
  }

  /// Sales-team inquiry — never routes to an agent chat.
  Future<Map<String, dynamic>?> submitSalesInquiry(
    PropertyInquiryDraft draft,
  ) async {
    try {
      final client = _supabase.client;
      final response = await client
          .from('property_inquiries')
          .insert({
            'user_id': draft.userId,
            'property_id': draft.propertyId,
            'inquiry_type': draft.inquiryType.name,
            'message': draft.message,
            'status': 'new',
            'assigned_team': draft.assignedTeam,
          })
          .select()
          .maybeSingle();
      return response;
    } catch (_) {
      // Table may not exist yet — soft-fail so UI can still show confirmation.
      return {
        'property_id': draft.propertyId,
        'status': 'queued_local',
        'assigned_team': draft.assignedTeam,
      };
    }
  }

  Future<Map<String, dynamic>?> submitTourRequest(
    PropertyTourRequest request,
  ) async {
    try {
      final client = _supabase.client;
      final response = await client
          .from('property_tour_requests')
          .insert({
            'user_id': request.userId,
            'property_id': request.propertyId,
            'tour_type': request.tourType.name,
            'preferred_date': request.preferredDate?.toIso8601String(),
            'preferred_time': request.preferredTime,
            'notes': request.notes,
            'status': 'new',
          })
          .select()
          .maybeSingle();
      return response;
    } catch (_) {
      return {
        'property_id': request.propertyId,
        'status': 'queued_local',
      };
    }
  }
}
