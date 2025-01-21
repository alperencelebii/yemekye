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
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
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

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _loadMarkersFromFirebase();
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
      _markers.clear();
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

          if (distanceInMeters <= 1000) {
            _markers.add(Marker(
              markerId: MarkerId(doc.id),
              position: shopPosition,
              infoWindow: InfoWindow(
                title: data['title'] ?? 'Mağaza Adı Yok',
                snippet: data['snippet'] ?? 'Adres Bilgisi Yok',
              ),
            ));
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
                  style: TextStyle(fontSize: 16, color: Color(0xFF1D1D1D)),
                ),
                Text(
                  'Alperen',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1D)),
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
                              ? const Color(0xFFF9A602)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFB9C3C3),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Popüler Restoranlar',
                style: TextStyle(
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
              const SizedBox(height: 10),
              // Restoranlar Listesi
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
                        final shopData =
                            shopDocs[index].data() as Map<String, dynamic>;
                        final shopName = shopData['name'] ?? 'Mağaza Adı Yok';
                        final shopAddress =
                            shopData['address'] ?? 'Adres Bilgisi Yok';
                        final shopImagePath = shopData['image']?.isNotEmpty ==
                                true
                            ? shopData['image']
                            : 'assets/images/rest.jpg';

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
                              restaurantImagePath: shopImagePath,
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
