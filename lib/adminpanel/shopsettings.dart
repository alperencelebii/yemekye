import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShopSettings extends StatefulWidget {
  @override
  _ShopSettingsState createState() => _ShopSettingsState();
}

class _ShopSettingsState extends State<ShopSettings> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

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

      await _firestore.collection('shops').doc(shopId).update({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
      });

      _showSuccessMessage("Mağaza bilgileri güncellendi.");
    } catch (e) {
      _showErrorMessage("Güncelleme sırasında hata oluştu: $e");
    } finally {
      setState(() {
        _isLoading = false;
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
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
}
