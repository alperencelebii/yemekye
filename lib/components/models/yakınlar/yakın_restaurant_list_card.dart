import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NearbyShopsWidget extends StatefulWidget {
  final Function(Map<String, dynamic> shopData) onShopTap;

  const NearbyShopsWidget({
    Key? key,
    required this.onShopTap,
  }) : super(key: key);

  @override
  _NearbyShopsWidgetState createState() => _NearbyShopsWidgetState();
}

class _NearbyShopsWidgetState extends State<NearbyShopsWidget> {
  Position? _userLocation;
  List<Map<String, dynamic>> _nearbyShops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _userLocation = position;
      });

      await _fetchNearbyShops(position);
    } catch (e) {
      print("Konum alınamadı: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyShops(Position userPosition) async {
    try {
      final markerSnapshot =
          await FirebaseFirestore.instance.collection('markers').get();

      final filteredMarkers = markerSnapshot.docs.where((marker) {
        final markerData = marker.data() as Map<String, dynamic>;

        final double? markerLat = markerData['latitude']?.toDouble();
        final double? markerLng = markerData['longitude']?.toDouble();

        if (markerLat == null || markerLng == null) {
          print("Eksik konum verisi: ${marker.id}");
          return false;
        }

        final distance = Geolocator.distanceBetween(userPosition.latitude,
            userPosition.longitude, markerLat, markerLng);

        return distance <= 1000; // 1 km yarıçap
      }).map((marker) {
        final markerData = marker.data() as Map<String, dynamic>;
        return {
          'latitude': markerData['latitude'],
          'longitude': markerData['longitude'],
          'shopId': markerData['shopId'],
          'title': markerData['title'] ?? 'Bilinmeyen Mağaza',
          'snippet': markerData['snippet'] ?? '',
        };
      }).toList();

      setState(() {
        _nearbyShops = filteredMarkers;
      });
    } catch (e) {
      print("Hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userLocation == null) {
      return const Center(child: Text("Konum alınamadı."));
    }

    if (_nearbyShops.isEmpty) {
      return const Center(child: Text("1 KM içinde mağaza bulunamadı."));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Yatay kaydırılabilir yapı
      child: Row(
        children: _nearbyShops.map((shopData) {
          return nearlistcard(
            shopName: shopData['title'],
            shopAddress: shopData['snippet'],
            shopImagePath: '', // Varsayılan görsel
            userLocation: LatLng(
              _userLocation!.latitude,
              _userLocation!.longitude,
            ),
            shopLatitude: shopData['latitude'],
            shopLongitude: shopData['longitude'],
            onTap: () {
              widget.onShopTap(shopData); // Detay sayfasına yönlendirme
            },
          );
        }).toList(),
      ),
    );
  }
}

class nearlistcard extends StatelessWidget {
  final String shopName;
  final String shopAddress;
  final String shopImagePath;
  final LatLng userLocation;
  final double shopLatitude;
  final double shopLongitude;
  final VoidCallback onTap;

  const nearlistcard({
    Key? key,
    required this.shopName,
    required this.shopAddress,
    required this.shopImagePath,
    required this.userLocation,
    required this.shopLatitude,
    required this.shopLongitude,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 240,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF242424),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shopAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF646464),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.orange.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(Geolocator.distanceBetween(userLocation.latitude, userLocation.longitude, shopLatitude, shopLongitude) / 1000).toStringAsFixed(2)} KM',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        image: DecorationImage(
          image: shopImagePath.startsWith('http') && shopImagePath.isNotEmpty
              ? NetworkImage(shopImagePath)
              : const AssetImage('assets/images/rest.jpg') as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
