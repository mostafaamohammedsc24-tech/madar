import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/layout/directional_layout.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../providers/chat_notifier.dart';
import '../../../../services/supabase_service.dart';
import '../../data/repositories/property_report_repository.dart';
import '../../data/services/property_translation_service.dart';
import '../../domain/enums/data_provenance.dart';
import '../../domain/enums/property_status.dart';
import '../../domain/models/property_documents.dart';
import '../../domain/models/property_finance.dart';
import '../../domain/models/property_language.dart';
import '../../domain/models/property_media.dart';
import '../../domain/models/property_report.dart';
import '../../domain/models/property_surroundings.dart';
import '../../domain/models/property_translation.dart';
import '../../domain/value_objects/money_amount.dart';
import '../../../../presentation/messages/open_listing_contact.dart';
import '../../../../presentation/search_map_screen/models/property_data.dart';
import '../screens/property_compare_sheet.dart';
import '../widgets/interactive_floor_plan_view.dart';
import '../widgets/property_extended_sections.dart';
import '../widgets/property_fullscreen_gallery.dart';
import '../widgets/property_listed_by_card.dart';
import '../widgets/property_map_section.dart';
import '../widgets/property_price_chart.dart';
import '../widgets/property_report_nav.dart';
import '../widgets/property_status_badge.dart';
import '../widgets/property_report_overlay_chrome.dart';
import '../widgets/property_sticky_action_bar.dart';
import '../widgets/property_translation_bar.dart';
import '../widgets/provenance_chip.dart';
import '../widgets/report_section.dart';
import '../widgets/sheet_grabber.dart';
import 'package:provider/provider.dart' as provider;

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
  final _translationService = PropertyTranslationService();
  final _sectionKeys = <String, GlobalKey>{};
  PropertyReport? _report;
  bool _loading = true;

  PropertyTranslationBundle? _translation;
  bool _showTranslated = false;
  bool _isTranslating = false;

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

  GlobalKey _keyFor(String id) =>
      _sectionKeys.putIfAbsent(id, GlobalKey.new);

  void _scrollToSection(String id) {
    final ctx = _sectionKeys[id]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _bootstrap() async {
    PropertyReport? report;

    // Paint immediately from the sheet payload so navigation never hangs on
    // network / mapper edge-cases.
    try {
      if (widget.property.isNotEmpty) {
        report = _repo.fromMap(widget.property);
      }
    } catch (e, st) {
      debugPrint('PropertyReport seed map failed: $e\n$st');
    }

    if (!mounted) return;
    setState(() {
      _report = report;
      _loading = report == null;
    });

    try {
      final id = widget.property['id']?.toString();
      if (id != null && id.isNotEmpty) {
        final loaded = await _repo.loadById(id, seed: widget.property);
        if (loaded != null) report = loaded;
      }
    } catch (e, st) {
      debugPrint('PropertyReportScreen bootstrap failed: $e\n$st');
    }

    if (!mounted) return;
    setState(() {
      _report = report;
      _loading = false;
    });
    if (report != null) {
      try {
        await _warmTranslationCache(report);
      } catch (_) {}
    }
  }

  ContentLanguage get _userLanguage {
    final lang = provider.Provider.of<LocaleProvider>(
      context,
      listen: false,
    ).language;
    switch (lang) {
      case AppLanguage.arabic:
        return ContentLanguage.arabic;
      case AppLanguage.kurdish:
        return ContentLanguage.kurdish;
      case AppLanguage.english:
        return ContentLanguage.english;
    }
  }

  Future<void> _warmTranslationCache(PropertyReport report) async {
    final userLang = _userLanguage;
    if (!report.needsTranslationFor(userLang)) return;
    final cached = await _translationService.getCached(
      propertyId: report.id,
      targetLanguage: userLang,
      contentVersion: report.contentVersion,
    );
    if (cached != null && mounted) {
      setState(() {
        _translation = cached;
        _showTranslated = true;
      });
    }
  }

  Future<void> _translateEntireProperty() async {
    final report = _report;
    if (report == null || _isTranslating) return;
    setState(() => _isTranslating = true);
    try {
      final bundle = await _translationService.translateProperty(
        report: report,
        targetLanguage: _userLanguage,
      );
      if (!mounted) return;
      setState(() {
        _translation = bundle;
        _showTranslated = true;
        _isTranslating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isTranslating = false);
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).translationFailed,
      );
    }
  }

  PropertyLocalizedTexts get _texts {
    final report = _report!;
    return PropertyLocalizedTexts.fromReport(
      report,
      bundle: _translation,
      showTranslated: _showTranslated && _translation != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (_report == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const DirectionalBackIcon(),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  loc.sectionNoDataYet,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() => _loading = true);
                    _bootstrap();
                  },
                  child: Text(loc.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final report = _report!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: report.showMedia
                ? _HeroPhotoBackdrop(
                    gallery: report.media,
                    status: report.status,
                    onOpen3d: report.showTour3d
                        ? () => _openExternalMedia(report.media.tour3d?.url)
                        : null,
                    onOpen360: report.showTour360
                        ? () => _openExternalMedia(report.media.tour360?.url)
                        : null,
                    onOpenFloorPlan: report.showFloorPlan
                        ? () => _showFloorPlanSheet(report)
                        : null,
                  )
                : ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.54,
            minChildSize: 0.40,
            maxChildSize: 0.96,
            snap: true,
            snapSizes: const [0.40, 0.54, 0.96],
            builder: (context, scrollController) {
              return Material(
                color: Colors.white,
                elevation: 12,
                shadowColor: Colors.black38,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  slivers: [
                    const SliverToBoxAdapter(child: SheetGrabber()),
                SliverToBoxAdapter(
                  key: _keyFor('overview'),
                  child: _buildHeader(report, loc, theme),
                ),
                SliverToBoxAdapter(
                  child: PropertyReportNav(
                    sections: buildReportNavItems(loc, report),
                    onTap: _scrollToSection,
                  ),
                ),
                if (report.needsTranslationFor(_userLanguage))
                  SliverToBoxAdapter(
                    child: PropertyTranslationBar(
                      propertyLanguage: report.originalLanguage ==
                              ContentLanguage.unknown
                          ? ContentLanguage.unknown
                          : report.originalLanguage,
                      userLanguage: _userLanguage,
                      showTranslated: _showTranslated,
                      isTranslating: _isTranslating,
                      hasTranslation: _translation != null,
                      onTranslate: _translateEntireProperty,
                      onShowOriginal: () =>
                          setState(() => _showTranslated = false),
                      onShowTranslated: () =>
                          setState(() => _showTranslated = true),
                    ),
                  ),
                if (report.showWhatsSpecial)
                  SliverToBoxAdapter(
                    key: _keyFor('details'),
                    child: ReportSection(
                      title: loc.whatsSpecial,
                      icon: Icons.auto_awesome,
                      child: _buildWhatsSpecial(theme),
                    ),
                  ),
                if (report.showFacts)
                  SliverToBoxAdapter(
                    key: _keyFor('facts'),
                    child: ReportSection(
                      title: loc.factsAndFeatures,
                      icon: Icons.grid_view_rounded,
                      child: _buildFacts(report, loc),
                    ),
                  ),
                if (report.showDimensions && report.dimensions != null)
                  SliverToBoxAdapter(
                    key: _keyFor('dimensions'),
                    child: ReportSection(
                      title: loc.dimensionsSection,
                      icon: Icons.straighten,
                      initiallyExpanded: false,
                      child: PropertyDimensionsSection(
                        dimensions: report.dimensions!,
                      ),
                    ),
                  ),
                if (report.showDescription)
                  SliverToBoxAdapter(
                    // 'details' key already used by whatsSpecial when present.
                    key: report.showWhatsSpecial
                        ? null
                        : _keyFor('details'),
                    child: ReportSection(
                      title: loc.description,
                      icon: Icons.notes_outlined,
                      initiallyExpanded: false,
                      child: Text(
                        _texts.description ?? report.description!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  key: _keyFor('financial'),
                  child: ReportSection(
                    title: loc.priceAndValuation,
                    icon: Icons.payments_outlined,
                    child: _buildPricing(report, loc, theme),
                  ),
                ),
                if (report.showPriceHistory)
                  SliverToBoxAdapter(
                    key: _keyFor('history'),
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
                    key: report.showPriceHistory
                        ? null
                        : _keyFor('history'),
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
                if (report.showConstruction && report.construction != null)
                  SliverToBoxAdapter(
                    key: _keyFor('construction'),
                    child: ReportSection(
                      title: loc.constructionSection,
                      icon: Icons.foundation_outlined,
                      initiallyExpanded: false,
                      child: PropertyConstructionSection(
                        construction: report.construction!,
                      ),
                    ),
                  ),
                if (report.showBuilder && report.builder != null)
                  SliverToBoxAdapter(
                    key: report.showConstruction
                        ? null
                        : _keyFor('construction'),
                    child: ReportSection(
                      title: loc.builderSection,
                      icon: Icons.engineering_outlined,
                      initiallyExpanded: false,
                      child: PropertyBuilderSection(builder: report.builder!),
                    ),
                  ),
                if (report.showVerification)
                  SliverToBoxAdapter(
                    child: ReportSection(
                      title: loc.verificationSection,
                      icon: Icons.verified_user_outlined,
                      initiallyExpanded: false,
                      child: PropertyVerificationSection(
                        verification: report.verification,
                      ),
                    ),
                  ),
                if (report.showNeighborhood)
                  SliverToBoxAdapter(
                    key: _keyFor('location'),
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
                if (report.showMap)
                  SliverToBoxAdapter(
                    key: report.showNeighborhood
                        ? null
                        : _keyFor('location'),
                    child: ReportSection(
                      title: loc.mapSection,
                      icon: Icons.map_outlined,
                      initiallyExpanded: false,
                      child: PropertyMapSection(
                        location: report.location,
                        nearby: report.surroundings.nearbyPlaces,
                      ),
                    ),
                  ),
                if (report.showLocationIntelligence)
                  SliverToBoxAdapter(
                    key: (report.showNeighborhood || report.showMap)
                        ? null
                        : _keyFor('location'),
                    child: ReportSection(
                      title: loc.locationIntelligence,
                      icon: Icons.my_location_outlined,
                      initiallyExpanded: false,
                      child: PropertyLocationIntelSection(report: report),
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
                    key: _keyFor('future'),
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
                if (report.showMarketAnalytics && report.marketAnalytics != null)
                  SliverToBoxAdapter(
                    key: _keyFor('investment'),
                    child: ReportSection(
                      title: loc.marketAnalyticsSection,
                      icon: Icons.analytics_outlined,
                      initiallyExpanded: false,
                      trailing: const ProvenanceChip(
                        provenance: DataProvenance.estimated,
                      ),
                      child: PropertyMarketAnalyticsSection(
                        analytics: report.marketAnalytics!,
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
                    key: _keyFor('documents'),
                    child: ReportSection(
                      title: loc.documents,
                      icon: Icons.folder_outlined,
                      initiallyExpanded: false,
                      child: _buildDocuments(report, theme),
                    ),
                  ),
                if (report.showPublisher)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: PropertyListedByCard(
                        publisher: report.publisher!,
                        onContact: _contactListing,
                      ),
                    ),
                  ),
                if (report.showListingMeta && report.listingMeta != null)
                  SliverToBoxAdapter(
                    key: _keyFor('contact'),
                    child: ReportSection(
                      title: loc.listingInfoSection,
                      icon: Icons.info_outline,
                      initiallyExpanded: false,
                      child: PropertyListingInfoSection(
                        meta: report.listingMeta!,
                        report: report,
                      ),
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
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: PropertyReportOverlayChrome(
                saved: report.isSaved,
                avatarUrl: report.publisher?.avatarUrl,
                onBack: () => Navigator.of(context).maybePop(),
                onSave: _toggleSave,
                onShare: _share,
                onAskAi: () => _openAiAdvisor(report),
                onMore: () => _showMoreMenu(report),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: PropertyStickyActionBar(
        publisher: report.publisher,
        onContact: _contactListing,
        onAskAi: () => _openAiAdvisor(report),
        onScheduleTour: () => _scheduleTour(report),
      ),
    );
  }

  Widget _buildHeader(
    PropertyReport report,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    final price = report.pricing.currentPrice;
    final hierarchy = report.location.hierarchy;
    final texts = _texts;
    final estMonthly = _estimatedMonthly(report);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PropertyStatusBadge(status: report.status),
              if (report.isVerified || report.verification.propertyVerified) ...[
                const SizedBox(width: 8),
                const ProvenanceChip(provenance: DataProvenance.verified),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (price != null)
            Text(
              price.format(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 34,
                height: 1.1,
                color: const Color(0xFF101828),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (report.facts.bedrooms != null && report.facts.bedrooms! > 0)
                _SpecChip(
                  icon: Icons.bed_outlined,
                  label: '${report.facts.bedrooms} ${loc.bedsShort}',
                ),
              if (report.facts.bathrooms != null && report.facts.bathrooms! > 0)
                _SpecChip(
                  icon: Icons.bathtub_outlined,
                  label: '${report.facts.bathrooms} ${loc.bathsShort}',
                ),
              if (report.areas.primary != null)
                _SpecChip(
                  icon: Icons.square_foot_outlined,
                  label:
                      '${report.areas.primary!.squareMeters.toStringAsFixed(0)} ${loc.areaUnitM2}',
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (hierarchy.isNotEmpty)
            Text(
              hierarchy.join(', '),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1D2939),
              ),
            )
          else if (report.location.displayLine.isNotEmpty)
            Text(
              report.location.displayLine,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1D2939),
              ),
            ),
          if (texts.title.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              texts.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (estMonthly != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4C46),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    loc.estPaymentAmount(estMonthly.format()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    loc.getPreQualified,
                    style: const TextStyle(
                      color: Color(0xFF0F4C46),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (report.listingMeta?.publishedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              loc.daysOnMadar(
                DateTime.now()
                    .difference(report.listingMeta!.publishedAt!)
                    .inDays
                    .clamp(0, 9999),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
              ),
            ),
          ],
          if (report.listingMeta?.propertyNumberId?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              '${loc.propertyIdLabel}: ${report.listingMeta!.propertyNumberId}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (report.showTags) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: report.tags
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
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

  Widget _buildWhatsSpecial(ThemeData theme) {
    final texts = _texts;
    final chips = texts.whatsSpecialHighlights;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chips.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (h) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      h.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: Color(0xFF344054),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        if (texts.whatsSpecialHeadline != null) ...[
          const SizedBox(height: 12),
          Text(
            texts.whatsSpecialHeadline!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (texts.whatsSpecialBody != null) ...[
          const SizedBox(height: 8),
          Text(texts.whatsSpecialBody!),
        ],
        if (texts.whatsSpecialInvestmentNotes.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...texts.whatsSpecialInvestmentNotes.map(
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
    final items = <(IconData, String)>[];
    final f = report.facts;
    final a = report.areas;
    final p = report.pricing;

    if (p.estimatedValue != null) {
      items.add((
        Icons.auto_awesome,
        '${p.estimatedValue!.format()} ${loc.madarEstimate}',
      ));
    }
    if (f.propertyType != null && f.propertyType!.isNotEmpty) {
      items.add((Icons.home_outlined, f.propertyType!));
    }
    if (p.pricePerSqm != null) {
      items.add((Icons.square_foot_outlined, p.pricePerSqm!.format()));
    }
    if (f.yearBuilt != null) {
      items.add((Icons.handyman_outlined, loc.builtInYear(f.yearBuilt!)));
    }
    if (a.land != null) {
      items.add((Icons.park_outlined, '${a.land!.format()} ${loc.landArea}'));
    } else if (a.builtUp != null) {
      items.add((Icons.square_foot, a.builtUp!.format()));
    } else if (a.primary != null) {
      items.add((Icons.square_foot, a.primary!.format()));
    }
    if (f.bedrooms != null) {
      items.add((Icons.bed_outlined, '${f.bedrooms} ${loc.bedrooms}'));
    }
    if (f.bathrooms != null) {
      items.add((Icons.bathtub_outlined, '${f.bathrooms} ${loc.bathrooms}'));
    }
    if (f.parkingSpaces != null) {
      items.add((Icons.local_parking_outlined, '${f.parkingSpaces} ${loc.parking}'));
    }
    if (f.floorNumber != null) {
      items.add((Icons.stairs_outlined, '${loc.floor} ${f.floorNumber}'));
    }
    if (f.hasElevator != null) {
      items.add((
        Icons.elevator_outlined,
        '${loc.elevator}: ${f.hasElevator! ? loc.yesLabel : loc.noLabel}',
      ));
    }

    final preview = items.take(6).toList();
    final rest = items.skip(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FactsIconGrid(items: preview),
        if (rest.isNotEmpty) _ShowMoreFacts(rest: rest),
        if (report.features.amenityTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _texts.amenityTags
                .map(
                  (t) => Chip(
                    label: Text(t),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
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
      children: [
        if (report.history.priceHistory.length >= 2)
          PropertyPriceChart(history: report.history.priceHistory),
        if (report.history.priceHistory.length >= 2) const SizedBox(height: 12),
        ...report.history.priceHistory.map((e) {
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
        }),
      ],
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

    final texts = _texts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FactGrid(items: items),
        if ((texts.rentToOwnEligibility ?? t.eligibilityNotes) != null) ...[
          const SizedBox(height: 12),
          Text(texts.rentToOwnEligibility ?? t.eligibilityNotes!),
        ],
        if ((texts.rentToOwnConditions ?? t.ownershipConditions) != null) ...[
          const SizedBox(height: 8),
          Text(texts.rentToOwnConditions ?? t.ownershipConditions!),
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
      items.add((loc.monthlyRentLabel, r.monthlyRent!.format()));
    }
    if (r.annualRent != null) {
      items.add((loc.annualRentLabel, r.annualRent!.format()));
    }
    if (r.rentalYield != null) {
      items.add((loc.grossRentalYield, '${r.rentalYield!.toStringAsFixed(1)}%'));
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
      items.add((loc.rentalYieldLabel, '${i.expectedRentalYield!.toStringAsFixed(1)}%'));
    }
    if (i.grossYield != null) {
      items.add((loc.grossRentalYield, '${i.grossYield!.toStringAsFixed(1)}%'));
    }
    if (i.netYield != null) {
      items.add(('Net ${loc.rentalYieldLabel}', '${i.netYield!.toStringAsFixed(1)}%'));
    }
    if (i.roi != null) {
      items.add((loc.roiLabel, '${i.roi!.toStringAsFixed(1)}%'));
    }
    if (i.estimatedAnnualRent != null) {
      items.add((loc.annualRentLabel, i.estimatedAnnualRent!.format()));
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
    final summary = _texts.neighborhoodSummary ?? n.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProvenanceChip(provenance: n.provenance),
        if (summary != null) ...[
          const SizedBox(height: 8),
          Text(summary),
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
    final loc = AppLocalizations.of(context);
    final c = report.surroundings.climateRisk!;
    return FactGrid(
      items: [
        if (c.floodRisk != null) (loc.floodRiskLabel, c.floodRisk!),
        if (c.extremeHeat != null) (loc.heatRiskLabel, c.extremeHeat!),
        if (c.wildfire != null) (loc.wildfireRiskLabel, c.wildfire!),
        if (c.waterRisk != null) (loc.waterRiskLabel, c.waterRisk!),
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

  Future<void> _toggleSave() async {
    final report = _report;
    if (report == null) return;
    final saved = await _repo.toggleSave(report.id);
    if (!mounted) return;
    setState(() => _report = report.copyWith(isSaved: saved));
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
    Fluttertoast.showToast(msg: loc.linkCopied);
  }

  Future<void> _contactListing() async {
    final report = _report;
    if (report == null) return;
    await openListingContact(
      context,
      publisher: report.publisher,
      propertyId: report.id,
      title: report.title,
      priceLine: report.pricing.currentPrice?.format(),
      imageUrl: report.media.photos.isNotEmpty
          ? report.media.photos.first.url
          : null,
      address: report.location.displayLine,
      property: {
        'id': report.id,
        'title': report.title,
        'asking_price': report.pricing.currentPrice?.amount,
        'address': report.location.displayLine,
        if (report.media.photos.isNotEmpty)
          'imageUrl': report.media.photos.first.url,
      },
    );
  }

  void _showMoreMenu(PropertyReport report) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                report.publisher?.routesToAgent == true
                    ? loc.contactAgentName(report.publisher!.displayName)
                    : loc.contactSalesTeam,
              ),
              onTap: () {
                Navigator.pop(ctx);
                _contactListing();
              },
            ),
            ListTile(
              title: Text(loc.hideHome),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).maybePop();
              },
            ),
            ListTile(
              title: Text(loc.getDirections),
              onTap: () {
                Navigator.pop(ctx);
                _openDirections(report);
              },
            ),
            ListTile(
              title: Text(loc.yourTags),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: Text(loc.reportAProblem),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: Text(loc.askAiAboutProperty),
              onTap: () {
                Navigator.pop(ctx);
                _openAiAdvisor(report);
              },
            ),
            ListTile(
              title: Text(loc.compareProperty),
              onTap: () async {
                Navigator.pop(ctx);
                List<PropertyData> candidates = const [];
                try {
                  final rows = await SupabaseService.instance.getProperties(
                    limit: 20,
                  );
                  candidates = rows
                      .map(PropertyData.fromSupabase)
                      .where((p) => p.id != report.id)
                      .toList();
                } catch (_) {}
                if (!mounted) return;
                PropertyCompareSheet.show(
                  context,
                  base: report,
                  candidates: candidates,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirections(PropertyReport report) async {
    final lat = report.location.latitude;
    final lng = report.location.longitude;
    final uri = (lat != null && lng != null)
        ? Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng')
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(report.location.displayLine)}',
          );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
                                  final system =
                                      PropertyTranslationService
                                          .buildPropertyAiSystemPrompt(
                                    report: report,
                                    translation: _translation,
                                    replyLanguage: _userLanguage,
                                  );
                                  ref
                                      .read(
                                        chatNotifierProvider(_aiConfig)
                                            .notifier,
                                      )
                                      .sendMessage(
                                        [
                                          {
                                            'role': 'system',
                                            'content': system,
                                          },
                                          {
                                            'role': 'user',
                                            'content': q,
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

  Future<void> _openExternalMedia(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showFloorPlanSheet(PropertyReport report) {
    final loc = AppLocalizations.of(context);
    final plan = report.floorPlan;
    final mediaPlans = report.media.items
        .where((i) => i.kind.name == 'floorPlan')
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scroll) {
            return Material(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    loc.floorPlan,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (plan != null && plan.hasAny)
                    InteractiveFloorPlanView(
                      plan: plan,
                      media: report.media,
                      onOpen3d: report.showTour3d
                          ? (id) => _openExternalMedia(
                                report.media.tour3d?.url,
                              )
                          : null,
                      onOpenPhotos: (photos) {
                        Navigator.pop(ctx);
                        PropertyFullscreenGallery.open(
                          context,
                          items: photos,
                          initialIndex: 0,
                        );
                      },
                    )
                  else if (mediaPlans.isNotEmpty)
                    ...mediaPlans.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InteractiveViewer(
                          child: Image.network(m.url, fit: BoxFit.contain),
                        ),
                      ),
                    )
                  else
                    const EmptySectionHint(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  MoneyAmount? _estimatedMonthly(PropertyReport report) {
    final rent = report.rentToOwn?.monthlyPayment;
    if (rent != null && rent.amount > 0) return rent;
    final marketRent = report.rental?.monthlyRent;
    if (marketRent != null && marketRent.amount > 0) return marketRent;
    final price = report.pricing.currentPrice;
    if (price == null || price.amount <= 0) return null;
    final defaults = report.mortgageDefaults;
    final down = (defaults?.downPaymentPercent ?? 20) / 100;
    final monthlyRate = (defaults?.interestRatePercent ?? 7.5) / 100 / 12;
    final n = (defaults?.termYears ?? 20) * 12;
    final principal = price.amount * (1 - down);
    if (principal <= 0 || n <= 0) return null;
    final payment = monthlyRate == 0
        ? principal / n
        : principal *
            (monthlyRate * math.pow(1 + monthlyRate, n)) /
            (math.pow(1 + monthlyRate, n) - 1);
    return MoneyAmount(amount: payment, currencyCode: price.currencyCode);
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _ShowMoreFacts extends StatefulWidget {
  const _ShowMoreFacts({required this.rest});

  final List<(IconData, String)> rest;

  @override
  State<_ShowMoreFacts> createState() => _ShowMoreFactsState();
}

class _ShowMoreFactsState extends State<_ShowMoreFacts> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_open) FactsIconGrid(items: widget.rest),
        TextButton(
          onPressed: () => setState(() => _open = !_open),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _open ? loc.showLess : loc.showMore,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _HeroPhotoBackdrop extends StatefulWidget {
  const _HeroPhotoBackdrop({
    required this.gallery,
    required this.status,
    this.onOpen3d,
    this.onOpen360,
    this.onOpenFloorPlan,
  });

  final PropertyMediaGallery gallery;
  final PropertyStatus status;
  final VoidCallback? onOpen3d;
  final VoidCallback? onOpen360;
  final VoidCallback? onOpenFloorPlan;

  @override
  State<_HeroPhotoBackdrop> createState() => _HeroPhotoBackdropState();
}

class _HeroPhotoBackdropState extends State<_HeroPhotoBackdrop> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final items = widget.gallery.photos.isNotEmpty
        ? widget.gallery.photos
        : widget.gallery.items;
    if (items.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF2A2A2A),
        child: Center(
          child: Icon(Icons.home_work_outlined, size: 64, color: Colors.white54),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: items.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) {
            return GestureDetector(
              onTap: () => PropertyFullscreenGallery.open(
                context,
                items: items,
                initialIndex: i,
              ),
              child: Image.network(
                items[i].url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFF2A2A2A),
                  child: Center(
                    child: Icon(Icons.broken_image_outlined, color: Colors.white54),
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.sizeOf(context).height * 0.46,
          child: Row(
            children: [
              PropertyStatusBadge(status: widget.status),
              const Spacer(),
              if (widget.gallery.has3dTour)
                _HeroMediaChip(label: loc.tour3d, onTap: widget.onOpen3d),
              if (widget.gallery.hasFloorPlan) ...[
                const SizedBox(width: 6),
                _HeroMediaChip(label: loc.floorPlan, onTap: widget.onOpenFloorPlan),
              ],
              if (widget.gallery.has360Tour) ...[
                const SizedBox(width: 6),
                _HeroMediaChip(label: loc.virtualTour, onTap: widget.onOpen360),
              ],
            ],
          ),
        ),
        if (items.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.sizeOf(context).height * 0.42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length.clamp(0, 12), (i) {
                final active = i == _index;
                return Container(
                  width: active ? 7 : 6,
                  height: active ? 7 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _HeroMediaChip extends StatelessWidget {
  const _HeroMediaChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF667085)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF344054),
          ),
        ),
      ],
    );
  }
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
