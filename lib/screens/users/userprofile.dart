import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yemekye/loginregister/login.dart';
import 'package:yemekye/screens/users/coupenlist.dart';
import 'package:yemekye/screens/users/profileedit.dart';
import 'package:yemekye/screens/users/userpastorders.dart'; // Kişisel Bilgiler Düzenleme

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String _userName = "Yükleniyor...";
  String _email = "";

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      setState(() {
        _userName = userDoc['name'] ?? "Bilinmiyor";
        _email = _user!.email ?? "Bilinmiyor";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text("Profil"),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildUserInfoSection(),
            SizedBox(height: 16),
            _buildProfileSection(),
            SizedBox(height: 16),
            _buildInfoSection(),
            SizedBox(height: 16),
            _buildLogoutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.account_circle, size: 50, color: Colors.orange),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _email,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return _buildContainer(
      children: [
        _buildListTile(Icons.person, "Kişisel Bilgiler", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileEditPage()),
          );
        }),
        _buildListTile(Icons.local_offer, "Kuponlarım", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CouponListPage()),
          );
        }),
        _buildListTile(Icons.support_agent, "Bize Ulaşın", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserPastOrdersScreen()),
          );
        }),
        _buildListTile(Icons.inventory_outlined, "Arkadaşını Davet Et", () {
          _shareInviteLink(context);
        }),
      ],
    );
  }

  Widget _buildInfoSection() {
    return _buildContainer(
      children: [
        _buildListTile(Icons.info, "Aydınlatma Metni", () {}),
      ],
    );
  }

  Widget _buildLogoutSection() {
    return _buildContainer(
      children: [
        _buildListTile(Icons.logout, "Çıkış Yap", () async {
          await _auth.signOut();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
          );
        }, color: Colors.red),
        _buildListTile(Icons.delete, "Hesabı Sil", () {
          _showDeleteConfirmation();
        }, color: Colors.red),
      ],
    );
  }

  Widget _buildContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap,
      {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hesabı Sil"),
        content: Text("Hesabınızı silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            child: Text("İptal"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Evet"),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Firestore'dan kullanıcı verisini sil
        await _firestore.collection('users').doc(user.uid).delete();

        // Firebase Authentication'dan kullanıcıyı sil
        await user.delete();

        // Kullanıcıyı çıkış ekranına yönlendir
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hesabınız başarıyla silindi.")),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }
}

Future<void> _shareInviteLink(BuildContext context) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

  Map<String, dynamic>? userData =
      userDoc.data() as Map<String, dynamic>?; // Güvenli veri okuma

  String inviteCode =
      userData?['inviteCode'] ?? "INV-${user.uid.substring(0, 6)}";

  // Eğer kullanıcıda kayıtlı bir davet kodu yoksa, Firestore'a ekle
  if (userData == null || !userData.containsKey('inviteCode')) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'inviteCode': inviteCode},
      SetOptions(merge: true),
    );
  }

  // 📌 Özel URI formatı (Uygulamayı açacak link)
  String appLink = "yemekye://open?code=$inviteCode";
  String storeLink =
      "https://play.google.com/store/apps/details?id=com.example.yourapp";

  String inviteMessage =
      "Merhaba! Yemekye uygulamasını indir ve 10 TL kazan! \n$appLink \nEğer uygulama açılmazsa buradan indir: $storeLink";

  Clipboard.setData(ClipboardData(text: inviteMessage));

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Davet bağlantısı kopyalandı!")),
  );

  // 📌 Önce uygulamanın açılıp açılamayacağını kontrol et
  bool canOpen = await canLaunchUrl(Uri.parse(appLink));
  if (canOpen) {
    await launchUrl(Uri.parse(appLink), mode: LaunchMode.externalApplication);
  } else {
    await launchUrl(Uri.parse(storeLink), mode: LaunchMode.externalApplication);
  }
}
