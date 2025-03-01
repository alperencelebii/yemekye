import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// 1KM YAKIN ÇAPANLIK UZAKLIĞA GÖRE GÖSTERİYOR

class NearbyShopsWidget extends StatefulWidget {
  final Function(Map<String, dynamic> shopData) onShopTap;
  final LatLng selectedPosition; // Kullanıcının seçtiği konum

  const NearbyShopsWidget({
    Key? key,
    required this.onShopTap,
    required this.selectedPosition, // Yeni eklenen parametre
  }) : super(key: key);

  @override
  _NearbyShopsWidgetState createState() => _NearbyShopsWidgetState();
}

class _NearbyShopsWidgetState extends State<NearbyShopsWidget> {
  List<Map<String, dynamic>> _nearbyShops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNearbyShops(widget.selectedPosition);
  }

Future<void> _fetchNearbyShops(LatLng selectedPosition) async {
  try {
    final markerSnapshot = await FirebaseFirestore.instance.collection('markers').get();
    final List<Map<String, dynamic>> filteredMarkers = [];

    for (var marker in markerSnapshot.docs) {
      final markerData = marker.data();

      final double? markerLat = markerData['latitude']?.toDouble();
      final double? markerLng = markerData['longitude']?.toDouble();
      final String? shopId = markerData['shopId'];

      if (markerLat == null || markerLng == null || shopId == null) {
        print("Eksik konum veya shopId verisi: ${marker.id}");
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

      final shopDoc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .get();

      final shopData = shopDoc.data();
      if (shopData == null || (shopData.containsKey('isDeleted') && shopData['isDeleted'] == true)) {
        print("Silinmiş restoran atlandı: $shopId");
        continue;
      }

      filteredMarkers.add({
        'latitude': markerLat,
        'longitude': markerLng,
        'shopId': shopId,
        'title': markerData['title'] ?? 'Bilinmeyen Mağaza',
        'snippet': markerData['snippet'] ?? '',
        'image': shopData['image'] ?? 'assets/images/rest.jpg',
        'isOpen': shopData['isOpen'] ?? false,
      });
    }

    // **Mounted kontrolü ekliyoruz**
    if (!mounted) return;

    setState(() {
      _nearbyShops = filteredMarkers;
      _isLoading = false;
    });
  } catch (e) {
    print("Hata: $e");
    if (!mounted) return;
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

    if (_nearbyShops.isEmpty) {
      return const Center(child: Text("1 KM içinde mağaza bulunamadı."));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Yatay kaydırılabilir yapı
      child: Row(
        children: _nearbyShops.map((shopData) {
          return NearListCard(
            shopName: shopData['title'],
            shopAddress: shopData['snippet'],
            shopImagePath: '', // Varsayılan görsel
            userLocation: widget.selectedPosition,
            shopLatitude: shopData['latitude'],
            shopLongitude: shopData['longitude'],
            isOpen: shopData['isOpen'] ?? false,
            onTap: () {
              widget.onShopTap(shopData); // Detay sayfasına yönlendirme
            },
          );
        }).toList(),
      ),
    );
  }
}

class NearListCard extends StatelessWidget {
  final String shopName;
  final String shopAddress;
  final String shopImagePath;
  final LatLng userLocation;
  final double shopLatitude;
  final double shopLongitude;
  final bool isOpen;
  final VoidCallback onTap;

  const NearListCard({
    Key? key,
    required this.shopName,
    required this.shopAddress,
    required this.shopImagePath,
    required this.userLocation,
    required this.shopLatitude,
    required this.shopLongitude,
    required this.onTap,
    required this.isOpen,
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
                    shopName,
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
                    shopAddress,
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
                            '${(Geolocator.distanceBetween(userLocation.latitude, userLocation.longitude, shopLatitude, shopLongitude) / 1000).toStringAsFixed(1)} KM',
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
    return Stack(
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            image: DecorationImage(
              image: shopImagePath.startsWith('http') && shopImagePath.isNotEmpty
                  ? NetworkImage(shopImagePath)
                  : const AssetImage('assets/images/rest.jpg') as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}