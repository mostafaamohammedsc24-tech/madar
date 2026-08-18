import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/property_location.dart';
import '../../domain/models/property_surroundings.dart';

/// Property location map. On web, GoogleMap is created only after an explicit
/// user tap — embedding a second map while the search map stays alive in the
/// indexed shell commonly freezes Flutter web.
class PropertyMapSection extends StatefulWidget {
  const PropertyMapSection({
    super.key,
    required this.location,
    this.nearby = const [],
  });

  final PropertyLocation location;
  final List<NearbyPlace> nearby;

  @override
  State<PropertyMapSection> createState() => _PropertyMapSectionState();
}

class _PropertyMapSectionState extends State<PropertyMapSection> {
  MapType _mapType = MapType.normal;
  bool _mapMounted = !kIsWeb;

  Future<void> _openExternalMaps() async {
    final lat = widget.location.latitude;
    final lng = widget.location.longitude;
    if (lat == null || lng == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (!widget.location.hasCoordinates) return const SizedBox.shrink();

    final center = LatLng(widget.location.latitude!, widget.location.longitude!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: _mapMounted
                ? GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: center, zoom: 14),
                    markers: {
                      Marker(
                        markerId: const MarkerId('property'),
                        position: center,
                        infoWindow: InfoWindow(
                          title: widget.location.displayLine.isNotEmpty
                              ? widget.location.displayLine
                              : loc.propertyReport,
                        ),
                      ),
                    },
                    mapType: _mapType,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    liteModeEnabled: false,
                  )
                : Material(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: InkWell(
                      onTap: () => setState(() => _mapMounted = true),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            loc.mapSection,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.openInMaps,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        if (_mapMounted)
          Wrap(
            spacing: 6,
            children: [
              ChoiceChip(
                label: Text(loc.mapStreet),
                selected: _mapType == MapType.normal,
                onSelected: (_) => setState(() => _mapType = MapType.normal),
                visualDensity: VisualDensity.compact,
              ),
              ChoiceChip(
                label: Text(loc.mapSatellite),
                selected: _mapType == MapType.satellite,
                onSelected: (_) =>
                    setState(() => _mapType = MapType.satellite),
                visualDensity: VisualDensity.compact,
              ),
              ChoiceChip(
                label: Text(loc.mapTerrain),
                selected: _mapType == MapType.terrain,
                onSelected: (_) => setState(() => _mapType = MapType.terrain),
                visualDensity: VisualDensity.compact,
              ),
            ],
          )
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _openExternalMaps,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(loc.openInMaps),
            ),
          ),
      ],
    );
  }
}
