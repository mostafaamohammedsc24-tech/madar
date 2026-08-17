import 'dart:typed_data';

import '../../../core/localization/app_localizations.dart';

enum OwnedListingKind { titled, managed }

enum OwnedListingStatus { active, pending, underReview }

/// A property the signed-in user owns or has submitted for listing.
class OwnedProperty {
  const OwnedProperty({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.titleKu,
    required this.addressAr,
    required this.addressEn,
    required this.addressKu,
    required this.kind,
    required this.status,
    required this.marketValueUsd,
    this.imageUrl,
    this.imageBytes,
    this.areaSqm = 0,
    this.bedrooms = 0,
    this.propertyType = 'apartment',
    this.monthlyIncomeUsd,
    this.managementFeeUsd,
    this.insights = const [],
    this.contactPhone,
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final String titleKu;
  final String addressAr;
  final String addressEn;
  final String addressKu;
  final OwnedListingKind kind;
  final OwnedListingStatus status;
  final double marketValueUsd;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final double areaSqm;
  final int bedrooms;
  final String propertyType;
  final double? monthlyIncomeUsd;
  final double? managementFeeUsd;
  final List<OwnedPriceInsight> insights;
  final String? contactPhone;

  String title(AppLocalizations loc) {
    return switch (loc.language) {
      AppLanguage.arabic => titleAr,
      AppLanguage.kurdish => titleKu,
      AppLanguage.english => titleEn,
    };
  }

  String address(AppLocalizations loc) {
    return switch (loc.language) {
      AppLanguage.arabic => addressAr,
      AppLanguage.kurdish => addressKu,
      AppLanguage.english => addressEn,
    };
  }

  factory OwnedProperty.fromRemote(Map<String, dynamic> map) {
    final media = map['property_media_v3'];
    String? imageUrl =
        map['image_url'] as String? ?? map['imageUrl'] as String?;
    if (imageUrl == null && media is List && media.isNotEmpty) {
      final first = media.first;
      if (first is Map) {
        imageUrl = first['media_url'] as String? ?? first['url'] as String?;
      }
    }

    final listing =
        (map['listing_type'] as String? ??
                map['listingType'] as String? ??
                map['kind'] as String? ??
                'sale')
            .toLowerCase();
    final kind = (listing == 'rent' || listing == 'managed')
        ? OwnedListingKind.managed
        : OwnedListingKind.titled;

    final rawStatus = (map['status'] as String? ?? 'active').toLowerCase();
    final status = switch (rawStatus) {
      'under_review' ||
      'review' ||
      'underreview' => OwnedListingStatus.underReview,
      'pending' => OwnedListingStatus.pending,
      _ => OwnedListingStatus.active,
    };

    final title = map['title'] as String? ?? map['address'] as String? ?? '';
    final address =
        map['address'] as String? ?? map['address_text'] as String? ?? '';

    return OwnedProperty(
      id: map['id']?.toString() ?? title,
      titleAr: map['title_ar'] as String? ?? title,
      titleEn: map['title_en'] as String? ?? title,
      titleKu: map['title_ku'] as String? ?? title,
      addressAr: map['address_ar'] as String? ?? address,
      addressEn: map['address_en'] as String? ?? address,
      addressKu: map['address_ku'] as String? ?? address,
      kind: kind,
      status: status,
      marketValueUsd:
          (map['asking_price_usd'] as num?)?.toDouble() ??
          (map['market_value_usd'] as num?)?.toDouble() ??
          0,
      imageUrl: imageUrl,
      areaSqm:
          (map['area'] as num?)?.toDouble() ??
          (map['area_sqm'] as num?)?.toDouble() ??
          0,
      bedrooms: (map['bedrooms'] as num?)?.toInt() ?? 0,
      propertyType: map['property_type'] as String? ?? 'apartment',
      monthlyIncomeUsd: (map['monthly_income_usd'] as num?)?.toDouble(),
      managementFeeUsd: (map['management_fee_usd'] as num?)?.toDouble(),
      insights: OwnedPriceInsightX.fromKeys(map['insights']),
      contactPhone: map['contact_phone'] as String?,
    );
  }
}

enum OwnedPriceInsight { photos, kitchen, deed }

extension OwnedPriceInsightX on OwnedPriceInsight {
  String label(AppLocalizations loc) {
    return switch (this) {
      OwnedPriceInsight.photos => loc.priceInsightPhotos,
      OwnedPriceInsight.kitchen => loc.priceInsightKitchen,
      OwnedPriceInsight.deed => loc.priceInsightDeed,
    };
  }

  static List<OwnedPriceInsight> fromKeys(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) {
          switch (item.toString()) {
            case 'photos':
              return OwnedPriceInsight.photos;
            case 'kitchen':
              return OwnedPriceInsight.kitchen;
            case 'deed':
              return OwnedPriceInsight.deed;
            default:
              return null;
          }
        })
        .whereType<OwnedPriceInsight>()
        .toList();
  }
}
