import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

// HEPSİ YARIÇAPTAKİLERİ GÖSTERİYOR

class NearbyShops extends StatefulWidget {
  final Function(Map<String, dynamic> shopData) onShopTap;
  final LatLng selectedPosition; // Kullanıcının seçtiği konum

  const NearbyShops({
    Key? key,
    required this.onShopTap,
    required this.selectedPosition,
  }) : super(key: key);

  @override
  _NearbyShopsState createState() => _NearbyShopsState();
}

class _NearbyShopsState extends State<NearbyShops> {
  List<Map<String, dynamic>> _nearbyShops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNearbyShops(widget.selectedPosition);
  }

  Future<void> _fetchNearbyShops(LatLng selectedPosition) async {
    try {
      final markerSnapshot =
          await FirebaseFirestore.instance.collection('markers').get();

      // Markerları çekiyoruz
      final List<Map<String, dynamic>> filteredMarkers = [];
      for (var marker in markerSnapshot.docs) {
        final markerData = marker.data() as Map<String, dynamic>;

        final double? markerLat = markerData['latitude']?.toDouble();
        final double? markerLng = markerData['longitude']?.toDouble();
        final String? shopId = markerData['shopId'];

        if (markerLat == null || markerLng == null || shopId == null) {
          print("Eksik konum veya shopId verisi: ${marker.id}");
          continue; // Hatalı veri varsa atlıyoruz
        }

        // Shops koleksiyonundan image bilgisini çekiyoruz
        final shopDoc = await FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .get();

        final shopData = shopDoc.data() as Map<String, dynamic>?;

        // Kullanıcı favori durumunu kontrol ediyoruz
        final user = FirebaseAuth.instance.currentUser;
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
          'image': shopData?['image'] ?? 'assets/images/rest.jpg', // Image bilgisi
          'isOpen': shopData?['isOpen'] ?? false, // Açık/Kapalı durumu
          'isFavorite': isFavorite, // Favori durumu ekleniyor
        });
      }

      setState(() {
        _nearbyShops = filteredMarkers;
        _isLoading = false;
      });
    } catch (e) {
      print("Hata: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(String shopId, bool isFavorite) async {
    final user = FirebaseAuth.instance.currentUser;
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
          return nearlistcards(
            shopName: shopData['title'],
            shopAddress: shopData['snippet'],
            shopImagePath: shopData['image'] ?? 'assets/images/rest.jpg',
            userLocation: widget.selectedPosition,
            shopLatitude: shopData['latitude'],
            shopLongitude: shopData['longitude'],
            isOpen: shopData['isOpen'] ?? false,
            shopId: shopData['shopId'], // Mağaza ID'si
            isFavorite: shopData['isFavorite'], // Firebase'den favori durumu alınıyor
            onFavoriteToggle: (isFavorite) => _toggleFavorite(shopData['shopId'], isFavorite), // Favori durumu güncelleniyor
            onTap: () {
              widget.onShopTap(shopData); // Detay sayfasına yönlendirme
            },
          );
        }).toList(),
      ),
    );
  }
}

class nearlistcards extends StatelessWidget {
  final String shopName;
  final String shopAddress;
  final String shopImagePath;
  final LatLng userLocation;
  final double shopLatitude;
  final double shopLongitude;
  final VoidCallback onTap;
  final bool isOpen; // Yeni parametre
  final bool isFavorite; // Favori durumu
  final Function(bool) onFavoriteToggle; // Favori durumu toggle fonksiyonu
  final String shopId; // Mağaza ID'si

  const nearlistcards({
    Key? key,
    required this.shopName,
    required this.shopAddress,
    required this.shopImagePath,
    required this.userLocation,
    required this.shopLatitude,
    required this.shopLongitude,
    required this.onTap,
    required this.isOpen,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.shopId,
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
                    const SizedBox(height: 4),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOpen
                                ? const Color(0xFF52BF71)
                                : const Color(0xFFFF6767),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    IconButton(
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        onFavoriteToggle(!isFavorite);
                      },
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