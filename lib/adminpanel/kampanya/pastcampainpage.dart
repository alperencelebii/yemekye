import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PastCampaignsPage extends StatefulWidget {
  @override
  _PastCampaignsPageState createState() => _PastCampaignsPageState();
}

class _PastCampaignsPageState extends State<PastCampaignsPage> {
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

  @override
  Widget build(BuildContext context) {
    if (_shopId == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Geçmiş Kampanyalar")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Geçmiş Kampanyalar"),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('campaigns')
            .where('shopid', isEqualTo: _shopId)
            .where('end_time', isLessThan: Timestamp.now())
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<DocumentSnapshot> pastCampaigns = snapshot.data!.docs;

          if (pastCampaigns.isEmpty) {
            return Center(child: Text("Geçmiş kampanya bulunmamaktadır."));
          }

          return ListView.builder(
            itemCount: pastCampaigns.length,
            padding: EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              var campaign = pastCampaigns[index];
              DateTime startTime =
                  (campaign['start_time'] as Timestamp).toDate();
              DateTime endTime = (campaign['end_time'] as Timestamp).toDate();

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 3,
                child: ListTile(
                  leading: Icon(Icons.history, color: Colors.orange),
                  title: Text("Ürün ID: ${campaign['productid']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("İndirim: %${campaign['discount']}",
                          style: TextStyle(color: Colors.green)),
                      Text(
                          "Saat: ${DateFormat.Hm().format(startTime)} - ${DateFormat.Hm().format(endTime)}",
                          style: TextStyle(color: Colors.blueGrey)),
                    ],
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
