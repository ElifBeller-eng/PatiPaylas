import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController contentCtrl = TextEditingController();

  // ⭐ KATEGORİ AYARLARI
  String selectedCategory = "Kedi"; // Varsayılan
  final List<String> categories = ["Kedi", "Köpek", "Kuş", "Diğer"];

  bool isLoading = false;

  File? mobileImageFile;
  Uint8List? webImageBytes;
  String? webImageName;

  final ImagePicker picker = ImagePicker();

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        webImageBytes = bytes;
        webImageName = picked.name;
        mobileImageFile = null;
      });
    } else {
      setState(() {
        mobileImageFile = File(picked.path);
        webImageBytes = null;
        webImageName = null;
      });
    }
  }

  Future<void> savePost() async {
    final title = titleCtrl.text.trim();
    final content = contentCtrl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Başlık ve içerik gerekli!")),
      );
      return;
    }

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString("username") ?? "Anonim"; 

    final result = await ApiService.addPostWithImage(
      title,
      content,
      username,
      selectedCategory, // ⭐ Seçilen kategori servise gidiyor
      mobileImageFile,
      webImageBytes,
      webImageName,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gönderi eklenemedi!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Gönderi"),
        backgroundColor: Colors.deepPurple[200],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Başlık",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              
              // ⭐ KATEGORİ SEÇİM KUTUSU (DROPDOWN)
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Kategori Seç",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Row(
                      children: [
                        // Kategoriye göre ikon gösterelim
                        Icon(
                          category == "Kedi" ? Icons.pets :
                          category == "Köpek" ? Icons.cruelty_free :
                          category == "Kuş" ? Icons.flutter_dash : Icons.public,
                          color: Colors.deepPurple,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue!;
                  });
                },
              ),

              const SizedBox(height: 16),
              
              TextField(
                controller: contentCtrl,
                decoration: const InputDecoration(
                  labelText: "İçerik",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.text_fields),
                ),
                maxLines: 4,
              ),

              const SizedBox(height: 20),

              Center(
                child: ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text("Fotoğraf Seç"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (kIsWeb && webImageBytes != null)
                Center(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(webImageBytes!, height: 200))),

              if (!kIsWeb && mobileImageFile != null)
                Center(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(mobileImageFile!, height: 200))),

              const SizedBox(height: 30),

              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: savePost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple[300],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Gönderiyi Paylaş", style: TextStyle(fontSize: 16)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}