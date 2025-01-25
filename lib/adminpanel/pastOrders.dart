import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PastOrdersScreen extends StatelessWidget {
  final String shopId;

  const PastOrdersScreen({Key? key, required this.shopId}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchPastOrders() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Onaylanmış siparişleri shopId'ye göre filtrele
      final querySnapshot = await firestore
          .collection('carts')
          .where('shopId', isEqualTo: shopId)
          .where('status', isEqualTo: 'Onaylandı')
          .where('updatedAt')
          .get();

      return querySnapshot.docs.map((doc) {
        final products = List<Map<String, dynamic>>.from(doc.data()['products'] ?? []);

        // TotalPrice hesaplama
        final totalPrice = products.fold(0.0, (sum, product) {
          final price = product['price'] ?? 0.0;
          final quantity = product['quantity'] ?? 0;
          return sum + (price * quantity);
        });

        return {
          'cartId': doc.id,
          'orderNumber': doc.data()['orderNumber'] ?? 'N/A', // orderNumber alanını ekle
          'products': products,
          'totalPrice': totalPrice,
          'updatedAt': (doc.data()['updatedAt'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Siparişleri yüklerken hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Siparişler'),
        backgroundColor: const Color(0xFFF9A602),
        foregroundColor: Colors.white,
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
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderNumber = order['orderNumber']; // orderNumber alanını al
              final products = order['products'] as List<Map<String, dynamic>>;
              final totalPrice = order['totalPrice'] as double;
              final updatedAt = order['updatedAt'] as DateTime;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sipariş Numarası: $orderNumber', // orderNumber'ı göster
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Toplam: ₺${totalPrice.toStringAsFixed(2)}'),
                      Text('Tarih: ${updatedAt.toLocal()}'),
                      const Divider(height: 20, thickness: 1),
                      const Text('Ürünler:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      ...products.map((product) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '- ${product['name']} x${product['quantity']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ],
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
