import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductAdds extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController discountPriceController = TextEditingController();
  final TextEditingController pieceController = TextEditingController();

  Future<void> addProduct() async {
    await FirebaseFirestore.instance.collection("products").add({
      "name": nameController.text,
      "category": categoryController.text,
      "price": double.tryParse(priceController.text) ?? 0.0,
      "discountprice": double.tryParse(discountPriceController.text) ?? 0.0,
      "piece": int.tryParse(pieceController.text) ?? 0,
      "used": true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ürün Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Ürün Adı"),
                validator: (value) => value!.isEmpty ? "Zorunlu" : null,
              ),
              TextFormField(
                controller: categoryController,
                decoration: InputDecoration(labelText: "Kategori"),
                validator: (value) => value!.isEmpty ? "Zorunlu" : null,
              ),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(labelText: "Fiyat"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: discountPriceController,
                decoration: InputDecoration(labelText: "İndirimli Fiyat"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: pieceController,
                decoration: InputDecoration(labelText: "Adet"),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    addProduct();
                    Navigator.pop(context);
                  }
                },
                child: Text("Kaydet"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
