import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yemekye/loginregister/login.dart';
import 'package:yemekye/screens/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthStateHandler(),
    );
  }
}

class AuthStateHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // Buradaki yazım hatası düzeltildi
          return HomeScreen(); // Oturum açık ise ana sayfaya yönlendirilir
        } else {
          return LoginPage(); // Oturum kapalı ise giriş sayfasına yönlendirilir
        }
      },
    );
  }
}
