import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String productName;
  final double productdiscountPrice;
  final int piece;

  const ProductCard({
    Key? key,
    required this.productName,
    required this.productdiscountPrice,
    required this.piece,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  'assets/images/images.jpeg', // Sabit resim yolu
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName, // Ürün adı
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'BeVietnamPro',
                      color: Color(0xFF353535),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₺${productdiscountPrice.toStringAsFixed(2)}", // Ürün fiyatı
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$piece Adet Kaldı', // Stok adedi
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13,
                color: Color(0xFF353535),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                // Detaylara yönlendirme
                print("Detaya git");
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1D),
                  borderRadius: BorderRadius.circular(50),
                ),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
