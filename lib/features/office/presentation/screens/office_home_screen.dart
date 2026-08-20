import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../presentation/search_map_screen/search_map_screen.dart';
import '../../../../presentation/search_map_screen/widgets/property_map_widget.dart';
import '../../../../services/property_ai_service.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/office_models.dart';
import '../providers/office_auth_notifier.dart';
import '../widgets/office_property_card.dart';
import '../widgets/office_sales_summary_card.dart';

/// Map-first office discovery with full AI search.
class OfficeHomeScreen extends StatefulWidget {
  const OfficeHomeScreen({super.key});

  @override
  State<OfficeHomeScreen> createState() => _OfficeHomeScreenState();
}

class _OfficeHomeScreenState extends State<OfficeHomeScreen> {
  final _searchCtrl = TextEditingController();
  final _propertyAi = PropertyAiService();
  final _mapKey = GlobalKey<PropertyMapWidgetState>();
  List<PropertyData> _all = [];
  List<PropertyData> _filtered = [];
  PropertyData? _selected;
  OfficeSalesSummary? _summary;
  bool _loading = true;
  bool _aiSearching = false;
  String _listingFilter = 'all';
  String? _aiInsight;
  Timer? _aiDebounce;
  int _aiToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _aiDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<OfficeAuthNotifier>();
    setState(() => _loading = true);
    final rows = await auth.repository.loadDiscoverableProperties();
    final summary = await auth.repository.salesSummaryThisMonth();
    if (!mounted) return;
    var props = rows.map(PropertyData.fromSupabase).toList();
    setState(() {
      _all = props;
      _filtered = props;
      _summary = summary;
      _loading = false;
    });
  }

  void _applyFilters({bool scheduleAi = true}) {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((p) {
        if (_listingFilter != 'all' && p.listingType != _listingFilter) {
          return false;
        }
        if (q.isEmpty) return true;
        final hay = [
          p.title,
          p.address,
          p.description,
          p.type,
          p.listingType,
          p.formattedPrice,
          p.price.toString(),
          p.area.toString(),
          ...p.tags,
          ...p.nearbySchools,
          ...p.nearbyAmenities,
        ].join(' ').toLowerCase();
        final tokens = q.split(RegExp(r'\s+')).where((t) => t.length > 1);
        return hay.contains(q) || tokens.every((t) => hay.contains(t));
      }).toList();
    });
    if (scheduleAi) _scheduleAiSearch(_searchCtrl.text.trim());
  }

  void _scheduleAiSearch(String query) {
    _aiDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _aiInsight = null;
        _aiSearching = false;
      });
      return;
    }
    final token = ++_aiToken;
    setState(() => _aiSearching = true);
    _aiDebounce = Timer(const Duration(milliseconds: 650), () async {
      final result = await _propertyAi.search(query: query, catalog: _all);
      if (!mounted || token != _aiToken) return;
      final byId = {for (final p in _all) p.id: p};
      var matched = result.matchedIds
          .map((id) => byId[id])
          .whereType<PropertyData>()
          .toList();
      if (matched.isEmpty) {
        matched = result.suggestions.map((s) => s.property).toList();
      }
      if (_listingFilter != 'all') {
        matched =
            matched.where((p) => p.listingType == _listingFilter).toList();
      }
      if (result.sortHint == 'price_asc') {
        matched.sort((a, b) => a.price.compareTo(b.price));
      } else if (result.sortHint == 'price_desc') {
        matched.sort((a, b) => b.price.compareTo(a.price));
      } else if (result.sortHint == 'area_desc') {
        matched.sort((a, b) => b.area.compareTo(a.area));
      }
      setState(() {
        if (matched.isNotEmpty) _filtered = matched;
        _aiInsight = result.reply.isNotEmpty ? result.reply : null;
        _aiSearching = false;
      });
      if (result.mapFocusLat != null && result.mapFocusLng != null) {
        _mapKey.currentState?.moveToLocation(
          LatLng(result.mapFocusLat!, result.mapFocusLng!),
        );
      }
    });
  }

  Future<void> _foundBuyer(PropertyData p) async {
    final loc = AppLocalizations.of(context);
    final auth = context.read<OfficeAuthNotifier>();
    final referral = await auth.repository.createFoundBuyerReferral(
      propertyId: p.id,
      message: loc.officeFoundBuyerDefaultMessage,
    );
    if (!mounted) return;
    if (referral == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.officeActionFailed)),
      );
      return;
    }
    if (referral.conversationId != null) {
      context.push('/office/chat/${referral.conversationId}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.officeReferralCreated)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final office = context.watch<OfficeAuthNotifier>().office;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/office/ai'),
        icon: const Icon(Icons.auto_awesome),
        label: Text(loc.officeAiFabLabel),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: PropertyMapWidget(
              key: _mapKey,
              properties: _filtered,
              mapType: 'normal',
              onPropertyTap: (p) => setState(() => _selected = p),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Material(
                    elevation: 1,
                    borderRadius: BorderRadius.circular(14),
                    color: theme.colorScheme.surface,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => _applyFilters(),
                      decoration: InputDecoration(
                        hintText: loc.officeSearchHint,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _aiSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: loc.officeAiFabLabel,
                                onPressed: () => context.push('/office/ai'),
                                icon: const Icon(Icons.auto_awesome, size: 20),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_aiInsight != null && _aiInsight!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Material(
                      color: theme.colorScheme.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          _aiInsight!.length > 160
                              ? '${_aiInsight!.substring(0, 160)}…'
                              : _aiInsight!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final f in [
                        ('all', loc.officeFilterAll),
                        ('sale', loc.officeFilterSale),
                        ('rent', loc.officeFilterRent),
                        ('mortgage', loc.officeFilterMortgage),
                      ])
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            label: Text(f.$2),
                            selected: _listingFilter == f.$1,
                            onSelected: (_) {
                              setState(() => _listingFilter = f.$1);
                              _applyFilters(scheduleAi: false);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                if (_summary != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: OfficeSalesSummaryCard(summary: _summary!),
                  ),
                if (office != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        office.name,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_selected != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: OfficePropertyCard(
                property: _selected!,
                officeName: office?.name,
                onOpen: () => context.push(
                  '/property-detail',
                  extra: _selected!.rawData,
                ),
                onFoundBuyer: () => _foundBuyer(_selected!),
                onDismiss: () => setState(() => _selected = null),
              ),
            ),
        ],
      ),
    );
  }
}
