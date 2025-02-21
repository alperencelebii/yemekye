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
      title: 'Kurumsal Web',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
        title: const Text('Kurumsal Şirket'),
        actions: [
          TextButton(onPressed: () {}, child: const Text("Hakkımızda", style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () {}, child: const Text("Hizmetler", style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () {}, child: const Text("İletişim", style: TextStyle(color: Colors.white))),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 400,
              color: Colors.blueGrey,
              child: const Center(
                child: Text(
                  'Hoşgeldiniz!',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Hizmetlerimiz',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: List.generate(3, (index) {
                      return Container(
                        width: 300,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Hizmet ${index + 1}',
                            style: const TextStyle(fontSize: 24, color: Colors.white),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 50,
        color: Colors.black87,
        child: const Center(
          child: Text(
            '© 2025 Kurumsal Şirket - Tüm Hakları Saklıdır.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}