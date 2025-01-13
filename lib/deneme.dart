import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  Set<Marker> _markers = Set();
  Position? _currentPosition;
  List<dynamic> _places = [];
  final String googleApiKey =
      'AIzaSyB1ybb_gcSvbL6iRGakBNIk6ixr535w1Qo'; // Google API anahtarınızı ekleyin

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  // Konum izinlerini kontrol et
  Future<void> _checkPermissions() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Konum izni verilmedi.')));
    }
  }

  // Kullanıcı konumunu al
  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });

    // Kullanıcı konumunu haritada işaretle
    if (mapController != null && _currentPosition != null) {
      mapController.animateCamera(CameraUpdate.newLatLng(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      ));

      // Yakınlardaki Kafe ve Pastaneleri yükle
      _loadNearbyPlaces();
    }
  }

  // Yakınlardaki Kafeleri ve Pastaneleri yükle
  Future<void> _loadNearbyPlaces() async {
    if (_currentPosition == null) return;

    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentPosition!.latitude},${_currentPosition!.longitude}&radius=1500&keyword=cafe|kafe|pastane|pasta&key=$googleApiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      List results = data['results'];

      setState(() {
        _places = results
            .where((place) =>
                place['name'].toLowerCase().contains('cafe') ||
                place['name'].toLowerCase().contains('kafe') ||
                place['name'].toLowerCase().contains('pastane') ||
                place['name'].toLowerCase().contains('pasta'))
            .toList();
      });

      // Kafe ve pastane işaretçilerini ekle
      for (var place in _places) {
        LatLng position = LatLng(place['geometry']['location']['lat'],
            place['geometry']['location']['lng']);

        _markers.add(Marker(
          markerId: MarkerId(place['place_id']),
          position: position,
          infoWindow: InfoWindow(title: place['name']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
      }

      setState(() {});
    } else {
      throw Exception('Veri alınırken hata oluştu!');
    }
  }

  // Seçilen yerin haritada gösterilmesi
  void _showPlaceOnMap(LatLng position) {
    mapController.animateCamera(CameraUpdate.newLatLng(position));
    _markers.add(Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(title: 'Seçilen Yer'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Yakınınızdaki Kafeler ve Pastaneler")),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                if (_currentPosition != null) {
                  mapController.animateCamera(CameraUpdate.newLatLng(
                    LatLng(_currentPosition!.latitude,
                        _currentPosition!.longitude),
                  ));
                }
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(40.7128, -74.0060), // Varsayılan konum
                zoom: 14,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          if (_places.isNotEmpty)
            Container(
              padding: EdgeInsets.all(8.0),
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _places.length,
                itemBuilder: (context, index) {
                  var place = _places[index];
                  return GestureDetector(
                    onTap: () {
                      LatLng position = LatLng(
                          place['geometry']['location']['lat'],
                          place['geometry']['location']['lng']);
                      _showPlaceOnMap(position);
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.0),
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            place['name'],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 5),
                          Icon(
                            Icons.place,
                            color: Colors.white,
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
