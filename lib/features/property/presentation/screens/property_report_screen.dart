import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/layout/directional_layout.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/chat_notifier.dart';
import '../../../../services/supabase_service.dart';
import '../../data/repositories/property_report_repository.dart';
import '../../domain/enums/data_provenance.dart';
import '../../domain/models/property_documents.dart';
import '../../domain/models/property_finance.dart';
import '../../domain/models/property_report.dart';
import '../../domain/models/property_surroundings.dart';
import '../widgets/property_media_gallery.dart';
import '../widgets/property_status_badge.dart';
import '../widgets/property_sticky_action_bar.dart';
import '../widgets/provenance_chip.dart';
import '../widgets/report_section.dart';

/// Comprehensive Property Intelligence Report.
/// Sections render only when the [PropertyReport] has real data.
class PropertyReportScreen extends ConsumerStatefulWidget {
  const PropertyReportScreen({super.key, required this.property});

  final Map<String, dynamic> property;

  @override
  ConsumerState<PropertyReportScreen> createState() =>
      _PropertyReportScreenState();
}

class _PropertyReportScreenState extends ConsumerState<PropertyReportScreen> {
  final _repo = PropertyReportRepository();
  PropertyReport? _report;
  bool _loading = true;

  static const _aiConfig = ChatConfig(
    provider: 'GEMINI',
    model: 'gemini/gemini-2.5-flash',
    streaming: true,
  );

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final id = widget.property['id']?.toString();
    PropertyReport? report;
    if (id != null && id.isNotEmpty) {
      report = await _repo.loadById(id, seed: widget.property);
    } else {
      report = _repo.fromMap(widget.property);
    }
    if (!mounted) return;
    setState(() {
      _report = report;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_loading || _report == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    final report = _report!;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: report.showMedia ? 320 : 120,
                  pinned: true,
                  leading: IconButton(
                    icon: DirectionalBackIcon(
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        report.isSaved
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                      ),
                      onPressed: _toggleSave,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: _share,
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: report.showMedia
                        ? PropertyMediaGalleryView(
                            gallery: report.media,
                            onOpen3d: report.showTour3d
                                ? () => _openExternalMedia(
                                      report.media.tour3d?.url,
                                    )
                                : null,
                            onOpen360: report.showTour360
                                ? () => _openExternalMedia(
                                      report.media.tour360?.url,
                                    )
                                : null,
                            onOpenFloorPlan: report.showFloorPlan
                                ? () => _showFloorPlanSheet(report)
                                : null,
                          )
                        : Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildHeader(report, loc, theme)),
                SliverToBoxAdapter(child: _buildActionRow(report, loc)),
                if (report.showWhatsSpecial)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.whatsSpecial,
                      icon: Icons.auto_awesome,
                      child: _buildWhatsSpecial(report, theme),
                    ),
                  ),
                if (report.showFacts)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.factsAndFeatures,
                      icon: Icons.grid_view_rounded,
                      child: _buildFacts(report, loc),
                    ),
                  ),
                if (report.showDescription)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.description,
                      icon: Icons.notes_outlined,
                      initiallyExpanded: false,
                      child: Text(
                        report.description!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: ReportSection(
                    title: loc.priceAndValuation,
                    icon: Icons.payments_outlined,
                    child: _buildPricing(report, loc, theme),
                  ),
                ),
                if (report.showPriceHistory)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.priceHistory,
                      icon: Icons.timeline,
                      initiallyExpanded: false,
                      child: _buildPriceHistory(report, theme),
                    ),
                  ),
                if (report.showTaxHistory)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.taxHistory,
                      icon: Icons.receipt_long_outlined,
                      initiallyExpanded: false,
                      child: _buildTaxHistory(report, theme),
                    ),
                  ),
                if (report.showSalesHistory)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.salesHistory,
                      icon: Icons.history,
                      initiallyExpanded: false,
                      child: _buildSalesHistory(report, theme),
                    ),
                  ),
                if (report.showRentToOwn)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.leaseToOwn,
                      icon: Icons.home_work_outlined,
                      child: _buildRentToOwn(report, loc, theme),
                    ),
                  ),
                if (report.showMortgage)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.mortgageCalc,
                      icon: Icons.calculate_outlined,
                      initiallyExpanded: false,
                      child: _MortgageCalculator(
                        price: report.pricing.currentPrice?.amount ?? 0,
                        defaults: report.mortgageDefaults,
                      ),
                    ),
                  ),
                if (report.showRental)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.rentAnalysis,
                      icon: Icons.apartment_outlined,
                      initiallyExpanded: false,
                      child: _buildRental(report, loc),
                    ),
                  ),
                if (report.showInvestment)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.investmentPotential,
                      icon: Icons.trending_up,
                      initiallyExpanded: false,
                      trailing: const ProvenanceChip(
                        provenance: DataProvenance.estimated,
                      ),
                      child: _buildInvestment(report, loc),
                    ),
                  ),
                if (report.showInterior)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.interior,
                      icon: Icons.weekend_outlined,
                      initiallyExpanded: false,
                      child: _featureList(report.features.interior.displayEntries),
                    ),
                  ),
                if (report.showExterior)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.exterior,
                      icon: Icons.cottage_outlined,
                      initiallyExpanded: false,
                      child: _featureList(report.features.exterior.displayEntries),
                    ),
                  ),
                if (report.showUtilities)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.utilitiesServices,
                      icon: Icons.electrical_services_outlined,
                      initiallyExpanded: false,
                      child: _featureList(
                        report.features.utilities.displayEntries,
                      ),
                    ),
                  ),
                if (report.showEnergy)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.energySustainability,
                      icon: Icons.solar_power_outlined,
                      initiallyExpanded: false,
                      child: _featureList(report.features.energy.displayEntries),
                    ),
                  ),
                if (report.showBuilding)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.buildingDetails,
                      icon: Icons.domain,
                      initiallyExpanded: false,
                      child: _featureList(
                        report.features.building.displayEntries,
                      ),
                    ),
                  ),
                if (report.showRenovation)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.renovationImprovements,
                      icon: Icons.construction_outlined,
                      initiallyExpanded: false,
                      child: _featureList(
                        report.features.renovation.displayEntries,
                      ),
                    ),
                  ),
                if (report.showDevelopmentPotential)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.developmentPotential,
                      icon: Icons.architecture_outlined,
                      initiallyExpanded: false,
                      child: _featureList(
                        report.features.developmentPotential.displayEntries,
                      ),
                    ),
                  ),
                if (report.showNeighborhood)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.neighborhood,
                      icon: Icons.location_city_outlined,
                      initiallyExpanded: false,
                      child: _buildNeighborhood(report, loc, theme),
                    ),
                  ),
                if (report.showNearby)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.nearbyPlaces,
                      icon: Icons.place_outlined,
                      initiallyExpanded: false,
                      child: _buildNearby(report, theme),
                    ),
                  ),
                if (report.showTransportation)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.transportationAccess,
                      icon: Icons.directions_transit_outlined,
                      initiallyExpanded: false,
                      child: _buildTransport(report, theme),
                    ),
                  ),
                if (report.showFutureProjects)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.futureOfArea,
                      icon: Icons.upcoming_outlined,
                      initiallyExpanded: false,
                      child: _buildProjects(
                        report.surroundings.futureProjects,
                        theme,
                      ),
                    ),
                  ),
                if (report.showInvestmentProjects)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.nearbyInvestmentOpportunities,
                      icon: Icons.business_center_outlined,
                      initiallyExpanded: false,
                      child: _buildProjects(
                        report.surroundings.investmentProjects,
                        theme,
                      ),
                    ),
                  ),
                if (report.showInfrastructure)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.infrastructure,
                      icon: Icons.account_tree_outlined,
                      initiallyExpanded: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: report.surroundings.infrastructureNotes
                            .map(
                              (n) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(n)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                if (report.showClimateRisk)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.risksEnvironment,
                      icon: Icons.warning_amber_outlined,
                      initiallyExpanded: false,
                      trailing: ProvenanceChip(
                        provenance:
                            report.surroundings.climateRisk!.provenance,
                      ),
                      child: _buildClimate(report, theme),
                    ),
                  ),
                if (report.showDocuments)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.documents,
                      icon: Icons.folder_outlined,
                      initiallyExpanded: false,
                      child: _buildDocuments(report, theme),
                    ),
                  ),
                if (report.showPublisher)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.publisher,
                      icon: Icons.badge_outlined,
                      initiallyExpanded: false,
                      child: _buildPublisher(report, theme),
                    ),
                  ),
                if (report.lastUpdatedAt != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Text(
                        '${loc.lastUpdated}: ${_formatDate(report.lastUpdatedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
          PropertyStickyActionBar(
            isSaved: report.isSaved,
            onSave: _toggleSave,
            onContact: _contactSales,
            onAskAi: () => _openAiAdvisor(report),
            onScheduleTour: () => _scheduleTour(report),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    PropertyReport report,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    final price = report.pricing.currentPrice;
    final perSqm = report.pricing.pricePerSqm;
    final hierarchy = report.location.hierarchy;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PropertyStatusBadge(status: report.status),
              if (report.isVerified) ...[
                const SizedBox(width: 8),
                const ProvenanceChip(provenance: DataProvenance.verified),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          if (hierarchy.isNotEmpty)
            Text(
              hierarchy.join(' · '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else if (report.location.displayLine.isNotEmpty)
            Text(
              report.location.displayLine,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 14),
          if (price != null)
            Text(
              price.format(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          if (perSqm != null) ...[
            const SizedBox(height: 4),
            Text(
              '${loc.sqmPrice}: ${perSqm.format()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (report.pricing.changePercent != null) ...[
            const SizedBox(height: 4),
            Text(
              '${loc.priceChange}: ${report.pricing.changePercent!.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: report.pricing.changePercent! >= 0
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow(PropertyReport report, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: _contactSales,
            icon: const Icon(Icons.support_agent, size: 18),
            label: Text(loc.contactConnect),
          ),
          OutlinedButton.icon(
            onPressed: () => _openAiAdvisor(report),
            icon: const Icon(Icons.psychology_outlined, size: 18),
            label: Text(loc.askAi),
          ),
          OutlinedButton.icon(
            onPressed: () => _scheduleTour(report),
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: Text(loc.scheduleTour),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsSpecial(PropertyReport report, ThemeData theme) {
    final ws = report.whatsSpecial!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ws.headline != null)
          Text(
            ws.headline!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        if (ws.body != null) ...[
          const SizedBox(height: 8),
          Text(ws.body!),
        ],
        if (ws.highlights.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...ws.highlights.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.star_outline, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(h)),
                ],
              ),
            ),
          ),
        ],
        if (ws.investmentNotes.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...ws.investmentNotes.map(
            (n) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $n'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFacts(PropertyReport report, AppLocalizations loc) {
    final items = <(String, String)>[];
    final f = report.facts;
    final a = report.areas;

    if (a.builtUp != null) {
      items.add((loc.builtUpArea, a.builtUp!.format()));
    } else if (a.primary != null) {
      items.add((loc.builtUpArea, a.primary!.format()));
    }
    if (a.land != null) items.add((loc.landArea, a.land!.format()));
    if (f.bedrooms != null) items.add((loc.bedrooms, '${f.bedrooms}'));
    if (f.bathrooms != null) items.add((loc.bathrooms, '${f.bathrooms}'));
    if (f.livingRooms != null) {
      items.add((loc.livingRooms, '${f.livingRooms}'));
    }
    if (f.propertyType != null) {
      items.add((loc.propertyTypeLabel, f.propertyType!));
    }
    if (f.yearBuilt != null) items.add((loc.yearBuilt, '${f.yearBuilt}'));
    if (f.yearRenovated != null) {
      items.add((loc.yearRenovated, '${f.yearRenovated}'));
    }
    if (f.parkingSpaces != null) {
      items.add((loc.parking, '${f.parkingSpaces}'));
    }
    if (f.floorNumber != null) items.add((loc.floor, '${f.floorNumber}'));
    if (f.totalFloors != null) {
      items.add((loc.totalFloors, '${f.totalFloors}'));
    }
    if (f.hasElevator != null) {
      items.add((loc.elevator, f.hasElevator! ? loc.yesLabel : loc.noLabel));
    }
    if (f.isFurnished != null) {
      items.add((loc.furnished, f.isFurnished! ? loc.yesLabel : loc.noLabel));
    }
    if (f.hasBalcony != null) {
      items.add((loc.balcony, f.hasBalcony! ? loc.yesLabel : loc.noLabel));
    }
    if (f.hasGarden != null) {
      items.add((loc.garden, f.hasGarden! ? loc.yesLabel : loc.noLabel));
    }
    if (f.hasPool != null) {
      items.add((loc.pool, f.hasPool! ? loc.yesLabel : loc.noLabel));
    }

    for (final e in a.nonEmptyEntries) {
      if (e.key == 'builtUp' || e.key == 'land') continue;
      items.add((e.key, e.value.format()));
    }

    if (report.features.amenityTags.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FactGrid(items: items),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: report.features.amenityTags
                .map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact))
                .toList(),
          ),
        ],
      );
    }
    return FactGrid(items: items);
  }

  Widget _buildPricing(
    PropertyReport report,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    final rows = <Widget>[];
    void addRow(String label, String value, DataProvenance p) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              ProvenanceChip(provenance: p),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }

    final p = report.pricing;
    if (p.currentPrice != null) {
      addRow(loc.currentPrice, p.currentPrice!.format(), p.currentPrice!.provenance);
    }
    if (p.pricePerSqm != null) {
      addRow(loc.sqmPrice, p.pricePerSqm!.format(), p.pricePerSqm!.provenance);
    }
    if (p.previousPrice != null) {
      addRow(
        loc.previousPrice,
        p.previousPrice!.format(),
        p.previousPrice!.provenance,
      );
    }
    if (p.estimatedValue != null) {
      addRow(
        loc.estimatedValue,
        p.estimatedValue!.format(),
        p.estimatedValue!.provenance,
      );
    }
    if (p.estimatedRentalValue != null) {
      addRow(
        loc.madarEstimate,
        p.estimatedRentalValue!.format(),
        p.estimatedRentalValue!.provenance,
      );
    }
    return Column(children: rows);
  }

  Widget _buildPriceHistory(PropertyReport report, ThemeData theme) {
    return Column(
      children: report.history.priceHistory.map((e) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(e.price.format()),
          subtitle: Text(
            '${_formatDate(e.effectiveDate)}${e.reason != null ? ' · ${e.reason}' : ''}',
          ),
          trailing: e.changePercent != null
              ? Text(
                  '${e.changePercent!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: e.changePercent! >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : ProvenanceChip(provenance: e.provenance),
        );
      }).toList(),
    );
  }

  Widget _buildTaxHistory(PropertyReport report, ThemeData theme) {
    return Column(
      children: report.history.taxHistory.map((e) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${e.taxYear}'),
          subtitle: Text(
            [
              if (e.assessedValue != null) e.assessedValue!.format(),
              if (e.taxAmount != null) e.taxAmount!.format(),
            ].join(' · '),
          ),
          trailing: ProvenanceChip(provenance: e.provenance),
        );
      }).toList(),
    );
  }

  Widget _buildSalesHistory(PropertyReport report, ThemeData theme) {
    return Column(
      children: report.history.salesHistory.map((e) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(e.salePrice.format()),
          subtitle: Text(
            [
              _formatDate(e.soldAt),
              if (e.transactionType != null) e.transactionType!,
              if (e.sourceName != null) e.sourceName!,
            ].join(' · '),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRentToOwn(
    PropertyReport report,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    final t = report.rentToOwn!;
    final items = <(String, String)>[];
    if (t.purchasePrice != null) {
      items.add((loc.currentPrice, t.purchasePrice!.format()));
    }
    if (t.initialPayment != null) {
      items.add((loc.initialPayment, t.initialPayment!.format()));
    }
    if (t.monthlyPayment != null) {
      items.add((loc.monthlyPayment, t.monthlyPayment!.format()));
    }
    if (t.contractMonths != null) {
      items.add((loc.contractDuration, '${t.contractMonths} ${loc.months}'));
    }
    if (t.ownershipAllocationPercent != null) {
      items.add((
        loc.ownershipContribution,
        '${t.ownershipAllocationPercent!.toStringAsFixed(0)}%',
      ));
    }
    if (t.remainingAmount != null) {
      items.add((loc.remainingBalance, t.remainingAmount!.format()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FactGrid(items: items),
        if (t.eligibilityNotes != null) ...[
          const SizedBox(height: 12),
          Text(t.eligibilityNotes!),
        ],
        if (t.ownershipConditions != null) ...[
          const SizedBox(height: 8),
          Text(t.ownershipConditions!),
        ],
        if (t.calculationRules.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            loc.rentToOwnCalculator,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          ...t.calculationRules.entries.map(
            (e) => Text('${e.key}: ${e.value}'),
          ),
        ],
      ],
    );
  }

  Widget _buildRental(PropertyReport report, AppLocalizations loc) {
    final r = report.rental!;
    final items = <(String, String)>[];
    if (r.monthlyRent != null) {
      items.add(('${loc.forRent}${loc.perMonth}', r.monthlyRent!.format()));
    }
    if (r.annualRent != null) {
      items.add((loc.rentAnalysis, r.annualRent!.format()));
    }
    if (r.rentalYield != null) {
      items.add(('Yield', '${r.rentalYield!.toStringAsFixed(1)}%'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProvenanceChip(provenance: r.provenance),
        const SizedBox(height: 8),
        FactGrid(items: items),
      ],
    );
  }

  Widget _buildInvestment(PropertyReport report, AppLocalizations loc) {
    final i = report.investment!;
    final items = <(String, String)>[];
    if (i.expectedRentalYield != null) {
      items.add(('Yield', '${i.expectedRentalYield!.toStringAsFixed(1)}%'));
    }
    if (i.grossYield != null) {
      items.add(('Gross', '${i.grossYield!.toStringAsFixed(1)}%'));
    }
    if (i.netYield != null) {
      items.add(('Net', '${i.netYield!.toStringAsFixed(1)}%'));
    }
    if (i.roi != null) {
      items.add(('ROI', '${i.roi!.toStringAsFixed(1)}%'));
    }
    if (i.estimatedAnnualRent != null) {
      items.add(('Annual rent', i.estimatedAnnualRent!.format()));
    }
    return FactGrid(items: items);
  }

  Widget _featureList(List<MapEntry<String, dynamic>> entries) {
    if (entries.isEmpty) return const EmptySectionHint();
    return Column(
      children: entries.map((e) {
        final value = e.value is bool
            ? (e.value as bool ? '✓' : '—')
            : e.value.toString();
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(e.key.replaceAll('_', ' ')),
          trailing: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNeighborhood(
    PropertyReport report,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    final n = report.surroundings.neighborhood!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProvenanceChip(provenance: n.provenance),
        if (n.summary != null) ...[
          const SizedBox(height: 8),
          Text(n.summary!),
        ],
        const SizedBox(height: 8),
        FactGrid(
          items: [
            if (n.walkScore != null)
              (loc.walkScore, n.walkScore!.toStringAsFixed(0)),
            if (n.transitScore != null)
              (loc.transitScore, n.transitScore!.toStringAsFixed(0)),
            if (n.demandLevel != null) ('Demand', n.demandLevel!),
            if (n.density != null) ('Density', n.density!),
          ],
        ),
      ],
    );
  }

  Widget _buildNearby(PropertyReport report, ThemeData theme) {
    final grouped = <NearbyPlaceCategory, List<NearbyPlace>>{};
    for (final p in report.surroundings.nearbyPlaces) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.key.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              ...e.value.map((p) {
                final meta = [
                  if (p.distanceMeters != null)
                    '${(p.distanceMeters! / 1000).toStringAsFixed(1)} km',
                  if (p.travelTimeMinutes != null)
                    '${p.travelTimeMinutes} min',
                ].join(' · ');
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name),
                  subtitle: meta.isEmpty ? null : Text(meta),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransport(PropertyReport report, ThemeData theme) {
    final t = report.surroundings.transportation!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (t.nearestMainRoad != null) Text(t.nearestMainRoad!),
        if (t.highways.isNotEmpty) Text('Highways: ${t.highways.join(', ')}'),
        if (t.transitOptions.isNotEmpty)
          Text('Transit: ${t.transitOptions.join(', ')}'),
        if (t.airportDistanceKm != null)
          Text('Airport: ${t.airportDistanceKm!.toStringAsFixed(1)} km'),
        if (t.cityCenterDistanceKm != null)
          Text('City center: ${t.cityCenterDistanceKm!.toStringAsFixed(1)} km'),
      ],
    );
  }

  Widget _buildProjects(List<FutureProject> projects, ThemeData theme) {
    return Column(
      children: projects.map((p) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(p.name),
            subtitle: Text(
              [
                if (p.type != null) p.type!,
                if (p.status != null) p.status!,
                if (p.developer != null) p.developer!,
                if (p.source != null) p.source!,
              ].join(' · '),
            ),
            trailing: Text(p.estimatedImpact.name),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClimate(PropertyReport report, ThemeData theme) {
    final c = report.surroundings.climateRisk!;
    return FactGrid(
      items: [
        if (c.floodRisk != null) ('Flood', c.floodRisk!),
        if (c.extremeHeat != null) ('Heat', c.extremeHeat!),
        if (c.wildfire != null) ('Wildfire', c.wildfire!),
        if (c.waterRisk != null) ('Water', c.waterRisk!),
      ],
    );
  }

  Widget _buildDocuments(PropertyReport report, ThemeData theme) {
    final docs = report.documents.where((d) => !d.isSensitive);
    return Column(
      children: docs
          .map(
            (d) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: Text(d.title),
              subtitle: Text(d.documentType),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPublisher(PropertyReport report, ThemeData theme) {
    final p = report.publisher!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text((p.companyName ?? p.name ?? '?')[0].toUpperCase()),
      ),
      title: Text(p.companyName ?? p.name ?? ''),
      subtitle: p.name != null && p.companyName != null ? Text(p.name!) : null,
      trailing: p.isVerified
          ? const ProvenanceChip(provenance: DataProvenance.verified)
          : null,
    );
  }

  Future<void> _toggleSave() async {
    final report = _report;
    if (report == null) return;
    final saved = await _repo.toggleSave(report.id);
    if (!mounted) return;
    setState(() {
      _report = PropertyReport(
        id: report.id,
        title: report.title,
        status: report.status,
        location: report.location,
        pricing: report.pricing,
        areas: report.areas,
        facts: report.facts,
        media: report.media,
        features: report.features,
        history: report.history,
        surroundings: report.surroundings,
        description: report.description,
        whatsSpecial: report.whatsSpecial,
        rentToOwn: report.rentToOwn,
        investment: report.investment,
        rental: report.rental,
        mortgageDefaults: report.mortgageDefaults,
        documents: report.documents,
        publisher: report.publisher,
        insights: report.insights,
        lastUpdatedAt: report.lastUpdatedAt,
        isVerified: report.isVerified,
        isFeatured: report.isFeatured,
        isSaved: saved,
        rawSource: report.rawSource,
      );
    });
  }

  Future<void> _share() async {
    final report = _report;
    if (report == null) return;
    final text =
        '${report.title}\n${report.pricing.currentPrice?.format() ?? ''}\n'
        'madar://property/${report.id}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    Fluttertoast.showToast(msg: '${loc.shareProperty}: copied');
  }

  Future<void> _contactSales() async {
    final loc = AppLocalizations.of(context);
    final report = _report!;
    final userId = SupabaseService.instance.currentUser?.id ?? 'anonymous';
    await _repo.submitSalesInquiry(
      PropertyInquiryDraft(
        propertyId: report.id,
        userId: userId,
        inquiryType: InquiryType.sales,
        message: 'Interest in ${report.title}',
      ),
    );
    if (!mounted) return;
    Fluttertoast.showToast(msg: loc.inquirySentToSales);
  }

  Future<void> _scheduleTour(PropertyReport report) async {
    final loc = AppLocalizations.of(context);
    TourType tourType = TourType.inPerson;
    final notesCtrl = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.scheduleTourTitle,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<TourType>(
                    segments: [
                      ButtonSegment(
                        value: TourType.inPerson,
                        label: Text(loc.inPersonTour),
                      ),
                      ButtonSegment(
                        value: TourType.video,
                        label: Text(loc.videoTour),
                      ),
                    ],
                    selected: {tourType},
                    onSelectionChanged: (s) =>
                        setModal(() => tourType = s.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: loc.tourNotesHint,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(loc.sendRequest),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (confirmed != true) return;
    final userId = SupabaseService.instance.currentUser?.id ?? 'anonymous';
    await _repo.submitTourRequest(
      PropertyTourRequest(
        propertyId: report.id,
        userId: userId,
        tourType: tourType,
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    Fluttertoast.showToast(msg: loc.tourRequestSent);
  }

  Future<void> _openAiAdvisor(PropertyReport report) async {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Consumer(
            builder: (ctx, ref, _) {
              final chat = ref.watch(chatNotifierProvider(_aiConfig));
              return SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      loc.askAiAboutProperty,
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.aiGroundedDisclaimer,
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (chat.response.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(chat.response),
                              ),
                            if (chat.isLoading)
                              const Padding(
                                padding: EdgeInsets.all(8),
                                child: LinearProgressIndicator(),
                              ),
                            if (chat.error != null)
                              Text(
                                chat.error.toString(),
                                style: TextStyle(
                                  color: Theme.of(ctx).colorScheme.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: loc.askAi,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: chat.isLoading
                              ? null
                              : () {
                                  final q = controller.text.trim();
                                  if (q.isEmpty) return;
                                  controller.clear();
                                  final contextBlock = _aiContext(report);
                                  ref
                                      .read(
                                        chatNotifierProvider(_aiConfig)
                                            .notifier,
                                      )
                                      .sendMessage(
                                        [
                                          {
                                            'role': 'system',
                                            'content':
                                                'You are a property advisor. Answer only from the provided property data. If data is missing, say so clearly. Never invent numbers.',
                                          },
                                          {
                                            'role': 'user',
                                            'content':
                                                '$contextBlock\n\nUser question: $q',
                                          },
                                        ],
                                        parameters: {
                                          'temperature': 0.4,
                                          'max_tokens': 700,
                                        },
                                      );
                                },
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _aiContext(PropertyReport report) {
    return '''
Property Intelligence Context (grounded facts only):
- Title: ${report.title}
- Status: ${report.status.wireValue}
- Price: ${report.pricing.currentPrice?.format() ?? 'n/a'}
- Price/m²: ${report.pricing.pricePerSqm?.format() ?? 'n/a'}
- Area: ${report.areas.primary?.format() ?? 'n/a'}
- Beds/Baths: ${report.facts.bedrooms ?? '-'}/${report.facts.bathrooms ?? '-'}
- Type: ${report.facts.propertyType ?? 'n/a'}
- Location: ${report.location.displayLine}
- Description: ${report.description ?? 'n/a'}
- What's Special: ${report.whatsSpecial?.body ?? 'n/a'}
- Amenities: ${report.features.amenityTags.join(', ')}
- Rent-to-Own available: ${report.rentToOwn?.isAvailable == true}
- Verified: ${report.isVerified}
''';
  }

  Future<void> _openExternalMedia(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showFloorPlanSheet(PropertyReport report) {
    final plans = report.media.items
        .where((i) => i.kind.toString().contains('floorPlan') || i.category.toString().contains('floorPlan'))
        .toList();
    // Prefer floor-plan kind
    final items = report.media.items
        .where((i) => i.kind.name == 'floorPlan')
        .toList();
    final show = items.isNotEmpty ? items : plans;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(loc.floorPlan)),
              if (show.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptySectionHint(),
                )
              else
                SizedBox(
                  height: 240,
                  child: PageView(
                    children: show
                        .map(
                          (m) => InteractiveViewer(
                            child: Image.network(m.url, fit: BoxFit.contain),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _MortgageCalculator extends StatefulWidget {
  const _MortgageCalculator({required this.price, this.defaults});

  final double price;
  final MortgageDefaults? defaults;

  @override
  State<_MortgageCalculator> createState() => _MortgageCalculatorState();
}

class _MortgageCalculatorState extends State<_MortgageCalculator> {
  late double _downPercent;
  late double _rate;
  late int _years;

  @override
  void initState() {
    super.initState();
    _downPercent = widget.defaults?.downPaymentPercent ?? 20;
    _rate = widget.defaults?.interestRatePercent ?? 7.5;
    _years = widget.defaults?.termYears ?? 20;
  }

  double get _payment {
    final principal = widget.price * (1 - _downPercent / 100);
    if (principal <= 0) return 0;
    final r = _rate / 100 / 12;
    final n = _years * 12;
    if (r == 0) return principal / n;
    final pow = _pow(1 + r, n);
    return principal * (r * pow) / (pow - 1);
  }

  double _pow(double base, int exp) {
    var r = 1.0;
    for (var i = 0; i < exp; i++) {
      r *= base;
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${loc.currentPrice}: ${widget.price.toStringAsFixed(0)}'),
        Text('Down ${_downPercent.toStringAsFixed(0)}%'),
        Slider(
          value: _downPercent,
          min: 5,
          max: 50,
          divisions: 45,
          onChanged: (v) => setState(() => _downPercent = v),
        ),
        Text('Rate ${_rate.toStringAsFixed(1)}%'),
        Slider(
          value: _rate,
          min: 1,
          max: 20,
          divisions: 38,
          onChanged: (v) => setState(() => _rate = v),
        ),
        Text('$_years ${loc.years}'),
        Slider(
          value: _years.toDouble(),
          min: 5,
          max: 30,
          divisions: 25,
          onChanged: (v) => setState(() => _years = v.round()),
        ),
        const SizedBox(height: 8),
        Text(
          '${loc.monthlyPayment}: ${_payment.toStringAsFixed(0)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
