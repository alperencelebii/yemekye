import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Konum alımı ve markerların Firebase'ten yüklenmesi
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

    // Marker'ları yükle
    _loadMarkersFromFirebase();
  }

  // Firebase'den markerları alıp haritaya ekler
  Future<void> _loadMarkersFromFirebase() async {
    if (_currentPosition == null) return;

    // Firebase 'markers' koleksiyonundan verileri al
    final snapshot =
        await FirebaseFirestore.instance.collection('markers').get();

    setState(() {
      _markers.clear(); // Mevcut markerları temizle
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final latitude = data['latitude'];
        final longitude = data['longitude'];

        // Null kontrolü yapalım
        if (latitude != null && longitude != null) {
          final shopPosition = LatLng(latitude, longitude);

          // Kullanıcı konumuyla marker arasındaki mesafeyi hesapla
          double distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            shopPosition.latitude,
            shopPosition.longitude,
          );

          // 1 km (1000 metre) mesafedeki markerları ekle
          if (distanceInMeters <= 1000) {
            final marker = Marker(
              markerId: MarkerId(doc.id),
              position: shopPosition,
              infoWindow: InfoWindow(
                title: data['name'] ?? 'Mağaza Adı Yok',
                snippet: data['address'] ?? 'Adres Bilgisi Yok',
              ),
            );
            _markers.add(marker);
          }
        }
      }
    });
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
              const Text(
                'Popüler Restoranlar',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
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
              // Restoranlar
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('shops').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('Restoran bulunamadı.');
                  }

                  final shopDocs = snapshot.data!.docs;

                  return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: shopDocs.length,
                      itemBuilder: (context, index) {
                        final shopData = shopDocs[index];
                        final shopName = shopData['name'] ?? 'Mağaza Adı Yok';
                        final shopAddress =
                            shopData['address'] ?? 'Adres Bilgisi Yok';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RestaurantDetails(
                                  shopName: shopName,
                                  shopAddress: shopAddress,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: RestaurantListCard(
                              restaurantName: shopName,
                              restaurantAddress: shopAddress,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
