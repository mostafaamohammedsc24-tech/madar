import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../presentation/search_map_screen/search_map_screen.dart';
import '../../../../presentation/search_map_screen/widgets/property_map_widget.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/office_models.dart';
import '../providers/office_auth_notifier.dart';
import '../widgets/office_property_card.dart';
import '../widgets/office_sales_summary_card.dart';

/// Map-first office discovery — reuses user PropertyMapWidget / PropertyData.
class OfficeHomeScreen extends StatefulWidget {
  const OfficeHomeScreen({super.key});

  @override
  State<OfficeHomeScreen> createState() => _OfficeHomeScreenState();
}

class _OfficeHomeScreenState extends State<OfficeHomeScreen> {
  final _searchCtrl = TextEditingController();
  List<PropertyData> _all = [];
  List<PropertyData> _filtered = [];
  PropertyData? _selected;
  OfficeSalesSummary? _summary;
  bool _loading = true;
  String _listingFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<OfficeAuthNotifier>();
    setState(() => _loading = true);
    final rows = await auth.repository.loadDiscoverableProperties();
    final summary = await auth.repository.salesSummaryThisMonth();
    if (!mounted) return;
    final props = rows.map(PropertyData.fromSupabase).toList();
    setState(() {
      _all = props;
      _filtered = props;
      _summary = summary;
      _loading = false;
    });
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((p) {
        if (_listingFilter != 'all' && p.listingType != _listingFilter) {
          return false;
        }
        if (q.isEmpty) return true;
        return p.title.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q) ||
            p.type.toLowerCase().contains(q);
      }).toList();
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
      body: Stack(
        children: [
          Positioned.fill(
            child: PropertyMapWidget(
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
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
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
                              _applyFilters();
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
          if (_loading)
            const Center(child: CircularProgressIndicator()),
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
          Positioned(
            right: 16,
            bottom: _selected != null ? 220 : 16,
            child: FloatingActionButton.extended(
              heroTag: 'office_report',
              onPressed: () => context.push('/office/report-property'),
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: Text(loc.officeReportProperty),
            ),
          ),
        ],
      ),
    );
  }
}
