import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_service.dart'; // To reuse the baseUrl

class AgentService {
  static const Duration _requestTimeout = Duration(seconds: 15);

  static Future<String> chatWithAgent(String query) async {
    try {
      final response = await http
          .post(
            Uri.parse('${DatabaseService.baseUrl}/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'query': query}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'No response from agent.';
      } else {
        return 'Error: Failed to connect to AI Stylist. Status: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: Failed to connect to AI Stylist.';
    }
  }
}
