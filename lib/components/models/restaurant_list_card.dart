import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RestaurantListCard extends StatelessWidget {
  final String shopName;
  final String shopAddress;
  final String shopImagePath;
  final LatLng userLocation;
  final double shopLatitude;
  final double shopLongitude;
  final VoidCallback onTap;

  const RestaurantListCard({
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
        width: 160, // Sabit genişlik
        height: 240, // Sabit yükseklik
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
                      maxLines: 1, // Metni bir satırda sınırla
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shopAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF646464),
                      ),
                      maxLines: 2, // Metni iki satırda sınırla
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(), // KM bilgisini en alta iter
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
      height: 120, // Sabit yükseklik
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
