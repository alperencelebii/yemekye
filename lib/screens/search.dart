import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Ürün ara (örn: Simit)',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              searchText = value.trim();
            });
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('shopproduct').snapshots(),
        builder: (context, shopSnapshot) {
          if (shopSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!shopSnapshot.hasData || shopSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Ürün bulunamadı.'));
          }

          final shopProducts = shopSnapshot.data!.docs;

          // products koleksiyonunu getir
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('products').get(),
            builder: (context, productSnapshot) {
              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!productSnapshot.hasData ||
                  productSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Ürün bulunamadı.'));
              }

              final products = productSnapshot.data!.docs;

              // shopproduct ve products koleksiyonlarını birleştir
              final combinedProducts = shopProducts.where((shopDoc) {
                final product = products.firstWhere(
                  (prod) => prod.id == shopDoc['productid'],
                  orElse: () => null as QueryDocumentSnapshot<
                      Object?>, // Eğer eşleşme yoksa null döner
                );

                if (product == null) {
                  return false; // Eğer eşleşen bir ürün yoksa bu shopProduct'ı atla
                }

                return product['name']
                    .toString()
                    .toLowerCase()
                    .contains(searchText.toLowerCase());
              }).toList();

              if (combinedProducts.isEmpty) {
                return const Center(child: Text('Ürün bulunamadı.'));
              }

              Map<String, List<QueryDocumentSnapshot>> shopGroups = {};

              for (var shopProduct in combinedProducts) {
                final shopId = shopProduct['shopid'];
                if (!shopGroups.containsKey(shopId)) {
                  shopGroups[shopId] = [];
                }
                shopGroups[shopId]!.add(shopProduct);
              }

              return ListView.separated(
                separatorBuilder: (context, index) =>
                    Divider(color: Colors.grey.shade400),
                itemCount: shopGroups.keys.length,
                itemBuilder: (context, index) {
                  final shopId = shopGroups.keys.elementAt(index);
                  final shopProducts = shopGroups[shopId]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Mağaza ID: $shopId",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      ...shopProducts.map((shopProduct) {
                        final product = products.firstWhere(
                            (prod) => prod.id == shopProduct['productid']);
                        return ProductCard(
                          shopId: shopId,
                          productId: shopProduct['productid'],
                          productName: product['name'],
                          productPrice: product['price'].toDouble(),
                          piece: shopProduct['piece'],
                        );
                      }).toList(),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String shopId;
  final String productId;
  final String productName;
  final double productPrice;
  final int piece;

  const ProductCard({
    Key? key,
    required this.shopId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.piece,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                'assets/images/product_image.png', // Ürün görseli yolu
                width: 54,
                height: 54,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₺${productPrice.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$piece Adet',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                // Sepete ekleme işlemi burada yapılır
              },
            ),
          ],
        ),
      ),
    );
  }
}
