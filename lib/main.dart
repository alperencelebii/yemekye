import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yemekye/adminpanel/weppanel/index.dart';
import 'package:yemekye/loginregister/login.dart';
import 'package:yemekye/yoneticipanel/Yoneticipanel.dart';
import 'package:yemekye/screens/homepage.dart';
import 'package:yemekye/adminpanel/admin.dart';
import 'package:yemekye/screens/navbar.dart';
import 'package:yemekye/screens/restaurant_details.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(); // Firebase'i yalnızca bir kez başlat

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YemekYe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: AuthStateHandler(),
    );
  }
}

class AuthStateHandler extends StatefulWidget {
  @override
  _AuthStateHandlerState createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  late Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Bir hata oluştu: ${snapshot.error}',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return ExpandableNavbar(); // Kullanıcı giriş yaptıysa Navbar göster
        } else {
          return LoginPage(); // Kullanıcı giriş yapmadıysa Login sayfası
        }
      },
    );
  }
}