import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:yemekye/components/models/yatay_restaurant_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = '';
  LatLng userLocation =
      const LatLng(41.015137, 28.979530); // Örnek kullanıcı konumu

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: const Text(
          'Arama Sayfası',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Arama Kutusu
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Mağaza veya Ürün Ara...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // Arama Sonuçları
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _searchResults(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sonuç bulunamadı.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final results = snapshot.data!;

                  return ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = results[index];
                      final isShop = data['type'] == 'shop';

                      if (isShop) {
                        // Mağaza bilgisi
                        return YatayRestaurantCard(
                          shopName: data['name'] ?? 'Ad bilgisi yok',
                          shopAddress: data['address'] ?? 'Adres bilgisi yok',
                          shopImagePath: data['image'] ?? '',
                          userLocation: userLocation,
                          shopLatitude: data['latitude'] ?? 0.0,
                          shopLongitude: data['longitude'] ?? 0.0,
                          isOpen: data['isOpen'] ?? false,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${data['name']} seçildi.'),
                              ),
                            );
                          },
                        );
                      } else {
                        // Ürün bilgisi (Mağaza ile ilişkilendirilmiş)
                        return YatayRestaurantCard(
                          shopName: data['shopName'] ?? 'Mağaza bilgisi yok',
                          shopAddress:
                              'Ürün: ${data['productName']} - Fiyat: ${data['price']} TL',
                          shopImagePath: data['shopImage'] ?? '',
                          userLocation: userLocation,
                          shopLatitude: data['latitude'] ?? 0.0,
                          shopLongitude: data['longitude'] ?? 0.0,
                          isOpen: data['isOpen'] ?? false,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${data['productName']} ürünü seçildi.'),
                              ),
                            );
                          },
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _searchResults() async {
    if (searchQuery.isEmpty) return []; // Eğer arama boşsa, sonuç döndürme

    final List<Map<String, dynamic>> results = [];
    final Set<String> addedShops = {}; // Mağazaları benzersiz yapmak için

    // 1. Mağaza Arama
    final shopQuery =
        await FirebaseFirestore.instance.collection('shops').get();
    for (var shop in shopQuery.docs) {
      final shopData = shop.data();
      if ((shopData['name'] as String?)?.toLowerCase().contains(searchQuery) ??
          false) {
        results.add({
          'type': 'shop',
          ...shopData,
        });
      }
    }

    // 2. Ürün Arama
    final productQuery =
        await FirebaseFirestore.instance.collection('products').get();
    for (var product in productQuery.docs) {
      final productData = product.data();
      if ((productData['name'] as String?)
              ?.toLowerCase()
              .contains(searchQuery) ??
          false) {
        // Ürüne bağlı mağazaları bulmak için `shopproduct` sorgusu
        final shopProductQuery = await FirebaseFirestore.instance
            .collection('shopproduct')
            .where('productid', isEqualTo: product.id)
            .get();

        for (var shopProduct in shopProductQuery.docs) {
          final shopId = shopProduct.data()['shopid'];

          // Eğer bu mağaza daha önce eklendiyse, işlemi atla
          if (addedShops.contains(shopId)) continue;

          final shopDoc = await FirebaseFirestore.instance
              .collection('shops')
              .doc(shopId)
              .get();

          if (shopDoc.exists) {
            final shopData = shopDoc.data();
            results.add({
              'type': 'product',
              'productName': productData['name'], // Ürün adı
              'price': shopProduct.data()['price'], // Ürün fiyatı
              'shopName': shopData?['name'], // Mağaza adı
              'shopImage': shopData?['image'], // Mağaza görseli
              'latitude': shopData?['latitude'], // Mağaza konumu
              'longitude': shopData?['longitude'],
              'isOpen': shopData?['isOpen'], // Mağaza açık mı?
            });

            // Bu mağazayı eklenenler listesine ekle
            addedShops.add(shopId);
          }
        }
      }
    }

    return results;
  }
}
