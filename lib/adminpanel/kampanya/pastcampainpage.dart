import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PastCampaignsPage extends StatefulWidget {
  @override
  _PastCampaignsPageState createState() => _PastCampaignsPageState();
}

class _PastCampaignsPageState extends State<PastCampaignsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  void _restartCampaign(DocumentSnapshot campaign) {
    if (_shopId == null) return;

    _firestore.collection('campaigns').add({
      'productid': campaign['productid'],
      'discount': campaign['discount'],
      'start_time': campaign['start_time'],
      'end_time': campaign['end_time'],
      'shopid': _shopId,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  void _editAndRestartCampaign(DocumentSnapshot campaign) {
    if (_shopId == null) return;

    TextEditingController startTimeController = TextEditingController();
    TextEditingController endTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Kampanya Saatlerini Düzenle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startTimeController,
                readOnly: true,
                onTap: () => _selectTime(context, startTimeController),
                decoration: InputDecoration(labelText: "Başlangıç Saati"),
              ),
              TextField(
                controller: endTimeController,
                readOnly: true,
                onTap: () => _selectTime(context, endTimeController),
                decoration: InputDecoration(labelText: "Bitiş Saati"),
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
                _firestore.collection('campaigns').add({
                  'productid': campaign['productid'],
                  'discount': campaign['discount'],
                  'start_time': Timestamp.fromDate(
                      DateFormat("HH:mm").parse(startTimeController.text)),
                  'end_time': Timestamp.fromDate(
                      DateFormat("HH:mm").parse(endTimeController.text)),
                  'shopid': _shopId,
                  'created_at': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              },
              child: Text("Kaydet ve Başlat"),
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
      controller.text = picked.format(context);
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
      appBar: AppBar(title: Text("Geçmiş Kampanyalar")),
      body: StreamBuilder(
        stream: _firestore
            .collection('campaigns')
            .where('shopid',
                isEqualTo: _shopId) // Sadece giriş yapanın shopId'sini göster
            .where('end_time', isLessThan: Timestamp.now())
            .orderBy('end_time', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Geçmiş kampanya bulunamadı."));
          }

          var campaigns = snapshot.data!.docs;

          return ListView.builder(
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              var campaign = campaigns[index];
              DateTime endTime = (campaign['end_time'] as Timestamp).toDate();

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text("İndirim: %${campaign['discount']}"),
                  subtitle:
                      Text("Bitiş Saati: ${DateFormat.Hm().format(endTime)}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.green),
                        onPressed: () => _restartCampaign(campaign),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _editAndRestartCampaign(campaign),
                      ),
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
