import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        _showErrorDialog("Hata", "QR kod bilgileri eksik.");
        return;
      }

      final user = _auth.currentUser;
      if (user == null) {
        _showErrorDialog("Hata", "Kullanıcı oturum açmamış.");
        return;
      }

      final shopDoc = await _firestore.collection('users').doc(user.uid).get();
      final currentShopId = shopDoc.data()?['shopid'];

      if (currentShopId != shopId) {
        _showErrorDialog("Hata", "Ürünler sizin mağazanıza ait değil.");
        return;
      }

      final cartDoc = await _firestore.collection('carts').doc(cartId).get();
      if (!cartDoc.exists) {
        _showErrorDialog("Hata", "Geçersiz sepet bilgisi.");
        return;
      }

      final products =
          List<Map<String, dynamic>>.from(cartDoc.data()?['products'] ?? []);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmCartScreen(
            products: products,
            cartId: cartId, // `cartId`'yi gönderiyoruz
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog("Hata", "İşlem sırasında bir hata oluştu: $e");
    }
  }

  void _showErrorDialog(String title, String message) {
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

                try {
                  await _verifyQRCode(_scannedCode);
                } finally {
                  setState(() {
                    _isQRScanned = false; // Tekrar tarama yapmaya izin ver
                  });
                }
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
                  color: const Color(0xFFF9A602),
                  width: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfirmCartScreen extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final String cartId; // `cartId` parametresi

  const ConfirmCartScreen({
    Key? key,
    required this.products,
    required this.cartId,
  }) : super(key: key);

  double calculateTotalPrice() {
    return products.fold(0, (total, product) {
      return total + (product['price'] * product['quantity']);
    });
  }

  Future<void> _reduceStock(BuildContext context) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Tüm ürünlerin stoklarını kontrol et ve düşür
      for (var product in products) {
        final productDoc = await firestore
            .collection('products')
            .doc(product['productId'])
            .get();

        if (productDoc.exists) {
          final currentStock = productDoc.data()?['piece'] ?? 0;
          final newStock = currentStock - product['quantity'];

          if (newStock < 0) {
            throw Exception(
                "${product['name']} için stok yetersiz. Mevcut stok: $currentStock");
          }

          await firestore
              .collection('products')
              .doc(product['productId'])
              .update({'piece': newStock});
        } else {
          throw Exception("${product['name']} bulunamadı.");
        }
      }

      // Sepeti "Onaylandı" olarak işaretle ve sipariş numarasını ekle
      await firestore.collection('carts').doc(cartId).update({
        'status': 'Onaylandı',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Satış tamamlandı!')),
      );

      Navigator.pop(context); // Kullanıcıyı önceki ekrana döndür
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Onay Sayfası'),
        backgroundColor: const Color(0xFFF9A602),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  elevation: 3,
                  child: ListTile(
                    title: Text(product['name'] ?? 'Ürün Adı Yok'),
                    subtitle: Text(
                      "Fiyat: ₺${product['price'].toStringAsFixed(2)}\nAdet: ${product['quantity']}",
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFFF9A602),
            ),
            child: Column(
              children: [
                Text(
                  "Toplam: ₺${calculateTotalPrice().toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _reduceStock(context),
                  child: const Text("Satışı Onayla"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
