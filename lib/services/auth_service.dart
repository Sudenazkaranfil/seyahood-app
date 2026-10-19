import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../l10n/auth_error_keys.dart';
import 'api_exception.dart';

/// Şifre doğru ama hesap henüz e-posta ile doğrulanmamış; kullanıcıyı
/// doğrulama ekranına yönlendirebilmek için e-postayı da taşır.
class AccountNotVerifiedException implements Exception {
  final String email;
  const AccountNotVerifiedException(this.email);
}

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

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    final error = body['error'] as String?;
    if (error == 'ACCOUNT_NOT_VERIFIED') {
      throw AccountNotVerifiedException(body['email'] as String? ?? email);
    }
    throw ApiException(authErrorKeys[error] ?? 'common.genericError');
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