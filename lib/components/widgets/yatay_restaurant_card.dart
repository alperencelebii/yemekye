import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class YatayRestaurantCard extends StatelessWidget {
  final String shopName;
  final String shopAddress;
  final String shopImagePath;
  final LatLng userLocation;
  final double shopLatitude;
  final double shopLongitude;
  final VoidCallback onTap;
  final bool isOpen;

  const YatayRestaurantCard({
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
    final screenWidth = MediaQuery.of(context).size.width;

    // Mesafeyi hesapla
    final distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      shopLatitude,
      shopLongitude,
    );
    final distanceInKm = (distance / 1000).toStringAsFixed(1);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0), // Daha fazla boşluk
        child: Container(
          width: screenWidth * 0.90, // Genişliği biraz artırdık
          height: 90, // Yüksekliği artırdık
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12), // Hafif yuvarlak köşeler
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6, // Gölgeyi biraz daha belirgin yapıyoruz
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildImage(), // Yuvarlak köşeli görsel
                const SizedBox(width: 12), // Daha fazla boşluk
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        shopName,
                        style: const TextStyle(
                          fontSize: 15, // Daha büyük yazı tipi
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
                          fontSize: 12, // Yazı boyutunu biraz büyüttük
                          color: Color(0xFF646464),
                        ),
                        maxLines: 1,
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
                                size: 14, // Daha büyük ikon
                                color: Colors.orange.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$distanceInKm KM',
                                style: const TextStyle(
                                  fontSize: 12, // Daha büyük yazı boyutu
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                isOpen ? Icons.check_circle : Icons.cancel,
                                size: 14, // Daha büyük ikon
                                color: isOpen
                                    ? const Color(0xFF52BF71)
                                    : const Color(0xFFFF6767),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOpen ? 'Açık' : 'Kapalı',
                                style: TextStyle(
                                  fontSize: 12, // Daha büyük yazı boyutu
                                  fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10), // NearListCard ile aynı köşe oranı
      child: Image(
        width: 70, // Görselin genişliğini biraz artırdık
        height: 70, // Görselin yüksekliğini artırdık
        fit: BoxFit.cover,
        image: shopImagePath.startsWith('http') && shopImagePath.isNotEmpty
            ? NetworkImage(shopImagePath)
            : const AssetImage('assets/images/rest.jpg') as ImageProvider,
      ),
    );
  }
}