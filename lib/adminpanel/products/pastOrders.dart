import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PastOrdersScreen extends StatelessWidget {
  final String shopId;

  const PastOrdersScreen({Key? key, required this.shopId}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchPastOrders() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final querySnapshot = await firestore
          .collection('carts')
          .where('shopId', isEqualTo: shopId)
          .where('status', isEqualTo: 'Onaylandı')
          .get();

      List<Map<String, dynamic>> orders = querySnapshot.docs.map((doc) {
        final products = List<Map<String, dynamic>>.from(doc.data()['products'] ?? []);
        final totalPrice = products.fold(0.0, (sum, product) {
          final price = product['price'] ?? 0.0;
          final quantity = product['quantity'] ?? 0;
          return sum + (price * quantity);
        });

        return {
          'cartId': doc.id,
          'orderNumber': doc.data()['orderNumber'] ?? 'N/A',
          'products': products,
          'totalPrice': totalPrice,
          'updatedAt': (doc.data()['updatedAt'] as Timestamp).toDate(),
        };
      }).toList();

      orders.sort((a, b) => b['updatedAt'].compareTo(a['updatedAt']));

      return orders;
    } catch (e) {
      throw Exception('Siparişleri yüklerken hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Siparişler'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF9A602), Color(0xFFFA5B08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>( 
        future: _fetchPastOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Bir hata oluştu: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Henüz geçmiş sipariş bulunmuyor.'),
            );
          }

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderNumber = order['orderNumber'];
              final products = order['products'] as List<Map<String, dynamic>>;
              final totalPrice = order['totalPrice'] as double;
              final updatedAt = order['updatedAt'] as DateTime;

              return GestureDetector(
                onTap: () {
                  // Sipariş detaylarını göstermek için yeni bir ekran açılabilir
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sipariş Numarası: $orderNumber',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₺${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tarih: ${updatedAt.toLocal()}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1),
                        const Text(
                          'Ürünler:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...products.map((product) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.shopping_bag, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${product['name']} x${product['quantity']}',
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF616161)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
