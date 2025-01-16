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
        await _firestore.collection('users').doc(currentUser.uid).get();

    if (!userDoc.exists || userDoc['shopid'] == null) return null;

    return userDoc['shopid'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ürünlerisadsadm")),
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

              return ListView(
                children: shopProducts.map((shopProductDoc) {
                  String productId = shopProductDoc['productid'];

                  return FutureBuilder(
                    future:
                        _firestore.collection('products').doc(productId).get(),
                    builder: (context,
                        AsyncSnapshot<DocumentSnapshot> productSnapshot) {
                      if (!productSnapshot.hasData) {
                        return const ListTile(
                          title: Text("Yükleniyor..."),
                        );
                      }

                      DocumentSnapshot productDoc = productSnapshot.data!;
                      if (!productDoc.exists) {
                        return const SizedBox.shrink();
                      }

                      return ListTile(
                        title: Text(productDoc['name']),
                        subtitle: Text("Kategori: ${productDoc['category']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // Ürün düzenleme mantığı buraya eklenebilir
                          },
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
