import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../l10n/auth_error_keys.dart';
import 'api_exception.dart';

class AuthService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] as String?;
      throw ApiException(authErrorKeys[error] ?? 'common.genericError');
    }
  }
  static Future<void> register(
      String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] as String?;
      throw ApiException(authErrorKeys[error] ?? 'common.genericError');
    }
  }
}