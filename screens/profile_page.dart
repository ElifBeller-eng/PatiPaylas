import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/post_card.dart';

class ProfilePage extends StatefulWidget {
  final String username;

  const ProfilePage({super.key, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> userInfo = {};
  List<dynamic> myPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    final info = await ApiService.getUserInfo(widget.username);
    final posts = await ApiService.getUserPosts(widget.username);

    if (!mounted) return;
    setState(() {
      userInfo = info;
      myPosts = posts;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilim 👤"),
        backgroundColor: Colors.deepPurple[200],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // --- ÜST KISIM (BİLGİLER) ---
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.deepPurple[50],
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.deepPurple[300],
                        child: Text(
                          widget.username.isNotEmpty ? widget.username[0].toUpperCase() : "?",
                          style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "@${widget.username}",
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              userInfo["email"] ?? "E-posta yok",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.deepPurple.shade100),
                              ),
                              child: Text(
                                "📸 ${userInfo['post_count']} Gönderi",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),

                // --- ALT KISIM (FOTOĞRAF GALERİSİ) ---
                Expanded(
                  child: myPosts.isEmpty
                      ? const Center(child: Text("Henüz hiç paylaşım yapmadın."))
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, 
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: myPosts.length,
                          itemBuilder: (context, index) {
                            final p = myPosts[index];
                            
                            // URL Düzeltme
                            String imgUrl = "";
                            if (p["image_url"] != null) {
                              imgUrl = "${ApiService.baseUrl}${p["image_url"]}";
                              if (kIsWeb && imgUrl.contains("192.168.1.101")) {
                                imgUrl = imgUrl.replaceAll("192.168.1.101", "127.0.0.1");
                              }
                            }

                            return GestureDetector(
                              onTap: () {
                                // Detay sayfasına git (PostCard kullanarak)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => Scaffold(
                                      appBar: AppBar(title: Text(p["title"] ?? "Detay")),
                                      body: SingleChildScrollView(
                                        child: PostCard(
                                          postId: p["id"],
                                          title: p["title"] ?? "Başlık Yok",
                                          content: p["content"] ?? "İçerik Yok",
                                          authorUsername: widget.username,
                                          currentUser: widget.username,
                                          imageUrl: p["image_url"],
                                          // ⭐ HATA BURADA ÇÖZÜLDÜ: Kategori eklendi
                                          category: p["category"] ?? "Diğer",
                                          // Silinirse sayfayı yenile:
                                          onDelete: loadProfileData, 
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[300]),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}