import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/property_extended.dart';
import '../../domain/models/property_report.dart';
import 'report_section.dart';

class PropertyDimensionsSection extends StatelessWidget {
  const PropertyDimensionsSection({super.key, required this.dimensions});

  final PropertyDimensions dimensions;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final site = <(String, String)>[];

    void addM(String label, double? v) {
      if (v != null) site.add((label, '${v.toStringAsFixed(1)} m'));
    }

    addM(loc.landLength, dimensions.landLengthM);
    addM(loc.landWidth, dimensions.landWidthM);
    addM(loc.buildingLength, dimensions.buildingLengthM);
    addM(loc.buildingWidth, dimensions.buildingWidthM);
    addM(loc.frontage, dimensions.frontageM);
    addM(loc.rearWidth, dimensions.rearWidthM);
    addM(loc.sideLength, dimensions.sideLengthM);
    addM(loc.streetWidth, dimensions.streetWidthM);
    addM(loc.setback, dimensions.setbackM);
    addM(loc.buildingHeight, dimensions.buildingHeightM);
    addM(loc.ceilingHeight, dimensions.ceilingHeightM);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (site.isNotEmpty) FactGrid(items: site),
        if (dimensions.hasRooms) ...[
          if (site.isNotEmpty) const SizedBox(height: 12),
          ...dimensions.rooms.map((room) {
            final parts = <String>[];
            final dims = room.formatDimensions();
            if (dims.isNotEmpty) parts.add(dims);
            if (room.areaSqm != null) {
              parts.add('${room.areaSqm!.toStringAsFixed(1)} m²');
            }
            if (room.ceilingHeightM != null) {
              parts.add('${loc.ceilingHeight}: ${room.ceilingHeightM!.toStringAsFixed(1)} m');
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      room.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(parts.join(' · ')),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class PropertyConstructionSection extends StatelessWidget {
  const PropertyConstructionSection({super.key, required this.construction});

  final PropertyConstruction construction;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final items = <(String, String)>[];
    if (construction.yearBuilt != null) {
      items.add((loc.yearBuilt, '${construction.yearBuilt}'));
    }
    if (construction.constructionStatus?.isNotEmpty == true) {
      items.add((loc.constructionStatusLabel, construction.constructionStatus!));
    }
    if (construction.lastRenovation?.isNotEmpty == true) {
      items.add((loc.lastRenovationLabel, construction.lastRenovation!));
    }
    if (construction.lastMaintenance?.isNotEmpty == true) {
      items.add((loc.lastMaintenanceLabel, construction.lastMaintenance!));
    }
    if (construction.constructionMaterial?.isNotEmpty == true) {
      items.add(('${loc.materialLabel} (${loc.constructionSection})', construction.constructionMaterial!));
    }
    if (construction.structureType?.isNotEmpty == true) {
      items.add((loc.structureTypeLabel, construction.structureType!));
    }
    if (construction.foundationType?.isNotEmpty == true) {
      items.add((loc.foundationTypeLabel, construction.foundationType!));
    }
    if (construction.roofType?.isNotEmpty == true) {
      items.add((loc.roofTypeLabel, construction.roofType!));
    }
    if (construction.exteriorMaterial?.isNotEmpty == true) {
      items.add(('${loc.exterior} ${loc.materialLabel}', construction.exteriorMaterial!));
    }
    if (construction.interiorMaterial?.isNotEmpty == true) {
      items.add(('${loc.interior} ${loc.materialLabel}', construction.interiorMaterial!));
    }
    return FactGrid(items: items);
  }
}

class PropertyBuilderSection extends StatelessWidget {
  const PropertyBuilderSection({
    super.key,
    required this.builder,
    this.onCompanyTap,
  });

  final PropertyBuilderInfo builder;
  final VoidCallback? onCompanyTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final items = <(String, String)>[];
    if (builder.companyName?.isNotEmpty == true) {
      items.add((loc.companyNameLabel, builder.companyName!));
    }
    if (builder.developer?.isNotEmpty == true) {
      items.add((loc.developerLabel, builder.developer!));
    }
    if (builder.contractorName?.isNotEmpty == true) {
      items.add((loc.contractorLabel, builder.contractorName!));
    }
    if (builder.projectName?.isNotEmpty == true) {
      items.add((loc.projectNameLabel, builder.projectName!));
    }
    if (builder.architect?.isNotEmpty == true) {
      items.add((loc.architectLabel, builder.architect!));
    }
    if (builder.engineeringOffice?.isNotEmpty == true) {
      items.add((loc.engineeringOfficeLabel, builder.engineeringOffice!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FactGrid(items: items),
        if (builder.companyId?.isNotEmpty == true && onCompanyTap != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onCompanyTap,
            icon: const Icon(Icons.business_outlined, size: 18),
            label: Text(loc.companyNameLabel),
          ),
        ],
      ],
    );
  }
}

class PropertyListingInfoSection extends StatelessWidget {
  const PropertyListingInfoSection({
    super.key,
    required this.meta,
    required this.report,
  });

  final PropertyListingMeta meta;
  final PropertyReport report;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final items = <(String, String)>[];
    if (meta.propertyNumberId?.isNotEmpty == true) {
      items.add((loc.propertyIdLabel, meta.propertyNumberId!));
    }
    if (meta.listingId?.isNotEmpty == true) {
      items.add((loc.listingIdLabel, meta.listingId!));
    }
    if (meta.publisherName?.isNotEmpty == true) {
      items.add((loc.publisher, meta.publisherName!));
    }
    if (meta.publishedAt != null) {
      items.add((
        loc.publishedDateLabel,
        '${meta.publishedAt!.year}-${meta.publishedAt!.month.toString().padLeft(2, '0')}-${meta.publishedAt!.day.toString().padLeft(2, '0')}',
      ));
    }
    if (meta.views != null) items.add((loc.viewsLabel, '${meta.views}'));
    if (meta.saves != null) items.add((loc.savesLabel, '${meta.saves}'));
    if (meta.shares != null) items.add((loc.sharesLabel, '${meta.shares}'));
    if (report.lastUpdatedAt != null) {
      items.add((
        loc.lastUpdated,
        '${report.lastUpdatedAt!.year}-${report.lastUpdatedAt!.month.toString().padLeft(2, '0')}-${report.lastUpdatedAt!.day.toString().padLeft(2, '0')}',
      ));
    }
    return FactGrid(items: items);
  }
}

class PropertyVerificationSection extends StatelessWidget {
  const PropertyVerificationSection({super.key, required this.verification});

  final PropertyVerificationFlags verification;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final flags = <(String, bool)>[
      (loc.propertyVerifiedLabel, verification.propertyVerified),
      (loc.locationVerifiedLabel, verification.locationVerified),
      (loc.informationVerifiedLabel, verification.informationVerified),
      (loc.documentsVerifiedLabel, verification.documentsVerified),
      (loc.photosVerifiedLabel, verification.photosVerified),
    ].where((e) => e.$2).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: flags
          .map(
            (f) => Chip(
              avatar: Icon(Icons.verified_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
              label: Text(f.$1),
              visualDensity: VisualDensity.compact,
            ),
          )
          .toList(),
    );
  }
}

class PropertyMarketAnalyticsSection extends StatelessWidget {
  const PropertyMarketAnalyticsSection({super.key, required this.analytics});

  final PropertyMarketAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final items = <(String, String)>[];
    if (analytics.averagePriceInArea != null) {
      items.add((loc.averagePriceArea, analytics.averagePriceInArea!));
    }
    if (analytics.averagePricePerSqm != null) {
      items.add((loc.sqmPrice, analytics.averagePricePerSqm!));
    }
    if (analytics.averageRent != null) {
      items.add((loc.monthlyRentLabel, analytics.averageRent!));
    }
    if (analytics.averageRentalYield != null) {
      items.add((loc.rentalYieldLabel, '${analytics.averageRentalYield!.toStringAsFixed(1)}%'));
    }
    if (analytics.priceTrend?.isNotEmpty == true) {
      items.add((loc.priceTrendLabel, analytics.priceTrend!));
    }
    if (analytics.demand?.isNotEmpty == true) {
      items.add((loc.demandLabel, analytics.demand!));
    }
    if (analytics.daysOnMarket != null) {
      items.add((loc.daysOnMarketLabel, '${analytics.daysOnMarket}'));
    }
    if (analytics.listingsCount != null) {
      items.add((loc.propertyCount, '${analytics.listingsCount}'));
    }
    return FactGrid(items: items);
  }
}

class PropertyLocationIntelSection extends StatelessWidget {
  const PropertyLocationIntelSection({super.key, required this.report});

  final PropertyReport report;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final l = report.location;
    final items = <(String, String)>[];
    if (l.latitude != null) {
      items.add((loc.latitudeLabel, l.latitude!.toStringAsFixed(6)));
    }
    if (l.longitude != null) {
      items.add((loc.longitudeLabel, l.longitude!.toStringAsFixed(6)));
    }
    if (l.elevationM != null) {
      items.add((loc.elevationLabel, '${l.elevationM!.toStringAsFixed(0)} m'));
    }
    if (l.neighborhood?.isNotEmpty == true) {
      items.add((loc.neighborhood, l.neighborhood!));
    }
    if (l.district?.isNotEmpty == true) {
      items.add((loc.districtLabel, l.district!));
    }
    if (l.city?.isNotEmpty == true) {
      items.add((loc.city, l.city!));
    }
    if (l.province?.isNotEmpty == true) {
      items.add((loc.provinceLabel, l.province!));
    }
    if (l.countryName?.isNotEmpty == true) {
      items.add((loc.country, l.countryName!));
    }
    return FactGrid(items: items);
  }
}
