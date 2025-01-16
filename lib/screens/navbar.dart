import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yemekye/screens/homepage.dart';
import 'package:yemekye/screens/restaurant_details.dart';

class ExpandableNavbar extends StatefulWidget {
  @override
  _ExpandableNavbarState createState() => _ExpandableNavbarState();
}

class _ExpandableNavbarState extends State<ExpandableNavbar> {
  int _currentIndex = 0;

  final List<String> _icons = [
    'assets/icons/home.svg',
    'assets/icons/ssearch.svg',
    'assets/icons/pie.svg',
    'assets/icons/clock.svg',
    'assets/icons/li_user.svg',
  ];

  final List<String> _labels = [
    'Home',
    'Search',
    'Favorites',
    'Profile',
    'Settings',
  ];

  final List<Widget> _pages = [
    HomeScreen(),
    HomeScreen(),
    HomeScreen(),
    HomeScreen(),
    HomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Seçili sayfa burada gösteriliyor
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Seçili öğe
        type: BottomNavigationBarType.fixed,
        items: List.generate(_icons.length, (index) {
          return BottomNavigationBarItem(
            icon: SvgPicture.asset(
              _icons[index],
              width: 24,
              height: 24,
              color: _currentIndex == index ? Colors.orange : Colors.grey,
            ),
            label: _labels[index],
          );
        }),
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Seçili öğe güncelleniyor
          });
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ExpandableNavbar(),
    debugShowCheckedModeBanner: false,
  ));
}
