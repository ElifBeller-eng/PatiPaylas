import 'package:flutter/material.dart';
import 'screens/login_page.dart';

void main() {
  runApp(const PatiPaylasApp());
}

class PatiPaylasApp extends StatelessWidget {
  const PatiPaylasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PatiPaylaş 🐾',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),   // 🔥 ARTIK BURADA LOGIN AÇILIYOR
    );
  }
}
