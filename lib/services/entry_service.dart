import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/entry.dart';
import '../config/api_config.dart';
import 'storage_service.dart';
import 'subscription_service.dart';

class EntryService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<List<Entry>> getEntries(int journalId) async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/journals/$journalId/entries'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Entry.fromJson(json)).toList();
    } else {
      throw Exception('Girişler yüklenemedi');
    }
  }

  static Future<Entry> createEntry(int journalId, Map<String, dynamic> entryData) async {
    final token = await StorageService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/journals/$journalId/entries'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(entryData),
    );

    if (response.statusCode == 200) {
      return Entry.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 403 &&
        jsonDecode(response.body)['error'] == 'PAGE_LIMIT_REACHED') {
      throw const LimitReachedException('page');
    } else {
      throw Exception('Giriş oluşturulamadı');
    }
  }

  static Future<void> deleteEntry(int journalId, int entryId) async {
    final token = await StorageService.getToken();
    await http.delete(
      Uri.parse('$baseUrl/journals/$journalId/entries/$entryId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<Entry> updateEntry(int journalId, int entryId, Map<String, dynamic> entryData) async {
    final token = await StorageService.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/journals/$journalId/entries/$entryId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(entryData),
    );

    if (response.statusCode == 200) {
      return Entry.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Giriş güncellenemedi');
    }
  }
}