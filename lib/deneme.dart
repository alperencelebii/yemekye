import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class GoogleMapScreen extends StatefulWidget {
  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  late GoogleMapController _mapController;
  Location _location = Location();

  final LatLng _initialLocation = const LatLng(41.015137, 28.979530);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialLocation,
          zoom: 14.0,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          _location.onLocationChanged.listen((LocationData locationData) {
            _mapController.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(locationData.latitude!, locationData.longitude!),
              ),
            );
          });
        },
      ),
    );
  }
}
