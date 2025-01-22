import 'package:flutter/material.dart';

class YatayRestaurantCard extends StatelessWidget {
  final String shopName;
  final String shopAddress;
  final String shopImagePath;
  final VoidCallback onTap;

  const YatayRestaurantCard({
    Key? key,
    required this.shopName,
    required this.shopAddress,
    required this.shopImagePath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth * 0.7, // Daha ince bir genişlik
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
        child: Row(
          children: [
            _buildImage(),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
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
                          '500 MT', // Dinamik değer eklenebilir
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
