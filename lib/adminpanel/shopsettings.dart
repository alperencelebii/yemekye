import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ShopSettings extends StatefulWidget {
  @override
  _ShopSettingsState createState() => _ShopSettingsState();
}

class _ShopSettingsState extends State<ShopSettings> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  List<String> _categories = [];
  File? _selectedImage;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadShopDetails();
  }

  Future<void> _loadShopDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        _showErrorMessage("Kullanıcı oturum açmamış.");
        return;
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists || userDoc['shopid'] == null) {
        _showErrorMessage("Mağaza bilgileri bulunamadı.");
        return;
      }

      String shopId = userDoc['shopid'];

      DocumentSnapshot shopDoc =
          await _firestore.collection('shops').doc(shopId).get();

      if (shopDoc.exists) {
        _nameController.text = shopDoc['name'] ?? '';
        _addressController.text = shopDoc['address'] ?? '';
        _categories = List<String>.from(shopDoc['categories'] ?? []);
        _imageUrl = shopDoc['image'];
      }
    } catch (e) {
      _showErrorMessage("Hata oluştu: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateShopDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        _showErrorMessage("Kullanıcı oturum açmamış.");
        return;
      }

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists || userDoc['shopid'] == null) {
        _showErrorMessage("Mağaza bilgileri bulunamadı.");
        return;
      }

      String shopId = userDoc['shopid'];

      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'categories': _categories,
      };

      if (_selectedImage != null) {
        String? newImageUrl = await _uploadImage();
        if (newImageUrl != null) {
          updateData['image'] = newImageUrl;
        }
      }

      await _firestore.collection('shops').doc(shopId).update(updateData);

      _showSuccessMessage("Mağaza bilgileri güncellendi.");
    } catch (e) {
      _showErrorMessage("Güncelleme sırasında hata oluştu: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _uploadImage() async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef =
          FirebaseStorage.instance.ref().child('shop_images/$fileName');
      UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _showErrorMessage("Resim yüklenirken hata oluştu: $e");
      return null;
    }
  }

  void _addCategory() {
    if (_categoryController.text.isNotEmpty) {
      setState(() {
        _categories.add(_categoryController.text.trim());
      });
      _categoryController.clear();
    }
  }

  void _removeCategory(String category) {
    setState(() {
      _categories.remove(category);
    });
  }

  void _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
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
        title: const Text("Mağaza Ayarları"),
        backgroundColor: const Color(0xFFF9A602),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mağaza Bilgileri",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF9A602),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Mağaza İsmi", _nameController),
                  _buildTextField("Mağaza Adresi", _addressController),
                  const SizedBox(height: 20),
                  const Text(
                    "Kategoriler",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF9A602),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCategorySection(),
                  const SizedBox(height: 20),
                  const Text(
                    "Mağaza Resmi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF9A602),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: _selectedImage == null && _imageUrl != null
                        ? Image.network(_imageUrl!, height: 150, width: 150)
                        : (_selectedImage != null
                            ? Image.file(_selectedImage!,
                                height: 150, width: 150)
                            : Container(
                                height: 150,
                                width: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.orange),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.add_a_photo,
                                    color: Colors.orange),
                              )),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateShopDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9A602),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Bilgileri Güncelle",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
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

  Widget _buildCategorySection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  hintText: "Yeni kategori ekleyin...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9A602),
              ),
              child: const Text("Ekle"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: _categories.map((category) {
            return Chip(
              label: Text(category),
              onDeleted: () => _removeCategory(category),
            );
          }).toList(),
        ),
      ],
    );
  }
}
