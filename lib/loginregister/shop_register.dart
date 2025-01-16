import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

class CreateShopPage extends StatefulWidget {
  @override
  _CreateShopPageState createState() => _CreateShopPageState();
}

class _CreateShopPageState extends State<CreateShopPage> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  File? _selectedImage;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _createShop() async {
    String shopName = _shopNameController.text.trim();
    String shopAddress = _shopAddressController.text.trim();

    if (shopName.isEmpty || shopAddress.isEmpty || _selectedImage == null) {
      _showErrorMessage("Lütfen tüm alanları doldurun ve bir resim seçin");
      return;
    }

    try {
      // Resmi Firebase Storage'a yükle
      String imageName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = _storage.ref().child("shop_images/$imageName");
      UploadTask uploadTask = ref.putFile(_selectedImage!);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Mağazayı Firestore'a kaydet
      DocumentReference shopRef = await _firestore.collection('shops').add({
        'name': shopName,
        'address': shopAddress,
        'image': imageUrl, // Resim URL'si
        'productid': [], // Başlangıçta ürünler boş olacak
      });

      String shopId = shopRef.id; // Yeni mağazanın ID'si

      // Kullanıcıyı bu mağaza ile ilişkilendir (örneğin, kullanıcı oturum açmışsa)
      var user = await _firestore.collection('users').doc('user-id').get();
      if (user.exists) {
        await _firestore.collection('users').doc('user-id').update({
          'shopid': shopId,
        });

        _showSuccessMessage("Mağaza başarıyla oluşturuldu!");
        Navigator.pop(context); // Önceki sayfaya dön
      }
    } catch (e) {
      _showErrorMessage("Mağaza oluşturulurken hata oluştu: $e");
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mağaza Oluştur"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : const Center(child: Text("Mağaza Resmi Seç")),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createShop,
                child: Text("Mağaza Oluştur"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
