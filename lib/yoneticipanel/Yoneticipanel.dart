import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yemekye/loginregister/shop_register.dart';
import 'package:yemekye/yoneticipanel/AddUsers.dart';
import 'package:yemekye/yoneticipanel/reports/reportlistpage.dart';

class Yonetici extends StatefulWidget {
  @override
  _YoneticiState createState() => _YoneticiState();
}

class _YoneticiState extends State<Yonetici> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Yönetici Paneli"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateShopPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReportListPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: "Mağaza Ara",
                hintText: "Mağaza ismi girin...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('shops').snapshots(),
              builder: (context, shopSnapshot) {
                if (shopSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final shops = shopSnapshot.data?.docs ?? [];

                // Arama sonucuna göre filtreleme
                final filteredShops = _searchQuery.isEmpty
                    ? shops
                    : shops.where((shop) {
                        final shopData =
                            shop.data() as Map<String, dynamic>? ?? {};
                        final shopName = shopData['name']?.toLowerCase() ?? "";
                        return shopName.contains(_searchQuery);
                      }).toList();

                if (filteredShops.isEmpty) {
                  return Center(child: Text("Aradığınız mağaza bulunamadı."));
                }

                return ListView.builder(
                  itemCount: filteredShops.length,
                  itemBuilder: (context, index) {
                    final shopData =
                        filteredShops[index].data() as Map<String, dynamic>;
                    final shopId = filteredShops[index].id;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.all(10),
                      elevation: 5,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Text(
                            shopData['name'] != null
                                ? shopData['name'][0].toUpperCase()
                                : "?",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          shopData['name'] ?? "Mağaza Adı Yok",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          shopData['address'] ?? "Adres Bilgisi Yok",
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  Icon(Icons.location_pin, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MarkerManagementPage(
                                      shopId: shopId,
                                      shopName: shopData['name'],
                                      shopAddress: shopData['address'],
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                deleteShop(shopId);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ShopDetailsPage(shopId: shopId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void deleteShop(String shopId) async {
    await FirebaseFirestore.instance.collection('shops').doc(shopId).delete();
  }
}

class MarkerManagementPage extends StatefulWidget {
  final String shopId;
  final String? shopName;
  final String? shopAddress;

  MarkerManagementPage({required this.shopId, this.shopName, this.shopAddress});

  @override
  _MarkerManagementPageState createState() => _MarkerManagementPageState();
}

class _MarkerManagementPageState extends State<MarkerManagementPage> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('markers')
        .where('shopId', isEqualTo: widget.shopId)
        .get();

    setState(() {
      _markers.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(data['latitude'], data['longitude']),
          infoWindow: InfoWindow(
            title: data['title'],
            snippet: data['snippet'],
          ),
        );
        _markers.add(marker);
      }
    });
  }

  Future<void> _addMarker(LatLng position) async {
    final markerId = 'marker_${DateTime.now().millisecondsSinceEpoch}';
    final marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: widget.shopName,
        snippet: widget.shopAddress,
      ),
    );

    setState(() {
      _markers.add(marker);
    });

    await FirebaseFirestore.instance.collection('markers').doc(markerId).set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'shopId': widget.shopId,
      'title': widget.shopName,
      'snippet': widget.shopAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.shopName} Marker Yönetimi"),
        backgroundColor: Colors.orange,
      ),
      body: GoogleMap(
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
        initialCameraPosition: CameraPosition(
          target: LatLng(39.92077, 32.85411), // Default konum
          zoom: 14,
        ),
        onTap: _addMarker,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}

class ShopDetailsPage extends StatelessWidget {
  final String shopId;

  ShopDetailsPage({required this.shopId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mağaza Detayları"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddUserPage(shopId: shopId),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('shops').doc(shopId).get(),
        builder: (context, shopSnapshot) {
          if (shopSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final shopData = shopSnapshot.data?.data() as Map<String, dynamic>?;

          if (shopData == null) {
            return Center(child: Text("Mağaza bulunamadı."));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mağaza Adı: ${shopData['name']}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text("Adres: ${shopData['address']}"),
                SizedBox(height: 20),
                Text(
                  "Ürünler:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('shopproduct')
                        .where('shopid', isEqualTo: shopId)
                        .snapshots(),
                    builder: (context, productSnapshot) {
                      if (productSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final shopProducts = productSnapshot.data?.docs ?? [];

                      return ListView.builder(
                        itemCount: shopProducts.length,
                        itemBuilder: (context, index) {
                          final productData = shopProducts[index].data()
                              as Map<String, dynamic>;
                          final productId = productData['productid'];

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('products')
                                .doc(productId)
                                .get(),
                            builder: (context, productDetailsSnapshot) {
                              if (productDetailsSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              }

                              final productDetails = productDetailsSnapshot.data
                                  ?.data() as Map<String, dynamic>?;

                              if (productDetails == null) {
                                return SizedBox.shrink();
                              }

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 5),
                                child: ListTile(
                                  leading: productDetails['image'] != null
                                      ? Image.network(
                                          productDetails['image'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        )
                                      : CircleAvatar(
                                          backgroundColor: Colors.grey,
                                          child: Icon(Icons.image, size: 20),
                                        ),
                                  title: Text(
                                    productDetails['name'] ?? "Ürün",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Fiyat: ${productDetails['discountprice']} - Stok:${productDetails['piece']}",
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      deleteProduct(productId);
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void deleteProduct(String productId) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .delete();
  }
}
