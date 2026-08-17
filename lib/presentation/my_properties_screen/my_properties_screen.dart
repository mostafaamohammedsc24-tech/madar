import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import 'models/owned_property.dart';
import 'widgets/add_property_sheet_widget.dart';
import 'widgets/owned_property_card.dart';
import 'widgets/partner_ad_carousel.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  final List<OwnedProperty> _local = [];
  List<OwnedProperty> _remote = [];
  bool _loading = true;

  List<OwnedProperty> get _items {
    final seen = <String>{};
    final out = <OwnedProperty>[];
    for (final item in [..._local, ..._remote]) {
      if (seen.add(item.id)) out.add(item);
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final properties = await SupabaseService.instance.getUserProperties();
      final submissions = await SupabaseService.instance
          .getPropertySubmissions();
      final mapped = [
        ...properties.map(OwnedProperty.fromRemote),
        ...submissions.map((row) {
          final copy = Map<String, dynamic>.from(row);
          copy['status'] ??= 'under_review';
          copy['title'] ??= copy['address'] ?? copy['address_text'];
          return OwnedProperty.fromRemote(copy);
        }),
      ];
      if (!mounted) return;
      setState(() {
        _remote = mapped;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAddSheet() async {
    await AddPropertySheetWidget.show(
      context,
      onSubmitted: (property) {
        setState(() => _local.insert(0, property));
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.propertyRequestSent),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final items = _items;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text(
          loc.myProperties,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: PartnerAdCarousel()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _openAddSheet,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      loc.addProperty,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Text(
                  '${loc.ownedListingCount} (${items.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (items.isEmpty)
              SliverToBoxAdapter(child: _EmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => OwnedPropertyCard(property: items[i]),
                  childCount: items.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_work_outlined,
              size: 36,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            loc.noPropertiesYet,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF344054),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.noPropertiesHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}
