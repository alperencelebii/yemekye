import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:yemekye/map/homescreen/locationpickermap.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedAddress = 'Konum Seçin';
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
    }
  }

  Future<void> _promptLocationSelection() async {
    final result = await showModalBottomSheet<LatLng?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const LocationPicker(),
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
        ? 'AIzaSyC9zFUi5DMC6Wi4X-kUDP6nQcep_8rgCjY'
        : 'AIzaSyCJ1LSqoi3NmgYLE0kXzKm698-ODaI9Nk8';
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final addressComponents = data['results'][0]['address_components'];
        String district = '';
        String neighborhood = '';
        String street = '';

        for (var component in addressComponents) {
          if (component['types'].contains('administrative_area_level_2')) {
            district = component['long_name'];
          }
          if (component['types'].contains('sublocality') ||
              component['types'].contains('sublocality_level_1')) {
            neighborhood = component['long_name'];
          }
          if (component['types'].contains('route')) {
            street = component['long_name'];
          }
        }

        // Format the address with available components
        return [
          district,
          neighborhood,
          street,
        ].where((e) => e.isNotEmpty).join(', ');
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
                  selectedAddress,
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
