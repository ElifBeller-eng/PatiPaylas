import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_service.dart';
import '../pages/home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  bool isLoading = false;

  Future<void> loginUser() async {
    final username = usernameCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    // 1. Boş alan kontrolü
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı adı ve şifre gerekli!")),
      );
      return;
    }

    setState(() => isLoading = true);

    // 2. Giriş isteği
    final result = await ApiService.login(username, password);

    // ⭐ KRİTİK KONTROL 1: İstek bitince sayfa hala açık mı?
    if (!mounted) return;

    setState(() => isLoading = false);

    if (result) {
      // 3. Kullanıcı adını kaydetme
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("username", username);

      // ⭐ KRİTİK KONTROL 2: Kayıt işleminden sonra sayfa hala açık mı?
      // (Burası eksikti, bu yüzden hata veriyordu)
      if (!mounted) return;

      // 4. Ana sayfaya geçiş
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      // Hata mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Giriş başarısız! Bilgileri kontrol et.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giriş Yap"),
        backgroundColor: Colors.deepPurple[200],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center( // İçeriği ortalamak için Center ekledim, daha şık durur
          child: SingleChildScrollView( // Klavye açılınca taşma olmasın diye
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // İsteğe bağlı logo veya ikon
                const Icon(Icons.pets, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 20),
                
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Kullanıcı Adı",
                    border: OutlineInputBorder(), // Kutulu tasarım
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: "Şifre",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                
                isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity, // Butonu genişlet
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple[300],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Giriş Yap", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                
                const SizedBox(height: 12),
                
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  child: const Text("Hesabın yok mu? Kayıt ol"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}