import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyProducts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ürünlerim")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("products").snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc["name"]),
                subtitle: Text("Kategori: ${doc["category"]}"),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    // Ürün düzenleme mantığı buraya eklenebilir.
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
