import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static const String _savedHatsKey = 'saved_hats';
  static const int _maxSavedHats = 100;

  static Future<bool> saveHat({
    required String name,
    String? brand,
    String? price,
    String? size,
    String? url,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHats = await getSavedHats();
      final bookmark = {
        'name': name,
        'brand': brand,
        'price': price,
        'size': size,
        'url': url,
        'created_at': DateTime.now().toIso8601String(),
      };
      savedHats.removeWhere((hat) {
        if (hat is! Map) return false;
        final savedUrl = hat['url']?.toString();
        if (url != null && url.isNotEmpty) {
          return savedUrl == url;
        }
        return hat['name']?.toString() == name;
      });
      savedHats.insert(0, bookmark);
      final encoded = jsonEncode(savedHats.take(_maxSavedHats).toList());
      return prefs.setString(_savedHatsKey, encoded);
    } catch (e) {
      debugPrint('Error saving local bookmark: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getSavedHats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_savedHatsKey);
      if (encoded == null || encoded.isEmpty) {
        return [];
      }
      final decoded = jsonDecode(encoded);
      return decoded is List<dynamic> ? decoded : [];
    } catch (e) {
      debugPrint('Error reading local bookmarks: $e');
      return [];
    }
  }

  static Future<bool> clearSavedHats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.remove(_savedHatsKey);
    } catch (e) {
      debugPrint('Error clearing local bookmarks: $e');
      return false;
    }
  }
}
