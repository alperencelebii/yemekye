import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SonDilim', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
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
          // İşletme girişi sayfasına yönlendirme
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => BusinessLoginPage()));
        },
        child: Icon(Icons.business, color: Colors.white),
        backgroundColor: Color(0xFFFFA500),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: AssetImage(
              'assets/images/hero_image.jpg'), // Projeye uygun bir görsel
          fit: BoxFit.cover,
          opacity: 0.6,
        ),
      ),
      child: Center(
        child: Text(
          'İsrafı Önle, Geleceği Kurtar!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
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
          Text(
            'Misyonumuz',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          Text(
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
      color: Color(0xFFFFA500).withOpacity(0.1),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'İstatistikler',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Türkiye\'de yılda 7.7 milyon ton gıda israf ediliyor. SonDilim ile bu israfı azaltmayı hedefliyoruz.',
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
          Text(
            'Nasıl Çalışır?',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          _buildStep('1. İşletme Kaydı',
              'İşletmeler platforma kayıt olur ve ürünlerini listeler.'),
          _buildStep('2. Kullanıcılar Ürünleri Görüntüler',
              'Kullanıcılar, yakınlarındaki işletmelerdeki fırsatları görüntüler.'),
          _buildStep('3. QR Kod ile Satın Al',
              'Kullanıcılar, QR kod ile ürünleri satın alır ve israf önlenir.'),
        ],
      ),
    );
  }

  Widget _buildStep(String title, String description) {
    return ListTile(
      leading: Icon(Icons.check_circle, color: Color(0xFFFFA500)),
      title: Text(title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      subtitle: Text(description, style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildContactSection() {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'İletişim',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Bizimle iletişime geçmek için aşağıdaki formu doldurun.',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              hintText: 'Adınız',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'E-posta',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // İletişim formu gönderme işlemi
            },
            child: Text('Gönder'),
            style: ElevatedButton.styleFrom(iconColor: Color(0xFFFFA500)),
          ),
        ],
      ),
    );
  }
}

class BusinessLoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İşletme Girişi', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Text('İşletme Girişi Sayfası'),
      ),
    );
  }
}
