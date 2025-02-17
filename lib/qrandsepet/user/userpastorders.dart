import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPastOrdersScreen extends StatefulWidget {
  @override
  _UserPastOrdersScreenState createState() => _UserPastOrdersScreenState();
}

class _UserPastOrdersScreenState extends State<UserPastOrdersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Kullanıcının geçmiş siparişlerini Firestore'dan getir
  Future<List<Map<String, dynamic>>> _fetchUserOrders() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final user = _auth.currentUser;
      if (user == null) return [];

      // Kullanıcının yaptığı siparişleri getir (onaylanmış siparişler)
      final querySnapshot = await firestore
          .collection('carts')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Onaylandı')
          .get();

      // Siparişlere bağlı mağaza bilgilerini almak için işlemi genişletelim
      List<Map<String, dynamic>> orders = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final shopId = data['shopId'] ?? '';

        // Mağaza bilgilerini getir
        final shopDoc = await firestore.collection('shops').doc(shopId).get();
        final shopName = shopDoc.exists ? shopDoc['name'] : 'Bilinmeyen Mağaza';

        final products =
            List<Map<String, dynamic>>.from(data['products'] ?? []);

        // Toplam fiyat hesapla
        final totalPrice = products.fold(0.0, (sum, product) {
          final price = product['price'] ?? 0.0;
          final quantity = product['quantity'] ?? 0;
          return sum + (price * quantity);
        });

        orders.add({
          'cartId': doc.id,
          'orderNumber': data['orderNumber'] ?? 'N/A',
          'products': products,
          'totalPrice': totalPrice,
          'updatedAt': (data['updatedAt'] as Timestamp).toDate(),
          'shopName': shopName,
        });
      }

      return orders;
    } catch (e) {
      throw Exception('Siparişleri yüklerken hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Siparişlerim'),
        backgroundColor: const Color(0xFF007BFF),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Bir hata oluştu: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Henüz geçmiş siparişiniz bulunmuyor.'),
            );
          }

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderNumber = order['orderNumber'];
              final shopName = order['shopName'];
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
                        'Sipariş Numarası: $orderNumber',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Mağaza: $shopName',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Toplam: ₺${totalPrice.toStringAsFixed(2)}'),
                      Text('Tarih: ${updatedAt.toLocal()}'),
                      const Divider(height: 20, thickness: 1),
                      const Text('Ürünler:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
