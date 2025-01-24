import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({Key? key}) : super(key: key);

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng? _pickedPosition;
  LatLng? _currentLocation;
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
        _pickedPosition ??= currentLatLng;
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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Adres veya yer ara",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => print("Arama: $value"),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              onTap: (position) async {
                setState(() => _pickedPosition = position);
                await _updateAddress(position);
              },
              initialCameraPosition: CameraPosition(
                target: _pickedPosition ?? const LatLng(39.92077, 32.85411),
                zoom: 10,
              ),
              markers: {
                if (_pickedPosition != null)
                  Marker(
                    markerId: const MarkerId('pickedPosition'),
                    position: _pickedPosition!,
                    icon: customMarker ?? BitmapDescriptor.defaultMarker,
                  ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  if (_pickedPosition != null) {
                    Navigator.of(context).pop(_pickedPosition);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A602),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(_address ?? 'Konumu Kaydet'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
