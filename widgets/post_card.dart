import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_saver/file_saver.dart';
import '../api_service.dart';

class PostCard extends StatefulWidget {
  final int postId;
  final String title;
  final String content;
  final String authorUsername;
  final String currentUser;
  final String? imageUrl;
  final String category; // ⭐ Kategori bilgisi
  final VoidCallback? onDelete; // ⭐ Silinince sayfayı yenilemek için tetikleyici

  const PostCard({
    super.key,
    required this.postId,
    required this.title,
    required this.content,
    required this.authorUsername,
    required this.currentUser,
    this.imageUrl,
    required this.category,
    this.onDelete,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLiked = false;
  int likeCount = 0;
  List<String> likers = [];

  @override
  void initState() {
    super.initState();
    loadLikes();
  }

  Future<void> loadLikes() async {
    final users = await ApiService.getLikes(widget.postId);
    if (!mounted) return;
    setState(() {
      likers = users;
      likeCount = users.length;
      isLiked = users.contains(widget.currentUser);
    });
  }

  Future<void> toggleLike() async {
    setState(() {
      isLiked = !isLiked;
      if (isLiked) { likeCount++; likers.add(widget.currentUser); } 
      else { likeCount--; likers.remove(widget.currentUser); }
    });
    await ApiService.toggleLike(widget.postId, widget.currentUser);
    loadLikes();
  }

  // ⭐ SİLME İŞLEMİ
  Future<void> deletePost() async {
    // Emin misin diye sor
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gönderiyi Sil"),
        content: const Text("Bu gönderiyi silmek istediğine emin misin?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sil", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deletePost(widget.postId, widget.currentUser);
      if (success && widget.onDelete != null) {
        widget.onDelete!(); // Sayfayı yenileme emri ver
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gönderi silindi 👋")));
      }
    }
  }

  void showLikersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Beğenenler ❤️"),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: likers.isEmpty 
            ? const Center(child: Text("Henüz kimse beğenmedi."))
            : ListView.builder(itemCount: likers.length, itemBuilder: (context, index) => ListTile(leading: const Icon(Icons.person), title: Text(likers[index]))),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat"))],
      ),
    );
  }

  void showCommentsSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => CommentsSheet(postId: widget.postId, currentUser: widget.currentUser));
  }

  @override
  Widget build(BuildContext context) {
    String fullImageUrl = "";
    if (widget.imageUrl != null) {
      if (widget.imageUrl!.startsWith("http")) {
        fullImageUrl = widget.imageUrl!;
        if (kIsWeb && fullImageUrl.contains("192.168.1.101")) fullImageUrl = fullImageUrl.replaceAll("192.168.1.101", "127.0.0.1");
      } else {
        fullImageUrl = "${ApiService.baseUrl}${widget.imageUrl}";
      }
    }

    // ⭐ SİLME BUTONU GÖRÜNSÜN MÜ?
    bool isMyPost = widget.currentUser == widget.authorUsername;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple[100],
                  child: Text(widget.authorUsername.isNotEmpty ? widget.authorUsername[0].toUpperCase() : "?", style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("@${widget.authorUsername}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      // ⭐ KATEGORİ ETİKETİ
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.deepPurple[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.deepPurple.shade100)),
                            child: Text(widget.category, style: TextStyle(fontSize: 10, color: Colors.deepPurple[700], fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(widget.title, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
                        ],
                      ),
                    ],
                  ),
                ),
                // ⭐ SİLME BUTONU (Sadece kendi postunsa)
                if (isMyPost)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: deletePost,
                  ),
              ],
            ),
          ),

          if (widget.imageUrl != null)
            GestureDetector(
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImagePage(imageUrl: fullImageUrl))); },
              child: Hero(
                tag: fullImageUrl,
                child: Container(
                  height: 300, width: double.infinity, color: Colors.black, 
                  child: Image.network(fullImageUrl, fit: BoxFit.contain, 
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.error)),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    },
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(widget.content, style: const TextStyle(fontSize: 15)),
          ),

          if (likeCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: showLikersDialog,
                child: Text("$likeCount kişi beğendi", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              ),
            ),

          const Divider(height: 1),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: toggleLike,
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey),
                label: Text(isLiked ? "Beğendin" : "Beğen", style: TextStyle(color: isLiked ? Colors.red : Colors.grey)),
              ),
              TextButton.icon(
                onPressed: showCommentsSheet,
                icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                label: const Text("Yorum Yap", style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}

// (CommentsSheet ve FullScreenImagePage aynı kaldığı için yer kaplamaması adına tekrar yazmıyorum, eski dosyanın altındakiler kalabilir.)
// Ancak kopyala-yapıştır yaparken hata olmasın diye CommentsSheet'i de ekliyorum:

class CommentsSheet extends StatefulWidget {
  final int postId;
  final String currentUser;
  const CommentsSheet({super.key, required this.postId, required this.currentUser});
  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController commentCtrl = TextEditingController();
  List<dynamic> comments = [];
  bool isLoading = true;
  @override
  void initState() { super.initState(); loadComments(); }
  Future<void> loadComments() async {
    final data = await ApiService.getComments(widget.postId);
    if (!mounted) return;
    setState(() { comments = data; isLoading = false; });
  }
  Future<void> sendComment() async {
    final text = commentCtrl.text.trim(); if (text.isEmpty) return;
    commentCtrl.clear();
    await ApiService.addComment(widget.postId, widget.currentUser, text);
    loadComments();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      height: 500,
      child: Column(children: [
        const Text("Yorumlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(),
        Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : comments.isEmpty ? const Center(child: Text("İlk yorumu sen yap! 👇")) : ListView.builder(itemCount: comments.length, itemBuilder: (context, index) { final c = comments[index]; return ListTile(leading: CircleAvatar(child: Text(c["username"][0].toUpperCase())), title: Text(c["username"], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(c["text"])); })),
        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Expanded(child: TextField(controller: commentCtrl, decoration: const InputDecoration(hintText: "Yorum yaz...", border: OutlineInputBorder()))), IconButton(icon: const Icon(Icons.send, color: Colors.deepPurple), onPressed: sendComment)]))
      ]),
    );
  }
}

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
        String fileName = "pati_${DateTime.now().millisecondsSinceEpoch}";
        await FileSaver.instance.saveFile(name: fileName, bytes: response.bodyBytes, mimeType: MimeType.jpeg);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İndirildi! ✅")));
      }
    } catch (e) { } finally { if (mounted) setState(() => isDownloading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white), actions: [isDownloading ? const CircularProgressIndicator() : IconButton(icon: const Icon(Icons.download), onPressed: downloadImage)]), body: Center(child: Hero(tag: widget.imageUrl, child: InteractiveViewer(child: Image.network(widget.imageUrl)))));
  }
}