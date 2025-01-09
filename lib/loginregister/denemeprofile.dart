import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Pet Profile'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Geri düğmesi işlemi
            },
          ),
        ),
        body: anademeelik(),
      ),
    );
  }
}

class anademeelik extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/images/pets.png'),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maxi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Dog | Border Collie',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(context, 'About', true),
                _buildTabItem(context, 'Health', false),
                _buildTabItem(context, 'Nutrition', false),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Appearance and distinctive signs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Brown-Dark-White mix, with light eyebrows shape and a heart shaped patch on left paw.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            _buildInfoRow('Gender', 'Male'),
            _buildInfoRow('Size', 'Medium'),
            _buildInfoRow('Weight', '22.2 kg'),
            SizedBox(height: 24),
            Text(
              'Important Dates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildInfoRow('Birthday', '3 November 2019'),
            _buildInfoRow('Adoption Day', '6 January 2020'),
            SizedBox(height: 24),
            Text(
              'Caretakers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildCaretakerRow('Esther Howard', 'esther.howard@gmail.com'),
            _buildCaretakerRow('Guy Hawkins', 'guyhawkins@gmail.com'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Edit işlemi
              },
              child: Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, String label, bool isSelected) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey,
          ),
        ),
        if (isSelected)
          Container(
            margin: EdgeInsets.only(top: 8),
            height: 4,
            width: 60,
            color: Colors.amber,
          ),
      ],
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaretakerRow(String name, String email) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage('assets/images/pets.png'), // Bakıcıların resmi de buradan alınabilir
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                email,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}