import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  User? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      setState(() {
        _nameController.text = userDoc['name'] ?? "";
        _emailController.text = _user!.email ?? "";
      });
    }
  }

  Future<void> _updateUserName() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': _nameController.text,
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("İsim başarıyla güncellendi!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateEmail() async {
    if (_emailController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      await _user!.updateEmail(_emailController.text);
      await _firestore.collection('users').doc(_user!.uid).update({
        'email': _emailController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("E-posta başarıyla güncellendi!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      await _user!.updatePassword(_newPasswordController.text);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Şifre başarıyla güncellendi!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profili Düzenle",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileCard(),
            SizedBox(height: 20),
            _buildInputSection("İsim", _nameController, _updateUserName),
            _buildInputSection("E-Posta", _emailController, _updateEmail),
            _buildInputSection(
                "Yeni Şifre", _newPasswordController, _updatePassword,
                obscureText: true),
            SizedBox(height: 20),
            if (_isLoading) CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 50, color: Colors.blueAccent),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nameController.text,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                _emailController.text,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(
      String label, TextEditingController controller, VoidCallback onSave,
      {bool obscureText = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              labelStyle: TextStyle(
                  color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 14),
              elevation: 4,
            ),
            child: Center(
              child: Text(
                "$label Güncelle",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
