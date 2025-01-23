import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yemekye/components/models/yatay_restaurant_card.dart';
import 'package:yemekye/screens/addproduct.dart';
import 'package:yemekye/screens/restaurant_details.dart';
import 'package:yemekye/components/models/restaurant_list_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> categories = ['Pastane', 'Kafe', 'FNK', 'Döner'];
  int selectedCategoryIndex = 0;
  String searchQuery = '';
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  LatLng? _currentPosition;
  List<Map<String, dynamic>> nearbyShops = [];
  bool showRestaurants = false;

  @override
  void initState() {
    super.initState();
    _startLocationStream();
  }

  bool _isRequestingPermission = false;
  void _startLocationStream() async {
    if (_isRequestingPermission) return;

    _isRequestingPermission = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Konum servisleri kapalı.';

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Konum izni reddedildi.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Konum izinleri kalıcı olarak reddedildi.';
      }

      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _loadMarkersFromFirebase();
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isRequestingPermission = false;
    }
  }

  // Firebase'den markerları alıp haritaya ekler
// Firebase'den markerları alıp haritaya ekler
  Future<void> _loadMarkersFromFirebase() async {
    if (_currentPosition == null) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('markers').get();

    setState(() {
      _markers.clear();
      nearbyShops.clear();
    });

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final latitude = data['latitude'];
      final longitude = data['longitude'];
      final shopId = data['shopId']; // shopId alınır

      if (latitude != null && longitude != null) {
        final shopPosition = LatLng(latitude, longitude);
        final distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          shopPosition.latitude,
          shopPosition.longitude,
        );

        if (distanceInMeters <= 1000) {
          final shopSnapshot = await FirebaseFirestore.instance
              .collection('shops')
              .doc(shopId)
              .get();

          final shopData = shopSnapshot.data();
          final shopImage = shopData?['image'] ?? 'assets/images/rest.jpg';
          final shopName = shopData?['name'] ?? 'Mağaza Adı Yok';
          final shopAddress = shopData?['address'] ?? 'Adres Bilgisi Yok';

          setState(() {
            _markers.add(Marker(
              markerId: MarkerId(doc.id),
              position: shopPosition,
              infoWindow: InfoWindow(
                title: shopName,
                snippet: shopAddress,
              ),
            ));
            nearbyShops.add({
              'name': shopName,
              'address': shopAddress,
              'image': shopImage,
              'distance': (distanceInMeters / 1000).toStringAsFixed(2),
              'latitude': latitude,
              'longitude': longitude,
            });
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Merhaba',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'BeVietnamPro',
                    color: Color(0xFF1D1D1D),
                  ),
                ),
                Text(
                  'Alperen',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'BeVietnamPro',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1D1D),
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: SvgPicture.asset('assets/icons/Vector.svg'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddProduct()),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              // Arama Çubuğu
              Container(
                height: 50,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/search.svg',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Ara',
                          hintStyle: TextStyle(
                            color: Color(0xFFB9C3C3),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
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

              // Harita
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _currentPosition == null
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        markers:
                            _markers, // Firebase'ten çekilen markerlar burada görünecek
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition!,
                          zoom: 14.0,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                      ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popüler Restoranlar',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // "Göster" butonuna basıldığında restoranları açıp kapatma
                      setState(() {
                        showRestaurants = !showRestaurants;
                      });
                    },
                    child: Text(
                      showRestaurants ? 'Gizle' : 'Göster',
                      style: const TextStyle(
                        color: Colors.blue, // Buton metni rengi
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
// Restoranlar
              if (showRestaurants)
                nearbyShops.isEmpty
                    ? const Text(
                        'Yakınlarda restoran bulunamadı.',
                        style: TextStyle(color: Colors.black),
                      )
                    : SizedBox(
                        height: 105,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: nearbyShops.length,
                          itemBuilder: (context, index) {
                            final shop = nearbyShops[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: YatayRestaurantCard(
                                shopName: shop['name'],
                                shopAddress: shop['address'],
                                shopImagePath: shop['image'],
                                userLocation: _currentPosition ?? LatLng(0, 0),
                                shopLatitude: shop['latitude'] ?? 0.0,
                                shopLongitude: shop['longitude'] ?? 0.0,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RestaurantDetails(
                                        shopName: shop['name'],
                                        shopAddress: shop['address'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}
