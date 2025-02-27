import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductPage extends StatefulWidget {
  final String productId;

  const EditProductPage({super.key, required this.productId});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _pieceController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? selectedCategory;
  String? selectedProduct;

  List<String> categories = [];
  List<String> products = [];

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
    _loadCategories();
  }

  Future<void> _loadProductDetails() async {
    DocumentSnapshot productDoc =
        await _firestore.collection('products').doc(widget.productId).get();

    if (productDoc.exists) {
      setState(() {
        selectedProduct = productDoc['name'];
        selectedCategory = productDoc['category'];
        _pieceController.text = productDoc['piece'].toString();
        _priceController.text = productDoc['price'].toString();
      });

      _loadProducts(selectedCategory!);
    }
  }

  Future<void> _loadCategories() async {
    QuerySnapshot categorySnapshot =
        await _firestore.collection('category_products').get();
    setState(() {
      categories = categorySnapshot.docs
          .map((doc) => doc['category'] as String)
          .toSet()
          .toList();
    });
  }

  Future<void> _loadProducts(String category) async {
    QuerySnapshot productSnapshot = await _firestore
        .collection('category_products')
        .where('category', isEqualTo: category)
        .get();

    setState(() {
      products =
          productSnapshot.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  Future<void> _updateProduct() async {
    try {
      await _firestore.collection('products').doc(widget.productId).update({
        'name': selectedProduct,
        'category': selectedCategory,
        'piece': int.tryParse(_pieceController.text) ?? 0,
        'price': double.tryParse(_priceController.text) ?? 0.0,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Ürün başarıyla güncellendi!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Güncelleme hatası: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ürün Düzenle"),
        backgroundColor: const Color(0xFFE69F44),
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
                    "Ürün Bilgilerini Düzenle",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE69F44),
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
                      onPressed: _updateProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE69F44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Ürünü Güncelle",
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
