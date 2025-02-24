import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PromoteButtonWidget extends StatefulWidget {
  final String id; // Ürün veya Mağaza ID'si
  final String type; // "shop" veya "product"

  const PromoteButtonWidget({
    Key? key,
    required this.id,
    required this.type,
  }) : super(key: key);

  @override
  _PromoteButtonWidgetState createState() => _PromoteButtonWidgetState();
}

class _PromoteButtonWidgetState extends State<PromoteButtonWidget> {
  bool _isLoading = false;

  Future<void> promoteItem() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseAuth auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user == null) return;

      final userDoc = await firestore.collection('sellers').doc(user.uid).get();
      final shopId = userDoc.data()?['shopid'];

      if (shopId == null) return;

      final collectionName =
          widget.type == "shop" ? "FeaturedShops" : "FeaturedProducts";

      final docRef = widget.type == "shop"
          ? firestore.collection('shops').doc(widget.id)
          : firestore.collection('products').doc(widget.id);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await firestore.collection(collectionName).doc(widget.id).set(docSnapshot.data()!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${widget.type == "shop" ? "Mağaza" : "Ürün"} başarıyla öne çıkarıldı!",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print("Öne çıkarma hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Bir hata oluştu, tekrar deneyin!"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : promoteItem,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        elevation: 4,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.type == "shop" ? "Mağazayı Öne Çıkar" : "Ürünü Öne Çıkar",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
    );
  }
}