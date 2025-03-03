import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteRestaurantsPage extends StatefulWidget {
  @override
  _FavoriteRestaurantsPageState createState() =>
      _FavoriteRestaurantsPageState();
}

class _FavoriteRestaurantsPageState extends State<FavoriteRestaurantsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _favoriteShops = [];

  @override
  void initState() {
    super.initState();
    _getFavoriteRestaurants();
  }

  Future<void> _getFavoriteRestaurants() async {
    User? user = _auth.currentUser;

    if (user != null) {
      QuerySnapshot favoriteShopsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      setState(() {
        _favoriteShops = favoriteShopsSnapshot.docs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favori Restoranlar"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _favoriteShops.isEmpty
            ? Center(child: Text("Favori restoranınız yok."))
            : ListView.builder(
                itemCount: _favoriteShops.length,
                itemBuilder: (context, index) {
                  String shopId = _favoriteShops[index]['shopId'];
                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('shops').doc(shopId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasData && snapshot.data != null) {
                        var shopData = snapshot.data!.data() as Map<String, dynamic>;
                        String shopName = shopData['name'];
                        String shopAddress = shopData['address'];
                        String shopImage = shopData['image'] ?? 'assets/images/rest.jpg';
                        double shopRating = shopData['averageRating'] ?? 0.0;
                        bool isOpen = shopData['isOpen'] ?? false;

                        return GestureDetector(
                          onTap: () {
                            // Handle restaurant tap for details
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Restaurant Image
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    shopImage,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Restaurant Info
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shopName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          shopAddress,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              size: 16,
                                              color: Colors.orange,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '$shopRating',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(
                                              isOpen
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              size: 16,
                                              color: isOpen
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              isOpen ? 'Açık' : 'Kapalı',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isOpen
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SizedBox();
                    },
                  );
                },
              ),
      ),
    );
  }
}