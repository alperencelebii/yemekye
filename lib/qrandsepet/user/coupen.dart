import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CouponChecker extends StatefulWidget {
  final Function(double) onDiscountApplied;

  CouponChecker({required this.onDiscountApplied});

  @override
  _CouponCheckerState createState() => _CouponCheckerState();
}

class _CouponCheckerState extends State<CouponChecker> {
  final TextEditingController _couponController = TextEditingController();
  String _message = "";
  double _discount = 0.0;

  Future<void> checkCoupon() async {
    String enteredCoupon = _couponController.text.trim();

    if (enteredCoupon.isEmpty) {
      setState(() {
        _message = "Kupon kodu boş olamaz!";
      });
      return;
    }

    try {
      // Firestore'dan kuponu kontrol et
      var couponQuery = await FirebaseFirestore.instance
          .collection('coupons')
          .where('code', isEqualTo: enteredCoupon)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (couponQuery.docs.isEmpty) {
        setState(() {
          _message = "Geçersiz veya süresi dolmuş kupon!";
          _discount = 0.0;
        });
        widget.onDiscountApplied(0.0);
        return;
      }

      var couponData = couponQuery.docs.first.data();
      double discountAmount = couponData['discount']?.toDouble() ?? 0.0;

      setState(() {
        _message = "Kupon başarıyla uygulandı! -₺$discountAmount";
        _discount = discountAmount;
      });

      widget.onDiscountApplied(discountAmount);
    } catch (e) {
      setState(() {
        _message = "Kupon kontrol edilirken hata oluştu!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _couponController,
            decoration: InputDecoration(
              labelText: "Kupon Kodu",
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(Icons.check),
                onPressed: checkCoupon,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            _message,
            style: TextStyle(
              color: _discount > 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
