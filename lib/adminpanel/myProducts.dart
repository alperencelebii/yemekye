import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ürünlerim"),
        backgroundColor: Colors.orange,
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

          // Belirli bir mağazanın ürünlerini çekiyoruz
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
                return const Center(
                    child: Text("Mağazanıza ait ürün bulunamadı."));
              }

              return ListView.builder(
                itemCount: shopProducts.length,
                padding: const EdgeInsets.all(8.0),
                itemBuilder: (context, index) {
                  String productId = shopProducts[index]['productid'];

                  return FutureBuilder(
                    future:
                        _firestore.collection('products').doc(productId).get(),
                    builder: (context,
                        AsyncSnapshot<DocumentSnapshot> productSnapshot) {
                      if (!productSnapshot.hasData) {
                        return const Center(
                            child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ));
                      }

                      DocumentSnapshot productDoc = productSnapshot.data!;
                      if (!productDoc.exists) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 10.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 3,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Ürün Resmi Placeholder
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                color: Colors.grey[200],
                              ),
                              child: const Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 16.0),

                            // Ürün Detayları
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productDoc['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    "Kategori: ${productDoc['category']}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Düzenle Butonu
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              onPressed: () {
                                // Ürün düzenleme mantığı buraya eklenebilir
                              },
                            ),
                          ],
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
