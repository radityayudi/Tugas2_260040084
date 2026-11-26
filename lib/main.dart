import 'package:flutter/material.dart';
import 'login_page.dart'; 

void main() {
  runApp(const KatalogBukuApp());
}

class KatalogBukuApp extends StatelessWidget {
  const KatalogBukuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Katalog Buku',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginPage(), // <-- memanggil LoginPage()
      debugShowCheckedModeBanner: false,
    );
  }
}