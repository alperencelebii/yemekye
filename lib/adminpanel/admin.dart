import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yemekye/adminpanel/products/addproduct.dart';
import 'package:yemekye/adminpanel/kampanya/campainpage.dart';
import 'package:yemekye/adminpanel/products/myProducts.dart';
import 'package:yemekye/adminpanel/products/satisanalis.dart';
import 'package:yemekye/qrandsepet/shops/qrcodescan.dart';
import 'package:yemekye/adminpanel/products/pastOrders.dart';
import 'shopsettings.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? shopInfo;
  bool isLoading = true;
  bool isOpen = false;
  List<FlSpot> dailyOrdersData = [];
  int todayOrders = 0;
  int totalOrders = 0;

  @override
  void initState() {
    super.initState();
    fetchShopInfo();
    fetchOrdersData();
  }

  Future<void> promoteShop() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('sellers').doc(user.uid).get();
        final shopId = userDoc.data()?['shopid'];

        if (shopId != null) {
          // Shops koleksiyonundaki mağazayı güncelle
          await _firestore.collection('shops').doc(shopId).update({
            'isPromoted': true,
            'promotionDate': FieldValue.serverTimestamp(),
          });

          // FeaturedShops koleksiyonuna ekle
          final shopDoc =
              await _firestore.collection('shops').doc(shopId).get();
          if (shopDoc.exists) {
            await _firestore.collection('FeaturedShops').doc(shopId).set(
                  shopDoc.data()!,
                );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Mağaza başarıyla öne çıkarıldı!")),
          );
        }
      }
    } catch (e) {
      print("Mağaza öne çıkarılırken hata oluştu: $e");
    }
  }

  // ✅ Ürünü Öne Çıkarma Fonksiyonu
  Future<void> promoteProduct(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('sellers').doc(user.uid).get();
        final shopId = userDoc.data()?['shopid'];

        if (shopId != null) {
          final productDoc = await _firestore
              .collection('shops')
              .doc(shopId)
              .collection('products')
              .doc(productId)
              .get();

          if (productDoc.exists) {
            await _firestore
                .collection('FeaturedProducts')
                .doc(productId)
                .set(productDoc.data()!);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Ürün başarıyla öne çıkarıldı!")),
            );
          }
        }
      }
    } catch (e) {
      print("Ürün öne çıkarılırken hata oluştu: $e");
    }
  }

  // ✅ Ürün Seçim Ekranı
  Future<void> showProductSelection() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('sellers').doc(user.uid).get();
    final shopId = userDoc.data()?['shopid'];
    if (shopId == null) return;

    final productsSnapshot = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('products')
        .get();

    if (productsSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Öne çıkarılacak ürün bulunamadı.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: productsSnapshot.docs.map((product) {
            return ListTile(
              leading: Image.network(
                product['image'] ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
              ),
              title: Text(product['name'] ?? 'Ürün Adı Yok'),
              subtitle: Text("Fiyat: ${product['price']} TL"),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  promoteProduct(product.id);
                },
                child: Text("Öne Çıkar"),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> fetchShopInfo() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('sellers').doc(user.uid).get();
        final shopId = userDoc.data()?['shopid'];

        if (shopId != null) {
          final shopDoc =
              await _firestore.collection('shops').doc(shopId).get();
          setState(() {
            shopInfo = shopDoc.data();
            isOpen = shopDoc.data()?['isOpen'] ?? false;
            isLoading = false;
          });
        } else {
          setState(() {
            shopInfo = null;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Mağaza bilgisi alınırken hata oluştu: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchOrdersData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('sellers').doc(user.uid).get();
        final shopId = userDoc.data()?['shopid'];

        if (shopId != null) {
          final ordersSnapshot = await _firestore
              .collection('carts')
              .where('shopId', isEqualTo: shopId)
              .where('status', isEqualTo: 'Onaylandı')
              .get();

          // Tarih gruplaması
          Map<String, int> orderCounts = {};
          final now = DateTime.now();

          for (var doc in ordersSnapshot.docs) {
            final updatedAt = (doc.data()['updatedAt'] as Timestamp).toDate();
            final formattedDate =
                "${updatedAt.year}-${updatedAt.month.toString().padLeft(2, '0')}-${updatedAt.day.toString().padLeft(2, '0')}";
            orderCounts[formattedDate] = (orderCounts[formattedDate] ?? 0) + 1;
          }

          // Son 7 günü oluştur
          List<DateTime> last7Days = List.generate(
              7, (index) => now.subtract(Duration(days: 6 - index)));
          List<FlSpot> spots = [];
          int todayCount = 0;

          for (int i = 0; i < last7Days.length; i++) {
            final date = last7Days[i];
            final formattedDate =
                "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
            final count = orderCounts[formattedDate] ?? 0;

            if (i == 6) {
              todayCount = count; // Bugünkü sipariş sayısı
            }

            spots.add(FlSpot(i.toDouble(), count.toDouble()));
          }

          setState(() {
            dailyOrdersData = spots;
            todayOrders = todayCount;
            totalOrders = ordersSnapshot.docs.length;
          });
        }
      }
    } catch (e) {
      print("Sipariş verileri alınırken hata oluştu: $e");
    }
  }

  Future<void> toggleShopStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('sellers').doc(user.uid).get();
        final shopId = userDoc.data()?['shopid'];

        if (shopId != null) {
          await _firestore.collection('shops').doc(shopId).update({
            'isOpen': !isOpen,
          });
          setState(() {
            isOpen = !isOpen;
          });
          final status = isOpen ? "Mağaza açıldı" : "Mağaza kapatıldı";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(status)),
          );
        }
      }
    } catch (e) {
      print("Mağaza durumu değiştirilirken hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color(0xFFF57C00),
        title: Text(
          "Mağaza Paneli",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_offer), // Kampanya ikonu
            tooltip: "Kampanyalar",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CampaignPage()),
              );
            },
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: buildDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              buildGraphCard(), // Grafiği daha yukarı aldık
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildInfoCard(
                      "Bugünkü Sipariş", todayOrders.toString(), Colors.orange),
                  buildInfoCard(
                      "Toplam Sipariş", totalOrders.toString(), Colors.green),
                ],
              ),
              SizedBox(height: 20),
              buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Drawer buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFAB40), Color(0xFFF57C00)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Text(
                "Yönetim Paneli",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text("Geçmiş Siparişler"),
            onTap: () => navigateToPastOrders(),
          ),
          ListTile(
            leading: Icon(Icons.shopping_basket),
            title: Text("Ürünler"),
            onTap: () => showSubMenu(context, "Ürünler"),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text("Ayarlar"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ShopSettings()),
            ),
          ),
          Divider(),
          isLoading
              ? Center(child: CircularProgressIndicator())
              : shopInfo != null
                  ? ListTile(
                      leading: Icon(Icons.store),
                      title: Text("Mağaza Bilgileri"),
                      subtitle: Text(shopInfo?['name'] ?? 'Bilinmiyor'),
                    )
                  : ListTile(
                      leading: Icon(Icons.error),
                      title: Text("Mağaza bilgisi bulunamadı"),
                    ),
          ListTile(
            leading: Icon(Icons.qr_code_2),
            title: Text("Qr Kod Oku"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => QRCodeScannerScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.analytics),
            title: Text("Satış Analizi"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    HourlyOrdersScreen(), // shopId'yi göndermeye gerek yok!
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGraphCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Günlük Sipariş Grafiği",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1, // Günlük sıçramalar
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < dailyOrdersData.length) {
                          DateTime date = DateTime.now().subtract(
                            Duration(days: 6 - value.toInt()),
                          );
                          return Text(
                            "${date.day}/${date.month}",
                            style: TextStyle(fontSize: 10),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1, // Y ekseninde sıçramalar
                      reservedSize: 28,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: dailyOrdersData,
                    isCurved: false,
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 255, 255, 255)
                              .withOpacity(0.3),
                          Colors.deepOrange.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionButton() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: toggleShopStatus,
          style: ElevatedButton.styleFrom(
            backgroundColor: isOpen ? Colors.red : Colors.green,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(isOpen ? Icons.close : Icons.check, color: Colors.white),
          label: Text(
            isOpen ? "Mağazayı Kapat" : "Mağazayı Aç",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        SizedBox(height: 12), // Boşluk bırak

        // ✅ Mağazayı Öne Çıkarma Butonu
        ElevatedButton.icon(
          onPressed: promoteShop, // Yeni fonksiyon eklendi
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(Icons.star, color: Colors.white),
          label: Text(
            "Mağazayı Öne Çıkar",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: showProductSelection,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          icon: Icon(Icons.local_offer, color: Colors.white),
          label: Text(
            "Ürünü Öne Çıkar",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget buildInfoCard(String title, String value, Color color) {
    return Container(
      width: 150,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void showSubMenu(BuildContext context, String menuTitle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        if (menuTitle == "Ürünler") {
          return Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE082),
                  Color(0xFFF9A602),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top pull indicator
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ürünler Menüsü",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.add_box, color: Colors.white),
                    title: const Text(
                      "Ürün Ekle",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddProduct()),
                      );
                    },
                  ),
                  Divider(color: Colors.white.withOpacity(0.5)),
                  ListTile(
                    leading: const Icon(Icons.list, color: Colors.white),
                    title: const Text(
                      "Ürünlerim",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyProducts()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void navigateToPastOrders() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc =
          await _firestore.collection('sellers').doc(user.uid).get();
      final shopId = userDoc.data()?['shopid'];
      if (shopId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PastOrdersScreen(shopId: shopId)),
        );
      }
    }
  }
}
