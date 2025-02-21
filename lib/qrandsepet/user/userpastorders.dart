import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserPastOrdersScreen extends StatefulWidget {
  @override
  _UserPastOrdersScreenState createState() => _UserPastOrdersScreenState();
}

class _UserPastOrdersScreenState extends State<UserPastOrdersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // Slider değerleri
  double hygieneRating = 1.0; 
  double freshnessRating = 1.0; 
  double serviceQualityRating = 1.0;

  // Ortalama puan hesaplamak için bir fonksiyon
  double get averageRating {
    return (hygieneRating + freshnessRating + serviceQualityRating) / 3;
  }


  Future<List<Map<String, dynamic>>> _fetchUserOrders() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await firestore
          .collection('carts')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Onaylandı')
          .get();

      List<Map<String, dynamic>> orders = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final shopId = data['shopId'] ?? '';

        final shopDoc = await firestore.collection('shops').doc(shopId).get();
        final shopName = shopDoc.exists ? shopDoc['name'] : 'Bilinmeyen Mağaza';
        final shopAddress =
            shopDoc.exists ? shopDoc['address'] : 'Bilinmeyen Mağaza';

        final products =
            List<Map<String, dynamic>>.from(data['products'] ?? []);

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
          'shopName': shopName,

          'shopAddress': shopAddress,

          'shopId': shopId, 

        });
      }

      return orders;
    } catch (e) {
      throw Exception('Siparişleri yüklerken hata oluştu: $e');
    }
  }

  // Puanları Firebase'e kaydet
  Future<void> _submitRatings(String shopId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Ortalama puanı hesaplayalım
      double average = averageRating;

      // Firebase'de shop'a ortalama puanı kaydedelim
await firestore.collection('shops').doc(shopId).update({
  'averageRating': average.toDouble(), // double olarak kaydediyoruz
  'hygieneRating': hygieneRating.toDouble(),
  'freshnessRating': freshnessRating.toDouble(),
  'serviceQualityRating': serviceQualityRating.toDouble(),
});


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Puanlar başarıyla kaydedildi!')),
      );
    } catch (e) {
      print('Puan kaydetme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Puan kaydedilirken hata oluştu!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Siparişlerim',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
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
              final shopId = order['shopId'];
              final shopName = order['shopName'];

              final shopAddress = order['shopAddress'];
              final products = order['products'] as List<Map<String, dynamic>>;
              final totalPrice = order['totalPrice'] as double;


              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(


                        'Sipariş No: ${order['orderNumber']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),

                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.store,
                              size: 18, color: Colors.blueGrey),
                          const SizedBox(width: 5),
                          Text(shopName, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 18, color: Colors.redAccent),
                          const SizedBox(width: 5),
                          Text(shopAddress,
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.date_range,
                              size: 18, color: Colors.green),
                          const SizedBox(width: 5),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toplam: ₺${totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const Divider(height: 20, thickness: 1),
                      const Text('Ürünler:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...products.map((product) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_bag,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 5),
                              Text(
                                '${product['name']} x${product['quantity']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                      Text(shopName, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      // Hijyen puanı
                      Text('Hijyen:'),
                      Slider(
                        value: hygieneRating,
                        min: 1.0,
                        max: 5.0,
                        divisions: 4,
                        label: hygieneRating.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            hygieneRating = value;
                          });
                        },
                      ),
                      // Tazelik puanı
                      Text('Tazelik:'),
                      Slider(
                        value: freshnessRating,
                        min: 1.0,
                        max: 5.0,
                        divisions: 4,
                        label: freshnessRating.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            freshnessRating = value;
                          });
                        },
                      ),
                      // Hizmet kalitesi puanı
                      Text('Hizmet Kalitesi:'),
                      Slider(
                        value: serviceQualityRating,
                        min: 1.0,
                        max: 5.0,
                        divisions: 4,
                        label: serviceQualityRating.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            serviceQualityRating = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      // Ortalama puanı göster
                      Text(
                        'Ortalama Puan: ${averageRating.toStringAsFixed(2)}',  // Ondalık sayı gösteriyoruz
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _submitRatings(shopId);
                        },
                        child: const Text('Puanları Kaydet'),
                      ),
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
