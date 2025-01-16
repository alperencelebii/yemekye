import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  _AddProductState createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pieceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountPriceController =
      TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _addProduct() async {
    String name = _nameController.text.trim();
    String piece = _pieceController.text.trim();
    String category = _categoryController.text.trim();
    String price = _priceController.text.trim();
    String discountPrice = _discountPriceController.text.trim();

    if (name.isEmpty ||
        piece.isEmpty ||
        category.isEmpty ||
        price.isEmpty ||
        discountPrice.isEmpty) {
      _showErrorMessage("Lütfen tüm alanları doldurun");
      return;
    }

    try {
      // Kullanıcının oturum açtığı bilgiyi alın
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        _showErrorMessage("Kullanıcı oturum açmamış");
        return;
      }

      // Kullanıcının mağaza ID'sini al
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists || userDoc['shopid'] == null) {
        _showErrorMessage("Kullanıcı bir mağazaya bağlı değil");
        return;
      }

      String shopId = userDoc['shopid'];

      // Yeni ürünü Firestore'da products koleksiyonuna ekle
      DocumentReference productRef =
          await _firestore.collection('products').add({
        'name': name,
        'piece': int.tryParse(piece) ?? 0,
        'category': category,
        'price': double.tryParse(price) ?? 0.0,
        'discountprice': double.tryParse(discountPrice) ?? 0.0,
      });

      String productId = productRef.id;

      // shopproduct koleksiyonuna ilişkiyi ekle
      await _firestore.collection('shopproduct').add({
        'shopid': shopId,
        'productid': productId,
      });

      _showSuccessMessage("Ürün başarıyla eklendi!");
      Navigator.pop(context); // Kullanıcıyı önceki ekrana yönlendir
    } catch (e) {
      _showErrorMessage("Ürün eklenirken hata oluştu: $e");
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ürün Ekle"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Ürün Adı",
              ),
            ),
            TextField(
              controller: _pieceController,
              decoration: const InputDecoration(
                labelText: "Adet",
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: "Kategori",
              ),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: "Fiyat",
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _discountPriceController,
              decoration: const InputDecoration(
                labelText: "İndirimli Fiyat",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addProduct,
              child: const Text("Ürünü Ekle"),
            ),
          ],
        ),
      ),
    );
  }
}
