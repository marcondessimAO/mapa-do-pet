import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';
import 'osm_tile_layer.dart';

/// Mini-mapa para ajustar o ponto aproximado do animal (RF-07): um toque move o
/// pino. O widget não guarda estado; quem o usa devolve o novo [location].
class LocationPicker extends StatelessWidget {
  const LocationPicker({
    required this.location,
    required this.onChanged,
    super.key,
  });

  static const double _height = 220;
  static const double _zoom = 16;
  static const double _pinSize = 48;

  final LatLng location;
  final ValueChanged<LatLng> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: _height,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: location,
                initialZoom: _zoom,
                onTap: (_, point) => onChanged(point),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                const OsmTileLayer(),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: location,
                      width: _pinSize,
                      height: _pinSize,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        size: _pinSize,
                        color: AppColors.caramelo,
                      ),
                    ),
                  ],
                ),
                const OsmAttribution(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Toque no mapa para ajustar o ponto.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
