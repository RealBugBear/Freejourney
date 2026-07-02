import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrainerLocationPickerWidget extends StatefulWidget {
  const TrainerLocationPickerWidget({
    super.key,
    this.initialLatLng,
    required this.onLocationPicked,
  });

  final LatLng? initialLatLng;
  final void Function(LatLng latLng) onLocationPicked;

  @override
  State<TrainerLocationPickerWidget> createState() =>
      _TrainerLocationPickerWidgetState();
}

class _TrainerLocationPickerWidgetState
    extends State<TrainerLocationPickerWidget> {
  late final MapController _mapController;
  LatLng? _pickedLocation;

  // Default center: Germany (Munich)
  static const _defaultCenter = LatLng(48.1351, 11.5820);
  static const _defaultZoom = 10.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pickedLocation = widget.initialLatLng;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onTap(TapPosition _, LatLng latLng) {
    setState(() => _pickedLocation = latLng);
    widget.onLocationPicked(latLng);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _pickedLocation ?? _defaultCenter,
            initialZoom: _defaultZoom,
            onTap: _onTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'de.reflexjourney.app',
            ),
            if (_pickedLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickedLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (_pickedLocation == null)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Tippe auf die Karte',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
