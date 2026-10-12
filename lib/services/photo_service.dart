import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:exif_reader/exif_reader.dart';
import 'dart:convert';
import '../config/api_config.dart';
import 'storage_service.dart';

class LocationEstimationException implements Exception {
  final String code;
  LocationEstimationException(this.code);
}

class LocationGuess {
  final String name;
  final double? lat;
  final double? lng;
  LocationGuess({required this.name, this.lat, this.lng});
}

class PhotoService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<String> uploadPhoto(String filePath, int entryId) async {
    final token = await StorageService.getToken();
    final file = File(filePath);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/entries/$entryId/photos'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['url'];
    } else {
      throw Exception('Fotoğraf yüklenemedi');
    }
  }

  static Future<String> uploadDirectToCloudinary(String filePath) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/xnzocixe/image/upload');
    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = 'seyahood_unsigned';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      return data['secure_url'];
    }
    throw Exception('Cloudinary yükleme başarısız');
  }

  static Future<LocationGuess> estimateLocation(String filePath) async {
    final token = await StorageService.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/photos/estimate-location'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      return LocationGuess(
        name: data['locationName'],
        lat: (data['lat'] as num?)?.toDouble(),
        lng: (data['lng'] as num?)?.toDouble(),
      );
    }
    final error = jsonDecode(body)['error'] ?? 'UNKNOWN';
    throw LocationEstimationException(error);
  }

  /// Fotoğrafın EXIF verisinde gömülü GPS konumu varsa (lat, lng) döner,
  /// yoksa null döner. Ekran görüntüsü, internetten indirilmiş fotoğraf
  /// veya konum servisi kapalıyken çekilmiş fotoğraflarda genelde bulunmaz.
  static Future<Map<String, double>?> extractExifGps(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final exif = await readExifFromBytes(bytes);
      final latTag = exif.tags['GPS GPSLatitude'];
      final lngTag = exif.tags['GPS GPSLongitude'];
      if (latTag == null || lngTag == null) return null;

      double dmsToDecimal(IfdValues values) {
        final parts = values.toList();
        final degrees = (parts[0] as Ratio).toDouble();
        final minutes = (parts[1] as Ratio).toDouble();
        final seconds = (parts[2] as Ratio).toDouble();
        return degrees + minutes / 60 + seconds / 3600;
      }

      double lat = dmsToDecimal(latTag.values);
      double lng = dmsToDecimal(lngTag.values);

      final latRef = exif.tags['GPS GPSLatitudeRef']?.printable ?? '';
      final lngRef = exif.tags['GPS GPSLongitudeRef']?.printable ?? '';
      if (latRef.toUpperCase().contains('S')) lat = -lat;
      if (lngRef.toUpperCase().contains('W')) lng = -lng;

      return {'lat': lat, 'lng': lng};
    } catch (e) {
      return null;
    }
  }

  /// Koordinatı Nominatim ile insan-okunur bir yer adına çevirir.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse'
            '?lat=$lat&lon=$lng&format=json&accept-language=tr'),
        headers: {'User-Agent': 'Seyahood/1.0'},
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      final address = data['address'] as Map<String, dynamic>?;
      final name = address?['city'] ?? address?['town'] ??
          address?['village'] ?? address?['county'];
      if (name != null) return name as String;
      final displayName = data['display_name'] as String?;
      return displayName?.split(',').first.trim();
    } catch (e) {
      return null;
    }
  }
}