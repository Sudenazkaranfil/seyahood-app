import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';
import '../services/journal_service.dart';
import '../services/subscription_service.dart';
import '../models/journal.dart';
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'follow_list_screen.dart';
import 'journal_detail_screen.dart';
import 'premium_screen.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_view.dart';
import '../widgets/plan_badge.dart';
import '../widgets/ad_banner.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _username;
  String? _firstName;
  String? _lastName;
  String? _bio;
  String? _profileImageUrl;
  String? _location;
  int _journalCount = 0;
  int _followerCount = 0;
  int _followingCount = 0;
  bool _isLoading = true;
  List<Journal> _journals = [];
  Color _coverColor = const Color(0xFFF5EFE8);
  String? _coverImagePath;
  final GlobalKey _profileCardKey = GlobalKey();
  bool _hasError = false;
  bool _isPlus = false;
  bool _isPro = false;

  static const String baseUrl = ApiConfig.baseUrl;

  final List<Map<String, dynamic>> _coverColors = [
    {'color': const Color(0xFFF5EFE8), 'label': 'Krem'},
    {'color': const Color(0xFFEAF3EE), 'label': 'Adaçayı'},
    {'color': const Color(0xFFF0EBE3), 'label': 'Kum'},
    {'color': const Color(0xFFE8EDF5), 'label': 'Sis'},
    {'color': const Color(0xFFF5EAF0), 'label': 'Gül'},
    {'color': const Color(0xFFEAE8F5), 'label': 'Lavanta'},
    {'color': const Color(0xFFF5F0E8), 'label': 'Vanilya'},
    {'color': const Color(0xFFE8F5F0), 'label': 'Nane'},
    {'color': const Color(0xFFF5EDE8), 'label': 'Şeftali'},
    {'color': const Color(0xFFE8EEF5), 'label': 'Gökyüzü'},
    {'color': const Color(0xFFF0F5E8), 'label': 'Fıstık'},
    {'color': const Color(0xFFF5E8EE), 'label': 'Pudra'},
  ];

  Color _getColor(int index) {
    final colors = [
      const Color(0xFFC46B4E), const Color(0xFF5B8A6F),
      const Color(0xFF7B8FA1), const Color(0xFF8B7355),
      const Color(0xFF6B5A8B), const Color(0xFF8B5030),
    ];
    return colors[index % colors.length];
  }

  Map<String, dynamic> _getLevelInfo(int journalCount) {
    if (journalCount <= 3) {
      return {
        'emoji': '🌱', 'title': 'Yeni Gezgin', 'next': 4,
        'current': journalCount, 'min': 0, 'max': 3,
        'color': const Color(0xFF7BAE7F),
      };
    } else if (journalCount <= 10) {
      return {
        'emoji': '🗺️', 'title': 'Kaşif', 'next': 11,
        'current': journalCount, 'min': 4, 'max': 10,
        'color': const Color(0xFFC46B4E),
      };
    } else if (journalCount <= 20) {
      return {
        'emoji': '✈️', 'title': 'Seyyah', 'next': 21,
        'current': journalCount, 'min': 11, 'max': 20,
        'color': const Color(0xFF5B8A6F),
      };
    } else if (journalCount <= 50) {
      return {
        'emoji': '🌍', 'title': 'Dünya Gezgini', 'next': 51,
        'current': journalCount, 'min': 21, 'max': 50,
        'color': const Color(0xFF3D6B9E),
      };
    } else {
      return {
        'emoji': '🏆', 'title': 'Efsane Gezgin', 'next': null,
        'current': journalCount, 'min': 50, 'max': null,
        'color': const Color(0xFFD4A017),
      };
    }

  }

  Future<void> _saveCoverColor(Color color) async {
    final token = await StorageService.getToken();
    final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    try {
      await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'coverColor': hex}),
      );
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final username = await StorageService.getUsername();
    final token = await StorageService.getToken();

    List<Journal> journals = [];
    try {
      journals = await JournalService.getJournals();
    } catch (e) {
      debugPrint('❌ PROFILE ERROR (journals): $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('PROFILE /auth/profile status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _firstName = data['firstName'];
          _lastName = data['lastName'];
          _bio = data['bio'];
          _profileImageUrl = data['profileImageUrl'];
          _location = data['location'];
          // Ekle:
          if (data['coverColor'] != null &&
              (data['coverColor'] as String).isNotEmpty) {
            _coverColor = Color(int.parse(
                data['coverColor'].replaceFirst('#', '0xFF')));
          }
        });
      } else {
        debugPrint('❌ PROFILE ERROR (auth/profile body): ${response.body}');
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      debugPrint('❌ PROFILE ERROR (auth/profile): $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }

    try {
      final followResponse = await http.get(
        Uri.parse('$baseUrl/users/$username/follow-status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (followResponse.statusCode == 200) {
        final data = jsonDecode(followResponse.body);
        setState(() {
          _followerCount = data['followerCount'] ?? 0;
          _followingCount = data['followingCount'] ?? 0;
        });
      }
    } catch (e) {}

    try {
      final subscription = await SubscriptionService.instance.getStatus();
      setState(() {
        _isPlus = subscription.isPlus;
        _isPro = subscription.isPro;
      });
    } catch (e) {}

    setState(() {
      _username = username ?? 'Gezgin';
      _journalCount = journals.length;
      _journals = journals;
      _isLoading = false;
    });
    widget.onProfileUpdated?.call();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Çıkış Yap', style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.w800, color: Color(0xFF1C110A),
              letterSpacing: -0.4)),
        ]),
        content: const Text('Hesabından çıkış yapmak istediğine emin misin?',
            style: TextStyle(fontSize: 14, color: Color(0xFF7C6A59), height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç',
                style: TextStyle(color: Color(0xFF7C6A59), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Çıkış Yap',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      await StorageService.clearAll();
      SubscriptionService.instance.clear();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showCoverPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Kapak Rengi', style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text('Uzun basarak değiştir',
                  style: AppTheme.sansBody(size: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),

              // Galeriden fotoğraf
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                      source: ImageSource.gallery, imageQuality: 80);
                  if (image != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName =
                        'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final bytes = await image.readAsBytes();
                    final savedFile = await File('${appDir.path}/$fileName')
                        .writeAsBytes(bytes);
                    setState(() => _coverImagePath = savedFile.path);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.terracottaLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.terracotta.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.terracotta,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.photo_library_outlined,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Galeriden Fotoğraf Seç',
                          style: AppTheme.sansBody(
                              size: 13, weight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      Text('Kendi fotoğrafını kapak yap',
                          style: AppTheme.sansBody(
                              size: 11, color: AppTheme.textSecondary)),
                    ]),
                  ]),
                ),
              ),

              // Renk seçenekleri
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10,
                  childAspectRatio: 1.6,
                ),
                itemCount: _coverColors.length,
                itemBuilder: (context, index) {
                  final item = _coverColors[index];
                  final color = item['color'] as Color;
                  final isSelected = _coverImagePath == null &&
                      _coverColor == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _coverColor = color;
                        _coverImagePath = null;
                      });
                      _saveCoverColor(color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isSelected
                                ? AppTheme.terracotta : AppTheme.border,
                            width: isSelected ? 2.5 : 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected)
                            Icon(Icons.check_rounded,
                                color: AppTheme.terracotta, size: 16),
                          Text(item['label'],
                              style: TextStyle(fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ]),
      ),
    );
  }

  Future<void> _shareProfileCard(String theme) async {
    try {
      final boundary = _profileCardKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/seyahood_profile_$theme.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Seyahood\'da beni takip et! seyahood.app/@${_username ?? ''}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paylaşılamadı!')));
    }
  }

  void _showShareOptions() {
    final level = _getLevelInfo(_journalCount);
    final inviteMessage =
        '✈️ Seyahood\'dayım!\n\n'
        'Seyahat anılarımı dijital ajandamda saklıyorum. '
        'Sen de katıl, kendi yolculuğunu kaydet:\n\n'
        'seyahood.app/@${_username ?? ''}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Profili Paylaş', style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
              const SizedBox(height: 16),

              // Bağlantı kopyala
              _buildShareOption(
                icon: Icons.link_rounded,
                title: 'Bağlantıyı Kopyala',
                subtitle: 'Profil linkini panoya kopyala',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Profil bağlantısı kopyalandı! 🔗')));
                },
              ),
              const SizedBox(height: 10),

              // Davet mesajı
              _buildShareOption(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Davet Mesajı Gönder',
                subtitle: 'Arkadaşlarını Seyahood\'a davet et',
                onTap: () {
                  Navigator.pop(context);
                  Share.share(inviteMessage);
                },
              ),
              const SizedBox(height: 14),

              // Profil kartı başlığı
              Text('Profil Kartı Paylaş',
                  style: AppTheme.sansBody(
                      size: 13, weight: FontWeight.w700,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text('Tema seç ve paylaş:',
                  style: AppTheme.sansBody(size: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 10),

              Row(children: [
                // Açık tema kartı önizleme
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showProfileCardPreview('light');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(children: [
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.navDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text('☀️',
                              style: const TextStyle(fontSize: 20))),
                        ),
                        const SizedBox(height: 6),
                        Text('Açık', style: AppTheme.sansBody(
                            size: 11, weight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Koyu tema kartı önizleme
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showProfileCardPreview('dark');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.navDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(children: [
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text('🌙',
                              style: const TextStyle(fontSize: 20))),
                        ),
                        const SizedBox(height: 6),
                        Text('Koyu', style: AppTheme.sansBody(
                            size: 11, weight: FontWeight.w700,
                            color: Colors.white)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ]),
      ),
    );
  }

  void _showProfileCardPreview(String theme) {
    final level = _getLevelInfo(_journalCount);
    final isDark = theme == 'dark';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.navDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.2) : AppTheme.border,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          // Kart önizleme
          RepaintBoundary(
            key: _profileCardKey,
            child: _buildProfileCard(isDark, level),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _shareProfileCard(theme);
              },
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Paylaş',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.terracotta,
                  foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark, Map<String, dynamic> level) {
    final bgColor = isDark ? AppTheme.navDark : const Color(0xFFFAF7F2);
    final textColor = isDark ? Colors.white : const Color(0xFF1C110A);
    final subColor = isDark
        ? Colors.white.withOpacity(0.5) : const Color(0xFF7C6A59);
    final divColor = isDark
        ? Colors.white.withOpacity(0.1) : const Color(0xFFEADBCE);
    final levelColor = level['color'] as Color;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08) : const Color(0xFFEADBCE)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        // Üst kısım
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : AppTheme.navDark.withOpacity(0.03),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(children: [
            // Avatar
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.terracotta : AppTheme.terracottaLight,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2) : AppTheme.border,
                    width: 2.5),
              ),
              child: _profileImageUrl != null
                  ? ClipOval(child: Image.network(
                  _profileImageUrl!, fit: BoxFit.cover))
                  : Center(child: Text(
                  (_firstName ?? _username ?? 'G')[0].toUpperCase(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.terracotta))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  _firstName != null && _lastName != null
                      ? '$_firstName $_lastName' : _username ?? 'Gezgin',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: textColor, letterSpacing: -0.4)),
              const SizedBox(height: 2),
              Text('@${_username ?? ''}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppTheme.terracotta)),
              if (_location != null && _location!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.place_rounded, size: 11, color: subColor),
                  const SizedBox(width: 3),
                  Text(_location!, style: TextStyle(fontSize: 11, color: subColor)),
                ]),
              ],
            ])),
            // Rozet
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: levelColor.withOpacity(0.3)),
              ),
              child: Column(children: [
                Text(level['emoji'], style: const TextStyle(fontSize: 16)),
                Text(level['title'], style: TextStyle(fontSize: 9,
                    fontWeight: FontWeight.w800, color: levelColor)),
              ]),
            ),
          ]),
        ),

        Container(height: 1, color: divColor),

        // Stats
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            _buildCardStat(_journalCount.toString(), 'Ajanda',
                textColor, subColor),
            Container(width: 1, height: 30, color: divColor),
            _buildCardStat(_followerCount.toString(), 'Takipçi',
                textColor, subColor),
            Container(width: 1, height: 30, color: divColor),
            _buildCardStat(_followingCount.toString(), 'Takip',
                textColor, subColor),
          ]),
        ),

        Container(height: 1, color: divColor),

        // Footer
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Seyahood ✈️',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                      color: AppTheme.terracotta)),
              Text('seyahood.app/@${_username ?? ''}',
                  style: TextStyle(fontSize: 10, color: subColor)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildCardStat(String value, String label,
      Color textColor, Color subColor) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
          color: textColor, letterSpacing: -0.5)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: subColor)),
    ]));
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppTheme.navDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.sansBody(
                    size: 13, weight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text(subtitle, style: AppTheme.sansBody(
                    size: 11, color: AppTheme.textSecondary)),
              ])),
          Icon(Icons.arrow_forward_ios_rounded,
              color: AppTheme.textMuted, size: 14),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: _isLoading
          ? const ProfileSkeletonLoader()
          : _hasError
          ? ErrorView(onRetry: _loadProfile)
          : SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(children: [
            _buildHeader(),
            const SizedBox(height: 14),
            _buildStats(),
            const SizedBox(height: 14),
            _buildLevelCard(),
            const SizedBox(height: 14),
            const AdBanner(),
            const SizedBox(height: 4),
            _buildJournalGrid(),
            const SizedBox(height: 24),
            _buildMenu(),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(
            color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(children: [
        Stack(clipBehavior: Clip.none, children: [
          // Cover
          GestureDetector(
            onLongPress: _showCoverPicker,
            child: Container(
              height: 110, width: double.infinity,
              decoration: BoxDecoration(
                color: _coverColor,
                image: _coverImagePath != null
                    ? DecorationImage(
                    image: FileImage(File(_coverImagePath!)),
                    fit: BoxFit.cover)
                    : null,
              ),
              child: _coverImagePath == null
                  ? Stack(children: [
                CustomPaint(
                    painter: _CoverDotPainter(_coverColor),
                    size: Size.infinite),
                Positioned(
                  bottom: 8, right: 12,
                  child: Row(children: [
                    Icon(Icons.touch_app_outlined, size: 11,
                        color: AppTheme.textMuted.withOpacity(0.5)),
                    const SizedBox(width: 3),
                    Text('Değiştirmek için uzun bas',
                        style: TextStyle(fontSize: 9,
                            color: AppTheme.textMuted.withOpacity(0.5),
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              ])
                  : Positioned(
                bottom: 8, right: 12,
                child: GestureDetector(
                  onTap: () => setState(() => _coverImagePath = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Kaldır',
                        style: TextStyle(fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ),
          // Avatar
          Positioned(
            bottom: -38, left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  final updated = await Navigator.push(context,
                      MaterialPageRoute(
                          builder: (context) => const EditProfileScreen()));
                  if (updated == true) _loadProfile();
                },
                child: Stack(children: [
                  Container(
                    width: 84, height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3ECE1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 14, offset: const Offset(0, 4))],
                    ),
                    child: _profileImageUrl != null
                        ? ClipRRect(
                        borderRadius: BorderRadius.circular(42),
                        child: Image.network(_profileImageUrl!,
                            fit: BoxFit.cover))
                        : const Center(child: Icon(Icons.person_rounded,
                        color: Color(0xFFC46B4E), size: 42)),
                  ),
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC46B4E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.photo_camera_rounded,
                          color: Colors.white, size: 13),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),

        const SizedBox(height: 48),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                  _firstName != null && _lastName != null
                      ? '$_firstName $_lastName' : _username ?? 'Gezgin',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: const Color(0xFF1C110A), letterSpacing: -0.5)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (_getLevelInfo(_journalCount)['color'] as Color)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: (_getLevelInfo(_journalCount)['color'] as Color)
                          .withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_getLevelInfo(_journalCount)['emoji'],
                      style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text(_getLevelInfo(_journalCount)['title'],
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                          color: _getLevelInfo(_journalCount)['color'] as Color)),
                ]),
              ),
              if (_isPlus || _isPro) ...[
                const SizedBox(width: 6),
                PlanBadge(isPlus: _isPlus, isPro: _isPro),
              ],
            ]),

            const SizedBox(height: 3),
            Text('@${_username ?? ''}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: Color(0xFFC46B4E))),

            if (_bio != null && _bio!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_bio!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13,
                      color: Color(0xFF523F31), height: 1.5)),
            ],

            if (_location != null && _location!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEADBCE)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.place_rounded, size: 13,
                      color: Color(0xFFC46B4E)),
                  const SizedBox(width: 4),
                  Text(_location!, style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: Color(0xFF7C6A59))),
                ]),
              ),
            ],

            const SizedBox(height: 18),

            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final updated = await Navigator.push(context,
                        MaterialPageRoute(
                            builder: (context) => const EditProfileScreen()));
                    if (updated == true) _loadProfile();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.terracottaLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.terracotta.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note_rounded,
                              color: AppTheme.terracotta, size: 18),
                          const SizedBox(width: 8),
                          Text('Profili Düzenle', style: AppTheme.sansBody(
                              size: 13, weight: FontWeight.w700,
                              color: AppTheme.terracotta)),
                        ]),
                  ),
                ),
              ),
              if (!_isPlus && !_isPro) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const PremiumScreen())),
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                        child: Text('👑', style: TextStyle(fontSize: 18))),
                  ),
                ),
              ],
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _showShareOptions,
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEADBCE)),
                  ),
                  child: const Icon(Icons.share_outlined,
                      color: Color(0xFF1C110A), size: 18),
                ),
              ),
            ]),
            const SizedBox(height: 20),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEADBCE)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _buildStatItem('Ajanda', _journalCount.toString(),
            Icons.auto_stories_rounded, null),
        Container(width: 1, height: 36, color: const Color(0xFFEADBCE)),
        _buildStatItem('Takipçi', _followerCount.toString(),
            Icons.groups_rounded, () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => FollowListScreen(
                      username: _username ?? '', type: 'followers')));
            }),
        Container(width: 1, height: 36, color: const Color(0xFFEADBCE)),
        _buildStatItem('Takip', _followingCount.toString(),
            Icons.person_add_alt_rounded, () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => FollowListScreen(
                      username: _username ?? '', type: 'following')));
            }),
      ]),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: const Color(0xFFC46B4E)),
            const SizedBox(width: 5),
            Text(value, style: const TextStyle(fontSize: 20,
                fontWeight: FontWeight.w800, color: Color(0xFF1C110A),
                letterSpacing: -0.5)),
          ]),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 11,
              fontWeight: FontWeight.w600, color: Color(0xFF7C6A59))),
        ]),
      ),
    );
  }

  Widget _buildLevelCard() {
    final level = _getLevelInfo(_journalCount);
    final bool isMax = level['next'] == null;
    final double progress = isMax
        ? 1.0
        : ((_journalCount - (level['min'] as int)) /
        ((level['max'] as int) - (level['min'] as int)))
        .clamp(0.0, 1.0);
    final int remaining =
    isMax ? 0 : (level['next'] as int) - _journalCount;
    final Color levelColor = level['color'] as Color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: levelColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: levelColor.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(level['emoji'],
                style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(level['title'], style: GoogleFonts.playfairDisplay(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1C110A))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Seviyeniz', style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: levelColor)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(
                isMax
                    ? '🏆 Tüm seviyeleri tamamladınız!'
                    : 'Bir sonraki seviyeye $remaining ajanda kaldı',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF7C6A59))),
          ])),
        ]),
        if (!isMax) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress, minHeight: 8,
              backgroundColor: levelColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(levelColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${level['min']} ajanda',
                style: const TextStyle(fontSize: 10, color: Color(0xFF7C6A59))),
            Text('${level['max']} ajanda',
                style: const TextStyle(fontSize: 10, color: Color(0xFF7C6A59))),
          ]),
        ],
      ]),
    );
  }

  Widget _buildJournalGrid() {
    if (_journals.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEADBCE)),
        ),
        child: Column(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFC46B4E).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_stories_rounded,
                color: Color(0xFFC46B4E), size: 26),
          ),
          const SizedBox(height: 12),
          const Text('Henüz Ajanda Yok',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: Color(0xFF1C110A))),
          const SizedBox(height: 4),
          const Text('Yeni bir ajanda oluşturup anılarını kaydetmeye başla.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF7C6A59))),
        ]),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Ajandalarım', style: GoogleFonts.playfairDisplay(
              fontSize: 17, fontWeight: FontWeight.w800,
              color: const Color(0xFF1C110A), letterSpacing: -0.4)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFC46B4E).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${_journals.length}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                    color: Color(0xFFC46B4E))),
          ),
        ]),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10,
            mainAxisSpacing: 14, childAspectRatio: 0.72,
          ),
          itemCount: _journals.length,
          itemBuilder: (context, index) {
            final journal = _journals[index];
            return GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(
                    builder: (context) =>
                        JournalDetailScreen(journal: journal)));
                _loadProfile();
              },
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(4),
                              right: Radius.circular(12)),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.14),
                              blurRadius: 8, offset: const Offset(2, 4))],
                        ),
                        child: Stack(children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(4),
                                right: Radius.circular(12)),
                            child: journal.coverImageUrl != null
                                ? Image.network(journal.coverImageUrl!,
                                fit: BoxFit.cover, width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (ctx, _, __) =>
                                    _buildFallbackCover(index, journal))
                                : _buildFallbackCover(index, journal),
                          ),
                          Positioned(
                            left: 0, top: 0, bottom: 0, width: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.black.withOpacity(0.35),
                                  Colors.black.withOpacity(0.0),
                                ]),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(journal.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700, color: Color(0xFF1C110A))),
                  ]),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildFallbackCover(int index, Journal journal) {
    final color = _getColor(index);
    return Container(
      width: double.infinity, height: double.infinity,
      color: color.withOpacity(0.08),
      child: Stack(children: [
        // Dot grid
        CustomPaint(
            painter: _DotGridPainter(color: color),
            size: Size.infinite),
        // Washi tape
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
              height: 4, color: color.withOpacity(0.4)),
        ),
        // Büyük harf
        Positioned(
          bottom: -8, right: 4,
          child: Text(
            journal.title.isNotEmpty
                ? journal.title[0].toUpperCase() : 'M',
            style: TextStyle(
                fontSize: 48, fontWeight: FontWeight.w800,
                color: color.withOpacity(0.15),
                fontFamily: 'serif'),
          ),
        ),
      ]),
    );
  }

  Color _getGradientColor(int index) {
    final colors = [
      const Color(0xFFC46B4E), const Color(0xFF5B8A6F),
      const Color(0xFF7B8FA1), const Color(0xFF8B7355),
      const Color(0xFF6B5A8B), const Color(0xFF8B5030),
    ];
    return colors[index % colors.length];
  }

  Widget _buildMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEADBCE)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        _buildMenuItem(Icons.workspace_premium_rounded,
            'Seyahood Premium', () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const PremiumScreen()));
            }),
        _buildMenuDivider(),
        _buildMenuItem(Icons.notifications_active_outlined,
            'Bildirimler & Hatırlatıcılar', () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Yakında!')));
            }),
        _buildMenuDivider(),
        _buildMenuItem(Icons.help_center_outlined, 'Yardım', () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const HelpScreen()));
        }),
        _buildMenuDivider(),
        _buildMenuItem(Icons.shield_outlined, 'Gizlilik & Veri Güvenliği', () {
          Navigator.pushNamed(context, '/privacy');
        }),
        _buildMenuDivider(),
        _buildMenuItem(Icons.logout_rounded, 'Hesaptan Çıkış Yap', _logout,
            isDestructive: true),
      ]),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.shade50 : const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDestructive
                        ? Colors.red.shade100 : const Color(0xFFEADBCE)),
              ),
              child: Icon(icon,
                  color: isDestructive
                      ? Colors.red.shade400 : const Color(0xFFC46B4E),
                  size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(
                fontSize: 14,
                fontWeight: isDestructive ? FontWeight.w700 : FontWeight.w600,
                color: isDestructive
                    ? Colors.red.shade400 : const Color(0xFF1C110A)))),
            if (!isDestructive)
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFC4956A), size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildMenuDivider() => const Divider(
      height: 1, color: Color(0xFFF0EAE1), indent: 20, endIndent: 20);
}

class _DotGridPainter extends CustomPainter {
  final Color color;
  const _DotGridPainter({this.color = const Color(0xFFC4956A)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    const spacing = 12.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoverDotPainter extends CustomPainter {
  final Color baseColor;
  _CoverDotPainter(this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor.withOpacity(0.5).withBlue(
          (baseColor.blue * 0.7).toInt())
          .withRed((baseColor.red * 0.8).toInt())
      ..style = PaintingStyle.fill;
    const spacing = 18.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CoverDotPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor;
}