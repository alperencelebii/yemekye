import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:yemekye/adminpanel/%C3%B6ne%C3%A7%C4%B1karma/featuredshops.dart';
import 'package:yemekye/components/models/yak%C4%B1nlar/yakin_restaurant_list_card.dart';
import 'package:yemekye/loginregister/login.dart';
import 'dart:convert';
import 'dart:io';
import 'package:yemekye/map/homescreen/locationpickermap.dart';
import 'package:yemekye/components/models/restaurant_list_card.dart';
import 'package:yemekye/components/models/yatay_restaurant_card.dart';
import 'restaurant_details.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedAddress = 'Konum Seçin';
  LatLng? selectedPosition;

  final List<String> categories = ['Pastane', 'Kafe', 'Restoran', 'Döner'];
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
      appBar: AppBar(
        title: const Text(
          'Son Dilim',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1D),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1D1D1D)),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut(); // Oturumu kapat
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false, // Tüm önceki sayfaları kaldır
                );
              } catch (e) {
                debugPrint("Oturum kapatma hatası: $e");
              }
            },
          ),
        ],
      ),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      selectedAddress,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'En İyiler',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF1D1D1D),
                ),
              ),
              const SizedBox(height: 5),
              const FeaturedShops(),
              const SizedBox(height: 5),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('shops').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('Hiçbir mağaza bulunamadı.'));
                  }

                  final shops = snapshot.data!.docs.toList();

                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // RestaurantListCard'ları yatay olarak sıralama
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                child: NearbyShopsWidget(
                                  onShopTap: (shopData) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RestaurantDetails(
                                          shopName: shopData['title'],
                                          shopAddress: shopData['snippet'],
                                          isOpen: shopData['isOpen'] ?? false,
                                        ),
                                      ),
                                    );
                                  },
                                  selectedPosition: selectedPosition ??
                                      LatLng(0, 0), // Seçilen konumu gönder
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                child: NearbyShops(
                                  onShopTap: (shopData) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RestaurantDetails(
                                          shopName: shopData['title'],
                                          shopAddress: shopData['snippet'],
                                          isOpen: shopData['isOpen'] ?? false,
                                        ),
                                      ),
                                    );
                                  },
                                  selectedPosition: selectedPosition ??
                                      LatLng(0, 0), // Seçilen konumu gönder
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Tüm Restaurantlar',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF1D1D1D),
                          ),
                        ),
                        // YatayRestaurantCard'ları alt alta sıralama
                        Column(
                          children: shops.map((shop) {
                            final shopData =
                                shop.data() as Map<String, dynamic>;
                            return YatayRestaurantCard(
                              shopName: shopData['name'] ?? 'Mağaza Adı Yok',
                              shopAddress:
                                  shopData['address'] ?? 'Adres Bilgisi Yok',
                              shopImagePath:
                                  shopData['image'] ?? 'assets/images/rest.jpg',
                              userLocation:
                                  selectedPosition ?? const LatLng(0, 0),
                              shopLatitude: shopData['latitude'] ?? 0.0,
                              shopLongitude: shopData['longitude'] ?? 0.0,
                              isOpen: shopData['isOpen'] ?? false,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RestaurantDetails(
                                      shopName: shopData['name'],
                                      shopAddress: shopData['address'],
                                      isOpen: shopData['isOpen'] ?? false,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
