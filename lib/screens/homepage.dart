import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yemekye/screens/addproduct.dart';
import 'package:yemekye/screens/restaurant_details.dart';
import 'package:yemekye/components/models/yatay_restaurant_card.dart';
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
  bool _isRequestingPermission = false;
  List<Map<String, dynamic>> nearbyShops = []; // Yakın restoranlar listesi

  @override
  void initState() {
    super.initState();
    _startLocationStream(); // Konum değişimini dinlemek için stream başlatıyoruz
  }

// Konum değişimini sürekli dinlemek için stream başlatıyoruz
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

      // Konum stream'ini başlatıyoruz
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // En az 10 metre ilerledikçe tetiklensin
        ),
      ).listen((Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _loadMarkersFromFirebase(); // Konum değiştikçe marker'ları güncelliyoruz
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<void> _loadMarkersFromFirebase() async {
    if (_currentPosition == null) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('markers').get();

    setState(() {
      _markers.clear(); // Önceden eklenmiş markerları temizle
      nearbyShops.clear(); // Önceden eklenmiş restoranları temizle
    });

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final latitude = data['latitude'];
      final longitude = data['longitude'];

      if (latitude != null && longitude != null) {
        final shopPosition = LatLng(latitude, longitude);
        final distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          shopPosition.latitude,
          shopPosition.longitude,
        );

        // 1 km içindeki restoranları ekle
        if (distanceInMeters <= 1000) {
          setState(() {
            _markers.add(Marker(
              markerId: MarkerId(doc.id),
              position: shopPosition,
              infoWindow: InfoWindow(
                title: data['title'] ?? 'Mağaza Adı Yok',
                snippet: data['snippet'] ?? 'Adres Bilgisi Yok',
              ),
            ));
            nearbyShops.add({
              'name': data['title'] ?? 'Mağaza Adı Yok',
              'address': data['snippet'] ?? 'Adres Bilgisi Yok',
              'image': data['image'] ?? 'assets/images/rest.jpg',
              'distance': (distanceInMeters / 1000).toStringAsFixed(2), // KM
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 166, 0),
              Color.fromARGB(255, 255, 255, 255)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                AssetImage('assets/images/sondilim.png'),
                            radius: 30,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Sondilim',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'En Güzel Paylaşım',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddProduct()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Slogan Alanı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          'Yakınında Ucuza Yemek bul!!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1D1D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Uygun fiyatlı yemeklerin keyfini çıkar.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Arama Çubuğu
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Restoran veya yemek ara...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Kategoriler
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
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
                                  ? const Color.fromARGB(255, 0, 0, 0)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1D1D1D),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
                            markers: _markers,
                            initialCameraPosition: CameraPosition(
                              target: _currentPosition!,
                              zoom: 14.0,
                            ),
                            myLocationEnabled: true,
                          ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sana En Yakınlar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Restoranlar Listesi
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
                                  userLocation: _currentPosition ??
                                      LatLng(0, 0), // Kullanıcının anlık konumu
                                  shopLatitude:
                                      shop['latitude'] ?? 0.0, // Null kontrolü
                                  shopLongitude:
                                      shop['longitude'] ?? 0.0, // Null kontrolü
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
        ),
      ),
    );
  }
}
