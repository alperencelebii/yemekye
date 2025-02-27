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
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Container(
          width: screenWidth * 0.88, // Daha kompakt hale getirildi
          height: 75, // NearListCard ile orantılı hale getirildi
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10), // Hafif yuvarlak köşeler
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildImage(), // Yuvarlak köşeli görsel
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        shopName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF242424),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shopAddress,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF646464),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.orange.withOpacity(0.9),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$distanceInKm KM',
                                style: const TextStyle(
                                  fontSize: 11,
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
                                size: 11, // Daha küçük ikon
                                color: isOpen
                                    ? const Color(0xFF52BF71)
                                    : const Color(0xFFFF6767),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isOpen ? 'Açık' : 'Kapalı',
                                style: TextStyle(
                                  fontSize: 11,
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
      borderRadius: BorderRadius.circular(8), // NearListCard ile aynı köşe oranı
      child: Image(
        width: 55, // NearListCard ile aynı görsel oranı
        height: 55,
        fit: BoxFit.cover,
        image: shopImagePath.startsWith('http') && shopImagePath.isNotEmpty
            ? NetworkImage(shopImagePath)
            : const AssetImage('assets/images/rest.jpg') as ImageProvider,
      ),
    );
  }
}