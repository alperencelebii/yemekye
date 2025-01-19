import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yemekye/qrandsepet/sepet.dart';

class QRCodeScannerScreen extends StatefulWidget {
  @override
  _QRCodeScannerScreenState createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isQRScanned = false;
  String _scannedCode = '';

  Future<void> _verifyQRCode(String qrData) async {
    try {
      final uri = Uri.parse(qrData);
      final cartId = uri.queryParameters['cartId'];
      final shopId = uri.queryParameters['shopId'];

      if (cartId == null || shopId == null) {
        _showResultDialog("Hata", "QR kod bilgileri eksik.");
        return;
      }

      final user = _auth.currentUser;
      if (user == null) {
        _showResultDialog("Hata", "Kullanıcı oturum açmamış.");
        return;
      }

      // Kullanıcının mağaza kimliği
      final shopDoc = await _firestore.collection('users').doc(user.uid).get();
      final currentShopId = shopDoc.data()?['shopid'];

      if (currentShopId != shopId) {
        _showResultDialog("Hata", "Ürünler sizin mağazanıza ait değil.");
        return;
      }

      // Sepeti al
      final cartDoc = await _firestore.collection('carts').doc(cartId).get();
      if (!cartDoc.exists) {
        _showResultDialog("Hata", "Geçersiz sepet bilgisi.");
        return;
      }

      final products =
          List<Map<String, dynamic>>.from(cartDoc.data()?['products'] ?? []);

      // Stokları güncelle
      for (var product in products) {
        final productId = product['productId'];
        final quantity = product['quantity'];

        final productRef = _firestore.collection('products').doc(productId);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(productRef);
          if (!snapshot.exists) {
            throw Exception("Ürün bulunamadı.");
          }

          final currentStock = snapshot.data()?['piece'] ?? 0;
          if (currentStock < quantity) {
            throw Exception("${product['name']} için yeterli stok yok.");
          }

          transaction.update(productRef, {'piece': currentStock - quantity});
        });
      }

      // Sepeti temizle
      await _firestore.collection('carts').doc(cartId).update({
        'products': FieldValue.delete(),
      });

      // Bellekteki sepeti temizle
      CartManager.clearCart();

      _showResultDialog("Başarılı", "Satış onaylandı ve sepet temizlendi.");
    } catch (e) {
      _showResultDialog("Hata", "İşlem sırasında bir hata oluştu: $e");
    }
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("Tamam"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Kod Taraması")),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (barcode) async {
              if (!_isQRScanned && barcode.barcodes.isNotEmpty) {
                setState(() {
                  _isQRScanned = true;
                  _scannedCode =
                      barcode.barcodes.first.rawValue ?? "Veri okunamadı";
                });

                await _verifyQRCode(_scannedCode);
              }
            },
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blue,
                  width: 2.0,
                ),
              ),
            ),
          ),
          if (_isQRScanned) _buildScannedCode(),
        ],
      ),
    );
  }

  Widget _buildScannedCode() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Scanned Code: $_scannedCode',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
