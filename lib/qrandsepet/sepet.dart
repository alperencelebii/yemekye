import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CartManager {
  static final List<Map<String, dynamic>> _cartItems = [];
  static String? _shopId;

  static List<Map<String, dynamic>> get cartItems =>
      List.unmodifiable(_cartItems);

  static void addToCart(String shopId, String productId, String productName,
      double productPrice, int piece, BuildContext context) {
    if (_shopId != null && _shopId != shopId) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Farklı Mağaza'),
            content: const Text(
                'Sepete sadece bir mağazadan ürün ekleyebilirsiniz. Sepeti boşaltmak ister misiniz?'),
            actions: [
              TextButton(
                child: const Text('Hayır'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Evet, Boşalt'),
                onPressed: () {
                  clearCart();
                  _shopId = shopId;
                  _cartItems.add({
                    'productId': productId,
                    'name': productName,
                    'price': productPrice,
                    'quantity': 1,
                    'piece': piece,
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    _shopId ??= shopId;

    var existingItem = _cartItems.firstWhere(
      (item) => item['productId'] == productId,
      orElse: () => {},
    );

    if (existingItem.isNotEmpty) {
      if (existingItem['quantity'] < piece) {
        existingItem['quantity'] += 1;
      }
    } else {
      _cartItems.add({
        'productId': productId,
        'name': productName,
        'price': productPrice,
        'quantity': 1,
        'piece': piece,
      });
    }
  }

  static void clearCart() {
    _cartItems.clear();
    _shopId = null;
  }

  static void updateQuantity(int index, int value) {
    if (value > 0 &&
        _cartItems[index]['quantity'] < _cartItems[index]['piece']) {
      _cartItems[index]['quantity'] += 1;
    } else if (value < 0 && _cartItems[index]['quantity'] > 1) {
      _cartItems[index]['quantity'] -= 1;
    } else if (value < 0 && _cartItems[index]['quantity'] == 1) {
      _cartItems.removeAt(index);
    }
  }
}

class SepetScreen extends StatefulWidget {
  const SepetScreen({Key? key}) : super(key: key);

  @override
  _SepetScreenState createState() => _SepetScreenState();
}

class _SepetScreenState extends State<SepetScreen> {
  double calculateTotalPrice() {
    return CartManager.cartItems.fold(0, (total, item) {
      return total + (item['price'] * item['quantity']);
    });
  }

  void showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> generateQRCode() async {
    if (CartManager._shopId == null || CartManager.cartItems.isEmpty) {
      showSnackbar(context, "Sepet boş!");
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final cartDoc = await firestore.collection('carts').add({
        'createdAt': FieldValue.serverTimestamp(),
        'deviceId': 'exampleDeviceId', // Cihaz ID'si
        'products': CartManager.cartItems,
        'shopId': CartManager._shopId,
      });

      final qrString =
          'https://example.com/cart?cartId=${cartDoc.id}&shopId=${CartManager._shopId}';

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('QR Kod'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                QrImageView(
                  data: qrString,
                  size: 200.0,
                ),
                const SizedBox(height: 10),
                Text('Toplam: ₺${calculateTotalPrice().toStringAsFixed(2)}'),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Kapat'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      showSnackbar(context, "QR kod oluşturulamadı: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sepet')),
      body: CartManager.cartItems.isEmpty
          ? const Center(child: Text('Sepetiniz boş.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: CartManager.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = CartManager.cartItems[index];
                      return ListTile(
                        title: Text(item['name']),
                        subtitle: Text(
                            "\u20ba${item['price']} x ${item['quantity']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  CartManager.updateQuantity(index, -1);
                                });
                              },
                            ),
                            Text('${item['quantity']}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  CartManager.updateQuantity(index, 1);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "Toplam: \u20ba${calculateTotalPrice().toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: generateQRCode,
                        child: const Text('QR Kod Oluştur'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
