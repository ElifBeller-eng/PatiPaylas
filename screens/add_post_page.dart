import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController contentCtrl = TextEditingController();

  bool isLoading = false;

  File? mobileImageFile;
  Uint8List? webImageBytes;
  String? webImageName;

  final ImagePicker picker = ImagePicker();

  // ----------------------------------------------------
  // Fotoğraf seçme
  // ----------------------------------------------------
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      // Web için
      final bytes = await picked.readAsBytes();
      setState(() {
        webImageBytes = bytes;
        webImageName = picked.name;
        mobileImageFile = null;
      });
    } else {
      // Mobil için
      setState(() {
        mobileImageFile = File(picked.path);
        webImageBytes = null;
        webImageName = null;
      });
    }
  }

  // ----------------------------------------------------
  // Gönderi kaydetme
  // ----------------------------------------------------
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

    final result = await ApiService.addPostWithImage(
      title,
      content,
      mobileImageFile,
      webImageBytes,
      webImageName,
    );

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
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Başlık"),
              ),
              TextField(
                controller: contentCtrl,
                decoration: const InputDecoration(labelText: "İçerik"),
                maxLines: 4,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: pickImage,
                child: const Text("Fotoğraf Seç"),
              ),

              const SizedBox(height: 10),

              if (kIsWeb && webImageBytes != null)
                Image.memory(webImageBytes!, height: 200),

              if (!kIsWeb && mobileImageFile != null)
                Image.file(mobileImageFile!, height: 200),

              const SizedBox(height: 30),

              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: savePost,
                      child: const Text("Gönderiyi Paylaş"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
