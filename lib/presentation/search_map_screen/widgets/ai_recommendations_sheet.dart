import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../core/layout/directional_layout.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/chat_notifier.dart';
import '../search_map_screen.dart';

class AiRecommendationsSheet extends ConsumerStatefulWidget {
  final List<PropertyData> allProperties;
  final Function(PropertyData) onPropertyTap;

  const AiRecommendationsSheet({
    required this.allProperties,
    required this.onPropertyTap,
    super.key,
  });

  @override
  ConsumerState<AiRecommendationsSheet> createState() =>
      _AiRecommendationsSheetState();
}

class _AiRecommendationsSheetState
    extends ConsumerState<AiRecommendationsSheet> {
  static const _config = ChatConfig(
    provider: 'GEMINI',
    model: 'gemini/gemini-2.5-flash',
    streaming: false,
  );

  List<PropertyData> _recommended = [];
  String _aiInsight = '';
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecommendations());
  }

  Future<void> _loadRecommendations() async {
    if (widget.allProperties.isEmpty) return;

    final propSummaries = widget.allProperties
        .take(20)
        .map(
          (p) =>
              '${p.title} | ${p.type} | ${p.listingType} | \$${p.price.toStringAsFixed(0)} | ${p.area.toStringAsFixed(0)}m² | ${p.bedrooms}br | ${p.address}',
        )
        .join('\n');

    final messages = [
      {
        'role': 'system',
        'content':
            'You are a real estate AI assistant. Analyze property listings and recommend the top 3 most attractive ones. Return ONLY a JSON object with this exact format: {"recommendations": [{"id": "prop_id"}, {"id": "prop_id"}, {"id": "prop_id"}], "insight": "Brief 1-2 sentence insight about why these are recommended"}. No markdown, no extra text.',
      },
      {
        'role': 'user',
        'content':
            'Here are available properties:\n$propSummaries\n\nRecommend the top 3 most attractive properties for a typical buyer looking for value and quality.',
      },
    ];

    ref
        .read(chatNotifierProvider(_config).notifier)
        .sendMessage(
          messages,
          parameters: {'temperature': 0.3, 'max_tokens': 300},
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isRTL = loc.isRTL;
    final chatState = ref.watch(chatNotifierProvider(_config));

    ref.listen<ChatState>(chatNotifierProvider(_config), (prev, next) {
      if (next.error != null) {
        Fluttertoast.showToast(
          msg: next.error.toString(),
          backgroundColor: Colors.red,
        );
      }
      if (!next.isLoading && next.response.isNotEmpty && !_hasLoaded) {
        _parseRecommendations(next.response);
      }
    });

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF57C00),
                        const Color(0xFFFF9800),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRTL
                            ? 'توصيات الذكاء الاصطناعي'
                            : 'AI Recommendations',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        isRTL
                            ? 'مخصصة بناءً على العقارات المتاحة'
                            : 'Personalized from available listings',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  onPressed: chatState.isLoading
                      ? null
                      : () {
                          setState(() {
                            _hasLoaded = false;
                            _recommended = [];
                            _aiInsight = '';
                          });
                          _loadRecommendations();
                        },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Flexible(
            child: chatState.isLoading && !_hasLoaded
                ? _buildLoadingState(theme, isRTL)
                : _recommended.isEmpty
                ? _buildEmptyState(theme, isRTL)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI Insight
                        if (_aiInsight.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF57C00).withAlpha(15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFF57C00).withAlpha(40),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: Color(0xFFF57C00),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _aiInsight,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Recommended properties
                        Text(
                          isRTL
                              ? 'العقارات الموصى بها'
                              : 'Recommended Properties',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._recommended.asMap().entries.map(
                          (entry) => _RecommendedPropertyCard(
                            rank: entry.key + 1,
                            property: entry.value,
                            onTap: () {
                              Navigator.pop(context);
                              widget.onPropertyTap(entry.value);
                            },
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isRTL) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: const Color(0xFFF57C00),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isRTL
                ? 'يحلل الذكاء الاصطناعي العقارات...'
                : 'AI is analyzing properties...',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isRTL) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
          ),
          const SizedBox(height: 12),
          Text(
            isRTL ? 'لا توجد توصيات متاحة' : 'No recommendations available',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _parseRecommendations(String response) {
    try {
      // Extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) return;

      final jsonStr = response.substring(jsonStart, jsonEnd + 1);
      // Simple manual parsing to avoid dart:convert issues
      final idMatches = RegExp(r'"id"\s*:\s*"([^"]+)"').allMatches(jsonStr);
      final ids = idMatches.map((m) => m.group(1)!).toList();

      // Extract insight
      final insightMatch = RegExp(
        r'"insight"\s*:\s*"([^"]+)"',
      ).firstMatch(jsonStr);
      final insight = insightMatch?.group(1) ?? '';

      final recommended = <PropertyData>[];
      for (final id in ids) {
        final prop = widget.allProperties.firstWhere(
          (p) => p.id == id,
          orElse: () => widget.allProperties.isNotEmpty
              ? widget.allProperties.first
              : widget.allProperties.first,
        );
        if (!recommended.any((p) => p.id == prop.id)) {
          recommended.add(prop);
        }
        if (recommended.length >= 3) break;
      }

      // Fallback: if no valid IDs found, pick top 3
      if (recommended.isEmpty && widget.allProperties.isNotEmpty) {
        recommended.addAll(widget.allProperties.take(3));
      }

      if (mounted) {
        setState(() {
          _recommended = recommended;
          _aiInsight = insight;
          _hasLoaded = true;
        });
      }
    } catch (_) {
      // Fallback to first 3 properties
      if (mounted && widget.allProperties.isNotEmpty) {
        setState(() {
          _recommended = widget.allProperties.take(3).toList();
          _hasLoaded = true;
        });
      }
    }
  }
}

// ─── Recommended Property Card ────────────────────────────────────────────────
class _RecommendedPropertyCard extends StatelessWidget {
  final int rank;
  final PropertyData property;
  final VoidCallback onTap;

  const _RecommendedPropertyCard({
    required this.rank,
    required this.property,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankColors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final rankColor = rank <= 3 ? rankColors[rank - 1] : AppTheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: rank == 1
                ? rankColor.withAlpha(80)
                : theme.colorScheme.outline.withAlpha(40),
          ),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: CustomImageWidget(
                imageUrl: property.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                semanticLabel: property.semanticLabel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: rankColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '#$rank',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            property.title,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.address,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          property.formattedPrice,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: property.listingTypeColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            property.listingTypeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: property.listingTypeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: DirectionalChevronIcon(
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
