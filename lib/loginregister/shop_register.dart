import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class CreateShopPage extends StatefulWidget {
  @override
  _CreateShopPageState createState() => _CreateShopPageState();
}

class _CreateShopPageState extends State<CreateShopPage> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? _selectedImage;
  bool _isUploading = false;

  // Kategoriler
  final List<String> _categories = [
    'Fast Food',
    'Kahvaltı',
    'Tatlı',
    'İçecek',
    'Pasta',
    'Deniz Ürünleri'
  ];
  final List<String> _selectedCategories = [];

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef =
          FirebaseStorage.instance.ref().child('shop_images/$fileName');
      UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _isUploading = false;
      });

      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showErrorMessage("Resim yüklenirken hata oluştu: $e");
      return null;
    }
  }

  void _createShop() async {
    String shopName = _shopNameController.text.trim();
    String shopAddress = _shopAddressController.text.trim();

    if (shopName.isEmpty ||
        shopAddress.isEmpty ||
        _selectedImage == null ||
        _selectedCategories.isEmpty) {
      _showErrorMessage("Lütfen tüm alanları doldurun ve kategori seçin.");
      return;
    }

    try {
      String? imageUrl = await _uploadImage();
      if (imageUrl == null) return;

      // Mağazayı Firestore'a kaydet
      await _firestore.collection('shops').add({
        'name': shopName,
        'address': shopAddress,
        'image': imageUrl,
        'categories': _selectedCategories, // Seçilen kategoriler
        'productid': [], // Başlangıçta ürünler boş olacak
      });

      _showSuccessMessage("Mağaza başarıyla oluşturuldu!");
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pop(context); // 1 saniye sonra bir önceki sayfaya dön
      });
    } catch (e) {
      _showErrorMessage("Mağaza oluşturulurken hata oluştu: $e");
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mağaza Oluştur"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Yeni Mağaza Bilgilerini Girin",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _shopNameController,
                decoration: InputDecoration(
                  labelText: "Mağaza Adı",
                  labelStyle: TextStyle(color: Colors.orange[700]),
                  hintText: "Mağaza adını yazın...",
                  prefixIcon: Icon(Icons.store, color: Colors.orange),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 2.0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.orange[300]!, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _shopAddressController,
                decoration: InputDecoration(
                  labelText: "Mağaza Adresi",
                  labelStyle: TextStyle(color: Colors.orange[700]),
                  hintText: "Mağaza adresini yazın...",
                  prefixIcon: Icon(Icons.location_on, color: Colors.orange),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 2.0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.orange[300]!, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: _selectedImage == null
                      ? Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.add_a_photo, color: Colors.orange),
                        )
                      : Image.file(
                          _selectedImage!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              SizedBox(height: 30),
              Text(
                "Kategoriler:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              Column(
                children: _categories.map((category) {
                  return CheckboxListTile(
                    title: Text(category),
                    value: _selectedCategories.contains(category),
                    onChanged: (bool? isChecked) {
                      setState(() {
                        if (isChecked == true) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _createShop,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isUploading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Mağaza Oluştur",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
