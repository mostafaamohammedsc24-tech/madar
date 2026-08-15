import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_URL and SUPABASE_ANON_KEY must be defined.');
    }
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // ─── AUTH ────────────────────────────────────────────────────────────────

  Future<void> signInWithPhone(String phone) async {
    await client.auth.signInWithOtp(phone: phone);
  }

  Future<AuthResponse> verifyOtp(String phone, String token) async {
    return await client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ─── USER PROFILE ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client.from('user_profiles').upsert({'id': userId, ...data});
  }

  Future<void> updateIdentityVerification({
    required String status,
    String? documentUrl,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await client
        .from('user_profiles')
        .update({
          'identity_verification_status': status,
          if (documentUrl != null) 'profile_photo_url': documentUrl,
        })
        .eq('id', userId);
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUserTransactions() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await client
          .from('transactions')
          .select('*, transaction_stages(*), transaction_barcodes(*)')
          .or('buyer_user_id.eq.$userId,seller_user_id.eq.$userId')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getTransactionByBarcode(
    String barcodeCode,
  ) async {
    try {
      final barcode = await client
          .from('transaction_barcodes')
          .select('*, transactions(*, transaction_stages(*))')
          .eq('barcode_code', barcodeCode)
          .maybeSingle();
      return barcode;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTransactionById(String txId) async {
    try {
      final response = await client
          .from('transactions')
          .select(
            '*, transaction_stages(*), transaction_barcodes(*), transaction_fees(*), transaction_financial_snapshots(*)',
          )
          .eq('id', txId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> redeemBarcode(String barcodeId) async {
    await client
        .from('transaction_barcodes')
        .update({
          'redeemed_at': DateTime.now().toIso8601String(),
          'redeemed_by_user_id': currentUser?.id,
        })
        .eq('id', barcodeId);
  }

  Future<void> updateTransactionStage(
    String transactionId,
    int stageIndex,
    String status,
  ) async {
    await client
        .from('transaction_stages')
        .update({
          'status': status,
          if (status == 'completed')
            'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('transaction_id', transactionId)
        .eq('stage_index', stageIndex);
  }

  Future<void> updateTransactionCurrentStage(
    String transactionId,
    int stage,
  ) async {
    await client
        .from('transactions')
        .update({'current_stage_index': stage})
        .eq('id', transactionId);
  }

  // ─── PROPERTIES ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProperties({
    String? countryCode,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = client
          .from('properties_v3')
          .select('*, property_media_v3(*), property_features_v3(*)');

      if (countryCode != null) {
        query = query.eq('country_code', countryCode);
      }
      if (propertyType != null) {
        query = query.eq('property_type', propertyType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPropertyById(String id) async {
    try {
      final response = await client
          .from('properties_v3')
          .select('*, property_media_v3(*), property_features_v3(*)')
          .eq('id', id)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUserProperties() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await client
          .from('properties_v3')
          .select('*, property_media_v3(*)')
          .eq('owner_user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> submitPropertyRequest({
    required double latitude,
    required double longitude,
    required String address,
    required String contactPhone,
    String? propertyType,
    String? listingType,
    String? notes,
    String? imageUrl,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    try {
      final response = await client
          .from('property_submission_requests')
          .insert({
            'user_id': userId,
            'latitude': latitude,
            'longitude': longitude,
            'address_text': address,
            'contact_phone': contactPhone,
            'status': 'pending',
            if (propertyType != null) 'property_type': propertyType,
            if (listingType != null) 'listing_type': listingType,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
            if (imageUrl != null) 'image_url': imageUrl,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadPropertyImage({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final path = 'property_submissions/$fileName';
      await client.storage
          .from('property-images')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      final url = client.storage.from('property-images').getPublicUrl(path);
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPropertySubmissions() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await client
          .from('property_submission_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ─── MESSAGES / CONVERSATIONS ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getConversations() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await client
          .from('conversations')
          .select('*, messages(content, created_at, sender_type)')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final response = await client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String senderType = 'user',
  }) async {
    final userId = currentUser?.id;
    await client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'sender_type': senderType,
      'content': content,
    });
    await client
        .from('conversations')
        .update({
          'updated_at': DateTime.now().toIso8601String(),
          'last_message_preview': content,
        })
        .eq('id', conversationId);
  }

  // ─── EMPLOYEES ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getEmployeeByCredentials(
    String employeeCode,
    String secretCode,
  ) async {
    try {
      final response = await client
          .from('employees')
          .select('*, org_positions(*), org_departments(*)')
          .eq('employee_code', employeeCode)
          .eq('secret_code', secretCode)
          .eq('is_active', true)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getEmployeeByPhone(String phone) async {
    try {
      final response = await client
          .from('employees')
          .select('id, full_name, role, employee_code, phone')
          .eq('phone', phone)
          .eq('is_active', true)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getEmployeeTasks(String employeeId) async {
    try {
      final response = await client
          .from('transaction_actions')
          .select('*, transactions(reference_number, current_stage_index)')
          .eq('assigned_to_employee_id', employeeId)
          .inFilter('status', ['pending', 'in_progress'])
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEmployeeTransactions(
    String employeeId,
    String role,
  ) async {
    try {
      final response = await client
          .from('transactions')
          .select('*, transaction_stages(*)')
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ─── OFFICES ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getOfficeByCredentials(
    String officeCode,
    String secretCode,
  ) async {
    try {
      final response = await client
          .from('offices')
          .select()
          .eq('office_code', officeCode)
          .eq('secret_code', secretCode)
          .eq('is_active', true)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> generateTransactionBarcode({
    required String officeId,
    required String transactionType,
    required String buyerPhone,
    required String sellerPhone,
    required String propertyAddress,
    required double amount,
    required String countryCode,
  }) async {
    try {
      // Create transaction first
      final txResponse = await client
          .from('transactions')
          .insert({
            'office_id': officeId,
            'transaction_type': transactionType,
            'country_code': countryCode,
            'status': 'initiated',
            'current_stage_index': 0,
            'total_amount': amount,
            'currency_code': 'IQD',
            'property_address_snapshot': propertyAddress,
          })
          .select()
          .single();

      final txId = txResponse['id'];

      // Generate barcode
      final barcodeCode =
          'MDR-${countryCode.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
      final barcodeResponse = await client
          .from('transaction_barcodes')
          .insert({
            'transaction_id': txId,
            'barcode_code': barcodeCode,
            'barcode_type': 'qr',
            'generated_by_office_id': officeId,
            'buyer_phone': buyerPhone,
            'seller_phone': sellerPhone,
            'expires_at': DateTime.now()
                .add(const Duration(days: 30))
                .toIso8601String(),
          })
          .select()
          .single();

      return {
        'transaction': txResponse,
        'barcode': barcodeResponse,
        'barcode_code': barcodeCode,
      };
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getOfficeTransactions(
    String officeId,
  ) async {
    try {
      final response = await client
          .from('transactions')
          .select('*, transaction_stages(*), transaction_barcodes(*)')
          .eq('office_id', officeId)
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(30);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // ─── SEARCH ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchProperties(String query) async {
    try {
      final response = await client
          .from('property_search_index')
          .select('*, properties_v3(*, property_media_v3(*))')
          .ilike('search_text', '%$query%')
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> saveRecentSearch(String query) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    try {
      await client.from('recent_searches').upsert({
        'user_id': userId,
        'query': query,
        'searched_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ─── FAVORITES ────────────────────────────────────────────────────────────

  Future<void> toggleFavorite(String propertyId) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    try {
      final existing = await client
          .from('user_favorite_properties')
          .select()
          .eq('user_id', userId)
          .eq('property_id', propertyId)
          .maybeSingle();
      if (existing != null) {
        await client
            .from('user_favorite_properties')
            .delete()
            .eq('user_id', userId)
            .eq('property_id', propertyId);
      } else {
        await client.from('user_favorite_properties').insert({
          'user_id': userId,
          'property_id': propertyId,
        });
      }
    } catch (_) {}
  }

  Future<Set<String>> getFavoritePropertyIds() async {
    final userId = currentUser?.id;
    if (userId == null) return {};
    try {
      final response = await client
          .from('user_favorite_properties')
          .select('property_id')
          .eq('user_id', userId);
      return Set<String>.from(
        (response as List).map((r) => r['property_id'] as String),
      );
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteProperties() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await client
          .from('user_favorite_properties')
          .select('property_id, properties_v3(*, property_media_v3(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSearch({
    required String query,
    Map<String, dynamic>? filters,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    try {
      await client.from('saved_searches').upsert({
        'user_id': userId,
        'query': query,
        if (filters != null) 'filters': filters,
        'saved_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getSavedSearches() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await client
          .from('saved_searches')
          .select()
          .eq('user_id', userId)
          .order('saved_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteSavedSearch(String searchId) async {
    try {
      await client.from('saved_searches').delete().eq('id', searchId);
    } catch (_) {}
  }

  // ─── REAL-TIME ────────────────────────────────────────────────────────────

  RealtimeChannel subscribeToTransaction(
    String transactionId,
    Function(Map<String, dynamic>) onUpdate,
  ) {
    return client
        .channel('transaction_$transactionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: transactionId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  RealtimeChannel subscribeToMessages(
    String conversationId,
    Function(Map<String, dynamic>) onMessage,
  ) {
    return client
        .channel('messages_$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) => onMessage(payload.newRecord),
        )
        .subscribe();
  }
}
