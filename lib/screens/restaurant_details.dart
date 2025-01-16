import 'package:flutter/material.dart';
import 'package:yemekye/components/models/product_card.dart';

class RestaurantDetails extends StatefulWidget {
  @override
  _RestaurantDetailsState createState() => _RestaurantDetailsState();
}

class _RestaurantDetailsState extends State<RestaurantDetails> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plandaki resim
          Container(
            height: MediaQuery.of(context).size.height *
                0.4, // Ekranın %40'ını kaplar
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/rest.jpg'), // Resim dosyasını ekle
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Beyaz container kısmı
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height *
                  0.65, // Ekranın alt %65'ini kaplar
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve ikonlar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Coffe House",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'BeVietnamPro',
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isLiked ? Colors.red : Colors.black,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isLiked = !_isLiked;
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.more_horiz),
                              color: Color(0xFF1D1D1D),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF22BA61)),
                        SizedBox(width: 4),
                        Container(
                          width: 220, // Genişliği sınırlandırın
                          child: Text(
                            "Beyazıt, 9 Mayıs 90 Cd. 20/A, 06750 Akyurt/Ankara",
                            style: TextStyle(
                              fontSize: 14,
                            ),
                            softWrap: true, // Satır kırılmasını etkinleştirir
                            overflow: TextOverflow
                                .visible, // Metnin görünürlüğünü ayarlar
                          ),
                        ),
                        GestureDetector(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            width: 28,
                            height: 28,
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(""),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      ' Pastalar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),

                    ProductCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
