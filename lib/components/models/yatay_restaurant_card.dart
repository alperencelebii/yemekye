import 'package:flutter/material.dart';

class YatayRestaurantCard extends StatelessWidget {
  const YatayRestaurantCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 328,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/rest.jpg',
              width: 80,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 29,
                      ),
                      Text(
                        'Şimşek Aspava',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          4,
                          (index) => Icon(Icons.star,
                              color: Colors.yellow.shade700, size: 14),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '4.7',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0E0D0D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Açık',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF22BA61),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '|',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kapanış Saati: 20.00',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0E0D0D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          color: Color(0xFF0E0D0D), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '500 MT',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF0E0D0D),
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
    );
  }
}
