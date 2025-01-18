import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yemekye/screens/addproduct.dart';
import 'package:yemekye/adminpanel/myProducts.dart';
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

  @override
  void initState() {
    super.initState();
    fetchShopInfo();
  }

  Future<void> fetchShopInfo() async {
    try {
      final user = _auth.currentUser; // Oturum açmış kullanıcı
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final shopId = userDoc.data()?['shopid']; // Kullanıcının mağaza ID'si

        if (shopId != null) {
          final shopDoc = await _firestore.collection('shops').doc(shopId).get();
          setState(() {
            shopInfo = shopDoc.data(); // Mağaza bilgilerini çek
            isLoading = false;
          });
        } else {
          setState(() {
            shopInfo = null;
            isLoading = false;
          });
          print("Mağaza ID'si bulunamadı.");
        }
      }
    } catch (e) {
      print("Mağaza bilgisi alınırken hata oluştu: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color(0xFFF9A602), // AppBar arka plan rengi
        title: Text("Mağazam"),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFFF9A602),
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
              leading: Icon(Icons.shopping_basket),
              title: Text("Ürünler"),
              onTap: () {
                Navigator.pop(context);
                showSubMenu(context, "Ürünler");
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Ayarlar"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ShopSettings()));
              },
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
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 3,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Günlük Kod Kullanımı",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(show: true),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              FlSpot(0, 1),
                              FlSpot(1, 2),
                              FlSpot(2, 1.5),
                              FlSpot(3, 2),
                              FlSpot(4, 2.8),
                            ],
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [const Color.fromARGB(255, 255, 220, 143), const Color.fromARGB(255, 255, 153, 0)],
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
                                  const Color.fromARGB(255, 255, 187, 0).withOpacity(0.3),
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
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoBox("Bugünkü Satış", "50"),
                _buildInfoBox("Toplam Satış", "200"),
              ],
            ),
            Spacer(),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.qr_code_2,
                    size: 50,
                    color: Color(0xFFF9A602),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String value) {
    return Container(
      width: 140,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

void showSubMenu(BuildContext context, String menuTitle) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    backgroundColor: Colors.white,
    builder: (context) {
      if (menuTitle == "Ürünler") {
        return Container(
          decoration: BoxDecoration(
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
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Ürünler Menüsü",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.add_box, color: Colors.white),
                  title: Text(
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
                  leading: Icon(Icons.list, color: Colors.white),
                  title: Text(
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
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      }
      return SizedBox.shrink();
    },
  );
}
}
