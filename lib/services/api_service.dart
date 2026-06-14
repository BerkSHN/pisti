import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String username,
    required String password,
  }) async {
    return _postAuth("/auth/register", {
      "full_name": fullName,
      "email": email,
      "username": username,
      "password": password,
    });
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _postAuth("/auth/login", {"email": email, "password": password});
  }

  static Future<Map<String, dynamic>> _postAuth(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl$path"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {"success": true, ...data};
      }

      return {
        "success": false,
        "message": data["detail"]?.toString() ?? "İşlem başarısız",
      };
    } catch (_) {
      return {"success": false, "message": "Sunucuya bağlanılamadı"};
    }
  }

  static Future<List<dynamic>> getEvents() async {
    final response = await http.get(Uri.parse("$baseUrl/events"));

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("API Error ${response.statusCode}");
  }

  static Future<bool> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/events"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(eventData),
      );

      print("POST STATUS: ${response.statusCode}");
      print("POST BODY: ${response.body}");

      // FastAPI başarılı kayıt durumunda 200 veya 201 döner
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print("ApiService createEvent Hatası: $e");
      return false;
    }
  }
}
