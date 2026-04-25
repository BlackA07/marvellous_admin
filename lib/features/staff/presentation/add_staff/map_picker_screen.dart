import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final void Function(double lat, double lng, String address) onLocationPicked;

  const MapPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.onLocationPicked,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  late LatLng _selectedLocation;
  bool _isLoading = false;

  static const Color _bg = Color(0xFF0D0D1A);
  static const Color _surface = Color(0xFF1A1A2E);
  static const Color _accent = Color(0xFF4F8EF7);
  static const Color _textWhite = Color(0xFFEAEAFF);
  static const Color _textMid = Color(0xFF9090B0);

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktopOrWeb =
        kIsWeb ||
        (!kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textWhite,
        elevation: 0,
        title: const Text(
          'Pick Location on Map',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textWhite,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isDesktopOrWeb
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_rounded, size: 60, color: _textMid),
                    const SizedBox(height: 16),
                    const Text(
                      "Google Maps is not fully supported on this desktop/web platform yet.\nPlease enter the address manually.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _textWhite, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Go Back"),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (latLng) {
                    setState(() => _selectedLocation = latLng);
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation,
                      draggable: true,
                      onDragEnd: (latLng) {
                        setState(() => _selectedLocation = latLng);
                      },
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                  style: _darkMapStyle,
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accent.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.touch_app_rounded, color: _accent, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tap on map or drag the pin to select location',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textMid,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.my_location_rounded,
                          color: _accent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Lat: ${_selectedLocation.latitude.toStringAsFixed(5)},  Lng: ${_selectedLocation.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              widget.onLocationPicked(
                                _selectedLocation.latitude,
                                _selectedLocation.longitude,
                                '',
                              );
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Confirm This Location',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1a1a2e"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a1a2e"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#263c3f"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#6b9a76"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9ca5b3"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#746855"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#1f2835"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#f3d19c"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f3948"}]},
  {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#515c6d"}]},
  {"featureType": "water", "elementType": "labels.text.stroke", "stylers": [{"color": "#17263c"}]}
]
''';
}
