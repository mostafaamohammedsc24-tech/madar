import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';

/// Static nested card — Zillow facts cards never use a down-chevron tile.
/// When [initiallyExpanded] is false, content is revealed with a text "Show more".
class ReportSection extends StatelessWidget {
  const ReportSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = true,
    this.trailing,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: const Color(0xFF667085)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: const Color(0xFF101828),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (initiallyExpanded)
            child
          else
            _ShowMoreBody(child: child),
        ],
      ),
    );
  }
}

class _ShowMoreBody extends StatefulWidget {
  const _ShowMoreBody({required this.child});

  final Widget child;

  @override
  State<_ShowMoreBody> createState() => _ShowMoreBodyState();
}

class _ShowMoreBodyState extends State<_ShowMoreBody> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_open) widget.child,
        TextButton(
          onPressed: () => setState(() => _open = !_open),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
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

class FactGrid extends StatelessWidget {
  const FactGrid({super.key, required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return FactsIconGrid(
      items: items
          .map((item) => (Icons.info_outline, '${item.$2} ${item.$1}'.trim()))
          .toList(),
    );
  }
}

/// Two-column icon + label rows used by Zillow "Facts & features".
class FactsIconGrid extends StatelessWidget {
  const FactsIconGrid({super.key, required this.items});

  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = items
        .map(
          (item) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.$1, size: 18, color: const Color(0xFF667085)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.$2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1D2939),
                  ),
                ),
              ),
            ],
          ),
        )
        .toList();

    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class EmptySectionHint extends StatelessWidget {
  const EmptySectionHint({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Text(
      loc.sectionNoDataYet,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
    );
  }
}
