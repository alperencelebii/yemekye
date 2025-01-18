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
      await _firestore.collection('shops').add({
        'name': shopName,
        'address': shopAddress,
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
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _createShop,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
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
