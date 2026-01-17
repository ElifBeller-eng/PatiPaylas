import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb için
import 'package:http/http.dart' as http;

class ApiService {
  // --- 1. AYARLAR (Web ve Mobil Ayrımı) ---
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:5000"; // Web (Tarayıcı)
    } else {
      return "http://192.168.1.101:5000"; // Mobil (Senin IP'n)
    }
  }

  // --- 2. AUTH İŞLEMLERİ (Login/Register) ---
  static Future<bool> register(String username, String password) async {
    final url = Uri.parse("$baseUrl/register");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Register Hatası: $e");
      return false;
    }
  }

  static Future<bool> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/login");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Login Hatası: $e");
      return false;
    }
  }

  // --- 3. POST İŞLEMLERİ ---
  static Future<List<dynamic>> getPosts() async {
    final url = Uri.parse("$baseUrl/posts");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("GetPosts Hatası: $e");
    }
    return [];
  }

  static Future<bool> addPostWithImage(
      String title,
      String content,
      File? mobileImage,
      Uint8List? webImageBytes,
      String? webImageName) async {
    
    var uri = Uri.parse("$baseUrl/add_post");
    var request = http.MultipartRequest('POST', uri);

    request.fields['title'] = title;
    request.fields['content'] = content;

    if (kIsWeb && webImageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        webImageBytes,
        filename: webImageName ?? 'image.jpg',
      ));
    } else if (!kIsWeb && mobileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        mobileImage.path,
      ));
    }

    try {
      var response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      print("AddPost Hatası: $e");
      return false;
    }
  }
}