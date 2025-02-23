import 'package:flutter/material.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SonDilim',
      theme: ThemeData(
        primarySwatch: Colors.orange,

      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SonDilim', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeroSection(),
            _buildMissionSection(),
            _buildStatisticsSection(),
            _buildHowItWorksSection(),
            _buildContactSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {

        },
        child: const Icon(Icons.business, color: Colors.white),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.black54],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Text(
          'İsrafı Önle, Geleceği Kurtar!',

          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMissionSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildSectionTitle('Misyonumuz'),
          const SizedBox(height: 10),
          const Text(
            'SonDilim, gıda israfını önlemek ve ekonomik zorluk yaşayan bireylere uygun fiyatlarla ürün sunmak için kurulmuş bir platformdur.',
            style: TextStyle(fontSize: 18, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildSectionTitle('İstatistikler'),
          const SizedBox(height: 10),
          const Text(
            'Türkiyede yılda 7.7 milyon ton gıda israf ediliyor. SonDilim ile bu israfı azaltmayı hedefliyoruz.',
            style: TextStyle(fontSize: 18, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildSectionTitle('Nasıl Çalışır?'),
          const SizedBox(height: 10),
          _buildStep('1. İşletme Kaydı', 'İşletmeler platforma kayıt olur ve ürünlerini listeler.'),
          _buildStep('2. Kullanıcılar Ürünleri Görüntüler', 'Kullanıcılar, yakınlarındaki işletmelerdeki fırsatları görüntüler.'),
          _buildStep('3. QR Kod ile Satın Al', 'Kullanıcılar, QR kod ile ürünleri satın alır ve israf önlenir.'),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black,
      child: Column(
        children: [
          _buildSectionTitle('İletişim', color: Colors.white),
          const SizedBox(height: 10),
          const Text(
            'Bizimle iletişime geçmek için aşağıdaki formu doldurun.',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          _buildTextField('Adınız'),
          _buildTextField('E-posta'),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Gönder'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String title, String description) {
    return ListTile(
      leading: const Icon(Icons.check_circle, color: Colors.orangeAccent),

      
    );
  }

  Widget _buildSectionTitle(String title, {Color color = Colors.black}) {
    return Text(
      title,
      
    );
  }

  Widget _buildTextField(String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}