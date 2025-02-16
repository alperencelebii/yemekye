import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CouponListPage extends StatefulWidget {
  @override
  _CouponListPageState createState() => _CouponListPageState();
}

class _CouponListPageState extends State<CouponListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kuponlarım",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('coupons').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final coupons = snapshot.data!.docs;

          if (coupons.isEmpty) {
            return Center(
              child: Text("Henüz kupon eklenmemiş.",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              var coupon = coupons[index];
              var data = coupon.data() as Map<String, dynamic>? ?? {};

              String couponCode = data['couponCode'] ?? 'Bilinmiyor';
              double discount = (data['discount'] as num?)?.toDouble() ?? 0.0;
              String discountType = data['discountType'] ?? 'percentage';
              DateTime startDate =
                  (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
              DateTime endDate =
                  (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now();
              int usageLimit = data['usageLimit'] ?? 0;
              int usedCount = data['usedCount'] ?? 0;

              bool isExpired = DateTime.now().isAfter(endDate);
              bool isUsedUp = usedCount >= usageLimit;

              return _buildCouponCard(
                couponCode,
                discount,
                discountType,
                startDate,
                endDate,
                usageLimit,
                usedCount,
                isExpired,
                isUsedUp,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCouponCard(
    String couponCode,
    double discount,
    String discountType,
    DateTime startDate,
    DateTime endDate,
    int usageLimit,
    int usedCount,
    bool isExpired,
    bool isUsedUp,
  ) {
    Color cardColor = isExpired || isUsedUp ? Colors.grey[300]! : Colors.white;
    Color textColor = isExpired || isUsedUp ? Colors.grey : Colors.black;
    String discountText = discountType == 'percentage'
        ? "%$discount İndirim"
        : "$discount TL İndirim";
    String statusText = isExpired
        ? "Süresi Doldu"
        : isUsedUp
            ? "Tükendi"
            : "Aktif";

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  couponCode,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.redAccent
                        : isUsedUp
                            ? Colors.orangeAccent
                            : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              discountText,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: textColor),
                    SizedBox(width: 4),
                    Text(
                      "Bitiş: ${DateFormat('dd-MM-yyyy').format(endDate)}",
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
