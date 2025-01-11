import 'package:flutter/material.dart';

class RestaurantDetails extends StatefulWidget {
  @override
  _RestaurantDetailsState createState() => _RestaurantDetailsState();
}

class _RestaurantDetailsState extends State<RestaurantDetails> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Resmin olduğu kısmı
          Container(
            height: MediaQuery.of(context).size.height / 2, // Fixing the image size to the top
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/rest.jpg'), // Resminizi buraya ekleyin
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Beyaz container kısmı
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red, // Beyaz renk burada kullanılıyor
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50), // Sol üst köşe
                topRight: Radius.circular(50), // Sağ üst köşe
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve ikonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Asya Fırın Kafe',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 32,
                        fontWeight: FontWeight.w600, // Semibold
                      ),
                    ),
                    Row(
                      children: [
                        // Kalp ikonu
                        IconButton(
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _isLiked = !_isLiked;
                            });
                          },
                        ),
                        // Üç nokta ikonu
                        IconButton(
                          icon: Icon(Icons.more_horiz),
                          onPressed: () {
                            // Üç nokta menüsünü açmak için kod ekleyebilirsiniz
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Diğer içerikler
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Restaurant Address: ABC Street', style: TextStyle(fontSize: 18)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Cuisine: Vietnamese, Asian', style: TextStyle(fontSize: 18)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Opening Hours: 9 AM - 9 PM', style: TextStyle(fontSize: 18)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Restaurant Address: ABC Street', style: TextStyle(fontSize: 18)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Cuisine: Vietnamese, Asian', style: TextStyle(fontSize: 18)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Opening Hours: 9 AM - 9 PM', style: TextStyle(fontSize: 18)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Restaurant Address: ABC Street', style: TextStyle(fontSize: 18)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Restaurant Address: ABC Street', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}