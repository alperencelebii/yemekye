import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRCodeScannerScreen extends StatefulWidget {
  @override
  _QRCodeScannerScreenState createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController _controller;
  bool _isQRScanned = false;
  String _scannedCode = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verifyQRCode(String qrData) async {
    try {
      final qrObject = Map<String, dynamic>.from(Uri.parse(qrData).queryParameters);
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
      appBar: AppBar(title: const Text("QR Kod Oku")),
      body: Stack(
        children: [
          _buildQrView(context),
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

  Widget _buildQrView(BuildContext context) {
    return QRView(
      key: _qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.blue,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: 220,
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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Scanned Code: $_scannedCode',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _controller = controller;
    });

    _controller.scannedDataStream.listen((scanData) async {
      if (!_isQRScanned) {
        setState(() {
          _isQRScanned = true;
          _scannedCode = scanData.code!;
        });

        await _verifyQRCode(scanData.code!);
      }
    });
  }
}
