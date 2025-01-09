import 'package:flutter/material.dart';
import 'package:yemekye/components/models/restaurant_list_card.dart';
import 'package:yemekye/components/models/yatay_restaurant_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ana Sayfa'),
      ),
      body: Center(
        child: YatayRestaurantCard(),
      ),
    );
  }
}
