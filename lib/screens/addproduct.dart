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
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        _showErrorMessage("Kullanıcı oturum açmamış");
        return;
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists || userDoc['shopid'] == null) {
        _showErrorMessage("Kullanıcı bir mağazaya bağlı değil");
        return;
      }

      String shopId = userDoc['shopid'];

      DocumentReference productRef =
          await _firestore.collection('products').add({
        'name': name,
        'piece': int.tryParse(piece) ?? 0,
        'category': category,
        'price': double.tryParse(price) ?? 0.0,
        'discountprice': double.tryParse(discountPrice) ?? 0.0,
      });

      String productId = productRef.id;

      await _firestore.collection('shopproduct').add({
        'shopid': shopId,
        'productid': productId,
      });

      await _firestore.collection('shops').doc(shopId).update({
        'productid': FieldValue.arrayUnion([productId]),
      });

      _showSuccessMessage("Ürün başarıyla eklendi!");
      Navigator.pop(context);
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
        backgroundColor: const Color(0xFFF9A602),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Yeni Ürün Bilgileri",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF9A602),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Ürün Adı", _nameController),
                  _buildTextField("Adet", _pieceController,
                      keyboardType: TextInputType.number),
                  _buildTextField("Kategori", _categoryController),
                  _buildTextField("Fiyat", _priceController,
                      keyboardType: TextInputType.number),
                  _buildTextField("İndirimli Fiyat", _discountPriceController,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9A602),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Ürünü Ekle",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFF9A602)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFF9A602), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
