import '../enums/property_status.dart';
import 'property_areas.dart';
import 'property_documents.dart';
import 'property_features.dart';
import 'property_finance.dart';
import 'property_language.dart';
import 'property_location.dart';
import 'property_media.dart';
import 'property_pricing.dart';
import 'property_surroundings.dart';

/// Aggregate root for the Property Intelligence Report.
/// Sections with no data must not be rendered.
class PropertyReport {
  const PropertyReport({
    required this.id,
    required this.title,
    required this.status,
    required this.location,
    required this.pricing,
    required this.areas,
    required this.facts,
    required this.media,
    required this.features,
    required this.history,
    required this.surroundings,
    this.description,
    this.whatsSpecial,
    this.rentToOwn,
    this.investment,
    this.rental,
    this.mortgageDefaults,
    this.documents = const [],
    this.publisher,
    this.insights = const [],
    this.lastUpdatedAt,
    this.isVerified = false,
    this.isFeatured = false,
    this.isSaved = false,
    this.originalLanguage = ContentLanguage.unknown,
    this.contentVersion = '1',
    this.rawSource = const {},
  });

  final String id;
  final String title;
  final PropertyStatus status;
  final PropertyLocation location;
  final PropertyPricing pricing;
  final PropertyAreas areas;
  final PropertyFacts facts;
  final PropertyMediaGallery media;
  final PropertyFeatures features;
  final PropertyHistory history;
  final PropertySurroundings surroundings;
  final String? description;
  final WhatsSpecialContent? whatsSpecial;
  final RentToOwnTerms? rentToOwn;
  final InvestmentMetrics? investment;
  final RentalAnalysis? rental;
  final MortgageDefaults? mortgageDefaults;
  final List<PropertyDocumentMeta> documents;
  final PropertyPublisher? publisher;
  final List<PropertyInsight> insights;
  final DateTime? lastUpdatedAt;
  final bool isVerified;
  final bool isFeatured;
  final bool isSaved;
  /// Language the publisher wrote human-readable content in.
  final ContentLanguage originalLanguage;
  /// Bumps when publisher edits translatable content — invalidates translations.
  final String contentVersion;
  final Map<String, dynamic> rawSource;

  /// Show translate CTA when property language differs from the user's UI language.
  bool needsTranslationFor(ContentLanguage userLanguage) {
    if (originalLanguage == ContentLanguage.unknown) {
      return (description?.trim().isNotEmpty == true) ||
          (whatsSpecial?.hasContent == true) ||
          title.trim().isNotEmpty;
    }
    return !originalLanguage.matches(userLanguage);
  }

  PropertyReport copyWith({
    bool? isSaved,
    ContentLanguage? originalLanguage,
    String? contentVersion,
  }) {
    return PropertyReport(
      id: id,
      title: title,
      status: status,
      location: location,
      pricing: pricing,
      areas: areas,
      facts: facts,
      media: media,
      features: features,
      history: history,
      surroundings: surroundings,
      description: description,
      whatsSpecial: whatsSpecial,
      rentToOwn: rentToOwn,
      investment: investment,
      rental: rental,
      mortgageDefaults: mortgageDefaults,
      documents: documents,
      publisher: publisher,
      insights: insights,
      lastUpdatedAt: lastUpdatedAt,
      isVerified: isVerified,
      isFeatured: isFeatured,
      isSaved: isSaved ?? this.isSaved,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      contentVersion: contentVersion ?? this.contentVersion,
      rawSource: rawSource,
    );
  }

  // ── Section visibility (progressive disclosure) ──────────────────────────

  bool get showMedia => media.isNotEmpty;
  bool get showDescription =>
      description != null && description!.trim().isNotEmpty;
  bool get showWhatsSpecial => whatsSpecial?.hasContent == true;
  bool get showFacts => facts.hasAny || areas.hasAny;
  bool get showInterior => features.hasInterior;
  bool get showExterior => features.hasExterior;
  bool get showUtilities => features.hasUtilities;
  bool get showEnergy => features.hasEnergy;
  bool get showBuilding => features.hasBuilding;
  bool get showRenovation => features.hasRenovation;
  bool get showDevelopmentPotential => features.hasDevelopmentPotential;
  bool get showPriceHistory => history.hasPriceHistory;
  bool get showTaxHistory => history.hasTaxHistory;
  bool get showSalesHistory => history.hasSalesHistory;
  bool get showValuation =>
      pricing.hasEstimates || pricing.previousPrice != null;
  bool get showInvestment => investment?.hasAny == true;
  bool get showRental => rental?.hasAny == true;
  bool get showRentToOwn => rentToOwn?.shouldShow == true;
  bool get showMortgage =>
      mortgageDefaults?.isFinancable == true ||
      status == PropertyStatus.mortgage ||
      status == PropertyStatus.forSale;
  bool get showNeighborhood => surroundings.neighborhood?.hasAny == true;
  bool get showNearby => surroundings.hasNearby;
  bool get showTransportation =>
      surroundings.transportation?.hasAny == true;
  bool get showFutureProjects => surroundings.hasFutureProjects;
  bool get showInvestmentProjects => surroundings.hasInvestmentProjects;
  bool get showInfrastructure =>
      surroundings.infrastructureNotes.isNotEmpty;
  bool get showClimateRisk => surroundings.climateRisk?.hasAny == true;
  bool get showDocuments => documents.any((d) => !d.isSensitive);
  bool get showPublisher => publisher?.hasIdentity == true;
  bool get showInsights => insights.isNotEmpty;
  bool get showMap => location.hasCoordinates;
  bool get showTour3d => media.has3dTour;
  bool get showTour360 => media.has360Tour;
  bool get showFloorPlan => media.hasFloorPlan;
}
