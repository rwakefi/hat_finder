import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class DatabaseService {
  static String get baseUrl => AppConfig.apiBaseUrl;

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
      debugPrint('Error saving hat: $e');
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
      debugPrint('Error fetching saved hats: $e');
      return [];
    }
  }
}
