import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/property_location.dart';
import '../../domain/models/property_surroundings.dart';

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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (!widget.location.hasCoordinates) return const SizedBox.shrink();

    final center = LatLng(widget.location.latitude!, widget.location.longitude!);
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('property'),
        position: center,
        infoWindow: InfoWindow(
          title: widget.location.displayLine.isNotEmpty
              ? widget.location.displayLine
              : loc.propertyReport,
        ),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: 14),
              markers: markers,
              mapType: _mapType,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              liteModeEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
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
              onSelected: (_) => setState(() => _mapType = MapType.satellite),
              visualDensity: VisualDensity.compact,
            ),
            ChoiceChip(
              label: Text(loc.mapTerrain),
              selected: _mapType == MapType.terrain,
              onSelected: (_) => setState(() => _mapType = MapType.terrain),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
}
