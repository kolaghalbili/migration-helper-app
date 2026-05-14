import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final void Function(LatLng) onLocationSelected;

  const MapLocationPicker({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LatLng? _selected;
  late final MapController _mapController;

  static const _defaultCenter = LatLng(48.8566, 2.3522); // Paris as default

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selected = widget.initialLocation;
  }

  @override
  void didUpdateWidget(MapLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != oldWidget.initialLocation &&
        widget.initialLocation != null) {
      setState(() => _selected = widget.initialLocation);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.initialLocation!, 12);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Pin your location on the map (optional)',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C)),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Tap anywhere on the map to drop a pin',
            style: TextStyle(fontSize: 12, color: Color(0xFF7A8B9A)),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 240,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selected ?? _defaultCenter,
                initialZoom: _selected != null ? 12 : 3,
                onTap: (tapPosition, point) {
                  setState(() => _selected = point);
                  widget.onLocationSelected(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.borderline.app',
                ),
                if (_selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFFE8944A),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Pinned: ${_selected!.latitude.toStringAsFixed(4)}, ${_selected!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _selected = null);
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(fontSize: 12, color: Color(0xFFE8944A)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
