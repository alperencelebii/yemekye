import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CartManager {
  static final List<Map<String, dynamic>> _cartItems = [];
  static String? _shopId;

  static List<Map<String, dynamic>> get cartItems =>
      List.unmodifiable(_cartItems);

  static void addToCart(String shopId, String productId, String productName,
      double productPrice, int piece, BuildContext context, bool isOpen) {
if (_shopId != null && _shopId != shopId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Row(
          children: [
            Icon(Icons.store_mall_directory, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(
              'Farklı Mağaza',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Sepete sadece bir mağazadan ürün ekleyebilirsiniz. Sepeti boşaltmak ister misiniz?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              textStyle: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text('Hayır'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Evet, Boşalt',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
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

if (isOpen == false) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(
              'Uyarı',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Bu Mağaza Şuanda Kapalı',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Tamam',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            onPressed: () {
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
      clearCart();
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

    // Mevcut en yüksek sipariş numarasını al
    final querySnapshot = await firestore
        .collection('carts')
        .orderBy('orderNumber', descending: true)
        .limit(1)
        .get();

    int orderNumber = 1; // İlk sipariş için başlangıç numarası
    if (querySnapshot.docs.isNotEmpty) {
      orderNumber = (querySnapshot.docs.first.data()['orderNumber'] ?? 0) + 1;
    }

    // Yeni sepet belgesini oluştur
    final cartDoc = await firestore.collection('carts').add({
  'createdAt': FieldValue.serverTimestamp(),
  'products': CartManager.cartItems,
  'shopId': CartManager._shopId,
  'orderNumber': orderNumber, // Sipariş numarası
  'status': 'Bekleniyor',
});

    final qrString =
        'https://example.com/cart?cartId=${cartDoc.id}&shopId=${CartManager._shopId}';

    // Firestore'daki 'status' alanını dinle
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection('carts').doc(cartDoc.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Status kontrolü
          if (data['status'] == 'Onaylandı') {
            return AlertDialog(
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.check_circle,
                      color: Colors.green, size: 80), // Yeşil Tik
                  const SizedBox(height: 10),
                  const Text(
                    'Satış Onaylandı!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sipariş Numaranız: $orderNumber',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Toplam: ₺${calculateTotalPrice().toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Tamam',
                      style: TextStyle(color: Color(0xFFF9A602))),
                  onPressed: () {
                    Navigator.of(context).pop();
                    CartManager.clearCart(); // Sepeti burada temizle
                    setState(() {}); // UI'yi güncellemek için
                  },
                ),
              ],
            );
          }
        }

        // Bekleme ekranında QR kodu göster
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 20),
              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!['status'] == 'Onay Bekleniyor') ...[
                const Text(
                  'Sipariş onayı bekleniyor...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              QrImageView(
                data: qrString,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ],
          ),
        );
      },
    );
  },
);
  } catch (e) {
    showSnackbar(context, "Sipariş oluşturulamadı: $e");
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
