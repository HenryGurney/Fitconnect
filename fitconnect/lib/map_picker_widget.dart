import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

class MapPickerWidget extends StatefulWidget {
  final Function(LatLng position) onPositionSelected;
  const MapPickerWidget({super.key, required this.onPositionSelected});

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  // Use Google Maps stable LatLng format for component tracking
  LatLng _selectedPosition = const LatLng(3.1390, 101.6869);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: FlutterMap(
              options: MapOptions(
                // FIX: Removed private file hooks. Map center updates directly via camera position
                onPositionChanged: (camera, hasGesture) {
                  setState(() {
                    _selectedPosition = LatLng(camera.center.latitude, camera.center.longitude);
                  });
                  widget.onPositionSelected(_selectedPosition);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.fitconnect.app',
                ),
                // Fixed Crosshair centered exactly over the viewport overlay
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 30),
                    child: Icon(Icons.location_on, color: Color(0xFF39FF14), size: 40),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Coordinates: ${_selectedPosition.latitude.toStringAsFixed(4)}, ${_selectedPosition.longitude.toStringAsFixed(4)}",
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        )
      ],
    );
  }
}