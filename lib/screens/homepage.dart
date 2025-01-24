import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedAddress = 'Konum Seçin';
  LatLng? selectedPosition;

  final List<String> categories = ['Pastane', 'Kafe', 'FNK', 'Döner'];
  int selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
  }

  Future<void> _loadInitialLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedAddress = prefs.getString('selectedAddress');
    double? lat = prefs.getDouble('latitude');
    double? lng = prefs.getDouble('longitude');

    if (savedAddress != null && lat != null && lng != null) {
      setState(() {
        selectedAddress = savedAddress;
        selectedPosition = LatLng(lat, lng);
      });
    } else {
      _promptLocationSelection();
    }
  }

  Future<void> _promptLocationSelection() async {
    final result = await showModalBottomSheet<LatLng?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LocationPicker(),
    );

    if (result != null) {
      await _saveSelectedLocation(result);
    }
  }

  Future<void> _saveSelectedLocation(LatLng position) async {
    String address = await _getAddressFromLatLng(position);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedAddress', address);
    await prefs.setDouble('latitude', position.latitude);
    await prefs.setDouble('longitude', position.longitude);

    setState(() {
      selectedAddress = address;
      selectedPosition = position;
    });
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    final apiKey = Platform.isAndroid
        ? 'AIzaSyDgIWs5tMOE89_0Q9xCl_fRBt3Hei-NmhI'
        : 'AIzaSyCJ1LSqoi3NmgYLE0kXzKm698-ODaI9Nk8';
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        return data['results'][0]['formatted_address'];
      }
    }
    return 'Adres bulunamadı';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: _promptLocationSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A602),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  selectedAddress ?? 'Konum Seçin',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Yakınından ucuza \nYemek bul..',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF1D1D1D),
                ),
              ),
              const SizedBox(height: 10),
              // Kategoriler
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(categories.length, (index) {
                    final isSelected = selectedCategoryIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF9A602)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFB9C3C3),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationPicker extends StatefulWidget {
  @override
  __LocationPickerState createState() => __LocationPickerState();
}

class __LocationPickerState extends State<_LocationPicker> {
  LatLng? _pickedPosition;
  late GoogleMapController _mapController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Adres veya yer ara",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Google Places API çağrısını buraya entegre edebilirsiniz.
              },
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
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
                      ),
                    },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_pickedPosition != null) {
                Navigator.of(context).pop(_pickedPosition);
              }
            },
            child: const Text('Konumu Kaydet'),
          ),
        ],
      ),
    );
  }
}
