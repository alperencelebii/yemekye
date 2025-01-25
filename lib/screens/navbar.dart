import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yemekye/adminpanel/admin.dart';
import 'package:yemekye/map/map.dart';
import 'package:yemekye/map/user_map.dart';
import 'package:yemekye/qrandsepet/shops/qrcodescan.dart';
import 'package:yemekye/screens/search.dart';
import 'package:yemekye/yoneticipanel/Yoneticipanel.dart';
import 'package:yemekye/screens/homepage.dart';
import 'package:yemekye/qrandsepet/user/sepet.dart';

class ExpandableNavbar extends StatefulWidget {
  @override
  _ExpandableNavbarState createState() => _ExpandableNavbarState();
}

class _ExpandableNavbarState extends State<ExpandableNavbar> {
  int _currentIndex = 0;

  final List<String> _icons = [
    'assets/icons/home.svg',
    'assets/icons/ssearch.svg',
    'assets/icons/ssearch.svg',
    'assets/icons/pie.svg',
    'assets/icons/clock.svg',
    'assets/icons/li_user.svg',
  ];

  final List<String> _labels = [
    'Home',
    'Search',
    'arama',
    'Favorites',
    'History',
    'Profile',
  ];

  final List<Widget> _pages = [
    HomeScreen(),
    AdminPanel(),
    GoogleMapsExample(),
    QRCodeScannerScreen(),
    SepetScreen(),
    Yonetici()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 255, 255)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icons.length, (index) {
              final isSelected = _currentIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFFF9A602) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        _icons[index],
                        width: 24,
                        height: 24,
                        color: isSelected
                            ? Color.fromARGB(255, 255, 255, 255)
                            : const Color.fromARGB(255, 0, 0, 0),
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            _labels[index],
                            style: const TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
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
