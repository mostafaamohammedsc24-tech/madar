import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/publishing_repository.dart';
import '../../domain/publisher_ops_models.dart';
import '../theme/publisher_tokens.dart';

/// Publisher operational center — compact overview + priority work queue.
class PublisherWorkScreen extends StatefulWidget {
  const PublisherWorkScreen({super.key});

  @override
  State<PublisherWorkScreen> createState() => _PublisherWorkScreenState();
}

class _PublisherWorkScreenState extends State<PublisherWorkScreen> {
  bool _loading = true;
  PublisherWorkOverview? _overview;
  List<PublisherQueueItem> _queue = [];
  PublisherQueueBucket? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = PublishingRepository(
      context.read<EmployeeAuthNotifier>().repository,
    );
    final overview = await repo.workOverview();
    final queue = await repo.workQueue();
    if (!mounted) return;
    setState(() {
      _overview = overview;
      _queue = queue;
      _loading = false;
    });
  }

  List<PublisherQueueItem> get _visible {
    if (_filter == null) return _queue;
    return _queue.where((q) => q.bucket == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final o = _overview;
    final items = _visible;

    return Scaffold(
      backgroundColor: PublisherTokens.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Work',
                                  style: PublisherTokens.textTheme(
                                    Theme.of(context).textTheme,
                                  ).headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: PublisherTokens.onSurface,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'What needs your attention right now',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: PublisherTokens.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () =>
                                context.push('/employee/publishing/create'),
                            style: FilledButton.styleFrom(
                              backgroundColor: PublisherTokens.secondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Create Publishing Request'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (o != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatChip(
                              label: 'Pending',
                              value: o.pendingRequests,
                              onTap: () => setState(
                                () => _filter =
                                    PublisherQueueBucket.needsAction,
                              ),
                            ),
                            _StatChip(
                              label: 'In progress',
                              value: o.inProgress,
                              onTap: () => setState(() => _filter = null),
                            ),
                            _StatChip(
                              label: 'Waiting info',
                              value: o.waitingInformation,
                              onTap: () => setState(
                                () => _filter = PublisherQueueBucket
                                    .waitingInformation,
                              ),
                            ),
                            _StatChip(
                              label: 'Ready review',
                              value: o.readyToReview,
                              onTap: () => setState(
                                () => _filter =
                                    PublisherQueueBucket.readyForReview,
                              ),
                            ),
                            _StatChip(
                              label: 'Ready publish',
                              value: o.readyToPublish,
                              highlight: true,
                              onTap: () => setState(
                                () => _filter =
                                    PublisherQueueBucket.readyToPublish,
                              ),
                            ),
                            _StatChip(
                              label: 'Published',
                              value: o.published,
                              onTap: () => setState(
                                () => _filter =
                                    PublisherQueueBucket.recentlyPublished,
                              ),
                            ),
                            _StatChip(
                              label: 'Needs update',
                              value: o.needsUpdate,
                              onTap: () => setState(
                                () => _filter =
                                    PublisherQueueBucket.requiresUpdate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            _filter == null
                                ? 'Priority queue'
                                : _filter!.labelEn,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: PublisherTokens.onSurface,
                            ),
                          ),
                          const Spacer(),
                          if (_filter != null)
                            TextButton(
                              onPressed: () =>
                                  setState(() => _filter = null),
                              child: const Text('Clear filter'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 40, 20, 40),
                        child: Column(
                          children: [
                            Text(
                              'No pending publishing requests',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: PublisherTokens.onSurface,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create a new publishing request to start a property.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: PublisherTokens.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final item = items[i];
                          final a = item.asset;
                          return Material(
                            color: PublisherTokens.card,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => context.push(
                                '/employee/publishing/property/${a.id}',
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: PublisherTokens.microDepth,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SelectableText(
                                          '#${a.publicPropertyId}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            letterSpacing: 0.3,
                                            color: PublisherTokens.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _MiniBadge(
                                          a.propertyType ?? 'property',
                                        ),
                                        const Spacer(),
                                        _MiniBadge(
                                          item.bucket.labelEn,
                                          tone: PublisherTokens.secondary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      a.displayTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        a.displayAddress,
                                        if (a.source != null)
                                          'Source: ${a.source}',
                                        if (a.ownerName != null)
                                          a.ownerName!,
                                      ].join(' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color:
                                            PublisherTokens.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.missing.isEmpty
                                                ? 'No blocking gaps'
                                                : 'Missing: ${item.missing.take(3).join(' · ')}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: item.missing.isEmpty
                                                  ? PublisherTokens.secondary
                                                  : PublisherTokens
                                                      .tertiaryContainer,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          a.updatedAt
                                                  ?.toLocal()
                                                  .toString()
                                                  .split('.')
                                                  .first ??
                                              '—',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: PublisherTokens
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.priorityLabel.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: PublisherTokens
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.onTap,
    this.highlight = false,
  });

  final String label;
  final int value;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight
          ? PublisherTokens.primary.withValues(alpha: 0.08)
          : PublisherTokens.card,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: highlight
                  ? PublisherTokens.secondary.withValues(alpha: 0.35)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: highlight
                      ? PublisherTokens.primary
                      : PublisherTokens.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: PublisherTokens.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge(this.text, {this.tone});

  final String text;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = tone ?? PublisherTokens.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }
}
