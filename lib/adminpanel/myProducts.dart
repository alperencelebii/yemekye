import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yemekye/adminpanel/campainpage.dart';
import 'package:yemekye/adminpanel/editproduct.dart';

class MyProducts extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> _getUserShopId() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    DocumentSnapshot userDoc =
        await _firestore.collection('sellers').doc(currentUser.uid).get();

    if (!userDoc.exists || userDoc['shopid'] == null) return null;

    return userDoc['shopid'];
  }

  // ✅ Ürünü Öne Çıkarma Fonksiyonu
  Future<void> promoteProduct(BuildContext context, String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('sellers').doc(user.uid).get();
      final shopId = userDoc.data()?['shopid'];

      if (shopId == null) return;

      final productDoc = await _firestore.collection('products').doc(productId).get();

      if (productDoc.exists) {
        await _firestore.collection('FeaturedProducts').doc(productId).set(productDoc.data()!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ürün başarıyla öne çıkarıldı!")),
        );
      }
    } catch (e) {
      print("Ürün öne çıkarılırken hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ürünlerim",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 170, 86),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_offer),
            tooltip: "Kampanyalar",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CampaignPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _getUserShopId(),
        builder: (context, AsyncSnapshot<String?> shopIdSnapshot) {
          if (shopIdSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!shopIdSnapshot.hasData || shopIdSnapshot.data == null) {
            return const Center(child: Text("Mağazanız bulunamadı."));
          }

          String shopId = shopIdSnapshot.data!;

          return StreamBuilder(
            stream: _firestore
                .collection('shopproduct')
                .where('shopid', isEqualTo: shopId)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              List<DocumentSnapshot> shopProducts = snapshot.data!.docs;

              if (shopProducts.isEmpty) {
                return const Center(child: Text("Mağazanıza ait ürün bulunamadı."));
              }

              return ListView.builder(
                itemCount: shopProducts.length,
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                itemBuilder: (context, index) {
                  var shopProductData = shopProducts[index].data() as Map<String, dynamic>;

                  if (!shopProductData.containsKey('productid')) {
                    return const SizedBox.shrink();
                  }

                  String productId = shopProductData['productid'];

                  return FutureBuilder(
                    future: _firestore.collection('products').doc(productId).get(),
                    builder: (context, AsyncSnapshot<DocumentSnapshot> productSnapshot) {
                      if (productSnapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      
                      if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      DocumentSnapshot productDoc = productSnapshot.data!;
                      Map<String, dynamic> productData =
                          productDoc.data() as Map<String, dynamic>;

                      int stock = productData['piece'] ?? 0;
                      int initialStock = productData['initialStock'] ?? stock;
                      double stockThreshold = initialStock * 0.10;

                      if (stock <= stockThreshold && stock > 0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${productData['name']} ürünü tükenmek üzere! (${stock} adet kaldı)",
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        });
                      }

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.0),
                                  color: Colors.grey[300],
                                ),
                                child: const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productData['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      "Kategori: ${productData['category']}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      "Stok: $stock adet",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: stock <= stockThreshold ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFFE69F44),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditProductPage(productId: productDoc.id),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.star,
                                      color: Colors.blueAccent,
                                    ),
                                    onPressed: () {
                                      promoteProduct(context, productId);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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