import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/app_export.dart';
import '../../../core/localization/app_localizations.dart';

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
  final VoidCallback? onVoiceSearch;
  final Function(String)? onSearch;
  final List<SearchSuggestionItem> suggestions;
  final ValueChanged<SearchSuggestionItem>? onSuggestionTap;

  const MapSearchBarWidget({
    this.onVoiceSearch,
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
  final SpeechToText _speech = SpeechToText();
  bool _hasText = false;
  bool _showSuggestions = false;
  bool _listening = false;
  bool _speechReady = false;

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
    _speech.stop();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    widget.onVoiceSearch?.call();
    final loc = AppLocalizations.of(context);
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    try {
      _speechReady = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
    } catch (_) {
      _speechReady = false;
    }

    if (!_speechReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.voiceNotAvailable)),
      );
      return;
    }

    final localeId = switch (loc.language) {
      AppLanguage.arabic => 'ar_IQ',
      AppLanguage.kurdish => 'ckb_IQ',
      AppLanguage.english => 'en_US',
    };

    setState(() => _listening = true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: localeId,
      ),
      onResult: (result) {
        if (!mounted) return;
        _controller.value = TextEditingValue(
          text: result.recognizedWords,
          selection: TextSelection.collapsed(
            offset: result.recognizedWords.length,
          ),
        );
        widget.onSearch?.call(result.recognizedWords);
        if (result.finalResult && mounted) {
          setState(() => _listening = false);
        }
      },
    );
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
    final loc = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCFCFCF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(
                Icons.search,
                color: Color(0xFF5F6368),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: _listening ? loc.voiceListening : loc.searchHint,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: _listening
                          ? AppTheme.primary
                          : const Color(0xFF5F6368),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    filled: false,
                  ),
                  style: TextStyle(
                    fontSize: 15,
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
                  onTap: _toggleVoice,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CustomIconWidget(
                      iconName: 'mic',
                      color: _listening
                          ? AppTheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
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
