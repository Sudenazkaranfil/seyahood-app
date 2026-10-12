import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/journal.dart';
import '../config/api_config.dart';
import 'storage_service.dart';
import 'subscription_service.dart';

class JournalService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<List<Journal>> getJournals() async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/journals'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Journal.fromJson(json)).toList();
    } else {
      throw Exception('Ajandalar yüklenemedi');
    }
  }

  static Future<List<Journal>> getPublicJournals({String? search, String? sortBy}) async {
    final token = await StorageService.getToken();
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sortBy != null) params['sortBy'] = sortBy;

    final uri = Uri.parse('$baseUrl/journals/public').replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Journal.fromJson(json)).toList();
    } else {
      throw Exception('Ajandalar yüklenemedi');
    }
  }

  static Future<List<Journal>> getSavedJournals() async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/journals/saved'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Journal.fromJson(json)).toList();
    } else {
      throw Exception('Kaydedilen ajandalar yüklenemedi');
    }
  }

  static Future<bool> toggleSave(int journalId) async {
    final token = await StorageService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/journals/$journalId/save'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['saved'];
    } else {
      throw Exception('İşlem başarısız');
    }
  }

  static Future<bool> isSaved(int journalId) async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/journals/$journalId/saved'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['saved'];
    }
    return false;
  }

  static Future<void> incrementView(int journalId) async {
    final token = await StorageService.getToken();
    await http.post(
      Uri.parse('$baseUrl/journals/$journalId/view'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<String> uploadCover(int journalId, String filePath) async {
    final token = await StorageService.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/journals/$journalId/cover'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      return jsonDecode(body)['coverImageUrl'];
    } else {
      throw Exception('Kapak fotoğrafı yüklenemedi');
    }
  }

  static Future<Journal> createJournal(String title, String visibility) async {
    final token = await StorageService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/journals'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'title': title, 'visibility': visibility}),
    );
    if (response.statusCode == 200) {
      return Journal.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 403 &&
        jsonDecode(response.body)['error'] == 'JOURNAL_LIMIT_REACHED') {
      throw const LimitReachedException('journal');
    } else {
      throw Exception('Ajanda oluşturulamadı');
    }
  }

  static Future<Journal> updateJournal(int id, String title, String visibility) async {
    final token = await StorageService.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/journals/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'title': title, 'visibility': visibility}),
    );
    if (response.statusCode == 200) {
      return Journal.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ajanda güncellenemedi');
    }
  }

  static Future<void> deleteJournal(int id) async {
    final token = await StorageService.getToken();
    await http.delete(
      Uri.parse('$baseUrl/journals/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }
}