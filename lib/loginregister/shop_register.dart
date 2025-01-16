import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateShopPage extends StatefulWidget {
  @override
  _CreateShopPageState createState() => _CreateShopPageState();
}

class _CreateShopPageState extends State<CreateShopPage> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _createShop() async {
    String shopName = _shopNameController.text.trim();
    String shopAddress = _shopAddressController.text.trim();

    if (shopName.isEmpty || shopAddress.isEmpty) {
      _showErrorMessage("Lütfen tüm alanları doldurun");
      return;
    }

    try {
      // Mağazayı Firestore'a kaydet
      DocumentReference shopRef = await _firestore.collection('shops').add({
        'name': shopName,
        'address': shopAddress,
        'productid': [], // Başlangıçta ürünler boş olacak
      });

      // Mağaza oluşturulduktan sonra, kullanıcının bağlı olduğu mağazayı güncelle
      // Kullanıcıyı mevcut mağaza ile ilişkilendir
      String shopId = shopRef.id; // Yeni mağazanın ID'si

      // Mağazayı oluşturan kullanıcıyı güncelleme
      // Örneğin, 'users' koleksiyonunda ilgili kullanıcıyı shopId ile güncelleme
      // Bu işlem kullanıcıyı mağaza ile ilişkilendirir.
      var user = await _firestore
          .collection('users')
          .doc('user-id')
          .get(); // 'user-id' ile kullanıcıyı hedefle

      if (user.exists) {
        await _firestore.collection('users').doc('user-id').update({
          'shopid': shopId,
        });
        // Mağaza oluşturma işlemi başarılı
        _showSuccessMessage("Mağaza oluşturuldu!");
        Navigator.pop(context); // Kullanıcıyı önceki sayfaya yönlendir
      }
    } catch (e) {
      _showErrorMessage("Mağaza oluşturulurken hata oluştu: $e");
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Mağaza Oluştur"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _shopNameController,
              decoration: InputDecoration(
                labelText: "Mağaza Adı",
              ),
            ),
            TextField(
              controller: _shopAddressController,
              decoration: InputDecoration(
                labelText: "Mağaza Adresi",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createShop,
              child: Text("Mağaza Oluştur"),
            ),
          ],
        ),
      ),
    );
  }
}
