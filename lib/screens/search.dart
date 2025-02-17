import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'restaurant_details.dart';

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
        backgroundColor: Colors.black,
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
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Ürün veya Mağaza Ara...',
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

                        final groupedResults = snapshot.data!;

                        return ListView.builder(
                          itemCount: groupedResults.length,
                          itemBuilder: (context, index) {
                            final shopName = groupedResults.keys.toList()[index];
                            final products = groupedResults[shopName]!;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final shopDoc = await FirebaseFirestore.instance
                                          .collection('shops')
                                          .where('name', isEqualTo: shopName)
                                          .get();

                                      if (shopDoc.docs.isNotEmpty) {
                                        final shopData = shopDoc.docs.first.data();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RestaurantDetails(
                                              shopName: shopData['name'],
                                              shopAddress: shopData['address'],
                                              isOpen: shopData['isOpen'] ?? false,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text(
                                        shopName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ...products.map(
                                    (product) => Container(
                                      margin: const EdgeInsets.symmetric(vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 241, 241, 241),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(10),
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            product['image'] ?? '',
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(
                                              Icons.image_not_supported,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          product['productName'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        trailing: Text(
                                          '${product['price']} ₺',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                                                            onTap: () async {
                                      final shopDoc = await FirebaseFirestore.instance
                                          .collection('shops')
                                          .where('name', isEqualTo: shopName)
                                          .get();

                                      if (shopDoc.docs.isNotEmpty) {
                                        final shopData = shopDoc.docs.first.data();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RestaurantDetails(
                                              shopName: shopData['name'],
                                              shopAddress: shopData['address'],
                                              isOpen: shopData['isOpen'] ?? false,
                                            ),
                                          ),);}}
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

    final shopQuery = await FirebaseFirestore.instance.collection('shops').get();
    for (var shop in shopQuery.docs) {
      final shopData = shop.data();
      final shopName = shopData['name']?.toLowerCase() ?? '';
      if (searchQuery.isNotEmpty && shopName.contains(searchQuery)) {
        groupedResults[shopData['name']] = [];
      }
    }

    final productQuery = await FirebaseFirestore.instance.collection('products').get();
    for (var product in productQuery.docs) {
      final productData = product.data();
      final productName = productData['name']?.toLowerCase() ?? '';
      if (searchQuery.isNotEmpty && productName.contains(searchQuery)) {
        final shopProductQuery = await FirebaseFirestore.instance
            .collection('shopproduct')
            .where('productid', isEqualTo: product.id)
            .get();
        for (var shopProduct in shopProductQuery.docs) {
          final shopId = shopProduct.data()['shopid'];
          final shopDoc = await FirebaseFirestore.instance.collection('shops').doc(shopId).get();
          if (shopDoc.exists) {
            final shopData = shopDoc.data();
            groupedResults.putIfAbsent(shopData!['name'], () => []).add({
              'productName': productData['name'],
              'price': productData['price'],
              'image': productData['image'],
            });
          }
        }
      }
    }
    return groupedResults;
  }
}