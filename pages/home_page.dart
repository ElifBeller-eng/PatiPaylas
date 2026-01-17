import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_service.dart';
import '../widgets/post_card.dart';
import '../screens/login_page.dart';
import '../screens/add_post_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> posts = [];
  bool isLoading = true;

  String username = "";

  @override
  void initState() {
    super.initState();
    loadUser();
    loadPosts();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      username = prefs.getString("username") ?? "";
    });
  }

  Future<void> loadPosts() async {
    final data = await ApiService.getPosts();
    if (!mounted) return;
    setState(() {
      posts = data;
      isLoading = false;
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("username");

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PatiPaylaş 🐾 | Merhaba $username 👋"),
        backgroundColor: Colors.deepPurple[200],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple[200],
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPostPage()),
          );

          if (result == true) {
            loadPosts(); // Yeni post atılınca listeyi yenile
          }
        },
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final p = posts[index];

                return PostCard(
                  name: p["title"] ?? "Başlık yok",
                  content: p["content"] ?? "İçerik yok",
                  // ⭐ DATABASE'DEN GELEN İSMİ KOYUYORUZ
                  username: p["username"] ?? "Anonim", 
                  imageUrl: p["image_url"],
                );
              },
            ),
    );
  }
}