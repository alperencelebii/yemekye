import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  _AddProductState createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final TextEditingController _pieceController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? selectedCategory;
  String? selectedProduct;
  List<String> categories = [];
  List<String> products = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    QuerySnapshot categorySnapshot = await _firestore.collection('category_products').get();
    setState(() {
      categories = categorySnapshot.docs.map((doc) => doc['category'] as String).toSet().toList();
    });
  }

  Future<void> _loadProducts(String category) async {
    QuerySnapshot productSnapshot = await _firestore
        .collection('category_products')
        .where('category', isEqualTo: category)
        .get();

    setState(() {
      products = productSnapshot.docs.map((doc) => doc['name'] as String).toList();
      selectedProduct = null;
    });
  }

  void _addProduct() async {
    if (selectedCategory == null || selectedProduct == null) {
      _showErrorMessage("Lütfen kategori ve ürün seçin");
      return;
    }

    String piece = _pieceController.text.trim();
    String price = _priceController.text.trim();


    if (piece.isEmpty || price.isEmpty) {
      _showErrorMessage("Lütfen adet ve fiyat girin");
      return;
    }

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showErrorMessage("Kullanıcı oturum açmamış");
        return;
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('sellers').doc(currentUser.uid).get();

      if (!userDoc.exists || userDoc['shopid'] == null) {
        _showErrorMessage("Kullanıcı bir mağazaya bağlı değil");
        return;
      }

      String shopId = userDoc['shopid'];

      DocumentReference productRef = await _firestore.collection('products').add({
        'name': selectedProduct,
        'category': selectedCategory,
        'piece': int.tryParse(piece) ?? 0,
        'price': double.tryParse(price) ?? 0.0,
      });

      await _firestore.collection('shopproduct').add({
        'shopid': shopId,
        'productid': productRef.id,
      });

      await _firestore.collection('shops').doc(shopId).update({
        'productid': FieldValue.arrayUnion([productRef.id]),
      });

      _showSuccessMessage("Ürün başarıyla eklendi!");
      Navigator.pop(context);
    } catch (e) {
      _showErrorMessage("Ürün eklenirken hata oluştu: $e");
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    hint: const Text("Kategori Seçin"),
                    items: categories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                        selectedProduct = null;
                        products = [];
                      });
                      _loadProducts(value!);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedProduct,
                    hint: const Text("Ürün Seçin"),
                    items: products
                        .map((product) => DropdownMenuItem(
                              value: product,
                              child: Text(product),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedProduct = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField("Adet", _pieceController, keyboardType: TextInputType.number),
                  _buildTextField("Fiyat", _priceController, keyboardType: TextInputType.number),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9A602),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
