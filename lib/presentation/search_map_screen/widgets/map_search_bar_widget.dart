import '../../../core/app_export.dart';

/// One rich autocomplete row: text query, area, landmark, or property.
class SearchSuggestionItem {
  const SearchSuggestionItem({
    required this.label,
    this.kind = 'query',
    this.payload,
  });

  final String label;

  /// 'query' | 'area' | 'landmark' | 'property'
  final String kind;
  final Object? payload;
}

// Smart search bar with mixed suggestions (queries, areas, landmarks).
class MapSearchBarWidget extends StatefulWidget {
  final VoidCallback onFilterTap;
  final VoidCallback onVoiceSearch;
  final Function(String)? onSearch;
  final List<SearchSuggestionItem> suggestions;
  final ValueChanged<SearchSuggestionItem>? onSuggestionTap;

  const MapSearchBarWidget({
    required this.onFilterTap,
    required this.onVoiceSearch,
    this.onSearch,
    this.suggestions = const [],
    this.onSuggestionTap,
    super.key,
  });

  @override
  State<MapSearchBarWidget> createState() => _MapSearchBarWidgetState();
}

class _MapSearchBarWidgetState extends State<MapSearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.isNotEmpty;
      setState(() {
        _hasText = hasText;
        _showSuggestions = hasText && widget.suggestions.isNotEmpty;
      });
      widget.onSearch?.call(_controller.text);
    });
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions =
            _focusNode.hasFocus && _hasText && widget.suggestions.isNotEmpty;
      });
    });
  }

  @override
  void didUpdateWidget(MapSearchBarWidget old) {
    super.didUpdateWidget(old);
    if (widget.suggestions != old.suggestions) {
      setState(() {
        _showSuggestions =
            _focusNode.hasFocus && _hasText && widget.suggestions.isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _iconFor(String kind) {
    switch (kind) {
      case 'area':
        return 'location_city';
      case 'landmark':
        return 'place';
      case 'property':
        return 'home';
      default:
        return 'search';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(31),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              CustomIconWidget(
                iconName: 'search',
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'ابحث: منطقة، سعر، مدرسة، مول…',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    filled: false,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  onSubmitted: (v) {
                    widget.onSearch?.call(v);
                    _focusNode.unfocus();
                  },
                ),
              ),
              if (_hasText)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    widget.onSearch?.call('');
                    _focusNode.unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: widget.onVoiceSearch,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CustomIconWidget(
                      iconName: 'mic',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              Container(width: 1, height: 24, color: AppTheme.borderLight),
              GestureDetector(
                onTap: widget.onFilterTap,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(100),
                    ),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'tune',
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Mixed autocomplete: areas, landmarks, free text
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.suggestions
                  .take(6)
                  .map(
                    (s) => InkWell(
                      onTap: () {
                        _controller.text = s.label;
                        _focusNode.unfocus();
                        setState(() => _showSuggestions = false);
                        if (widget.onSuggestionTap != null) {
                          widget.onSuggestionTap!(s);
                        } else {
                          widget.onSearch?.call(s.label);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: _iconFor(s.kind),
                              color: s.kind == 'area'
                                  ? AppTheme.primary
                                  : s.kind == 'landmark'
                                      ? const Color(0xFFF57C00)
                                      : AppTheme.primary.withAlpha(150),
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            CustomIconWidget(
                              iconName: 'north_west',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
