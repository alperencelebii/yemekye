import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class YatayRestaurantCard extends StatelessWidget {
  final String shopName;
  final String shopAddress;
  final String shopImagePath;
  final LatLng userLocation; // Kullanıcının anlık konumu
  final double shopLatitude;
  final double shopLongitude;
  final VoidCallback onTap;

  const YatayRestaurantCard({
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
    final screenWidth = MediaQuery.of(context).size.width;

    // Mesafeyi hesapla
    final distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      shopLatitude,
      shopLongitude,
    );
    final distanceInKm =
        (distance / 1000).toStringAsFixed(2); // Kilometre cinsinden

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Sağ ve soldan 16px boşluk
        child: Container(
          width: screenWidth, // Tam ekran genişlik
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
          child: Row(
            children: [
              _buildImage(),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName,
                        style: const TextStyle(
                          fontSize: 16, // Daha küçük bir yazı tipi
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.orange.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$distanceInKm KM', // Dinamik mesafe
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
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 90, // Daha dar bir genişlik
      height: 90, // Sabit kare boyut
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          bottomLeft: Radius.circular(15),
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
