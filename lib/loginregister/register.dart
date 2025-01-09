import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yemekye/loginregister/login.dart';

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
  final TextEditingController _phoneNumberController =
      TextEditingController(); // Telefon numarası için kontrolcü

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Container(
                height: size.height * .7,
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
                  child: Center(
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
                        SizedBox(
                          height: size.height * 0.08,
                        ),
                        InkWell(
                          onTap: () {
                            _registerUser();
                          },
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
                                child: Text(
                                  "Kaydet",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
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
          ),
          Padding(
            padding:
                EdgeInsets.only(top: size.height * .06, left: size.width * .02),
            child: Align(
              alignment: Alignment.topLeft,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_outlined,
                      color: Colors.blue.withOpacity(.75),
                      size: 26,
                    ),
                  ),
                  SizedBox(
                    width: size.width * 0.3,
                  ),
                  Text(
                    "Kayıt ol",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.blue.withOpacity(.75),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
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
        style: TextStyle(
          color: Colors.white,
        ),
        cursorColor: Colors.white,
        keyboardType: TextInputType.emailAddress,
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(
            prefixIcon,
            color: Colors.white,
          ),
          hintText: hintText,
          prefixText: ' ',
          hintStyle: TextStyle(color: Colors.white),
          focusColor: Colors.white,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white,
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white,
            ),
          ),
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
    String phoneNumber = _phoneNumberController.text.trim(); // Telefon numarası

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

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcıyı Firestore'a kaydet
      await usersCollection.doc(userCredential.user!.uid).set({
        'name': name,
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber, // Firestore'a telefon numarasını ekle
      });

      // Başarılı kayıt işlemi sonrasında, kullanıcıyı giriş sayfasına yönlendirin
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(),
        ),
      );
    } catch (e) {
      // Kayıt işlemi sırasında bir hata oluştuğunda burada işlemleri gerçekleştirin
      _showErrorMessage("Kayıt sırasında bir hata oluştu: $e");
    }
  }

  void _showErrorMessage(String message) {
    // Hata mesajını kullanıcıya göstermek için uygun bir yöntem kullanabilirsiniz (örneğin, bir snackbar veya Toast mesajı)
    print("Hata: $message");
  }
}
