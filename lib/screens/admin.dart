import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'productsadd.dart';
import 'myproducts.dart';
import 'shopsettings.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Scaffold'a bir GlobalKey atandı
      appBar: AppBar(
        title: Text("Admin Panel"),
        leading: IconButton(
          icon: Icon(Icons.menu), // Sol üstteki 3 çizgi
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // GlobalKey ile Drawer açma
          },
        ),
      ),
      drawer: Drawer( // Sidebar menüsü
        child: ListView(
          children: [
            ListTile(
              title: Text("Ürünler"),
              onTap: () {
                Navigator.pop(context); // Drawer'ı kapatır.
                showSubMenu(context, "Ürünler");
              },
            ),
            ListTile(
              title: Text("Ayarlar"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ShopSettings()));
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Günlük Kod Kullanımı",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 1), // Rastgele veri
                        FlSpot(1, 2),
                        FlSpot(2, 1.5),
                        FlSpot(3, 3),
                        FlSpot(4, 2.8),
                      ],
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.lightBlueAccent],
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.3),
                            Colors.lightBlueAccent.withOpacity(0.3)
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
    );
  }

  void showSubMenu(BuildContext context, String menuTitle) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        if (menuTitle == "Ürünler") {
          return ListView(
            children: [
              ListTile(
                title: Text("Ürün Ekle"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ProductAdds()));
                },
              ),
              ListTile(
                title: Text("Ürünlerim"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => MyProducts()));
                },
              ),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}
