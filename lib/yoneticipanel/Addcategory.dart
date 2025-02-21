import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryProductPage extends StatefulWidget {
  const CategoryProductPage({super.key});

  @override
  _CategoryProductPageState createState() => _CategoryProductPageState();
}

class _CategoryProductPageState extends State<CategoryProductPage> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  String? selectedCategory;
  List<String> categories = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

 Future<void> _loadCategories() async {
  QuerySnapshot categorySnapshot = await _firestore.collection('categories').get();

  for (var doc in categorySnapshot.docs) {
    print(doc.data()); // Firestore’dan gelen tüm veriyi konsola yazdır
  }

  setState(() {
    categories = categorySnapshot.docs.map((doc) {
      print("Kategori Verisi: ${doc.data()}"); // Gelen veriyi göster
      return doc['name'] as String; // Eğer hata devam ederse doc.keys yazdır
    }).toList();
  });
}

  void _addCategory() async {
    String category = _categoryController.text.trim();
    if (category.isEmpty) return;
    await _firestore.collection('categories').add({'name': category});
    _categoryController.clear();
    _loadCategories();
  }

  void _addProduct() async {
    if (selectedCategory == null) {
      _showMessage("Lütfen bir kategori seçin");
      return;
    }

    String product = _productController.text.trim();
    if (product.isEmpty) return;
    
    await _firestore.collection('category_products').add({
      'name': product,
      'category': selectedCategory,
    });
    _productController.clear();
    _showMessage("Ürün başarıyla eklendi!");
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kategori ve Ürün Ekle"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: "Yeni Kategori",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addCategory,
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              hint: const Text("Kategori Seçin"),
              items: categories.map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _productController,
              decoration: InputDecoration(
                labelText: "Yeni Ürün",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addProduct,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
