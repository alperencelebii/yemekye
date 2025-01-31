import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletPage extends StatefulWidget {
  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double balance = 0.0;
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    fetchBalance();
  }

  Future<void> fetchBalance() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('wallets').doc(user.uid).get();
      setState(() {
        balance = (doc.data()?['balance'] ?? 0).toDouble();
      });
    }
  }

  Future<void> addMoney(double amount) async {
    final user = _auth.currentUser;
    if (user != null) {
      final docRef = _firestore.collection('wallets').doc(user.uid);

      await docRef.set({'balance': balance + amount}, SetOptions(merge: true));

      Map<String, dynamic> newTransaction = {
        'userId': user.uid,
        'amount': amount,
        'type': 'deposit',
        'timestamp': Timestamp.now(),
      };

      setState(() {
        balance += amount;
        transactions.insert(0, newTransaction);
      });

      await _firestore.collection('transactions').add(newTransaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Cüzdanım',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Bakiye Container'ı
            AnimatedContainer(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.deepPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Mevcut Bakiye',
                      style: TextStyle(fontSize: 18, color: Colors.white70)),
                  SizedBox(height: 10),
                  AnimatedDefaultTextStyle(
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    duration: Duration(milliseconds: 500),
                    child: Text('\₺${balance.toStringAsFixed(2)}'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Para Yükleme Butonu
            ElevatedButton(
              onPressed: () => addMoney(50.0),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade500,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                child: Text('+ 50₺ Yükle',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            SizedBox(height: 30),

            // 📜 İşlem Listesi
            Expanded(
              child: StreamBuilder(
                stream: _firestore
                    .collection('transactions')
                    .where('userId', isEqualTo: _auth.currentUser?.uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasData) {
                    transactions = snapshot.data!.docs.map((doc) {
                      return doc.data() as Map<String, dynamic>;
                    }).toList();
                  }

                  if (transactions.isEmpty) {
                    return Center(
                      child: Text('Henüz işlem yok.',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> data = transactions[index];

                      // 📆 Tarih Formatlama
                      String formattedDate = "Tarih Yok";
                      if (data.containsKey('timestamp') &&
                          data['timestamp'] != null) {
                        Timestamp timestamp = data['timestamp'] as Timestamp;
                        DateTime date = timestamp.toDate();
                        formattedDate =
                            "${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute}";
                      }

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: data['type'] == 'deposit'
                                ? Colors.green
                                : Colors.red,
                            child: Icon(
                              data['type'] == 'deposit'
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            data['type'] == 'deposit'
                                ? 'Para Yatırma'
                                : 'Para Çekme',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(formattedDate,
                              style: TextStyle(color: Colors.grey.shade700)),
                          trailing: Text(
                            '\₺${data['amount'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: data['type'] == 'deposit'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
