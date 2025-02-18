import 'package:firebase_auth/firebase_auth.dart';
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
                Icon(Icons.store_mall_directory,
                    color: Colors.orange, size: 28),
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
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 28),
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
  final TextEditingController _couponController = TextEditingController();
  double _discount = 0.0; // Kupon indirim tutarı

  double calculateTotalPrice() {
    double total = CartManager.cartItems.fold(0, (total, item) {
      return total + (item['price'] * item['quantity']);
    });
    return (total - _discount)
        .clamp(0, double.infinity); // İndirim sıfırın altına düşmesin
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

      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      final cartDoc = await firestore.collection('carts').add({
        'createdAt': FieldValue.serverTimestamp(),
        'products': CartManager.cartItems,
        'shopId': CartManager._shopId,
        'orderNumber': orderNumber,
        'status': 'Bekleniyor',
        if (userId != null) 'userId': userId,
      });

      if (userId != null) {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(cartDoc.id)
            .set({
          'cartId': cartDoc.id,
          'createdAt': FieldValue.serverTimestamp(),
          'shopId': CartManager._shopId,
          'orderNumber': orderNumber,
          'status': 'Bekleniyor',
        });
      }

      await firestore.collection('orders').add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'shopId': CartManager._shopId,
        'products': CartManager.cartItems,
        'orderNumber': orderNumber,
        'status': 'Onay Bekleniyor',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Siparişi geçmiş siparişler koleksiyonuna da kaydedelim
      await firestore.collection('orders').add({
        'userId': FirebaseAuth.instance.currentUser?.uid,  // Kullanıcı ID'si
        'shopId': CartManager._shopId,
        'products': CartManager.cartItems,
        'orderNumber': orderNumber,
        'status': 'Onay Bekleniyor',
        'createdAt': FieldValue.serverTimestamp(),
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
                          "Toplam: \u20ba${calculateTotalPrice().toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _discount > 0
                                ? Colors.green
                                : Color(0xFFF9A602),
                          ),
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

<<<<<<< HEAD

=======
>>>>>>> c42d051fe35a94d69df7f781a5b51a33046bc926
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9A602),
        title: const Text('Sepet', style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🔹 Mağaza bilgilerini göstermek için FutureBuilder kullanıyoruz
          if (CartManager._shopId != null)
            FutureBuilder<Map<String, dynamic>?>(
              future: getShopInfo(CartManager._shopId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text("Mağaza bilgisi bulunamadı"));
                }

                final shopData = snapshot.data!;
                final bool isOpen = shopData['isOpen'] ?? false;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 6,
                  color: Colors.white,
                  shadowColor: Colors.black26,
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.storefront_rounded,
                              color: Colors.orange, size: 40),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shopData['name'] ?? "Mağaza İsmi",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      color: Colors.grey[600], size: 18),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      shopData['address'] ??
                                          "Adres bilgisi yok",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isOpen ? Icons.check_circle : Icons.cancel,
                                size: 16,
                                color: isOpen
                                    ? Colors.green[800]
                                    : Colors.red[800],
                              ),
                              SizedBox(width: 6),
                              Text(
                                isOpen ? "Açık" : "Kapalı",
                                style: TextStyle(
                                  color: isOpen
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          Expanded(
            child: ListView.builder(
              itemCount: CartManager.cartItems.length,
              itemBuilder: (context, index) {
                final item = CartManager.cartItems[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 5,
                  shadowColor: Colors.black26,
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "\u20ba${item['price']} x ${item['quantity']}",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.grey.shade200,
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    CartManager.updateQuantity(index, -1);
                                  });
                                },
                              ),
                              Text(
                                '${item['quantity']}',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline,
                                    color: Colors.green),
                                onPressed: () {
                                  setState(() {
                                    CartManager.updateQuantity(index, 1);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
<<<<<<< HEAD
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
=======
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
>>>>>>> c42d051fe35a94d69df7f781a5b51a33046bc926
        ],
      ),
    );
  }
}

Future<Map<String, dynamic>?> getShopInfo(String shopId) async {
  try {
    DocumentSnapshot shopSnapshot =
        await FirebaseFirestore.instance.collection('shops').doc(shopId).get();

    if (shopSnapshot.exists) {
      return shopSnapshot.data() as Map<String, dynamic>;
    }
  } catch (e) {
    print("Mağaza bilgisi alınamadı: $e");
  }
  return null;
}
