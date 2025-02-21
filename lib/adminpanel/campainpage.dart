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
  Set<String> _selectedProducts = Set();

  @override
  void initState() {
    super.initState();
    _getUserShopId();
    _moveExpiredCampaigns(); // Sayfa yüklendiğinde geçmiş kampanyaları taşı
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

  void _createCampaignForSelectedProducts() {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen en az bir ürün seçin.")),
      );
      return;
    }

    TextEditingController discountController = TextEditingController();
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
            "Seçilen Ürünler için Kampanya",
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
                  prefixIcon: Icon(Icons.percent, color: Color(0xFFE69F44)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFFE69F44)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFFE69F44)),
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
                  prefixIcon: Icon(Icons.access_time, color: Color(0xFFE69F44)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFFE69F44)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFFE69F44)),
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
                  prefixIcon: Icon(Icons.timer_off, color: Color(0xFFE69F44)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFFE69F44)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFFE69F44)),
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
               backgroundColor: Color(0xFFE69F44),
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

                  // Başlangıç zamanı kontrolü
                  if (startTime.isBefore(now)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Başlangıç zamanı şu anki zamandan önce olamaz.")),
                    );
                    return;
                  }

                  // Bitiş zamanı kontrolü
                  if (endTime.isBefore(startTime)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Bitiş zamanı başlangıç zamanından önce olamaz.")),
                    );
                    return;
                  }

                  _selectedProducts.forEach((productId) {
                    _firestore.collection('campaigns').add({
                      'productid': productId,
                      'discount': int.parse(discountController.text),
                      'start_time': Timestamp.fromDate(startTime),
                      'end_time': Timestamp.fromDate(endTime),
                      'shopid': _shopId,
                      'created_at': FieldValue.serverTimestamp(),
                    });
                  });

                  Navigator.pop(context);
                  setState(() {
                    _selectedProducts.clear();
                  });
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
                  backgroundColor: Color(0xFFE69F44),
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
          backgroundColor: Color(0xFFE69F44),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Kampanyalarım"),
        backgroundColor: Color(0xFFE69F44),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _createCampaignForSelectedProducts,
        child: Icon(Icons.local_offer),
        backgroundColor: Color(0xFFE69F44),
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

          if (shopProducts.isEmpty) {
            return Center(child: Text("Mağazanıza ait ürün bulunamadı."));
          }

          // Sadece bu mağazaya ait ürünlerin productid'lerini al
          List<String> productIds =
              shopProducts.map((doc) => doc['productid'] as String).toList();

          return StreamBuilder(
            stream: _firestore
                .collection('products')
                .where(FieldPath.documentId, whereIn: productIds)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> productSnapshot) {
              if (!productSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              Map<String, List<DocumentSnapshot>> categorizedProducts = {};

              productSnapshot.data!.docs.forEach((product) {
                String category = product['category'];
                if (!categorizedProducts.containsKey(category)) {
                  categorizedProducts[category] = [];
                }
                categorizedProducts[category]!.add(product);
              });

              return ListView(
                children: categorizedProducts.entries.map((entry) {
                  String category = entry.key;
                  List<DocumentSnapshot> products = entry.value;

                  return Card(
                    margin: EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                    child: ExpansionTile(
                      title: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFE69F44).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE69F44),
                            ),
                          ),
                        ),
                      ),
                      children: products.map((product) {
                        String productId = product.id;
                        String productName = product['name'];

                        return StreamBuilder(
                          stream: _firestore
                              .collection('campaigns')
                              .where('productid', isEqualTo: productId)
                              .snapshots(),
                          builder: (context,
                              AsyncSnapshot<QuerySnapshot> campaignSnapshot) {
                            bool hasCampaign = campaignSnapshot.hasData &&
                                campaignSnapshot.data!.docs.isNotEmpty;
                            DocumentSnapshot? campaignDoc;
                            Timestamp? startTime;
                            Timestamp? endTime;

                            if (hasCampaign) {
                              campaignDoc = campaignSnapshot.data!.docs.first;
                              startTime = campaignDoc['start_time'];
                              endTime = campaignDoc['end_time'];
                            }

                            return Card(
                              margin: EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              child: ListTile(
                                leading: Icon(Icons.local_offer,
                                    color: Color(0xFFE69F44)),
                                title: Text(
                                  productName,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: hasCampaign
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Aktif Kampanya",
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "Başlangıç: ${DateFormat('dd/MM/yyyy HH:mm').format(startTime!.toDate())}",
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          Text(
                                            "Bitiş: ${DateFormat('dd/MM/yyyy HH:mm').format(endTime!.toDate())}",
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      )
                                    : null,
                                trailing: hasCampaign
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
                                          await _endCampaign(campaignDoc!.id);
                                        },
                                      )
                                    : Checkbox(
                                        value: _selectedProducts.contains(productId),
                                        onChanged: (bool? selected) {
                                          setState(() {
                                            if (selected!) {
                                              _selectedProducts.add(productId);
                                            } else {
                                              _selectedProducts.remove(productId);
                                            }
                                          });
                                        },
                                      ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}