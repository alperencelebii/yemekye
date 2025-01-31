import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PastCampaignsPage extends StatelessWidget {
  final String shopId;

  PastCampaignsPage({required this.shopId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Geçmiş Kampanyalar"),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('past_campaigns')
            .where('shopid', isEqualTo: shopId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Geçmiş kampanya bulunamadı."));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return FutureBuilder(
                future: FirebaseFirestore.instance.collection('products').doc(doc['productid']).get(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> productSnapshot) {
                  if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                    return SizedBox.shrink();
                  }

                  var productData = productSnapshot.data!;
                  String productName = productData['name'];

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      leading: Icon(Icons.history, color: Colors.grey),
                      title: Text(
                        productName,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "İndirim: %${doc['discount']}",
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            "Bitiş Saati: ${DateFormat('dd/MM/yyyy HH:mm').format((doc['end_time'] as Timestamp).toDate())}",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton.icon(
                        icon: Icon(Icons.refresh, color: Colors.white),
                        label: Text("Tekrar Başlat"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          _createCampaign(context, doc['productid'], productName, existingCampaign: doc.data() as Map<String, dynamic>);
                        },
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _createCampaign(BuildContext context, String productId, String productName, {Map<String, dynamic>? existingCampaign}) {
    TextEditingController discountController = TextEditingController(text: existingCampaign != null ? existingCampaign['discount'].toString() : '');
    TextEditingController startTimeController = TextEditingController();
    TextEditingController endTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "$productName için Kampanya",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "İndirim Oranı (%)",
                  prefixIcon: Icon(Icons.percent, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: startTimeController,
                readOnly: true,
                onTap: () => _selectTime(context, startTimeController),
                decoration: InputDecoration(
                  labelText: "Başlangıç Saati (HH:mm)",
                  prefixIcon: Icon(Icons.access_time, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: endTimeController,
                readOnly: true,
                onTap: () => _selectTime(context, endTimeController),
                decoration: InputDecoration(
                  labelText: "Bitiş Saati (HH:mm)",
                  prefixIcon: Icon(Icons.timer_off, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("İptal", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (discountController.text.isNotEmpty &&
                    startTimeController.text.isNotEmpty &&
                    endTimeController.text.isNotEmpty) {
                  DateTime now = DateTime.now();
                  DateTime startTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    int.parse(startTimeController.text.split(':')[0]),
                    int.parse(startTimeController.text.split(':')[1]),
                  );
                  DateTime endTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    int.parse(endTimeController.text.split(':')[0]),
                    int.parse(endTimeController.text.split(':')[1]),
                  );

                  FirebaseFirestore.instance.collection('campaigns').add({
                    'productid': productId,
                    'discount': int.parse(discountController.text),
                    'start_time': Timestamp.fromDate(startTime),
                    'end_time': Timestamp.fromDate(endTime),
                    'shopid': shopId,
                    'created_at': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                }
              },
              child: Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    DateTime now = DateTime.now();
    int selectedHour = now.hour;
    int selectedMinute = now.minute;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 300,
          child: Column(
            children: [
              Text(
                "Saat Seç",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                            initialItem: selectedHour),
                        onSelectedItemChanged: (int value) {
                          selectedHour = value;
                        },
                        children: List.generate(
                          24,
                          (index) => Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(":",
                        style: TextStyle(fontSize: 28, color: Colors.grey)),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                            initialItem: selectedMinute),
                        onSelectedItemChanged: (int value) {
                          selectedMinute = value;
                        },
                        children: List.generate(
                          60,
                          (index) => Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  controller.text =
                      '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
                  Navigator.pop(context);
                },
                icon: Icon(Icons.check_circle, color: Colors.white),
                label: Text("Kaydet"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  textStyle:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}