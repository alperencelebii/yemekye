import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleMapUser extends StatefulWidget {
  @override
  _GoogleMapUserState createState() => _GoogleMapUserState();
}

class _GoogleMapUserState extends State<GoogleMapUser> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentPosition;
  LatLng? _lastLoadedPosition;
  List<Map<String, dynamic>> _nearbyMarkers = [];
  final double _distanceThreshold = 500; // 500 metre eşiği

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      LatLng newPosition = LatLng(position.latitude, position.longitude);

      if (_lastLoadedPosition == null ||
          Geolocator.distanceBetween(
                  _lastLoadedPosition!.latitude,
                  _lastLoadedPosition!.longitude,
                  newPosition.latitude,
                  newPosition.longitude) >
              _distanceThreshold) {
        setState(() {
          _currentPosition = newPosition;
          _lastLoadedPosition = newPosition;
        });
        await _loadMarkersFromFirebase();
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadMarkersFromFirebase() async {
    if (_currentPosition == null) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('markers').get();
    List<Map<String, dynamic>> nearby = [];
    Set<Marker> newMarkers = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final markerPosition = LatLng(data['latitude'], data['longitude']);
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        markerPosition.latitude,
        markerPosition.longitude,
      );

      if (distance <= 1000) {
        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: markerPosition,
          infoWindow: InfoWindow(
            title: data['title'],
            snippet: data['snippet'],
          ),
        );
        newMarkers.add(marker);
        nearby.add({
          'title': data['title'],
          'snippet': data['snippet'],
          'distance': (distance / 1000).toStringAsFixed(2),
        });
      }
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
      _nearbyMarkers = nearby;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps Example'),
        backgroundColor: Color(0xFFF9A602),
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentPosition == null
                ? Center(child: CircularProgressIndicator())
                : GoogleMap(
                    onMapCreated: _onMapCreated,
                    markers: _markers,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition!,
                      zoom: 15.0,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
          ),
          if (_nearbyMarkers.isNotEmpty)
            Container(
              height: 150,
              color: Color(0xFFF9A602).withOpacity(0.2),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _nearbyMarkers.length,
                itemBuilder: (context, index) {
                  final marker = _nearbyMarkers[index];
                  return Card(
                    color: Colors.white,
                    shadowColor: Color(0xFFF9A602),
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            marker['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF9A602),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(marker['snippet']),
                          SizedBox(height: 5),
                          Text(
                            '${marker['distance']} km',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }
}
