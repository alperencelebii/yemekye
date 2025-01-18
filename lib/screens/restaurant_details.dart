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
      body: Stack(
        children: [
          // Arka plan resmi
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/rest.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Beyaz alt panel
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve ikonlar
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
                            Icon(Icons.favorite_border, color: Colors.black),
                            Icon(Icons.more_horiz, color: Color(0xFF1D1D1D)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF22BA61)),
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

                    // Dinamik Kategoriler ve Ürünler
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('shops')
                          .where('name', isEqualTo: shopName)
                          .get()
                          .then((snapshot) {
                        if (snapshot.docs.isNotEmpty) {
                          return snapshot.docs.first; // Sadece ilk döküman
                        } else {
                          throw Exception('Mağaza bulunamadı.');
                        }
                      }),
                      builder: (context, shopSnapshot) {
                        if (shopSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!shopSnapshot.hasData ||
                            shopSnapshot.data == null) {
                          return const Text('Mağaza bulunamadı.');
                        }

                        // `productid` listesini alın
                        final productIds = List<String>.from(
                            shopSnapshot.data!.data()?['productid'] ?? []);

                        if (productIds.isEmpty) {
                          return const Text('Bu mağazada ürün bulunamadı.');
                        }

                        // Ürünleri çekmek için bir FutureBuilder ekleyin
                        return FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('products')
                              .where(FieldPath.documentId, whereIn: productIds)
                              .get(),
                          builder: (context, productSnapshot) {
                            if (productSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (!productSnapshot.hasData ||
                                productSnapshot.data!.docs.isEmpty) {
                              return const Text('Ürün bulunamadı.');
                            }

                            // Ürünleri kategorilere göre gruplama
                            final products = productSnapshot.data!.docs;
                            final Map<String, List<QueryDocumentSnapshot>>
                                categories = {};

                            for (var product in products) {
                              final category =
                                  product['category'] ?? 'Kategori Yok';
                              if (!categories.containsKey(category)) {
                                categories[category] = [];
                              }
                              categories[category]!.add(product);
                            }

                            // Gruplamayı gösterme
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: categories.entries.map((entry) {
                                final category = entry.key;
                                final categoryProducts = entry.value;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    Text(
                                      category,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'BeVietnamPro',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...categoryProducts.map((product) {
                                      return ProductCard(
                                        productId: product.id,
                                        productName:
                                            product['name'] ?? 'Ürün Adı Yok',
                                        productPrice: (product['price'] is num)
                                            ? product['price'].toDouble()
                                            : 0.0,
                                        piece: (product['piece'] is int)
                                            ? product['piece']
                                            : 0,
                                        shopId: shopSnapshot.data!
                                            .id, // 🔥 'shopId' olarak belge kimliğini kullan
                                      );
                                    }).toList(),
                                  ],
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
