import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/publishing_repository.dart';
import '../../domain/publishing_models.dart';
import '../theme/publisher_tokens.dart';

enum _StatusFilter { all, active, pending, sold }

enum _SortMode { newest, oldest }

/// Stitch publisher Properties workspace — search, status chips, property cards, FAB.
class PublisherPropertiesScreen extends StatefulWidget {
  const PublisherPropertiesScreen({super.key});

  @override
  State<PublisherPropertiesScreen> createState() =>
      _PublisherPropertiesScreenState();
}

class _PublisherPropertiesScreenState extends State<PublisherPropertiesScreen> {
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  List<PropertyAsset> _all = [];
  _StatusFilter _filter = _StatusFilter.all;
  _SortMode _sort = _SortMode.newest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = PublishingRepository(
      context.read<EmployeeAuthNotifier>().repository,
    );
    final list = await repo.listAssets(limit: 80);
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  List<PropertyAsset> get _visible {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = _all.where((a) {
      if (_filter != _StatusFilter.all &&
          a.displayMarketStatus != _filter.name) {
        return false;
      }
      if (q.isEmpty) return true;
      return a.publicPropertyId.toLowerCase().contains(q) ||
          (a.addressText ?? '').toLowerCase().contains(q) ||
          (a.ownerName ?? '').toLowerCase().contains(q) ||
          (a.displayTitle).toLowerCase().contains(q) ||
          (a.city ?? '').toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) {
      final da = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return _sort == _SortMode.newest ? db.compareTo(da) : da.compareTo(db);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;

    return Scaffold(
      backgroundColor: PublisherTokens.surface,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton(
          onPressed: () => context.push('/employee/publishing/create'),
          backgroundColor: PublisherTokens.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: PublisherTokens.surface,
              border: Border(
                bottom: BorderSide(color: PublisherTokens.surfaceContainer),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 16,
                    color: PublisherTokens.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by ID, Address, or Client...',
                    hintStyle: TextStyle(
                      color: PublisherTokens.onSurfaceVariant
                          .withValues(alpha: 0.85),
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: PublisherTokens.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: PublisherTokens.surfaceLow,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: PublisherTokens.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'All Status',
                        selected: _filter == _StatusFilter.all,
                        onTap: () =>
                            setState(() => _filter = _StatusFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Active',
                        selected: _filter == _StatusFilter.active,
                        onTap: () =>
                            setState(() => _filter = _StatusFilter.active),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pending',
                        selected: _filter == _StatusFilter.pending,
                        onTap: () =>
                            setState(() => _filter = _StatusFilter.pending),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Sold',
                        selected: _filter == _StatusFilter.sold,
                        onTap: () =>
                            setState(() => _filter = _StatusFilter.sold),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'More',
                        selected: false,
                        icon: Icons.filter_list,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'More filters: pipeline, city, type — coming next.',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Showing ${items.length} properties',
                    style: const TextStyle(
                      fontSize: 14,
                      color: PublisherTokens.onSurfaceVariant,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() {
                    _sort = _sort == _SortMode.newest
                        ? _SortMode.oldest
                        : _SortMode.newest;
                  }),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sort,
                        size: 18,
                        color: PublisherTokens.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _sort == _SortMode.newest
                            ? 'Newest First'
                            : 'Oldest First',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: PublisherTokens.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: items.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'No properties match this filter.',
                                  style: TextStyle(
                                    color: PublisherTokens.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, i) {
                              final asset = items[i];
                              return _PropertyCard(
                                asset: asset,
                                onOpen: () => context.push(
                                  '/employee/publishing/property/${asset.id}',
                                ),
                                onEdit: () => context.push(
                                  '/employee/publishing/property/${asset.id}',
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? PublisherTokens.primary
          : PublisherTokens.surfaceLow,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? Colors.white
                      : PublisherTokens.onSurface,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: selected
                      ? Colors.white
                      : PublisherTokens.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.asset,
    required this.onOpen,
    required this.onEdit,
  });

  final PropertyAsset asset;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final status = asset.displayMarketStatus;
    final sold = status == 'sold';
    final pending = status == 'pending';

    Color badgeBg;
    Color badgeFg;
    if (sold) {
      badgeBg = PublisherTokens.surfaceHighest;
      badgeFg = PublisherTokens.onSurfaceVariant;
    } else if (pending) {
      badgeBg = PublisherTokens.tertiaryContainer;
      badgeFg = PublisherTokens.onTertiaryContainer;
    } else {
      badgeBg = PublisherTokens.primaryContainer;
      badgeFg = PublisherTokens.onPrimaryContainer;
    }

    return Material(
      color: PublisherTokens.card,
      elevation: 0,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PublisherTokens.surfaceContainer),
            boxShadow: PublisherTokens.microDepth,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: PublisherTokens.surfaceHighest,
                        child: asset.coverImageUrl == null
                            ? const Icon(
                                Icons.apartment,
                                color: PublisherTokens.onSurfaceVariant,
                              )
                            : Image.network(
                                asset.coverImageUrl!,
                                fit: BoxFit.cover,
                                color: sold ? Colors.grey : null,
                                colorBlendMode:
                                    sold ? BlendMode.saturation : null,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.apartment,
                                  color: PublisherTokens.onSurfaceVariant,
                                ),
                              ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PublisherTokens.card.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${asset.shortId}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                              color: PublisherTokens.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 96,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              asset.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: sold
                                    ? PublisherTokens.onSurfaceVariant
                                    : PublisherTokens.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: badgeFg,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        asset.displayAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: PublisherTokens.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  asset.priceLabel.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                    color: PublisherTokens.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  asset.formattedPrice,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: sold
                                        ? PublisherTokens.onSurfaceVariant
                                        : PublisherTokens.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (sold)
                            _RoundAction(
                              icon: Icons.visibility_outlined,
                              onTap: onOpen,
                            )
                          else ...[
                            _RoundAction(
                              icon: Icons.payments_outlined,
                              onTap: onEdit,
                            ),
                            const SizedBox(width: 8),
                            _RoundAction(
                              icon: Icons.edit_outlined,
                              onTap: onEdit,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PublisherTokens.surfaceContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: PublisherTokens.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
