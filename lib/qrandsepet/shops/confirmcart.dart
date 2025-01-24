import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ConfirmCartScreen extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final String cartId; // `cartId` parametresi

  const ConfirmCartScreen({
    Key? key,
    required this.products,
    required this.cartId,
  }) : super(key: key);

  double calculateTotalPrice() {
    return products.fold(0, (total, product) {
      return total + (product['price'] * product['quantity']);
    });
  }

  Future<void> _reduceStock(BuildContext context) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Tüm ürünlerin stoklarını kontrol et ve düşür
      for (var product in products) {
        final productDoc = await firestore
            .collection('products')
            .doc(product['productId'])
            .get();

        if (productDoc.exists) {
          final currentStock = productDoc.data()?['piece'] ?? 0;
          final newStock = currentStock - product['quantity'];

          if (newStock < 0) {
            throw Exception(
                "${product['name']} için stok yetersiz. Mevcut stok: $currentStock");
          }

          await firestore
              .collection('products')
              .doc(product['productId'])
              .update({'piece': newStock});
        } else {
          throw Exception("${product['name']} bulunamadı.");
        }
      }

      // Sepeti "Onaylandı" olarak işaretle ve sipariş numarasını ekle
      await firestore.collection('carts').doc(cartId).update({
        'status': 'Onaylandı',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Satış tamamlandı!')),
      );

      Navigator.pop(context); // Kullanıcıyı önceki ekrana döndür
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Onay Sayfası'),
        backgroundColor: const Color(0xFFF9A602),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  elevation: 3,
                  child: ListTile(
                    title: Text(product['name'] ?? 'Ürün Adı Yok'),
                    subtitle: Text(
                      "Fiyat: ₺${product['price'].toStringAsFixed(2)}\nAdet: ${product['quantity']}",
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFFF9A602),
            ),
            child: Column(
              children: [
                Text(
                  "Toplam: ₺${calculateTotalPrice().toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _reduceStock(context),
                  child: const Text("Satışı Onayla"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
