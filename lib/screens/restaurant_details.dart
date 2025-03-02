import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yemekye/components/widgets/product_card.dart';

class RestaurantDetails extends StatelessWidget {
  final String shopName;
  final String shopAddress;
  final bool isOpen;

  const RestaurantDetails({
    Key? key,
    required this.shopName,
    required this.shopAddress,
    required this.isOpen,
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
          final imageUrl = shopData['image'] ?? 'assets/images/rest.jpg';
          final totalRating = (shopData['averageRating'] as num?)?.toDouble() ?? 0.0;

          return Stack(
            children: [
              /// **Header Image**
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: (imageUrl.startsWith('http'))
                        ? NetworkImage(imageUrl) as ImageProvider
                        : const AssetImage('assets/images/rest.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              /// **Main Content**
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
                        /// **Shop Name & Stylish Rating**
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                /// **Shop Name**
                                Text(
                                  shopName,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'BeVietnamPro',
                                  ),
                                ),
                                const SizedBox(width: 8),

                                /// **Modern Rating Badge**
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100, // Soft yellow background
                                    borderRadius: BorderRadius.circular(20), // Rounded shape
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        totalRating.toStringAsFixed(1), // Example: 4.5
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            /// **Report Button**
                            IconButton(
                              icon: const Icon(Icons.flag, color: Colors.red),
                              onPressed: () {
                                _showReportDialog(context, shopDoc.id);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        /// **Address with Google Maps Link**
                        GestureDetector(
                          onTap: () async {
                            final markerSnapshot = await FirebaseFirestore.instance
                                .collection('markers')
                                .where('shopId', isEqualTo: shopDoc.id)
                                .get();

                            if (markerSnapshot.docs.isNotEmpty) {
                              final markerData = markerSnapshot.docs.first.data();
                              final latitude = markerData['latitude'] as double?;
                              final longitude = markerData['longitude'] as double?;

                              if (latitude != null && longitude != null) {
                                final Uri googleMapsUri = Uri.parse(
                                    'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

                                if (await launchUrl(googleMapsUri)) {
                                  debugPrint("Google Maps açıldı.");
                                } else {
                                  debugPrint("Google Maps açılamadı.");
                                }
                              } else {
                                debugPrint("Konum bilgisi eksik.");
                              }
                            }
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFF22BA61)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shopAddress,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// **Product List**
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

  /// **Product List Widget**
  Widget _buildProductList(QueryDocumentSnapshot<Map<String, dynamic>> shopDoc) {
    final shopData = shopDoc.data();
    final productIds =
        (shopData['productid'] != null && shopData['productid'] is List)
            ? List<String>.from(shopData['productid'])
            : <String>[];

    if (productIds.isEmpty) {
      return const Center(child: Text('Bu mağazada ürün bulunamadı.'));
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
          return const Center(child: Text('Ürün bulunamadı.'));
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
                    isOpen: isOpen,
                    productPrice: (product['price'] as num?)?.toDouble() ?? 0.0,
                    piece: product['piece'] ?? 0,
                    shopId: shopDoc.id,
                  );
                }).toList(),
              ],
            );
          }).toList(),
        );
      },
    );
  }


  void _showReportDialog(BuildContext context, String shopId) {
    final TextEditingController topicController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rapor Et'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: topicController, decoration: const InputDecoration(labelText: 'Konu')),
              TextField(controller: messageController, decoration: const InputDecoration(labelText: 'Mesaj'), maxLines: 3),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                final topic = topicController.text.trim();
                final message = messageController.text.trim();
                if (topic.isNotEmpty && message.isNotEmpty) {
                  _reportShop(shopId, topic, message);
                  Navigator.pop(context);
                }
              },
              child: const Text('Gönder'),
            ),
          ],
        );
      },
    );
  }



  void _reportShop(String shopId, String topic, String message) async {
    final reportCollection = FirebaseFirestore.instance.collection('reports');

    await reportCollection.add({
      'shopId': shopId,
      'topic': topic,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    debugPrint("Mağaza raporlandı: $shopId, Konu: $topic");
  }
}
