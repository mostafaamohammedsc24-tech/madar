import '../../../core/app_export.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../features/property/presentation/widgets/sheet_grabber.dart';
import '../models/property_data.dart';
import 'property_card.dart';

/// Results sheet hovering above the global bottom nav.
/// Collapsed: white strip with a bold centered results count.
/// Expanded: recommendation chip, sort toolbar, then the card feed.
class DraggablePropertySheet extends StatelessWidget {
  const DraggablePropertySheet({
    super.key,
    required this.controller,
    required this.maxSize,
    required this.merged,
    required this.expanded,
    required this.resultsLabel,
    required this.toolbar,
    required this.properties,
    required this.onOpen,
  });

  final DraggableScrollableController controller;
  final double maxSize;

  /// Sheet reached the top band — square the corners.
  final bool merged;

  /// Past the halfway point — reveal toolbar and cards.
  final bool expanded;
  final String resultsLabel;
  final Widget toolbar;
  final List<PropertyData> properties;
  final ValueChanged<PropertyData> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: maxSize,
      snap: true,
      snapSizes: [0.12, maxSize],
      builder: (context, scrollController) {
        return Material(
          color: Colors.white,
          elevation: 10,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(merged ? 0 : 16),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SheetGrabber(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Text(
                        resultsLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (expanded) ...[
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: Color(0xFF1565C0),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  loc.recommendedBySearch,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      toolbar,
                      const Divider(
                        height: 16,
                        thickness: 1,
                        color: Color(0xFFEEEEEE),
                      ),
                    ],
                  ),
                ),
                if (properties.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          loc.noData,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: properties.length,
                    itemBuilder: (context, i) {
                      final property = properties[i];
                      return PropertyCard(
                        property: property,
                        onTap: () => onOpen(property),
                      );
                    },
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ] else
                const SliverToBoxAdapter(child: SizedBox(height: 220)),
            ],
          ),
        );
      },
    );
  }
}
