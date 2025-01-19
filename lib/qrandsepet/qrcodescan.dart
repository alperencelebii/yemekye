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
      final qrObject =
          Map<String, dynamic>.from(Uri.parse(qrData).queryParameters);
      final shopId = qrObject['shopId'];
      final items = qrObject['items'];

      final user = _auth.currentUser;
      if (user == null) {
        _showResultDialog("Hata", "Kullanıcı oturum açmamış.");
        return;
      }

      final shopDoc = await _firestore.collection('users').doc(user.uid).get();
      final currentShopId = shopDoc.data()?['shopid'];

      if (currentShopId == shopId) {
        _showResultDialog("Başarılı", "Satış onaylandı!");
      } else {
        _showResultDialog("Hata", "Ürünler sizin mağazanıza ait değil.");
      }
    } catch (e) {
      _showResultDialog("Hata", "Geçersiz QR kod: $e");
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
