import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NearbyShopsWidget extends StatefulWidget {
  final Function(Map<String, dynamic> shopData) onShopTap;
  final LatLng selectedPosition; // Kullanıcının seçtiği konum

  const NearbyShopsWidget({
    Key? key,
    required this.onShopTap,
    required this.selectedPosition,
  }) : super(key: key);

  @override
  _NearbyShopsWidgetState createState() => _NearbyShopsWidgetState();
}
class _NearbyShopsWidgetState extends State<NearbyShopsWidget> {
  List<Map<String, dynamic>> _nearbyShops = [];
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

        final shopDoc = await FirebaseFirestore.instance.collection('shops').doc(shopId).get();
        final shopData = shopDoc.data();

        if (shopData == null || (shopData.containsKey('isDeleted') && shopData['isDeleted'] == true)) {
          continue;
        }

        // Check if the shop is a favorite by the current user
        final user = _auth.currentUser;
        bool isFavorite = false;
        if (user != null) {
          final favoriteDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .doc(shopId)
              .get();
          isFavorite = favoriteDoc.exists;
        }

        filteredMarkers.add({
          'latitude': markerLat,
          'longitude': markerLng,
          'shopId': shopId,
          'title': markerData['title'] ?? 'Bilinmeyen Mağaza',
          'snippet': markerData['snippet'] ?? '',
          'image': shopData['image'] ?? 'assets/images/rest.jpg',
          'isOpen': shopData['isOpen'] ?? false,
          'isFavorite': isFavorite, // Add the favorite status
        });
      }

      if (!mounted) return;

      setState(() {
        _nearbyShops = filteredMarkers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(String shopId, bool isFavorite) async {
    final user = _auth.currentUser;
    if (user == null) {
      return; // Kullanıcı oturum açmamışsa, işlem yapılmaz
    }

    final userFavoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites');

    if (isFavorite) {
      // Favoriye ekle
      await userFavoritesRef.doc(shopId).set({
        'shopId': shopId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      // Favoriden çıkar
      await userFavoritesRef.doc(shopId).delete();
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
            shopImagePath: shopData['image'],
            userLocation: widget.selectedPosition,
            shopLatitude: shopData['latitude'],
            shopLongitude: shopData['longitude'],
            isOpen: shopData['isOpen'] ?? false, // Bu satır
            shopId: shopData['shopId'], // Mağaza ID'si
            isFavorite: shopData['isFavorite'], // Favori durumu Firebase'den alınıyor
            onFavoriteToggle: (isFavorite) => _toggleFavorite(shopData['shopId'], isFavorite), // Favori toggle fonksiyonu
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
  final String shopId;
  final bool isFavorite;
  final Function(bool) onFavoriteToggle;

  const NearListCard({
    Key? key,
    required this.shopName,
    required this.shopAddress,
    required this.shopImagePath,
    required this.userLocation,
    required this.shopLatitude,
    required this.shopLongitude,
    required this.onTap,
    required this.shopId,
    required this.isFavorite,
    required this.onFavoriteToggle,
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
        child: Stack(
          children: [
            Column(
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
            // Favori ekleme ikonu sağ üst köşede
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey, // Kırmızı ya da gri
                  size: 30, // Boyutu büyüttük
                ),
                onPressed: () {
                  onFavoriteToggle(!isFavorite);  // Favori durumu değiştirme
                },
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