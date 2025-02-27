import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PopularRestaurantsWidget extends StatefulWidget {
  final Function(Map<String, dynamic> shopData) onShopTap;
  final LatLng selectedPosition;

  const PopularRestaurantsWidget({
    Key? key,
    required this.onShopTap,
    required this.selectedPosition,
  }) : super(key: key);

  @override
  _PopularRestaurantsWidgetState createState() =>
      _PopularRestaurantsWidgetState();
}

class _PopularRestaurantsWidgetState extends State<PopularRestaurantsWidget> {
  List<Map<String, dynamic>> _popularRestaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPopularRestaurants(widget.selectedPosition);
  }

  Future<void> _fetchPopularRestaurants(LatLng selectedPosition) async {
    try {
      final markerSnapshot =
          await FirebaseFirestore.instance.collection('markers').get();

      List<Map<String, dynamic>> restaurants = [];

      for (var marker in markerSnapshot.docs) {
        final markerData = marker.data() as Map<String, dynamic>;

        final double? markerLat = markerData['latitude']?.toDouble();
        final double? markerLng = markerData['longitude']?.toDouble();
        final String? shopId = markerData['shopId'];

        if (markerLat == null || markerLng == null || shopId == null) {
          continue;
        }

        final distance = Geolocator.distanceBetween(
          selectedPosition.latitude,
          selectedPosition.longitude,
          markerLat,
          markerLng,
        );

        if (distance > 1000) {
          continue;
        }

        // 🔥 Restoranın sipariş sayısını çekiyoruz
        final orderCountQuery = await FirebaseFirestore.instance
            .collection('carts')
            .where('shopId', isEqualTo: shopId)
            .where('status', isEqualTo: 'Onaylandı')
            .get();

        final int orderCount = orderCountQuery.docs.length;

        final shopDoc = await FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .get();

        final shopData = shopDoc.data() as Map<String, dynamic>?;

        restaurants.add({
          'latitude': markerLat,
          'longitude': markerLng,
          'shopId': shopId,
          'title': markerData['title'] ?? 'Bilinmeyen Restoran',
          'snippet': markerData['snippet'] ?? '',
          'image': shopData?['image'] ?? 'assets/images/rest.jpg',
          'isOpen': shopData?['isOpen'] ?? false,
          'orderCount': orderCount, // 🔥 Sipariş sayısını ekledik
          'distance': (distance / 1000).toStringAsFixed(1), // KM
        });
      }

      // 🔥 Restoranları sipariş sayısına göre sıralıyoruz (Çok sipariş alan en önde!)
      restaurants.sort((a, b) => b['orderCount'].compareTo(a['orderCount']));

      setState(() {
        _popularRestaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      print("Hata: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_popularRestaurants.isEmpty) {
      return const Center(child: Text("1 KM içinde restoran bulunamadı."));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _popularRestaurants.map((restaurant) {
          return RestaurantListCard(
            restaurantName: restaurant['title'],
            restaurantAddress: restaurant['snippet'],
            restaurantImagePath: restaurant['image'],
            userLocation: widget.selectedPosition,
            restaurantLatitude: restaurant['latitude'],
            restaurantLongitude: restaurant['longitude'],
            isOpen: restaurant['isOpen'] ?? false,
            distance: restaurant['distance'], // Mesafe
            onTap: () {
              widget.onShopTap(restaurant);
            },
          );
        }).toList(),
      ),
    );
  }
}

class RestaurantListCard extends StatelessWidget {
  final String restaurantName;
  final String restaurantAddress;
  final String restaurantImagePath;
  final LatLng userLocation;
  final double restaurantLatitude;
  final double restaurantLongitude;
  final bool isOpen;
  final String distance;
  final VoidCallback onTap;

  const RestaurantListCard({
    Key? key,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantImagePath,
    required this.userLocation,
    required this.restaurantLatitude,
    required this.restaurantLongitude,
    required this.onTap,
    required this.isOpen,
    required this.distance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurantName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    restaurantAddress,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF777777),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.orange.withOpacity(0.8),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$distance KM',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            isOpen ? Icons.check_circle : Icons.cancel,
                            size: 14,
                            color: isOpen
                                ? const Color(0xFF52BF71)
                                : const Color(0xFFFF6767),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOpen ? 'Açık' : 'Kapalı',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isOpen
                                  ? const Color(0xFF52BF71)
                                  : const Color(0xFFFF6767),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        image: DecorationImage(
          image: NetworkImage(restaurantImagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}