import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

   static Future<List<dynamic>> getEvents() async {
    final response = await http.get(
    Uri.parse("$baseUrl/events"),
  );

  print("STATUS: ${response.statusCode}");
  print("BODY: ${response.body}");

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception(
    "API Error ${response.statusCode}",
  );
  }
  
}