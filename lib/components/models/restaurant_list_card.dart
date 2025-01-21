import 'package:flutter/material.dart';

class RestaurantListCard extends StatelessWidget {
  final String restaurantName;
  final String restaurantAddress;

  const RestaurantListCard({
    Key? key,
    required this.restaurantName,
    required this.restaurantAddress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 125,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14.0),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(),
          _buildInfo(),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 125,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14.0)),
        image: const DecorationImage(
          image: AssetImage('assets/images/rest.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getShortnames(restaurantName),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _getShortAddress(restaurantAddress),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Açık',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF22BA61),
            ),
          ),
        ],
      ),
    );
  }

  String _getShortAddress(String address) {
    final words = address.split(' ');
    if (words.length <= 2) {
      return address;
    }
    return '${words[0]} ${words[1]}...';
  }

  String _getShortnames(String names) {
    if (names.length <= 14) {
      return names;
    }
    return '${names.substring(0, 14)}...';
  }
}
