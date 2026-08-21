import 'package:shared_preferences/shared_preferences.dart';

import '../../../../services/office_seed.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/models/office_models.dart';

class OfficeRepository {
  OfficeRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;

  static const _tokenKey = 'office_session_token';
  static const _officeJsonKey = 'office_session_office';

  String? _token;
  OfficeAccount? _office;

  String? get sessionToken => _token;
  OfficeAccount? get currentOffice => _office;
  bool get isAuthenticated =>
      _token != null && _token!.isNotEmpty && _office != null;

  bool get _isSeedSession => OfficeSeed.isSeedToken(_token);

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final id = prefs.getString('${_officeJsonKey}_id');
    final code = prefs.getString('${_officeJsonKey}_code');
    final name = prefs.getString('${_officeJsonKey}_name');
    final country = prefs.getString('${_officeJsonKey}_country');
    final currency = prefs.getString('${_officeJsonKey}_currency');
    if (_token != null && id != null && code != null && name != null) {
      _office = OfficeAccount(
        id: id,
        officeCode: code,
        name: name,
        countryCode: country ?? 'IQ',
        currencyCode: currency ?? 'IQD',
        address: prefs.getString('${_officeJsonKey}_address'),
        phone: prefs.getString('${_officeJsonKey}_phone'),
        managerName: prefs.getString('${_officeJsonKey}_manager'),
      );
    }
  }

  Future<void> _persistSession(OfficeSession session) async {
    _token = session.token;
    _office = session.office;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString('${_officeJsonKey}_id', session.office.id);
    await prefs.setString('${_officeJsonKey}_code', session.office.officeCode);
    await prefs.setString('${_officeJsonKey}_name', session.office.name);
    await prefs.setString(
      '${_officeJsonKey}_country',
      session.office.countryCode,
    );
    await prefs.setString(
      '${_officeJsonKey}_currency',
      session.office.currencyCode,
    );
    if (session.office.address != null) {
      await prefs.setString(
        '${_officeJsonKey}_address',
        session.office.address!,
      );
    }
    if (session.office.phone != null) {
      await prefs.setString('${_officeJsonKey}_phone', session.office.phone!);
    }
    if (session.office.managerName != null) {
      await prefs.setString(
        '${_officeJsonKey}_manager',
        session.office.managerName!,
      );
    }
  }

  Future<void> clearSession() async {
    if (_token != null) {
      try {
        await _supabase.client.rpc(
          'office_logout',
          params: {'p_session_token': _token},
        );
      } catch (_) {}
    }
    _token = null;
    _office = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    for (final k in [
      'id',
      'code',
      'name',
      'country',
      'currency',
      'address',
      'phone',
      'manager',
    ]) {
      await prefs.remove('${_officeJsonKey}_$k');
    }
  }

  Future<({bool success, String? message, OfficeSession? session})> login({
    required String officeCode,
    required String secretCode,
  }) async {
    // Local seed login for exploring the office portal.
    if (OfficeSeed.matches(officeCode, secretCode)) {
      final session = OfficeSeed.session();
      await _persistSession(session);
      return (success: true, message: null, session: session);
    }
    try {
      final result = await _supabase.client.rpc(
        'office_login',
        params: {
          'p_office_code': officeCode.trim(),
          'p_secret_code': secretCode,
        },
      );
      if (result is! Map) {
        return (success: false, message: 'invalid_response', session: null);
      }
      final map = Map<String, dynamic>.from(result);
      if (map['success'] != true) {
        return (
          success: false,
          message: map['message']?.toString() ?? 'invalid_credentials',
          session: null,
        );
      }
      final officeMap = Map<String, dynamic>.from(map['office'] as Map);
      final session = OfficeSession(
        token: map['session_token'] as String,
        office: OfficeAccount.fromMap(officeMap),
        expiresAt: map['expires_at'] != null
            ? DateTime.tryParse(map['expires_at'].toString())
            : null,
      );
      await _persistSession(session);
      return (success: true, message: null, session: session);
    } catch (e) {
      return (success: false, message: 'login_unavailable', session: null);
    }
  }

  Future<List<Map<String, dynamic>>> loadDiscoverableProperties({
    String? countryCode,
  }) async {
    if (_isSeedSession) return OfficeSeed.discoverableProperties();
    return _supabase.getProperties(
      countryCode: countryCode ?? _office?.countryCode,
      limit: 80,
    );
  }

  Future<List<Map<String, dynamic>>> loadOfficeAssignedProperties() async {
    if (_isSeedSession) return OfficeSeed.assignedProperties();
    if (_office == null) return [];
    try {
      final rows = await _supabase.client
          .from('office_properties')
          .select('*, property_id')
          .eq('office_id', _office!.id)
          .order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<OfficeReferral?> createFoundBuyerReferral({
    required String propertyId,
    String? buyerPhone,
    String? message,
  }) async {
    if (_office == null) return null;
    if (_isSeedSession) {
      return OfficeSeed.createFoundBuyer(
        propertyId: propertyId,
        buyerPhone: buyerPhone,
        message: message,
      );
    }
    try {
      // Ensure management conversation
      final conv = await _supabase.client
          .from('office_conversations')
          .insert({
            'office_id': _office!.id,
            'team_key': 'office_management',
            'property_id': propertyId,
            'title': 'Found buyer — property',
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final referral = await _supabase.client
          .from('office_referrals')
          .insert({
            'office_id': _office!.id,
            'property_id': propertyId,
            'buyer_phone': buyerPhone,
            'status': 'new',
            'conversation_id': conv['id'],
            'message': message ?? 'I have a buyer interested in this property.',
          })
          .select()
          .single();

      await _supabase.client.from('office_conversations').update({
        'referral_id': referral['id'],
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', conv['id']);

      await _supabase.client.from('office_messages').insert({
        'conversation_id': conv['id'],
        'office_id': _office!.id,
        'sender_side': 'office',
        'sender_label': _office!.name,
        'message_type': 'property_card',
        'body': message ?? 'I have a buyer interested in this property.',
        'property_id': propertyId,
      });

      await _supabase.client.from('office_messages').insert({
        'conversation_id': conv['id'],
        'office_id': _office!.id,
        'sender_side': 'office',
        'sender_label': _office!.name,
        'message_type': 'text',
        'body': message ?? 'I have a buyer interested in this property.',
        'property_id': propertyId,
      });

      return OfficeReferral.fromMap(Map<String, dynamic>.from(referral));
    } catch (_) {
      return null;
    }
  }

  Future<OfficePropertyReport?> submitPropertyReport({
    required String? propertyType,
    required String? listingType,
    required String? addressText,
    required String? ownerPhone,
    double? estimatedPrice,
    String? notes,
    double? lat,
    double? lng,
  }) async {
    if (_office == null) return null;
    try {
      final row = await _supabase.client
          .from('office_property_reports')
          .insert({
            'office_id': _office!.id,
            'property_type': propertyType,
            'listing_type': listingType,
            'address_text': addressText,
            'owner_phone': ownerPhone,
            'estimated_price': estimatedPrice,
            'notes': notes,
            'latitude': lat,
            'longitude': lng,
            'currency_code': _office!.currencyCode,
            'status': 'under_review',
          })
          .select()
          .single();
      return OfficePropertyReport.fromMap(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<List<OfficeReferral>> listReferrals() async {
    if (_isSeedSession) return OfficeSeed.referrals();
    if (_office == null) return [];
    try {
      final rows = await _supabase.client
          .from('office_referrals')
          .select()
          .eq('office_id', _office!.id)
          .order('created_at', ascending: false);
      return (rows as List)
          .whereType<Map>()
          .map((e) => OfficeReferral.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<OfficePropertyReport>> listReports() async {
    if (_isSeedSession) return [];
    if (_office == null) return [];
    try {
      final rows = await _supabase.client
          .from('office_property_reports')
          .select()
          .eq('office_id', _office!.id)
          .order('created_at', ascending: false);
      return (rows as List)
          .whereType<Map>()
          .map(
            (e) => OfficePropertyReport.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<OfficeConversation>> listConversations() async {
    if (_isSeedSession) return OfficeSeed.conversations();
    if (_office == null) return [];
    try {
      final rows = await _supabase.client
          .from('office_conversations')
          .select()
          .eq('office_id', _office!.id)
          .order('last_message_at', ascending: false);
      return (rows as List)
          .whereType<Map>()
          .map((e) => OfficeConversation.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<OfficeMessage>> listMessages(String conversationId) async {
    if (_isSeedSession) return OfficeSeed.messagesFor(conversationId);
    try {
      final rows = await _supabase.client
          .from('office_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      return (rows as List)
          .whereType<Map>()
          .map((e) => OfficeMessage.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> sendTextMessage({
    required String conversationId,
    required String body,
  }) async {
    if (_isSeedSession) {
      OfficeSeed.appendSeedMessage(
        conversationId: conversationId,
        body: body,
      );
      return true;
    }
    if (_office == null) return false;
    try {
      await _supabase.client.from('office_messages').insert({
        'conversation_id': conversationId,
        'office_id': _office!.id,
        'sender_side': 'office',
        'sender_label': _office!.name,
        'message_type': 'text',
        'body': body,
      });
      await _supabase.client
          .from('office_conversations')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<OfficeSalesSummary> salesSummaryThisMonth() async {
    if (_isSeedSession) return OfficeSeed.salesSummary();
    if (_office == null) {
      return const OfficeSalesSummary(
        salesThisMonth: 0,
        completed: 0,
        inProgress: 0,
        awaitingParties: 0,
      );
    }
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1).toIso8601String();
      final rows = await _supabase.client
          .from('transactions')
          .select('id, lifecycle_state, status, created_at')
          .eq('created_by_office_id', _office!.id)
          .gte('created_at', start);

      final list = List<Map<String, dynamic>>.from(rows);
      var completed = 0;
      var inProgress = 0;
      var awaiting = 0;
      for (final t in list) {
        final state =
            (t['lifecycle_state'] as String? ?? t['status'] as String? ?? '')
                .toLowerCase();
        if (state == 'completed') {
          completed++;
        } else if (state == 'waiting_for_parties' || state == 'pending') {
          awaiting++;
        } else {
          inProgress++;
        }
      }
      return OfficeSalesSummary(
        salesThisMonth: list.length,
        completed: completed,
        inProgress: inProgress,
        awaitingParties: awaiting,
      );
    } catch (_) {
      return const OfficeSalesSummary(
        salesThisMonth: 0,
        completed: 0,
        inProgress: 0,
        awaitingParties: 0,
      );
    }
  }

  Future<List<Map<String, dynamic>>> listOfficeTransactions() async {
    if (_isSeedSession) return OfficeSeed.transactions();
    if (_office == null) return [];
    try {
      final rows = await _supabase.client
          .from('transactions')
          .select()
          .eq('created_by_office_id', _office!.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<OfficeBarcodeCreateResult> createTransactionWithBarcodes({
    required String transactionType,
    required String buyerPhone,
    required String sellerPhone,
    String? propertyId,
    double? salePrice,
  }) async {
    if (_token == null || _office == null) {
      return const OfficeBarcodeCreateResult(
        success: false,
        message: 'unauthorized',
      );
    }
    if (_isSeedSession) {
      final id = 'seed-live-${DateTime.now().millisecondsSinceEpoch}';
      final number =
          'IQ-BGD-${transactionType.toUpperCase()}-SEED-${id.substring(id.length - 6)}';
      final buy = 'BUY-LIVE-${id.substring(id.length - 6)}';
      final sel = 'SEL-LIVE-${id.substring(id.length - 6)}';
      return OfficeBarcodeCreateResult(
        success: true,
        transactionId: id,
        transactionNumber: number,
        buyerBarcode: buy,
        sellerBarcode: sel,
      );
    }
    try {
      final result = await _supabase.client.rpc(
        'office_create_transaction_with_barcodes',
        params: {
          'p_session_token': _token,
          'p_transaction_type': transactionType,
          'p_buyer_phone': buyerPhone,
          'p_seller_phone': sellerPhone,
          'p_property_id': propertyId,
          'p_sale_price': salePrice,
          'p_currency_code': _office!.currencyCode,
          'p_country_code': _office!.countryCode,
        },
      );
      if (result is! Map) {
        return const OfficeBarcodeCreateResult(
          success: false,
          message: 'invalid_response',
        );
      }
      final map = Map<String, dynamic>.from(result);
      if (map['success'] != true) {
        return OfficeBarcodeCreateResult(
          success: false,
          message: map['message']?.toString(),
        );
      }
      return OfficeBarcodeCreateResult(
        success: true,
        transactionId: map['transaction_id']?.toString(),
        transactionNumber: map['transaction_number']?.toString(),
        buyerBarcode: map['buyer_barcode']?.toString(),
        sellerBarcode: map['seller_barcode']?.toString(),
      );
    } catch (_) {
      return const OfficeBarcodeCreateResult(
        success: false,
        message: 'create_unavailable',
      );
    }
  }

  Future<List<Map<String, dynamic>>> listNotifications() async {
    if (_isSeedSession) return OfficeSeed.notifications();
    if (_office == null) return [];
    try {
      final rows = await _supabase.client
          .from('office_notifications')
          .select()
          .eq('office_id', _office!.id)
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listCommissionRules() async {
    try {
      final rows = await _supabase.client
          .from('office_commission_rules')
          .select()
          .eq('country_code', _office?.countryCode ?? 'IQ');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listDocuments() async {
    if (_office == null) return [];
    try {
      final rows = await _supabase.client
          .from('office_documents')
          .select()
          .eq('office_id', _office!.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listSupportTickets() async {
    if (_office == null) return [];
    try {
      final rows = await _supabase.client
          .from('office_support_tickets')
          .select()
          .eq('office_id', _office!.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<bool> createSupportTicket({
    required String subject,
    required String body,
  }) async {
    if (_office == null) return false;
    try {
      await _supabase.client.from('office_support_tickets').insert({
        'office_id': _office!.id,
        'subject': subject,
        'body': body,
        'status': 'open',
        'assigned_team': 'office_management',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Expected office share from configurable rules (not hard-coded UI %).
  Future<({double? officeShare, double? companyShare})> expectedCommissionShare({
    required String propertySource,
    required String buyerSource,
    String transactionType = 'sale',
  }) async {
    final rules = await listCommissionRules();
    for (final r in rules) {
      if (r['property_source'] == propertySource &&
          r['buyer_source'] == buyerSource &&
          (r['transaction_type'] as String? ?? 'sale') == transactionType) {
        return (
          officeShare: (r['office_share'] as num?)?.toDouble(),
          companyShare: (r['company_share'] as num?)?.toDouble(),
        );
      }
    }
    return (officeShare: null, companyShare: null);
  }
}
