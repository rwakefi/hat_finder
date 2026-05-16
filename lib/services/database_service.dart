import 'dart:convert';
import 'package:http/http.dart' as http;

class DatabaseService {
  // Local development URL (port 8081 as configured in backend/main.py)
  static const String baseUrl = 'http://localhost:8081';
  
  // Production URL: https://hatfinder-production.up.railway.app

  static Future<bool> saveHat({
    required String name,
    String? brand,
    String? price,
    String? size,
    String? url,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/save_hat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'brand': brand,
          'price': price,
          'size': size,
          'url': url,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error saving hat: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getSavedHats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/hats'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching saved hats: $e');
      return [];
    }
  }
}
