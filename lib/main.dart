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
      title: 'YemekYe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
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
        // Yükleniyor durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Hata varsa, hata mesajı göster
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Bir hata oluştu: ${snapshot.error}')),
          );
        }

        // Kullanıcı oturum açmışsa, ana sayfaya yönlendir
        if (snapshot.hasData) {
          return HomeScreen();
        } else {
          return LoginPage();
        }
      },
    );
  }
}