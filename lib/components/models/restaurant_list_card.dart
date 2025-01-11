import 'package:flutter/material.dart';

class RestaurantListCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 125,
      height: 254,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14.0),
        color: Colors.white,
      ),
      child: Column(
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
      height: 156,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14.0)),
        image: DecorationImage(
          image: AssetImage('assets/images/rest.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Şimşek Aspava',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            _buildRating(),
            Text(
              'Açık',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22BA61)),
            ),
            _buildTimeInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildRating() {
    return Row(
      children: [
        Row(
          children: List.generate(
              4,
              (index) =>
                  Icon(Icons.star, color: Colors.yellow.shade700, size: 12)),
        ),
        SizedBox(width: 4),
        Text(
          '4.7 (5645)',
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0E0D0D)),
        ),
      ],
    );
  }

  Widget _buildTimeInfo() {
    return Row(
      children: [
        Icon(Icons.access_time, color: Color(0xFF0E0D0D), size: 12),
        SizedBox(width: 4),
        Text('500 MT',
            style: TextStyle(fontSize: 10, color: Color(0xFF0E0D0D))),
      ],
    );
  }
}
