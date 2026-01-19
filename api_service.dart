import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:5000"; 
    } else {
      return "http://192.168.1.101:5000"; // IP adresini kontrol et
    }
  }

  // --- AUTH ---
  static Future<bool> register(String username, String password, String email) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password, "email": email}));
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // --- POSTS ---
  static Future<List<dynamic>> getPosts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/posts"));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) { print(e); }
    return [];
  }

  static Future<bool> addPostWithImage(String title, String content, String username, String category, File? mobileImage, Uint8List? webBytes, String? webName) async {
    var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/add_post"));
    request.fields['title'] = title;
    request.fields['content'] = content;
    request.fields['username'] = username;
    request.fields['category'] = category;

    if (kIsWeb && webBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('image', webBytes, filename: webName ?? 'image.jpg'));
    } else if (!kIsWeb && mobileImage != null) {
      request.files.add(await http.MultipartFile.fromPath('image', mobileImage.path));
    }

    try {
      var response = await request.send();
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

  // ⭐ YENİ: SİLME FONKSİYONU
  static Future<bool> deletePost(int postId, String username) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/delete_post"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"post_id": postId, "username": username}));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // --- LIKES & COMMENTS ---
  static Future<Map<String, dynamic>> toggleLike(int postId, String username) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/toggle_like"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"post_id": postId, "username": username}));
      if (response.statusCode == 200 || response.statusCode == 201) return json.decode(response.body);
    } catch (e) { }
    return {};
  }

  static Future<List<String>> getLikes(int postId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/likes/$postId"));
      if (response.statusCode == 200) return List<String>.from(json.decode(response.body));
    } catch (e) { }
    return [];
  }

  static Future<bool> addComment(int postId, String username, String text) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/add_comment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"post_id": postId, "username": username, "comment_text": text}));
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<List<dynamic>> getComments(int postId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/comments/$postId"));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) { }
    return [];
  }

  // --- PROFILE ---
  static Future<Map<String, dynamic>> getUserInfo(String username) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/user_info/$username"));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) { }
    return {};
  }

  static Future<List<dynamic>> getUserPosts(String username) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/user_posts/$username"));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) { }
    return [];
  }
}