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

  Future<void> _deleteExpiredCampaigns() async {
    QuerySnapshot expiredCampaigns = await _firestore
        .collection('campaigns')
        .where('end_time',
            isLessThan: Timestamp.now()) // Süresi dolmuş kampanyalar
        .get();

    for (var doc in expiredCampaigns.docs) {
      await _firestore.collection('campaigns').doc(doc.id).delete();
    }
  }

  void _createCampaign(String productId, String productName) {
    TextEditingController discountController = TextEditingController();
    TextEditingController startTimeController = TextEditingController();
    TextEditingController endTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$productName için Kampanya"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "İndirim Oranı (%)"),
              ),
              TextField(
                controller: startTimeController,
                readOnly: true,
                onTap: () => _selectTime(context, startTimeController),
                decoration:
                    InputDecoration(labelText: "Başlangıç Saati (HH:mm)"),
              ),
              TextField(
                controller: endTimeController,
                readOnly: true,
                onTap: () => _selectTime(context, endTimeController),
                decoration: InputDecoration(labelText: "Bitiş Saati (HH:mm)"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("İptal"),
            ),
            ElevatedButton(
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

                  _firestore.collection('campaigns').add({
                    'productid': productId,
                    'discount': int.parse(discountController.text),
                    'start_time': Timestamp.fromDate(startTime),
                    'end_time': Timestamp.fromDate(endTime),
                    'shopid': _shopId,
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
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      String formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
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
      body: FutureBuilder(
        future: _deleteExpiredCampaigns(),
        builder: (context, snapshot) {
          return StreamBuilder(
            stream: _firestore
                .collection('shopproduct')
                .where('shopid', isEqualTo: _shopId)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              List<DocumentSnapshot> shopProducts = snapshot.data!.docs;

              if (shopProducts.isEmpty) {
                return Center(child: Text("Mağazanıza ait ürün bulunamadı."));
              }

              return ListView.builder(
                itemCount: shopProducts.length,
                padding: EdgeInsets.all(8.0),
                itemBuilder: (context, index) {
                  String productId = shopProducts[index]['productid'];

                  return FutureBuilder(
                    future:
                        _firestore.collection('products').doc(productId).get(),
                    builder: (context,
                        AsyncSnapshot<DocumentSnapshot> productSnapshot) {
                      if (!productSnapshot.hasData ||
                          !productSnapshot.data!.exists) {
                        return SizedBox.shrink();
                      }

                      var productData = productSnapshot.data!;
                      String productName = productData['name'];

                      return Card(
                        margin: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 10.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                        child: ListTile(
                          leading:
                              Icon(Icons.shopping_bag, color: Colors.orange),
                          title: Text(productName),
                          subtitle: StreamBuilder(
                            stream: _firestore
                                .collection('campaigns')
                                .where('productid', isEqualTo: productId)
                                .snapshots(),
                            builder: (context,
                                AsyncSnapshot<QuerySnapshot> campaignSnapshot) {
                              if (!campaignSnapshot.hasData ||
                                  campaignSnapshot.data!.docs.isEmpty) {
                                return Text(
                                  "Kampanya Yok",
                                  style: TextStyle(color: Colors.grey),
                                );
                              }

                              var campaignData =
                                  campaignSnapshot.data!.docs.first;
                              DateTime endTime =
                                  (campaignData['end_time'] as Timestamp)
                                      .toDate();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "İndirim: %${campaignData['discount']}",
                                    style: TextStyle(color: Colors.green),
                                  ),
                                  Text(
                                    "Saat: ${DateFormat.Hm().format((campaignData['start_time'] as Timestamp).toDate())} - ${DateFormat.Hm().format(endTime)}",
                                    style: TextStyle(color: Colors.blueGrey),
                                  ),
                                  TextButton(
                                    onPressed: () => _firestore
                                        .collection('campaigns')
                                        .doc(campaignData.id)
                                        .delete(),
                                    child: Text(
                                      "Kampanyayı Kaldır",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          trailing: ElevatedButton(
                            onPressed: () =>
                                _createCampaign(productId, productName),
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
              );
            },
          );
        },
      ),
    );
  }
}
