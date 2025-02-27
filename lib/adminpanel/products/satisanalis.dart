import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HourlyOrdersScreen extends StatefulWidget {
  @override
  _HourlyOrdersScreenState createState() => _HourlyOrdersScreenState();
}

class _HourlyOrdersScreenState extends State<HourlyOrdersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<FlSpot> hourlyOrdersData = [];
  bool isLoading = true;
  double dailyEarnings = 0;
  double weeklyEarnings = 0;
  double monthlyEarnings = 0;
  double totalEarningsInRange = 0;
  List<Map<String, dynamic>> bestSellingProducts = [];
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    fetchOrderAnalysisData();
  }

  Future<void> fetchOrderAnalysisData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('sellers').doc(user.uid).get();
        final shopId = userDoc.data()?['shopid'];

        if (shopId != null) {
          final ordersSnapshot = await _firestore
              .collection('carts')
              .where('shopId', isEqualTo: shopId)
              .where('status', isEqualTo: 'Onaylandı')
              .get();

          if (ordersSnapshot.docs.isEmpty) {
            setState(() => isLoading = false);
            return;
          }

          Map<int, int> hourlyCounts = {for (var i = 0; i < 24; i++) i: 0};
          Map<String, int> productSales = {};
          double dailyTotal = 0;
          double weeklyTotal = 0;
          double monthlyTotal = 0;
          double totalInRange = 0;

          DateTime now = DateTime.now();
          DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
          DateTime startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
          DateTime startOfMonth = DateTime(now.year, now.month - 1, now.day, 0, 0, 0);
          DateTime startOfLast7Days = startOfDay.subtract(Duration(days: 7));

          for (var doc in ordersSnapshot.docs) {
            final data = doc.data();
            final updatedAtTimestamp = data['updatedAt'] ?? data['createdAt'];
            final updatedAt = (updatedAtTimestamp as Timestamp).toDate();

            if (selectedDateRange != null) {
              if (updatedAt.isBefore(selectedDateRange!.start)) continue;
              if (updatedAt.isAfter(selectedDateRange!.end)) continue;
            }

            int hour = updatedAt.hour;
            hourlyCounts[hour] = (hourlyCounts[hour] ?? 0) + 1;

            double orderTotal = 0;
            List products = data['products'] ?? [];
            for (var product in products) {
              double price = (product['price'] ?? 0).toDouble();
              int quantity = (product['quantity'] ?? 0);
              orderTotal += price * quantity;
              String productName = product['name'];
              productSales[productName] = (productSales[productName] ?? 0) + quantity;
            }

            if (selectedDateRange != null) {
              totalInRange += orderTotal;
            } else {
              if (updatedAt.isAfter(startOfDay)) dailyTotal += orderTotal;
              if (updatedAt.isAfter(startOfLast7Days)) weeklyTotal += orderTotal;
              if (updatedAt.isAfter(startOfMonth)) monthlyTotal += orderTotal;
            }
          }

          List<Map<String, dynamic>> sortedProducts = productSales.entries
              .map((entry) => {'name': entry.key, 'quantity': entry.value})
              .toList()
            ..sort((a, b) => (b['quantity'] as int? ?? 0).compareTo(a['quantity'] as int? ?? 0));

          List<FlSpot> spots = hourlyCounts.entries
              .map((entry) => FlSpot(entry.key.toDouble(), entry.value.toDouble()))
              .toList();

          setState(() {
            hourlyOrdersData = spots;
            dailyEarnings = dailyTotal;
            weeklyEarnings = weeklyTotal;
            monthlyEarnings = monthlyTotal;
            totalEarningsInRange = totalInRange;
            bestSellingProducts = sortedProducts.take(5).toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
        isLoading = true;
      });
      fetchOrderAnalysisData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sipariş Analizi", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 255, 172, 47),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarih Aralığı Seçici Butonu
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _selectDateRange(context),
                      icon: Icon(Icons.calendar_today, color: Colors.white),
                      label: Text(
                        selectedDateRange == null
                            ? "Tarih Aralığı Seç"
                            : "Tarih Aralığını Değiştir",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Seçilen Tarih Aralığı Gösterimi
                  if (selectedDateRange != null)
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              "${DateFormat('dd/MM/yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.end)}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                  // Grafik ve Diğer Bilgiler
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SizedBox(
                      height: 300,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true, getDrawingHorizontalLine: (value) => FlLine(color: Colors.black26, strokeWidth: 1)),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                interval: 3,
                                getTitlesWidget: (value, meta) {
                                  return Text("${value.toInt()}:00", style: TextStyle(fontSize: 12, color: Colors.black));
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true, border: Border.all(color: Colors.orange, width: 2)),
                          lineBarsData: [
                            LineChartBarData(
                              spots: hourlyOrdersData,
                              isCurved: false,
                              color: Colors.orange,
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [const Color.fromARGB(255, 255, 123, 0).withOpacity(0.6), Colors.orange.withOpacity(0.1)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Divider(thickness: 2, height: 30),
                  if (selectedDateRange == null) ...[
                    _buildEarningsCard("📊 Bugünkü Kazanç", dailyEarnings),
                    _buildEarningsCard("📅 Son 7 Gün Kazanç", weeklyEarnings),
                    _buildEarningsCard("📆 Son 30 Gün Kazanç", monthlyEarnings),
                  ] else
                    _buildEarningsCard("💰 Toplam Kazanç", totalEarningsInRange),
                  Divider(thickness: 2, height: 30),
                  Text(
                    "🔥 En Çok Satılan Ürünler", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...bestSellingProducts.map((product) => ListTile(
                              leading: Icon(Icons.shopping_cart, color: const Color.fromARGB(255, 255, 170, 11)),
                              title: Text(
                                product['name'], 
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: Text(
                                "x${product['quantity']}", 
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEarningsCard(String title, double amount) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(Icons.monetization_on, color: Colors.green),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text("₺${amount.toStringAsFixed(2)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 0, 0, 0))),
      ),
    );
  }
}