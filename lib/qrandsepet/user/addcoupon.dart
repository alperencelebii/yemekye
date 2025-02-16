import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddCouponPage extends StatefulWidget {
  @override
  _AddCouponPageState createState() => _AddCouponPageState();
}

class _AddCouponPageState extends State<AddCouponPage> {
  final TextEditingController _couponCodeController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _usageLimitController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _discountType = 'percentage';

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
          _startDateController.text =
              DateFormat('yyyy-MM-dd').format(selectedDate);
        } else {
          _endDate = selectedDate;
          _endDateController.text =
              DateFormat('yyyy-MM-dd').format(selectedDate);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kupon Ekle", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade700, Colors.orange.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.orange.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTextField("Kupon Kodu", _couponCodeController,
                      icon: Icons.card_giftcard),
                  _buildTextField("Kullanım Limiti", _usageLimitController,
                      isNumber: true, icon: Icons.repeat),
                  _buildDropdown(),
                  _buildTextField(
                    _discountType == 'percentage'
                        ? "İndirim Oranı (%)"
                        : "İndirim Tutarı (TL)",
                    _discountController,
                    isNumber: true,
                    icon: Icons.percent,
                  ),
                  _buildDateField("Başlangıç Tarihi", _startDateController,
                      () => _selectDate(context, true)),
                  _buildDateField("Bitiş Tarihi", _endDateController,
                      () => _selectDate(context, false)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.orange,
                      shadowColor: Colors.orangeAccent,
                      elevation: 5,
                    ),
                    onPressed: _addCoupon,
                    child: Text("Kupon Ekle",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.orange) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: _discountType,
        decoration: InputDecoration(
          labelText: "İndirim Türü",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
        items: [
          DropdownMenuItem(value: 'percentage', child: Text('Yüzde (%)')),
          DropdownMenuItem(value: 'fixed', child: Text('Sabit Fiyat (TL)')),
        ],
        onChanged: (value) {
          setState(() {
            _discountType = value!;
          });
        },
      ),
    );
  }

  Widget _buildDateField(
      String label, TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: Icon(Icons.calendar_today, color: Colors.orange),
          filled: true,
          fillColor: Colors.white,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _addCoupon() async {
    final couponCode = _couponCodeController.text.trim();
    final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;
    final usageLimit = int.tryParse(_usageLimitController.text.trim()) ?? 0;

    if (couponCode.isEmpty ||
        discount <= 0 ||
        usageLimit <= 0 ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('coupons')
          .doc(couponCode)
          .set({
        'couponCode': couponCode,
        'discount': discount,
        'discountType': _discountType,
        'startDate': Timestamp.fromDate(_startDate!),
        'endDate': Timestamp.fromDate(_endDate!),
        'usageLimit': usageLimit,
        'usedCount': 0,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kupon başarıyla eklendi!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kupon eklenirken hata oluştu: $e')),
      );
    }
  }
}
