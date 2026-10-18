import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/app_notification.dart';
import 'storage_service.dart';
import 'api_exception.dart';

class NotificationService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<List<AppNotification>> getNotifications() async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } else {
      throw const ApiException('apiError.notificationsLoadFailed');
    }
  }

  static Future<int> getUnreadCount() async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread-count'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['count'] ?? 0;
    }
    return 0;
  }

  static Future<void> markRead(int id) async {
    final token = await StorageService.getToken();
    await http.post(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<void> markAllRead() async {
    final token = await StorageService.getToken();
    await http.post(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
