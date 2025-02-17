import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yemekye/loginregister/login.dart';
import 'package:yemekye/loginregister/shop_register.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordAgainController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _shopIdController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedRole = 'User';

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Container(
                  height: size.height * .9,
                  width: size.width * .85,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(.75),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(.75),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTextField(
                            _nameController, Icons.person, 'Ad Soyad'),
                        _buildTextField(
                            _usernameController, Icons.person, 'Kullanıcı Adı'),
                        _buildTextField(_emailController, Icons.mail, 'E-Mail'),
                        _buildTextField(_phoneNumberController, Icons.phone,
                            'Telefon Numarası'),
                        _buildTextField(
                            _passwordController, Icons.vpn_key, 'Parola',
                            isPassword: true),
                        _buildTextField(_passwordAgainController, Icons.vpn_key,
                            'Parola Tekrar',
                            isPassword: true),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          items: ['User', 'Seller'].map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role,
                                  style: TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                          dropdownColor: Colors.blue,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person, color: Colors.white),
                            hintText: "Kullanıcı Türü",
                            hintStyle: TextStyle(color: Colors.white),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white)),
                          ),
                        ),
                        if (_selectedRole == 'Seller')
                          _buildTextField(
                              _shopIdController, Icons.store, 'Mağaza ID'),
                        SizedBox(height: size.height * 0.08),
                        InkWell(
                          onTap: () => _registerUser(),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Center(
                                child: Text("Kaydet",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _registerUser() async {
    String name = _nameController.text.trim();
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String passwordAgain = _passwordAgainController.text.trim();
    String phoneNumber = _phoneNumberController.text.trim();
    String shopId = _shopIdController.text.trim();

    if (name.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        passwordAgain.isEmpty) {
      _showErrorMessage("Tüm alanları doldurun");
      return;
    }
    if (password != passwordAgain) {
      _showErrorMessage("Parolalar eşleşmiyor");
      return;
    }
    if (_selectedRole == 'Seller' && shopId.isEmpty) {
      _showErrorMessage("Mağaza ID gerekli");
      return;
    }

    try {
      if (_selectedRole == 'Seller') {
        DocumentSnapshot shopDoc = await FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .get();
        if (!shopDoc.exists) {
          _showErrorMessage("Geçersiz Mağaza ID");
          return;
        }
      }

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      String userId = userCredential.user!.uid;

      CollectionReference collection = FirebaseFirestore.instance
          .collection(_selectedRole == 'Seller' ? 'sellers' : 'users');

      await collection.doc(userId).set({
        'name': name,
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': _selectedRole,
        if (_selectedRole == 'Seller') 'shopId': shopId,
      });

      if (_selectedRole == 'Seller') {
        await FirebaseFirestore.instance
            .collection('shops')
            .doc(shopId)
            .update({
          'sellers': FieldValue.arrayUnion([userId]),
        });
      }

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LoginPage()));
    } catch (e) {
      _showErrorMessage("Kayıt sırasında hata oluştu: $e");
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red),
    );
  }
}

Widget _buildTextField(
  TextEditingController controller,
  IconData prefixIcon,
  String hintText, {
  bool isPassword = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      keyboardType:
          isPassword ? TextInputType.text : TextInputType.emailAddress,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon, color: Colors.white),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    ),
  );
}
