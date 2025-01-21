import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'addproduct.dart';
import 'restaurant_details.dart';
import '../components/models/restaurant_list_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final categories = ['Pastane', 'Kafe', 'FNK', 'Döner'];
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

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _currentPosition = LatLng(position.latitude, position.longitude);
    _loadMarkersFromFirebase();
  }

  Future<void> _loadMarkersFromFirebase() async {
    if (_currentPosition == null) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('markers').get();
    _markers = snapshot.docs
        .map((doc) {
          final data = doc.data();
          final shopPosition = LatLng(data['latitude'], data['longitude']);
          if (Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  shopPosition.latitude,
                  shopPosition.longitude) <=
              1000) {
            return Marker(
              markerId: MarkerId(doc.id),
              position: shopPosition,
              infoWindow: InfoWindow(
                  title: data['title'] ?? 'Mağaza Adı Yok',
                  snippet: data['snippet'] ?? 'Adres Bilgisi Yok'),
            );
          }
          return null;
        })
        .whereType<Marker>()
        .toSet();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yakınından ucuza \nYemek bul..',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            _buildSearchBar(),
            const SizedBox(height: 10),
            _buildCategories(),
            const SizedBox(height: 20),
            const Text('Popüler Restoranlar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            _buildMap(),
            const SizedBox(height: 10),
            Expanded(child: _buildRestaurantList()),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Merhaba',
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  Text('Alperen',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ]),
            const Spacer(),
            IconButton(
              icon: SvgPicture.asset('assets/icons/Vector.svg'),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddProduct())),
            ),
          ],
        ),
      );

  Widget _buildSearchBar() => Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          SvgPicture.asset('assets/icons/search.svg', width: 20, height: 20),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
            decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Ara',
                hintStyle: TextStyle(color: Colors.grey)),
            onChanged: (value) => setState(() => searchQuery = value),
          )),
        ]),
      );

  Widget _buildCategories() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.asMap().entries.map((entry) {
            final index = entry.key;
            final isSelected = index == selectedCategoryIndex;
            return GestureDetector(
              onTap: () => setState(() => selectedCategoryIndex = index),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(entry.value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey)),
              ),
            );
          }).toList(),
        ),
      );

  Widget _buildMap() => Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: _currentPosition == null
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                markers: _markers,
                initialCameraPosition:
                    CameraPosition(target: _currentPosition!, zoom: 14.0),
                myLocationEnabled: true,
              ),
      );

  Widget _buildRestaurantList() => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('shops').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text('Restoran bulunamadı.');
          }
          return ListView(
            scrollDirection: Axis.horizontal,
            children: snapshot.data!.docs.map((doc) {
              return GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RestaurantDetails(
                              shopName: doc['name'] ?? 'Mağaza Adı Yok',
                              shopAddress:
                                  doc['address'] ?? 'Adres Bilgisi Yok',
                            ))),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: RestaurantListCard(
                    restaurantName: doc['name'] ?? 'Mağaza Adı Yok',
                    restaurantAddress: doc['address'] ?? 'Adres Bilgisi Yok',
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
}
