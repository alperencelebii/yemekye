import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleMapsExample extends StatefulWidget {
  @override
  _GoogleMapsExampleState createState() => _GoogleMapsExampleState();
}

class _GoogleMapsExampleState extends State<GoogleMapsExample> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentPosition;
  List<Map<String, dynamic>> _nearbyMarkers = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Konum servislerini kontrol et
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Konum izni kontrolü
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Anlık konumu al
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    // Konum alındığında markerları yükle
    _loadMarkersFromFirebase();
  }

  Future<void> _loadMarkersFromFirebase() async {
    if (_currentPosition == null) {
      return; // Eğer konum alınmadıysa, yükleme işlemi yapma
    }

    final snapshot =
        await FirebaseFirestore.instance.collection('markers').get();
    List<Map<String, dynamic>> nearby = [];
    setState(() {
      _markers.clear(); // Önceki marker'ları temizle
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
          // 1 km mesafedeki markerlar
          final marker = Marker(
            markerId: MarkerId(doc.id),
            position: markerPosition,
            infoWindow: InfoWindow(
              title: data['title'],
              snippet: data['snippet'],
            ),
          );
          _markers.add(marker);
          nearby.add({
            'title': data['title'],
            'snippet': data['snippet'],
            'distance': (distance / 1000).toStringAsFixed(2), // km cinsinden
          });
        }
      }
      _nearbyMarkers = nearby;
    });
  }

  Future<void> _addMarker(LatLng position) async {
    final String markerIdVal =
        'marker_${DateTime.now().millisecondsSinceEpoch}';

    final Marker marker = Marker(
      markerId: MarkerId(markerIdVal),
      position: position,
      infoWindow: InfoWindow(
        title: 'Marker $markerIdVal',
        snippet: 'This is a custom marker',
      ),
    );

    setState(() {
      _markers.add(marker);
    });

    // Marker'ı Firebase'e kaydet
    await FirebaseFirestore.instance
        .collection('markers')
        .doc(markerIdVal)
        .set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'title': 'Marker $markerIdVal',
      'snippet': 'This is a custom marker',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps Example'),
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
                    onTap: _addMarker,
                    myLocationEnabled: true, // Konumu gösterme
                    myLocationButtonEnabled: true, // Konum butonunu gösterme
                  ),
          ),
          if (_nearbyMarkers.isNotEmpty)
            Container(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _nearbyMarkers.length,
                itemBuilder: (context, index) {
                  final marker = _nearbyMarkers[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            marker['title'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text(marker['snippet']),
                          SizedBox(height: 5),
                          Text('${marker['distance']} km'),
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
