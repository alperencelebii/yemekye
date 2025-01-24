import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';

class LocationPicker extends StatefulWidget {
  const LocationPicker({Key? key}) : super(key: key);

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng? _pickedPosition;
  late GoogleMapController _mapController;
  BitmapDescriptor? _customMarker;
  Location _location = Location();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
  }

  Future<void> _loadCustomMarker() async {
    final customMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/a1.png', // Marker için optimize bir dosya kullanın.
    );
    setState(() {
      _customMarker = customMarker;
    });
  }

  Future<void> _getCurrentLocation() async {
    final currentLocation = await _location.getLocation();
    final currentLatLng =
        LatLng(currentLocation.latitude!, currentLocation.longitude!);

    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(currentLatLng, 15),
    );

    setState(() {
      _pickedPosition = currentLatLng;
    });
  }

  void _onCameraMove(CameraPosition position) {
    // Kamera hareketlerini kontrol etmek için debounce ekleniyor.
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      setState(() {
        _pickedPosition = position.target;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onCameraMove:
                      _onCameraMove, // Kamera hareketleri debounce ile optimize edildi.
                  onTap: (position) {
                    setState(() {
                      _pickedPosition = position;
                    });
                  },
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(39.92077, 32.85411), // Türkiye merkez
                    zoom: 10,
                  ),
                  markers: _pickedPosition == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('pickedPosition'),
                            position: _pickedPosition!,
                            icon:
                                _customMarker ?? BitmapDescriptor.defaultMarker,
                          ),
                        },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: FloatingActionButton(
                    onPressed: _getCurrentLocation,
                    backgroundColor: const Color(0xFFF9A602),
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
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
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Konumu Kaydet'),
          ),
        ],
      ),
    );
  }
}
