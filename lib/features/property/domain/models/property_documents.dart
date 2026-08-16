import '../enums/data_provenance.dart';

class PropertyDocumentMeta {
  const PropertyDocumentMeta({
    required this.id,
    required this.title,
    required this.documentType,
    this.url,
    this.isSensitive = true,
    this.provenance = DataProvenance.publisherProvided,
    this.uploadedAt,
  });

  final String id;
  final String title;
  final String documentType;
  final String? url;
  final bool isSensitive;
  final DataProvenance provenance;
  final DateTime? uploadedAt;
}

class PropertyPublisher {
  const PropertyPublisher({
    this.id,
    this.name,
    this.companyName,
    this.logoUrl,
    this.phone,
    this.isVerified = false,
  });

  final String? id;
  final String? name;
  final String? companyName;
  final String? logoUrl;
  final String? phone;
  final bool isVerified;

  bool get hasIdentity =>
      (name != null && name!.isNotEmpty) ||
      (companyName != null && companyName!.isNotEmpty);
}

enum InquiryType { general, sales, rentToOwn, financing, other }

class PropertyInquiryDraft {
  const PropertyInquiryDraft({
    required this.propertyId,
    required this.userId,
    required this.inquiryType,
    this.message,
    this.assignedTeam = 'sales',
  });

  final String propertyId;
  final String userId;
  final InquiryType inquiryType;
  final String? message;
  final String assignedTeam;
}

enum TourType { inPerson, video }

class PropertyTourRequest {
  const PropertyTourRequest({
    required this.propertyId,
    required this.userId,
    required this.tourType,
    this.preferredDate,
    this.preferredTime,
    this.notes,
  });

  final String propertyId;
  final String userId;
  final TourType tourType;
  final DateTime? preferredDate;
  final String? preferredTime;
  final String? notes;
}

/// Future-facing insight tags — never shown as hard facts if AI/rule based.
class PropertyInsight {
  const PropertyInsight({
    required this.code,
    required this.label,
    this.provenance = DataProvenance.estimated,
  });

  final String code;
  final String label;
  final DataProvenance provenance;
}
