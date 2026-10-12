import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';
import '../widgets/error_view.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  final _favoriteDestinationController = TextEditingController();

  String? _profileImageUrl;
  String? _localImagePath;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasError = false;

  static const String baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _favoriteDestinationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _hasError = false; });
    final token = await StorageService.getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _locationController.text = data['location'] ?? '';
          _websiteController.text = data['website'] ?? '';
          _favoriteDestinationController.text =
              data['favoriteDestination'] ?? '';
          _profileImageUrl = data['profileImageUrl'];
        });
      }
    } catch (e) {
      setState(() => _hasError = true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bytes = await image.readAsBytes();
    final savedFile = await File('${appDir.path}/$fileName').writeAsBytes(bytes);
    setState(() => _localImagePath = savedFile.path);
  }

  Future<String?> _uploadProfileImage(String filePath) async {
    final token = await StorageService.getToken();
    final request = http.MultipartRequest(
        'POST', Uri.parse('$baseUrl/auth/profile/image'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      return data['profileImageUrl'];
    }
    return null;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final token = await StorageService.getToken();
    try {
      String? imageUrl = _profileImageUrl;
      if (_localImagePath != null) {
        imageUrl = await _uploadProfileImage(_localImagePath!);
      }
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'bio': _bioController.text.trim(),
          'location': _locationController.text.trim(),
          'website': _websiteController.text.trim(),
          'favoriteDestination': _favoriteDestinationController.text.trim(),
          'profileImageUrl': imageUrl,
        }),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppTheme.navDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            content: const Row(children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: AppTheme.terracotta, size: 20),
              SizedBox(width: 10),
              Text('Profil başarıyla güncellendi!',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ));
        }
      } else {
        throw Exception('Güncellenemedi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: const Row(children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Güncellenemedi, tekrar deneyin.',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ));
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.navDark,
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28)),
            boxShadow: [BoxShadow(
                color: AppTheme.navDark.withOpacity(0.3),
                blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 16),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profili Düzenle',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 17, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: -0.3)),
                      Text('Gezgin Kimliği & Tercihler',
                          style: AppTheme.sansBody(
                              size: 11, weight: FontWeight.w600,
                              color: AppTheme.terracotta)),
                    ])),
                _isSaving
                    ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(
                        color: AppTheme.terracotta, strokeWidth: 2.2))
                    : GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                          color: AppTheme.terracotta.withOpacity(0.3),
                          blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Text('Kaydet', style: AppTheme.sansBody(
                        size: 13, weight: FontWeight.w800,
                        color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(
              color: AppTheme.terracotta))
              : _hasError
              ? ErrorView(onRetry: _loadProfile)
              : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 24),
            child: Column(children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: 104, height: 104,
                      decoration: BoxDecoration(
                        color: AppTheme.terracottaLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.terracotta, width: 3),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6))],
                      ),
                      child: ClipOval(
                        child: _localImagePath != null
                            ? Image.file(File(_localImagePath!),
                            fit: BoxFit.cover)
                            : _profileImageUrl != null
                            ? Image.network(_profileImageUrl!,
                            fit: BoxFit.cover)
                            : const Center(child: Icon(
                            Icons.person_outline_rounded,
                            color: AppTheme.terracotta,
                            size: 52)),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.navDark,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                        child: const Center(child: Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white, size: 16)),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Text('Fotoğrafı Değiştir',
                    style: AppTheme.sansBody(
                        size: 13, weight: FontWeight.w700,
                        color: AppTheme.terracotta)),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: _buildField('Ad',
                            _firstNameController, 'Adınız',
                            Icons.badge_outlined)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildField('Soyad',
                            _lastNameController, 'Soyadınız',
                            Icons.badge_outlined)),
                      ]),
                      _buildField('Hakkında', _bioController,
                          'Gezgin hikayenden bahset...',
                          Icons.edit_note_rounded, maxLines: 3),
                      _buildField('Konum', _locationController,
                          'Şehir, Ülke (örn: İstanbul, TR)',
                          Icons.location_on_outlined),
                      _buildField('Web Sitesi', _websiteController,
                          'https://...', Icons.language_outlined),
                      _buildField('Favori Destinasyon',
                          _favoriteDestinationController,
                          'En unutamadığın rota (örn: Kapadokya)',
                          Icons.flight_takeoff_rounded),
                    ]),
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      String hint, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: AppTheme.terracotta),
          const SizedBox(width: 6),
          Text(label, style: AppTheme.sansBody(
              size: 12, weight: FontWeight.w700,
              color: AppTheme.textPrimary)),
        ]),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTheme.sansBody(size: 14, weight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.sansBody(size: 13, color: AppTheme.textMuted),
            filled: true, fillColor: const Color(0xFFFAF7F2),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppTheme.border, width: 1.2)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppTheme.border, width: 1.2)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: AppTheme.terracotta, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ]),
    );
  }
}