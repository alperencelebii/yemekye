import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:yemekye/adminpanel/kampanya/pastcampainpage.dart';

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

  Future<void> _moveExpiredCampaigns() async {
    QuerySnapshot expiredCampaigns = await _firestore
        .collection('campaigns')
        .where('end_time', isLessThan: Timestamp.now())
        .get();

    for (var doc in expiredCampaigns.docs) {
      Map<String, dynamic> campaignData = doc.data() as Map<String, dynamic>;

      await _firestore.collection('past_campaigns').doc(doc.id).set({
        ...campaignData,
        'moved_at': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('campaigns').doc(doc.id).delete();
    }
  }

  void _createCampaign(String productId, String productName,
      {Map<String, dynamic>? existingCampaign}) {
    TextEditingController discountController = TextEditingController(
        text: existingCampaign != null
            ? existingCampaign['discount'].toString()
            : '');
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

  Future<void> _endCampaign(String campaignId) async {
    DocumentSnapshot campaignDoc =
        await _firestore.collection('campaigns').doc(campaignId).get();
    if (campaignDoc.exists) {
      Map<String, dynamic> campaignData =
          campaignDoc.data() as Map<String, dynamic>;

      await _firestore.collection('past_campaigns').doc(campaignId).set({
        ...campaignData,
        'moved_at': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('campaigns').doc(campaignId).delete();
    }
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

  @override
  Widget build(BuildContext context) {
    if (_shopId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Kampanyalar"),
          backgroundColor: Colors.orange,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Kampanyalarım"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PastCampaignsPage(shopId: _shopId!)),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _moveExpiredCampaigns(),
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

                      return StreamBuilder(
                        stream: _firestore
                            .collection('campaigns')
                            .where('productid', isEqualTo: productId)
                            .snapshots(),
                        builder: (context,
                            AsyncSnapshot<QuerySnapshot> campaignSnapshot) {
                          bool isActive = false;
                          String? campaignId;
                          Timestamp? startTime;
                          Timestamp? endTime;

                          if (campaignSnapshot.hasData &&
                              campaignSnapshot.data!.docs.isNotEmpty) {
                            var campaignData =
                                campaignSnapshot.data!.docs.first;
                            DateTime now = DateTime.now();
                            campaignId = campaignData.id;
                            startTime = campaignData['start_time'];
                            endTime = campaignData['end_time'];
                            isActive = now.isAfter(startTime!.toDate()) &&
                                now.isBefore(endTime!.toDate());
                          }

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.all(8),
                            child: ListTile(
                              leading:
                                  Icon(Icons.local_offer, color: Colors.orange),
                              title: Text(
                                productName,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isActive)
                                    Text(
                                      "Aktif Kampanya",
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  if (startTime != null && endTime != null)
                                    Text(
                                      "Başlangıç: ${DateFormat('dd/MM/yyyy HH:mm').format(startTime!.toDate())}\nBitiş: ${DateFormat('dd/MM/yyyy HH:mm').format(endTime!.toDate())}",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                ],
                              ),
                              trailing: isActive
                                  ? ElevatedButton.icon(
                                      icon: Icon(Icons.stop_circle,
                                          color: Colors.white),
                                      label: Text("Kampanyayı Bitir"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await _endCampaign(campaignId!);
                                      },
                                    )
                                  : ElevatedButton.icon(
                                      icon: Icon(Icons.local_offer,
                                          color: Colors.white),
                                      label: Text("İndirim Yap"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () => _createCampaign(
                                          productId, productName),
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
          );
        },
      ),
    );
  }
}
