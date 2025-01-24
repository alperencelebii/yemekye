import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({Key? key}) : super(key: key);

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng? _currentLocation;
  LatLng _centerPosition = const LatLng(39.92077, 32.85411);
  String? _address;
  late GoogleMapController _mapController;
  BitmapDescriptor? customMarker;
  final Location _location = Location();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _getCurrentLocation();
  }

  Future<void> _loadCustomMarker() async {
    customMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/marker.png',
    );
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final locationData = await _location.getLocation();
      final currentLatLng =
          LatLng(locationData.latitude!, locationData.longitude!);
      setState(() {
        _currentLocation = currentLatLng;
        _centerPosition = currentLatLng;
      });
      _mapController
          .animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 15));
      await _updateAddress(currentLatLng);
    } catch (e) {
      print("Hata: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    // Geocoding API implementation can go here.
    setState(() => _address = "Adres bulunamadı");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Konum Seç"),
        backgroundColor: const Color(0xFFF9A602),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (cameraPosition) {
              setState(() {
                _centerPosition = cameraPosition.target;
              });
            },
            onCameraIdle: () async {
              await _updateAddress(_centerPosition);
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(39.92077, 32.85411),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => ScaleGestureRecognizer(),
              ),
            },
          ),
          Center(
            child: Icon(
              Icons.location_on,
              size: 48,
              color: Colors.red,
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Text(
                _address ?? "Konum alınıyor...",
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9A602),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.my_location),
                  label: const Text("Anlık Konumu Al"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(_centerPosition);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9A602),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("Konumu Seç"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
