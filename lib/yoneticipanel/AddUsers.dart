import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class AddUserPage extends StatelessWidget {
  final String shopId;

  AddUserPage({required this.shopId});

  void addUserToShop(String userId) async {
    final shopRef = FirebaseFirestore.instance.collection('shops').doc(shopId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final shopSnapshot = await transaction.get(shopRef);
      final shopData = shopSnapshot.data() as Map<String, dynamic>?;

      if (shopData != null) {
        List<dynamic> users = shopData['users'] ?? [];
        if (!users.contains(userId)) {
          users.add(userId);
          transaction.update(shopRef, {'users': users});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kullanıcı Ekle"),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final users = userSnapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return Center(child: Text("Kullanıcı bulunamadı."));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;

              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text("${userData['name']}"),
                  subtitle: Text(userData['email'] ?? "E-posta yok"),
                  trailing: IconButton(
                    icon: Icon(Icons.add, color: Colors.green),
                    onPressed: () {
                      addUserToShop(userId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Kullanıcı mağazaya eklendi.")),
                      );
                    },
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
