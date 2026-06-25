import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static String? _accessToken;

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
static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String fullName,   // 🎯 Ad Soyad
    required String username,   // 🎯 Takma Ad (Kullanıcı Adı)
    required String email,
    required String bio,
    String? profileImage,
    String? oldPassword,
    String? newPassword,
  }) async {
    try {
      final Map<String, dynamic> bodyData = {
        "full_name": fullName,     // Backend'deki full_name karşılığı
        "username": username,       // 🎯 Backend'deki username karşılığı
        "email": email,
        "bio": bio,
        "profile_image": profileImage,
      };

      if (oldPassword != null && oldPassword.isNotEmpty) {
        bodyData["old_password"] = oldPassword;
      }
      if (newPassword != null && newPassword.isNotEmpty) {
        bodyData["new_password"] = newPassword;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        return {"success": true};
      } else {
        final errData = jsonDecode(response.body);
        return {"success": false, "message": errData["detail"] ?? "Hata oluştu"};
      }
    } catch (e) {
      return {"success": false, "message": "Bağlantı hatası: $e"};
    }
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
        final token = data["access_token"];
        if (token is String) {
          _accessToken = token;
        }
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

  static Future<bool> logout() async {
    final token = _accessToken;
    _accessToken = null;

    if (token == null) {
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/logout"),
        headers: {"Authorization": "Bearer $token"},
      );
      return response.statusCode == 200 || response.statusCode == 401;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getEvents() async {
    final response = await http.get(Uri.parse("$baseUrl/events"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("API Error ${response.statusCode}");
  }

  static Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(eventData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        return {"success": false, "message": "Etkinlik oluşturulamadı."};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> joinEvent({required String userId, required String eventId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/join_event'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'event_id': eventId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"success": false, "message": "Bir hata oluştu."};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> leaveEvent({required String userId, required String eventId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leave_event'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'event_id': eventId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          "success": false, 
          "message": errorData["detail"] ?? "Etkinlikten ayrılırken bir hata oluştu."
        };
      }
    } catch (e) {
      return {
        "success": false, 
        "message": "Bağlantı hatası: ${e.toString()}"
      };
    }
  }

  static Future<List<String>> getUserJoinedEvents(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["joined_events"] != null) {
          return List<String>.from(data["joined_events"].map((e) => e.toString()));
        }
      }
      return [];
    } catch (e) {
      print("Kullanıcı etkinlikleri çekilemedi: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUserJoinedEventsDetails(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId/joined_events_details'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print("Katılınan etkinlik detayları çekilemedi: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUserProfileSummary(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data')) {
            return decoded['data'] as Map<String, dynamic>;
          } else if (decoded.containsKey('user')) {
            return decoded['user'] as Map<String, dynamic>;
          }
          return decoded;
        }
      }
      return null;
    } catch (e) {
      print("Profil servis hatası: $e");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserCreatedEvents(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId/created-events'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      print("Oluşturulan etkinlikler çekilemedi: $e");
      return [];
    }
  }
  static Future<bool> updateMyEventsProfile({
  required String userId,
  required String newUsername,
  required String? newAvatar,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/events/update-creator/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'creator': newUsername,
        'avatar': newAvatar,
      }),
    );
    return response.statusCode == 200;
  } catch (e) {
    print("Etkinlik profil güncelleme hatası: $e");
    return false;
  }
}
static Future<bool> updateEventImage(String eventId, String base64Image) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/update-image/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imageUrl': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["success"] == true;
      }
      return false;
    } catch (e) {
      print("updateEventImage Hatası: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> addComment(String eventId, String userId, String username, String avatar, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events/$eventId/comment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'username': username,
          'avatar': avatar, // 🎯 Giriş yapan kullanıcının profil resmi gidiyor
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("addComment Hatası: $e");
      return null;
    }
  }

  // 🎯 YENİ: Beğenme durumunu tersine çevirme (Like/Unlike) fonksiyonu
  static Future<Map<String, dynamic>?> toggleLike(String eventId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events/$eventId/toggle-like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("toggleLike Hatası: $e");
      return null;
    }
  }
}