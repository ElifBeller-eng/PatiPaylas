import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../widgets/post_card.dart';
import '../screens/login_page.dart';
import '../screens/add_post_page.dart';
import '../screens/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> allPosts = []; // Tüm postlar burada duracak
  List<dynamic> filteredPosts = []; // Ekranda gösterilenler burada duracak
  bool isLoading = true;
  String currentUser = "";
  
  // ⭐ FİLTRE AYARLARI
  String selectedCategory = "Tümü";
  final List<String> categories = ["Tümü", "Kedi", "Köpek", "Kuş", "Diğer"];

  @override
  void initState() {
    super.initState();
    loadUserAndPosts();
  }

  Future<void> loadUserAndPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString("username") ?? "";
    
    final data = await ApiService.getPosts();

    if (!mounted) return;
    setState(() {
      currentUser = user;
      allPosts = data;
      // İlk açılışta filtre "Tümü" olduğu için hepsini göster
      filteredPosts = data; 
      isLoading = false;
    });
  }

  // ⭐ KATEGORİYE GÖRE FİLTRELEME FONKSİYONU
  void filterPosts(String category) {
    setState(() {
      selectedCategory = category;
      if (category == "Tümü") {
        filteredPosts = allPosts;
      } else {
        filteredPosts = allPosts.where((p) => p["category"] == category).toList();
      }
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
        title: Text("PatiPaylaş 🐾 | $currentUser"),
        backgroundColor: Colors.deepPurple[200],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: "Profilim",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(username: currentUser)));
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: logout)
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
          if (result == true) loadUserAndPosts();
        },
      ),
      body: Column(
        children: [
          // ❤️ 1. POLİ KÖŞESİ (SABİT)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple[50], 
              border: Border(bottom: BorderSide(color: Colors.deepPurple.shade100, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.deepPurple, width: 2)),
                  child: const CircleAvatar(radius: 25, backgroundImage: AssetImage('assets/poli.jpeg'), backgroundColor: Colors.white),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Poli'ye Sonsuz Sevgiler... ♾️❤️", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ⭐ 2. KATEGORİ BUTONLARI (YENİ)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategory == cat;
                
                // Kategori İkonu Belirle
                IconData icon;
                if (cat == "Tümü") icon = Icons.grid_view;
                else if (cat == "Kedi") icon = Icons.pets;
                else if (cat == "Köpek") icon = Icons.cruelty_free;
                else if (cat == "Kuş") icon = Icons.flutter_dash;
                else icon = Icons.public;

                return GestureDetector(
                  onTap: () => filterPosts(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurple : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.deepPurple),
                      boxShadow: isSelected ? [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))] : [],
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.deepPurple),
                        const SizedBox(width: 6),
                        Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // ❤️ 3. LİSTE KISMI (Filtrelenmiş Liste)
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text("Bu kategoride gönderi yok.", style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredPosts.length, // ⭐ filteredPosts kullanıyoruz
                      itemBuilder: (context, index) {
                        final p = filteredPosts[index];
                        return PostCard(
                          postId: p["id"],
                          title: p["title"] ?? "Başlık yok",
                          content: p["content"] ?? "İçerik yok",
                          authorUsername: p["username"] ?? "Anonim",
                          currentUser: currentUser,
                          imageUrl: p["image_url"],
                          category: p["category"] ?? "Diğer",
                          onDelete: loadUserAndPosts,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}