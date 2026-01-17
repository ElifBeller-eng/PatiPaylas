import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_saver/file_saver.dart';
import '../api_service.dart';

class PostCard extends StatefulWidget {
  final String name;     // Başlık
  final String content;  // İçerik
  final String username; // ⭐ YENİ: Paylaşan kişi
  final String? imageUrl;

  const PostCard({
    super.key,
    required this.name,
    required this.content,
    required this.username, // ⭐ Zorunlu
    this.imageUrl,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLiked = false; // Beğenildi mi durumu

  @override
  Widget build(BuildContext context) {
    // URL Düzeltme
    String fullImageUrl = "";
    if (widget.imageUrl != null) {
      if (widget.imageUrl!.startsWith("http")) {
        fullImageUrl = widget.imageUrl!;
        if (kIsWeb && fullImageUrl.contains("192.168.1.101")) {
          fullImageUrl = fullImageUrl.replaceAll("192.168.1.101", "127.0.0.1");
        }
      } else {
        fullImageUrl = "${ApiService.baseUrl}${widget.imageUrl}";
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. ÜST KISIM: KULLANICI ADI ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                // Profil Resmi Yerine Harf
                CircleAvatar(
                  backgroundColor: Colors.deepPurple[100],
                  child: Text(
                    widget.username.isNotEmpty ? widget.username[0].toUpperCase() : "?",
                    style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                // İsim ve Başlık
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "@${widget.username}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      widget.name, // Başlık buraya geldi
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- 2. FOTOĞRAF ---
          if (widget.imageUrl != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImagePage(imageUrl: fullImageUrl),
                  ),
                );
              },
              child: Hero(
                tag: fullImageUrl,
                child: Image.network(
                  fullImageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        height: 200, 
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.error, color: Colors.grey)),
                      ),
                ),
              ),
            ),

          // --- 3. İÇERİK METNİ ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(widget.content, style: const TextStyle(fontSize: 15)),
          ),

          const Divider(height: 1),

          // --- 4. ALT KISIM: BUTONLAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // BEĞEN BUTONU
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      isLiked = !isLiked;
                    });
                  },
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  label: Text(
                    isLiked ? "Beğendin" : "Beğen",
                    style: TextStyle(color: isLiked ? Colors.red : Colors.grey),
                  ),
                ),
                // YORUM BUTONU
                TextButton.icon(
                  onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Yorum özelliği yakında! 🚀")),
                    );
                  },
                  icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                  label: const Text("Yorum Yap", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// FULL SCREEN VE İNDİRME SAYFASI (HATASIZ HALİ)
class FullScreenImagePage extends StatefulWidget {
  final String imageUrl;
  const FullScreenImagePage({super.key, required this.imageUrl});
  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  bool isDownloading = false;

  Future<void> downloadImage() async {
    setState(() => isDownloading = true);
    try {
      var response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        String fileName = "pati_post_${DateTime.now().millisecondsSinceEpoch}";
        // ext parametresini SİLDİK, mimeType kullanıyoruz
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: response.bodyBytes,
          mimeType: MimeType.jpeg,
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İndirildi! ✅")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          isDownloading
              ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white))
              : IconButton(icon: const Icon(Icons.download), onPressed: downloadImage),
        ],
      ),
      body: Center(
        child: Hero(
          tag: widget.imageUrl,
          child: InteractiveViewer(child: Image.network(widget.imageUrl)),
        ),
      ),
    );
  }
}