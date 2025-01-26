import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yemekye/qrandsepet/shops/confirmcart.dart';

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
    final cartRef = _firestore.collection('carts').doc(cartId);

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

    // QR kod okutulduğunda durum "Bekliyor" olarak güncellenir
    await cartRef.update({'status': 'Onay Bekleniyor'});

    final products =
        List<Map<String, dynamic>>.from(cartDoc.data()?['products'] ?? []);

    // ConfirmCartScreen'e yönlendir
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmCartScreen(
          products: products,
          cartId: cartId,
        ),
      ),
    );
  } catch (e) {
    _showErrorDialog("Hata", "İşlem sırasında bir hata oluştu: $e");
  }
}

@override
void initState() {
  super.initState();
  // QR tarayıcı başlatıldığında durum "QR Bekleniyor" olarak ayarlanır
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final cartId = args?['cartId'];

      if (cartId != null) {
        final cartRef = _firestore.collection('carts').doc(cartId);
        await cartRef.update({'status': 'QR Bekleniyor'});
      }
    } catch (e) {
      debugPrint("Hata: $e");
    }
  });
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
                  _isQRScanned = true;
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
}}