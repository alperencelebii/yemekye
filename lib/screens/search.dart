import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: const Text(
          'Ürün Arama',
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
                hintText: 'Ürün Ara...',
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
              child: searchQuery.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Arama yapmak için bir kelime girin.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    )
                  : FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                      future: _searchResults(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
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

                        final groupedResults = snapshot.data!;

                        return ListView.builder(
                          itemCount: groupedResults.length,
                          itemBuilder: (context, index) {
                            final shopName = groupedResults.keys.toList()[index];
                            final products = groupedResults[shopName]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Mağaza Başlığı
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0),
                                  child: Text(
                                    shopName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orangeAccent,
                                    ),
                                  ),
                                ),
                                const Divider(
                                  thickness: 1.5,
                                  color: Colors.orangeAccent,
                                ),
                                // Ürün Listesi
                                ...products.map(
                                  (product) => Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 4,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.all(10),
                                      leading: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: Image.network(
                                          product['image'] ?? '',
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error,
                                                  stackTrace) =>
                                              const Icon(
                                            Icons.image_not_supported,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        product['productName'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        'Fiyat: ${product['price']} TL',
                                        style: const TextStyle(
                                            color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
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

  Future<Map<String, List<Map<String, dynamic>>>> _searchResults() async {
    final Map<String, List<Map<String, dynamic>>> groupedResults = {};

    // Tüm ürünleri al
    final productQuery = await FirebaseFirestore.instance.collection('products').get();

    for (var product in productQuery.docs) {
      final productData = product.data();
      final productName = productData['name']?.toLowerCase() ?? '';

      // Arama sorgusuyla eşleşme kontrolü
      if (searchQuery.isNotEmpty && !productName.contains(searchQuery)) {
        continue;
      }

      // Ürüne bağlı mağazaları bulmak için `shopproduct` sorgusu
      final shopProductQuery = await FirebaseFirestore.instance
          .collection('shopproduct')
          .where('productid', isEqualTo: product.id)
          .get();

      for (var shopProduct in shopProductQuery.docs) {
        final shopId = shopProduct.data()['shopid'];
        final shopDoc = await FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .get();

        if (shopDoc.exists) {
          final shopData = shopDoc.data();
          final shopName = shopData?['name'] ?? 'Mağaza Bilinmiyor';

          groupedResults.putIfAbsent(shopName, () => []);
          groupedResults[shopName]!.add({
            'productName': productData['name'],
            'price': productData['price'],
            'image': shopDoc['image'],
          });
        }
      }
    }

    return groupedResults;
  }
}
