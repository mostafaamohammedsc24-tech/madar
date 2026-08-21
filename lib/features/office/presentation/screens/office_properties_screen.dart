import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../presentation/search_map_screen/models/property_data.dart';
import '../providers/office_auth_notifier.dart';

/// Stitch-style Arabic “عقاراتي” portfolio for the office.
class OfficePropertiesScreen extends StatefulWidget {
  const OfficePropertiesScreen({super.key});

  @override
  State<OfficePropertiesScreen> createState() => _OfficePropertiesScreenState();
}

class _OfficePropertiesScreenState extends State<OfficePropertiesScreen> {
  bool _loading = true;
  List<PropertyData> _items = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<OfficeAuthNotifier>();
    setState(() => _loading = true);
    final rows = await auth.repository.loadDiscoverableProperties();
    if (!mounted) return;
    setState(() {
      _items = rows.map(PropertyData.fromSupabase).toList();
      _loading = false;
    });
  }

  List<PropertyData> get _visible {
    switch (_filter) {
      case 'available':
        return _items
            .where((p) => p.listingType == 'sale' || p.listingType == 'rent')
            .toList();
      case 'progress':
        return _items.where((p) => p.isFeatured).toList();
      case 'sold':
        return _items
            .where((p) => p.listingType.toLowerCase().contains('sold'))
            .toList();
      default:
        return _items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final items = _visible;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/office/report-property'),
        backgroundColor: const Color(0xFF0041C8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(loc.officeAddProperty),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Text(
                    loc.officeNavProperties,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0B1C30),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.officeManagePropertiesSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _chip(
                          loc.officeFilterAll,
                          'all',
                          count: _items.length,
                        ),
                        _chip(
                          loc.officeFilterAvailable,
                          'available',
                          count: _items.length,
                        ),
                        _chip(loc.officeFilterInProgress, 'progress'),
                        _chip(loc.officeFilterSold, 'sold'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Text(
                        loc.officeNoAssignedProperties,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...items.map((p) => _PropertyPortfolioCard(property: p)),
                ],
              ),
            ),
    );
  }

  Widget _chip(String label, String key, {int? count}) {
    final selected = _filter == key;
    final text = count == null ? label : '$label ($count)';
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        onSelected: (_) => setState(() => _filter = key),
        selectedColor: const Color(0xFF0041C8),
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF0B1C30),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        showCheckmark: false,
      ),
    );
  }
}

class _PropertyPortfolioCard extends StatelessWidget {
  const _PropertyPortfolioCard({required this.property});

  final PropertyData property;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = property.listingType == 'rent' ? 'للإيجار' : 'متاح';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push(
            '/property-detail',
            extra: property.rawData,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: const Color(0xFF0041C8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              property.imageUrl.isEmpty
                                  ? ColoredBox(
                                      color: theme.colorScheme
                                          .surfaceContainerHighest,
                                      child: const Icon(Icons.home_work),
                                    )
                                  : Image.network(
                                      property.imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCE1FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0039B3),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ID: ${property.id}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      property.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    property.formattedPrice,
                                    style: const TextStyle(
                                      color: Color(0xFF0041C8),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.place_outlined,
                                    size: 14,
                                    color: Color(0xFF737688),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      property.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF737688),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _stat('المساحة', '${property.area.round()} م²'),
                                  _stat('الغرف', '${property.bedrooms}'),
                                  _stat('الحمامات', '${property.bathrooms}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF737688)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0B1C30),
            ),
          ),
        ],
      ),
    );
  }
}
