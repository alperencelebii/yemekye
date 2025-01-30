import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CampaignPage extends StatefulWidget {
  @override
  _CampaignPageState createState() => _CampaignPageState();
}

class _CampaignPageState extends State<CampaignPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _shopId;

  @override
  void initState() {
    super.initState();
    _getUserShopId();
  }

  Future<void> _getUserShopId() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('sellers').doc(currentUser.uid).get();

    if (userDoc.exists && userDoc['shopid'] != null) {
      setState(() {
        _shopId = userDoc['shopid'];
      });
    }
  }

  Future<void> _createCampaign(String productId, String productName) async {
    TextEditingController discountController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$productName için Kampanya",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "İndirim Oranı (%)"),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Başlangıç Tarihi:"),
                  TextButton(
                    onPressed: () async {
                      DateTime? pickedDate = await _pickDate();
                      if (pickedDate != null) {
                        setState(() {
                          startDate = pickedDate;
                        });
                      }
                    },
                    child: Text(startDate != null
                        ? DateFormat.yMd().format(startDate!)
                        : "Seç"),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Başlangıç Saati:"),
                  TextButton(
                    onPressed: () async {
                      TimeOfDay? pickedTime = await _pickTime();
                      if (pickedTime != null) {
                        setState(() {
                          startTime = pickedTime;
                        });
                      }
                    },
                    child: Text(
                        startTime != null ? startTime!.format(context) : "Seç"),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Bitiş Tarihi:"),
                  TextButton(
                    onPressed: () async {
                      DateTime? pickedDate = await _pickDate();
                      if (pickedDate != null) {
                        setState(() {
                          endDate = pickedDate;
                        });
                      }
                    },
                    child: Text(endDate != null
                        ? DateFormat.yMd().format(endDate!)
                        : "Seç"),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Bitiş Saati:"),
                  TextButton(
                    onPressed: () async {
                      TimeOfDay? pickedTime = await _pickTime();
                      if (pickedTime != null) {
                        setState(() {
                          endTime = pickedTime;
                        });
                      }
                    },
                    child: Text(
                        endTime != null ? endTime!.format(context) : "Seç"),
                  ),
                ],
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (discountController.text.isNotEmpty &&
                      startDate != null &&
                      startTime != null &&
                      endDate != null &&
                      endTime != null) {
                    DateTime start = DateTime(
                      startDate!.year,
                      startDate!.month,
                      startDate!.day,
                      startTime!.hour,
                      startTime!.minute,
                    );
                    DateTime end = DateTime(
                      endDate!.year,
                      endDate!.month,
                      endDate!.day,
                      endTime!.hour,
                      endTime!.minute,
                    );

                    _firestore.collection('campaigns').add({
                      'productid': productId,
                      'discount': int.parse(discountController.text),
                      'start_time': Timestamp.fromDate(start),
                      'end_time': Timestamp.fromDate(end),
                      'shopid': _shopId,
                      'created_at': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                  }
                },
                child: Text("Kampanya Oluştur"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<DateTime?> _pickDate() async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
  }

  Future<TimeOfDay?> _pickTime() async {
    return await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_shopId == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Kampanyalar")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Kampanyalarım"),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('shopproduct')
            .where('shopid', isEqualTo: _shopId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<DocumentSnapshot> shopProducts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: shopProducts.length,
            padding: EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              String productId = shopProducts[index]['productid'];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 3,
                child: ListTile(
                  title: Text("Ürün ID: $productId"),
                  trailing: ElevatedButton(
                    onPressed: () => _createCampaign(productId, "Ürün"),
                    child: Text("İndirim Yap"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
