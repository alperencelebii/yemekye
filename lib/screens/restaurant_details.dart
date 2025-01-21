import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yemekye/components/models/product_card.dart';

class RestaurantDetails extends StatelessWidget {
  final String shopName;
  final String shopAddress;

  const RestaurantDetails({
    Key? key,
    required this.shopName,
    required this.shopAddress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('shops')
            .where('name', isEqualTo: shopName)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Mağaza bulunamadı.'));
          }

          final shopDoc = snapshot.data!.docs.first;
          final shopData = shopDoc.data();
          final imageUrl =
              shopData['image'] != null && shopData['image'] is String
                  ? shopData['image'] as String
                  : 'assets/images/rest.jpg';

          return Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: (imageUrl.startsWith('http') && imageUrl.isNotEmpty)
                        ? NetworkImage(imageUrl) as ImageProvider
                        : const AssetImage('assets/images/rest.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.65,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              shopName,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'BeVietnamPro',
                              ),
                            ),
                            Row(
                              children: const [
                                Icon(Icons.favorite_border,
                                    color: Colors.black),
                                Icon(Icons.more_horiz,
                                    color: Color(0xFF1D1D1D)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Color(0xFF22BA61)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                shopAddress,
                                style: const TextStyle(fontSize: 14),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildProductList(shopDoc),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductList(
      QueryDocumentSnapshot<Map<String, dynamic>> shopDoc) {
    final shopData = shopDoc.data();
    final productIds =
        shopData['productid'] != null && shopData['productid'] is List
            ? List<String>.from(shopData['productid'])
            : <String>[];

    if (productIds.isEmpty) {
      return const Text('Bu mağazada ürün bulunamadı.');
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .where(FieldPath.documentId, whereIn: productIds)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Ürün bulunamadı.');
        }

        final products = snapshot.data!.docs;
        final Map<String, List<QueryDocumentSnapshot>> categories = {};

        for (var product in products) {
          final category = product['category'] ?? 'Kategori Yok';
          categories.putIfAbsent(category, () => []).add(product);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: categories.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'BeVietnamPro',
                  ),
                ),
                const SizedBox(height: 8),
                ...entry.value.map((product) {
                  return ProductCard(
                    productId: product.id,
                    productName: product['name'] ?? 'Ürün Adı Yok',
                    productPrice: (product['price'] as num?)?.toDouble() ?? 0.0,
                    piece: product['piece'] ?? 0,
                    shopId: shopDoc.id, // Firestore belge kimliği
                  );
                }).toList(),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
