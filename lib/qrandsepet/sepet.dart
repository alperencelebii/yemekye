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

      // QR Kod gösterilirken sepet temizlenmiyor
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('QR Kod', style: TextStyle(color: Colors.black)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                QrImageView(
                  data: qrString,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  'Toplam: ₺${calculateTotalPrice().toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Kapat',
                    style: TextStyle(color: Color(0xFFF9A602))),
                onPressed: () {
                  Navigator.of(context).pop();
                  CartManager.clearCart(); // Sepeti burada temizliyoruz
                  setState(() {}); // UI'yi güncellemek için
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9A602),
        title: const Text('Sepet', style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: CartManager.cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Color(0xFFF9A602)),
                  SizedBox(height: 20),
                  Text(
                    'Sepetiniz boş.',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: CartManager.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = CartManager.cartItems[index];
                      return Card(
                        color: const Color(0xFFF9A602),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        elevation: 4,
                        child: ListTile(
                          title: Text(
                            item['name'],
                            style: const TextStyle(color: Colors.black87),
                          ),
                          subtitle: Text(
                            "\u20ba${item['price']} x ${item['quantity']}",
                            style: const TextStyle(color: Colors.black54),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove,
                                    color: Colors.black87),
                                onPressed: () {
                                  setState(() {
                                    CartManager.updateQuantity(index, -1);
                                  });
                                },
                              ),
                              Text('${item['quantity']}',
                                  style:
                                      const TextStyle(color: Colors.black87)),
                              IconButton(
                                icon: const Icon(Icons.add,
                                    color: Colors.black87),
                                onPressed: () {
                                  setState(() {
                                    CartManager.updateQuantity(index, 1);
                                  });
                                },
                              ),
                            ],
                          ),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF9A602),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF9A602),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        onPressed: generateQRCode,
                        child: const Text('QR Kod Oluştur',
                            style: TextStyle(color: Colors.black87)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
