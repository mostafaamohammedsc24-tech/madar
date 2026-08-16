import '../enums/office_enums.dart';

class OfficeAccount {
  const OfficeAccount({
    required this.id,
    required this.officeCode,
    required this.name,
    required this.countryCode,
    required this.currencyCode,
    this.address,
    this.phone,
    this.managerName,
    this.licenseNumber,
    this.status = OfficeStatus.active,
    this.joinedAt,
  });

  final String id;
  final String officeCode;
  final String name;
  final String countryCode;
  final String currencyCode;
  final String? address;
  final String? phone;
  final String? managerName;
  final String? licenseNumber;
  final OfficeStatus status;
  final DateTime? joinedAt;

  factory OfficeAccount.fromMap(Map<String, dynamic> d) {
    return OfficeAccount(
      id: d['id']?.toString() ?? '',
      officeCode: d['office_code'] as String? ?? '',
      name: d['name'] as String? ?? '',
      countryCode: d['country_code'] as String? ?? 'IQ',
      currencyCode: d['currency_code'] as String? ?? 'IQD',
      address: d['address'] as String?,
      phone: d['phone'] as String?,
      managerName: d['manager_name'] as String?,
      licenseNumber: d['license_number'] as String?,
      status: officeStatusFromWire(d['status'] as String?),
      joinedAt: d['joined_at'] != null
          ? DateTime.tryParse(d['joined_at'].toString())
          : null,
    );
  }
}

class OfficeSession {
  const OfficeSession({
    required this.token,
    required this.office,
    this.expiresAt,
  });

  final String token;
  final OfficeAccount office;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

class OfficeReferral {
  const OfficeReferral({
    required this.id,
    required this.officeId,
    required this.propertyId,
    required this.status,
    this.buyerPhone,
    this.message,
    this.conversationId,
    this.createdAt,
  });

  final String id;
  final String officeId;
  final String propertyId;
  final OfficeReferralStatus status;
  final String? buyerPhone;
  final String? message;
  final String? conversationId;
  final DateTime? createdAt;

  factory OfficeReferral.fromMap(Map<String, dynamic> d) {
    return OfficeReferral(
      id: d['id']?.toString() ?? '',
      officeId: d['office_id']?.toString() ?? '',
      propertyId: d['property_id']?.toString() ?? '',
      status: referralStatusFromWire(d['status'] as String?),
      buyerPhone: d['buyer_phone'] as String?,
      message: d['message'] as String?,
      conversationId: d['conversation_id']?.toString(),
      createdAt: d['created_at'] != null
          ? DateTime.tryParse(d['created_at'].toString())
          : null,
    );
  }
}

class OfficePropertyReport {
  const OfficePropertyReport({
    required this.id,
    required this.officeId,
    required this.status,
    this.propertyType,
    this.listingType,
    this.addressText,
    this.ownerPhone,
    this.estimatedPrice,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String officeId;
  final OfficeReportStatus status;
  final String? propertyType;
  final String? listingType;
  final String? addressText;
  final String? ownerPhone;
  final double? estimatedPrice;
  final String? notes;
  final DateTime? createdAt;

  factory OfficePropertyReport.fromMap(Map<String, dynamic> d) {
    final raw = (d['status'] as String? ?? '').toLowerCase();
    final status = switch (raw) {
      'contacting_owner' => OfficeReportStatus.contactingOwner,
      'owner_approved' => OfficeReportStatus.ownerApproved,
      'owner_declined' => OfficeReportStatus.ownerDeclined,
      _ => OfficeReportStatus.underReview,
    };
    return OfficePropertyReport(
      id: d['id']?.toString() ?? '',
      officeId: d['office_id']?.toString() ?? '',
      status: status,
      propertyType: d['property_type'] as String?,
      listingType: d['listing_type'] as String?,
      addressText: d['address_text'] as String?,
      ownerPhone: d['owner_phone'] as String?,
      estimatedPrice: (d['estimated_price'] as num?)?.toDouble(),
      notes: d['notes'] as String?,
      createdAt: d['created_at'] != null
          ? DateTime.tryParse(d['created_at'].toString())
          : null,
    );
  }
}

class OfficeSalesSummary {
  const OfficeSalesSummary({
    required this.salesThisMonth,
    required this.completed,
    required this.inProgress,
    required this.awaitingParties,
  });

  final int salesThisMonth;
  final int completed;
  final int inProgress;
  final int awaitingParties;
}

class OfficeConversation {
  const OfficeConversation({
    required this.id,
    required this.officeId,
    required this.teamKey,
    this.propertyId,
    this.referralId,
    this.title,
    this.lastMessageAt,
  });

  final String id;
  final String officeId;
  final String teamKey;
  final String? propertyId;
  final String? referralId;
  final String? title;
  final DateTime? lastMessageAt;

  factory OfficeConversation.fromMap(Map<String, dynamic> d) {
    return OfficeConversation(
      id: d['id']?.toString() ?? '',
      officeId: d['office_id']?.toString() ?? '',
      teamKey: d['team_key'] as String? ?? 'office_management',
      propertyId: d['property_id']?.toString(),
      referralId: d['referral_id']?.toString(),
      title: d['title'] as String?,
      lastMessageAt: d['last_message_at'] != null
          ? DateTime.tryParse(d['last_message_at'].toString())
          : null,
    );
  }
}

class OfficeMessage {
  const OfficeMessage({
    required this.id,
    required this.conversationId,
    required this.senderSide,
    required this.messageType,
    this.body,
    this.mediaUrl,
    this.propertyId,
    this.createdAt,
    this.readAt,
  });

  final String id;
  final String conversationId;
  final String senderSide;
  final String messageType;
  final String? body;
  final String? mediaUrl;
  final String? propertyId;
  final DateTime? createdAt;
  final DateTime? readAt;

  factory OfficeMessage.fromMap(Map<String, dynamic> d) {
    return OfficeMessage(
      id: d['id']?.toString() ?? '',
      conversationId: d['conversation_id']?.toString() ?? '',
      senderSide: d['sender_side'] as String? ?? 'office',
      messageType: d['message_type'] as String? ?? 'text',
      body: d['body'] as String?,
      mediaUrl: d['media_url'] as String?,
      propertyId: d['property_id']?.toString(),
      createdAt: d['created_at'] != null
          ? DateTime.tryParse(d['created_at'].toString())
          : null,
      readAt: d['read_at'] != null
          ? DateTime.tryParse(d['read_at'].toString())
          : null,
    );
  }
}

class OfficeBarcodeCreateResult {
  const OfficeBarcodeCreateResult({
    required this.success,
    this.transactionId,
    this.transactionNumber,
    this.buyerBarcode,
    this.sellerBarcode,
    this.message,
  });

  final bool success;
  final String? transactionId;
  final String? transactionNumber;
  final String? buyerBarcode;
  final String? sellerBarcode;
  final String? message;
}
