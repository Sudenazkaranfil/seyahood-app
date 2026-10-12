import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/journal.dart';
import '../models/entry.dart';
import '../services/journal_service.dart';
import '../services/entry_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'user_profile_screen.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_view.dart';
import '../widgets/ad_banner.dart';
import 'user_profile_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/interstitial_ad_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Journal> _journals = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isSearchingUsers = false;
  final _searchController = TextEditingController();
  String _sortBy = 'newest';
  String _selectedVibe = 'all';
  bool _hasError = false;
  List<Map<String, dynamic>> _popularUsers = [];

  final List<Map<String, String>> _vibes = [
    {'id': 'all', 'label': '🗺️ Tüm Rotalar'},
    {'id': 'europe', 'label': '🏛️ Kültür & Tarih'},
    {'id': 'nature', 'label': '🏔️ Doğa & Kamp'},
    {'id': 'sea', 'label': '🌊 Akdeniz & Sahil'},
    {'id': 'food', 'label': '☕ Kafe & Lezzet'},
    {'id': 'backpack', 'label': '🎒 Sırt Çantalı'},
  ];

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildPopularUsers() {
    if (_popularUsers.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(children: [
          const Icon(Icons.people_rounded, size: 16, color: AppTheme.terracotta),
          const SizedBox(width: 6),
          Text('Öne Çıkan Gezginler', style: GoogleFonts.playfairDisplay(
              fontSize: 16, fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary)),
        ]),
      ),
      SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _popularUsers.length,
          itemBuilder: (context, index) {
            final user = _popularUsers[index];
            final username = user['username'] ?? '';
            final profileImageUrl = user['profileImageUrl'];
            final followerCount = user['followerCount'] ?? 0;

            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) =>
                      UserProfileScreen(username: username))),
              child: Container(
                width: 76,
                margin: const EdgeInsets.only(right: 12),
                child: Column(children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.terracottaLight,
                      border: Border.all(
                          color: AppTheme.terracotta.withOpacity(0.4), width: 2),
                    ),
                    child: ClipOval(
                      child: profileImageUrl != null
                          ? Image.network(profileImageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.person_rounded,
                              color: AppTheme.terracotta, size: 28))
                          : Icon(Icons.person_rounded,
                          color: AppTheme.terracotta, size: 28),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('@$username',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTheme.sansBody(
                          size: 10, weight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  Text('$followerCount takipçi',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTheme.sansBody(
                          size: 9, color: AppTheme.textSecondary)),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
    ]);
  }

  Future<void> _loadJournals({String? search}) async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final allJournals = await JournalService.getPublicJournals();
      final token = await StorageService.getToken();
      final usersResponse = await http.get(
        Uri.parse('https://memorylane-wk1y.onrender.com/users/popular'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (usersResponse.statusCode == 200) {
        final data = jsonDecode(usersResponse.body);
        setState(() => _popularUsers = List<Map<String, dynamic>>.from(data));
      }
      final filtered = search != null && search.isNotEmpty
          ? allJournals.where((j) =>
          j.title.toLowerCase().contains(search.toLowerCase())).toList()
          : allJournals;
      setState(() {
        _journals = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _hasError = true; });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() { _users = []; _isSearchingUsers = false; });
      return;
    }
    setState(() => _isSearchingUsers = true);
    try {
      final users = await UserService.searchUsers(query);
      setState(() => _users = users);
    } catch (e) {
      setState(() => _users = []);
    } finally {
      setState(() => _isSearchingUsers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('Keşfet',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 28, fontWeight: FontWeight.w800,
                            color: const Color(0xFF1C110A), letterSpacing: -0.6)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.terracotta.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Ajanda',
                          style: AppTheme.sansBody(
                              size: 10, weight: FontWeight.w700,
                              color: AppTheme.terracotta)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text('Dünyanın dört bir yanından yol hikayeleri',
                      style: AppTheme.sansBody(
                          size: 13, color: AppTheme.textSecondary)),
                ]),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(children: [
                      Icon(Icons.tune_rounded, size: 15,
                          color: AppTheme.terracotta),
                      const SizedBox(width: 6),
                      Text('Sırala', style: AppTheme.sansBody(
                          size: 12, weight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Arama
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  _loadJournals(search: value);
                  _searchUsers(value);
                },
                style: AppTheme.sansBody(size: 14),
                decoration: InputDecoration(
                  hintText: 'Şehir, mekan veya gezgin ara...',
                  hintStyle: AppTheme.sansBody(
                      size: 13, color: AppTheme.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppTheme.terracotta, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          color: AppTheme.textMuted, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadJournals();
                        setState(() => _users = []);
                      })
                      : null,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Vibe hapları
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _vibes.length,
              itemBuilder: (context, index) {
                final vibe = _vibes[index];
                final isSelected = _selectedVibe == vibe['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedVibe = vibe['id']!);
                    if (vibe['id'] == 'all') {
                      _loadJournals();
                    } else {
                      _loadJournals(
                          search: vibe['label']!.substring(3).trim());
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.navDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected ? AppTheme.navDark : AppTheme.border),
                    ),
                    child: Center(
                      child: Text(vibe['label']!,
                          style: AppTheme.sansBody(
                              size: 11,
                              weight: isSelected
                                  ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white : const Color(0xFF523F31))),
                    ),
                  ),
                );
              },
            ),
          ),

          // Kullanıcılar
          if (_users.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (context) =>
                            UserProfileScreen(username: user['username']))),
                    child: Container(
                      width: 72, margin: const EdgeInsets.only(right: 12),
                      child: Column(children: [
                        Container(
                          width: 54, height: 54,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFC4956A), Color(0xFFEADBCE), Color(0xFFC46B4E)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                          ),
                          child: ClipOval(
                            child: user['profileImageUrl'] != null
                                ? Image.network(user['profileImageUrl'], fit: BoxFit.cover)
                                : Container(
                                color: AppTheme.terracottaLight,
                                child: Icon(Icons.person_rounded,
                                    color: AppTheme.terracotta, size: 24)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('@${user['username']}',
                            style: AppTheme.sansBody(
                                size: 11, weight: FontWeight.w600,
                                color: AppTheme.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Liste
          Expanded(
            child: _isLoading
                ? const ExploreSkeletonLoader()
                : _hasError
                ? ErrorView(onRetry: _loadJournals)
                : _journals.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.explore_off_rounded,
                        size: 32, color: AppTheme.terracotta),
                  ),
                  const SizedBox(height: 14),
                  Text(
                      _searchController.text.isNotEmpty
                          ? '"${_searchController.text}" ile eşleşen ajanda bulunamadı'
                          : 'Henüz paylaşılan ajanda yok',
                      textAlign: TextAlign.center,
                      style: AppTheme.sansBody(
                          size: 14, weight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Farklı bir arama yapmayı deneyin.',
                      style: AppTheme.sansBody(
                          size: 12, color: AppTheme.textSecondary)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
              itemCount: _journals.length,
              itemBuilder: (context, index) {
                if (index == 0 && _searchController.text.isEmpty) {
                  return Column(children: [
                    _buildPopularUsers(),
                    const AdBanner(),
                    _buildFeaturedCard(_journals[0]),
                  ]);
                }
                return _buildJournalCard(_journals[index]);
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 44, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2)))),
              Text('Ajandaları Sırala',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              _buildFilterChip('✨ En Yeni Eklenenler', 'newest'),
              const SizedBox(height: 10),
              _buildFilterChip('🔥 En Popüler & Beğenilenler', 'popular'),
              const SizedBox(height: 10),
              _buildFilterChip('👁️ En Çok Okunanlar', 'most_views'),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ]),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        _loadJournals(search: _searchController.text);
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.navDark : const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? AppTheme.navDark : AppTheme.border),
        ),
        child: Row(children: [
          Text(label, style: AppTheme.sansBody(
              size: 14, weight: FontWeight.w700,
              color: isSelected ? Colors.white : AppTheme.textPrimary)),
          const Spacer(),
          if (isSelected) Icon(Icons.check_circle_rounded,
              color: AppTheme.terracotta, size: 20),
        ]),
      ),
    );
  }

  Widget _buildFeaturedCard(Journal journal) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (context) => ExploreJournalScreen(journal: journal))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(fit: StackFit.expand, children: [
            journal.coverImageUrl != null
                ? Image.network(journal.coverImageUrl!, fit: BoxFit.cover)
                : Container(
              color: const Color(0xFFFAF7F2),
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(painter: DottedBackgroundPainter(),
                    size: Size.infinite),
                Text(
                  journal.title.isNotEmpty
                      ? journal.title[0].toUpperCase() : 'M',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 120, fontWeight: FontWeight.bold,
                      color: AppTheme.terracotta.withOpacity(0.12)),
                ),
              ]),
            ),
            // Gradient overlay sadece fotoğraf varsa
            if (journal.coverImageUrl != null)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent,
                      AppTheme.navDark.withOpacity(0.8),
                      AppTheme.navDark.withOpacity(0.95)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    stops: const [0.2, 0.7, 1.0],
                  ),
                ),
              ),
            // Kapaksız için alt gradient
            if (journal.coverImageUrl == null)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent,
                      const Color(0xFFFAF7F2).withOpacity(0.0),
                      const Color(0xFFEDE8E3).withOpacity(0.8)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    stops: const [0.4, 0.7, 1.0],
                  ),
                ),
              ),
            Positioned(
              top: 14, left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.terracotta,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Haftanın Ajandası',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ]),
              ),
            ),
            Positioned(
                top: 12, right: 12,
                child: _SaveButton(journalId: journal.id)),
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(journal.title,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: journal.coverImageUrl != null
                                ? Colors.white : AppTheme.textPrimary,
                            letterSpacing: -0.4)),
                    const SizedBox(height: 6),
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (context) =>
                                UserProfileScreen(username: journal.username ?? ''))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: journal.coverImageUrl != null
                                ? Colors.white.withOpacity(0.15)
                                : AppTheme.terracotta.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            Icon(Icons.person_outline, size: 12,
                                color: journal.coverImageUrl != null
                                    ? Colors.white : AppTheme.terracotta),
                            const SizedBox(width: 4),
                            Text('@${journal.username ?? 'gezgin'}',
                                style: AppTheme.sansBody(
                                    size: 11, weight: FontWeight.w600,
                                    color: journal.coverImageUrl != null
                                        ? Colors.white : AppTheme.terracotta)),
                          ]),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.remove_red_eye_outlined, size: 13,
                          color: journal.coverImageUrl != null
                              ? Colors.white70 : AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('${journal.viewCount}',
                          style: AppTheme.sansBody(
                              size: 11, weight: FontWeight.w700,
                              color: journal.coverImageUrl != null
                                  ? Colors.white70 : AppTheme.textSecondary)),
                    ]),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildJournalCard(Journal journal) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (context) => ExploreJournalScreen(journal: journal))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(children: [
              journal.coverImageUrl != null
                  ? Image.network(journal.coverImageUrl!,
                  height: 140, width: double.infinity, fit: BoxFit.cover)
                  : SizedBox(
                height: 110, width: double.infinity,
                child: Stack(alignment: Alignment.center, children: [
                  Container(color: const Color(0xFFFAF7F2)),
                  CustomPaint(painter: DottedBackgroundPainter(),
                      size: Size.infinite),
                  // Washi tape üst şerit
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                        height: 4,
                        color: AppTheme.terracotta.withOpacity(0.4)),
                  ),
                  // Büyük harf
                  Text(
                    journal.title.isNotEmpty
                        ? journal.title[0].toUpperCase() : 'M',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 72, fontWeight: FontWeight.bold,
                        color: AppTheme.terracotta.withOpacity(0.12)),
                  ),
                ]),
              ),
              Positioned(top: 10, right: 10,
                  child: _SaveButton(journalId: journal.id)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(journal.title, style: AppTheme.sansBody(
                      size: 15, weight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (context) =>
                              UserProfileScreen(username: journal.username ?? ''))),
                      child: Text('@${journal.username ?? ''}',
                          style: AppTheme.sansBody(
                              size: 12, weight: FontWeight.w700,
                              color: AppTheme.terracotta)),
                    ),
                    const Spacer(),
                    Icon(Icons.remove_red_eye_outlined,
                        size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text('${journal.viewCount}',
                        style: AppTheme.sansBody(
                            size: 11, color: AppTheme.textSecondary)),
                    const SizedBox(width: 10),
                    Text(
                        '${journal.createdAt.day}.${journal.createdAt.month}.${journal.createdAt.year}',
                        style: AppTheme.sansBody(
                            size: 11, color: AppTheme.textSecondary)),
                  ]),
                ]),
          ),
        ]),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final int journalId;
  const _SaveButton({required this.journalId});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _saved = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    try {
      final saved = await JournalService.isSaved(widget.journalId);
      setState(() { _saved = saved; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return SizedBox(width: 24, height: 24,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppTheme.terracotta));
    return GestureDetector(
      onTap: () async {
        try {
          final saved = await JournalService.toggleSave(widget.journalId);
          setState(() => _saved = saved);
        } catch (e) {}
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _saved ? AppTheme.terracotta : Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(_saved ? 'Kaydedildi' : 'Kaydet',
              style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
      ),
    );
  }
}

class ExploreJournalScreen extends StatefulWidget {
  final Journal journal;
  const ExploreJournalScreen({super.key, required this.journal});

  @override
  State<ExploreJournalScreen> createState() => _ExploreJournalScreenState();
}

class _ExploreJournalScreenState extends State<ExploreJournalScreen> {
  List<Entry> _entries = [];
  bool _isLoading = true;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadEntries();
    JournalService.incrementView(widget.journal.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    try {
      final entries = await EntryService.getEntries(widget.journal.id);
      setState(() { _entries = entries; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _exit() {
    InterstitialAdService.instance.onJournalViewed();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _exit();
      },
      child: Scaffold(
      backgroundColor: AppTheme.navDark,
      appBar: AppBar(
        backgroundColor: AppTheme.navDark,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFFAF7F2), size: 16),
          ),
          onPressed: _exit,
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.journal.title,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: const Color(0xFFFAF7F2))),
          if (widget.journal.username != null)
            Text('@${widget.journal.username} • Ajandası',
                style: AppTheme.sansBody(
                    size: 11, color: AppTheme.terracotta)),
        ]),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _SaveButton(journalId: widget.journal.id)),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.terracotta))
          : _entries.isEmpty
          ? Center(child: Text('Bu ajandada henüz sayfa yok',
          style: AppTheme.sansBody(
              size: 14, color: const Color(0xFFEADBCE))))
          : Column(children: [
        Expanded(child: _buildPageView()),
        _buildThumbnailList(),
      ]),
      ),
    );
  }

  Widget _buildPageView() {
    return Stack(children: [
      PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: _entries.length,
        itemBuilder: (context, index) => _buildPage(_entries[index], index),
      ),
      if (_currentPage > 0)
        Positioned(
          left: 12, top: 0, bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.navDark.withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                ),
                child: const Icon(Icons.chevron_left_rounded,
                    color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      if (_currentPage < _entries.length - 1)
        Positioned(
          right: 12, top: 0, bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.navDark.withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                ),
                child: const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _buildPage(Entry entry, int index) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaleX = constraints.maxWidth / 360.0;
            final scaleY = constraints.maxHeight / 600.0;
            final scale = scaleX < scaleY ? scaleX : scaleY;
            return Stack(children: [
              CustomPaint(painter: DottedBackgroundPainter(),
                  size: Size.infinite),
              if (entry.canvasData != null)
                ..._buildCanvasPreview(entry.canvasData!, scale)
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (entry.locationName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                  color: AppTheme.terracotta,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(entry.locationName!,
                                        style: AppTheme.sansBody(
                                            size: 12,
                                            weight: FontWeight.w600,
                                            color: Colors.white)),
                                  ]),
                            ),
                          if (entry.textContent != null) ...[
                            const SizedBox(height: 16),
                            Text(entry.textContent!,
                                style: GoogleFonts.playfairDisplay(
                                    fontSize: 15,
                                    color: AppTheme.textPrimary,
                                    height: 1.6,
                                    fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center),
                          ],
                        ]),
                  ),
                ),
              Positioned(
                bottom: 14, right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                      entry.date != null
                          ? '${entry.date!.day} ${_getMonth(entry.date!.month)}'
                          : '',
                      style: AppTheme.sansBody(
                          size: 10, weight: FontWeight.w700,
                          color: AppTheme.textSecondary)),
                ),
              ),
              Positioned(
                top: 14, right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.navDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${index + 1} / ${_entries.length}',
                      style: AppTheme.sansBody(
                          size: 10, weight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  List<Widget> _buildCanvasPreview(String canvasData, double scale) {
    try {
      final Map<String, dynamic> data = jsonDecode(canvasData);
      List<Widget> widgets = [];

      if (data.containsKey('stickers') || data.containsKey('locations')) {
        final stickers = (data['stickers'] as List?) ?? [];
        final locations = (data['locations'] as List?) ?? [];
        final paths = (data['paths'] as List?) ?? [];

        if (paths.isNotEmpty) {
          final drawingPaths =
          paths.map((p) => DrawingPath.fromJson(p)).toList();
          widgets.add(Positioned.fill(
              child: CustomPaint(
                  painter: DrawingPainter(drawingPaths, scale))));
        }

        for (final s in stickers.where((s) => s['type'] == 'image')) {
          final model = s['model'] as Map<String, dynamic>?;
          if (model == null) continue;
          final top = (model['top'] as num? ?? 0).toDouble() * scale;
          final left = (model['left'] as num? ?? 0).toDouble() * scale;
          final stickerScale = (model['scale'] as num? ?? 1.0).toDouble();
          final angle = (model['angle'] as num? ?? 0).toDouble();
          final url = model['url'] as String? ?? '';
          widgets.add(Positioned(
            left: left, top: top,
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scale: stickerScale * scale,
                alignment: Alignment.topLeft,
                child: url.startsWith('http')
                    ? Image.network(url, width: 50, height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 50, height: 50))
                    : const SizedBox(),
              ),
            ),
          ));
        }

        for (final l in locations) {
          final name = l['name'] as String? ?? '';
          final x = (l['x'] as num? ?? 0).toDouble() * scale;
          final y = (l['y'] as num? ?? 0).toDouble() * scale;
          final color = l['color'] != null
              ? Color(l['color']) : AppTheme.terracotta;
          widgets.add(Positioned(
            left: x, top: y,
            child: Transform.scale(
              scale: scale, alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(24)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(name, style: TextStyle(
                      color: color.computeLuminance() > 0.5
                          ? Colors.black87 : Colors.white,
                      fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ));
        }

        for (final s in stickers.where((s) => s['type'] != 'image')) {
          final type = s['type'] as String;
          final content = s['content'] as String?;
          final model = s['model'] as Map<String, dynamic>?;
          if (model == null) continue;
          final top = (model['top'] as num? ?? 0).toDouble() * scale;
          final left = (model['left'] as num? ?? 0).toDouble() * scale;
          final stickerScale = (model['scale'] as num? ?? 1.0).toDouble();
          final text = model['text'] as String? ?? content ?? '';
          final textStyleData = model['textStyle'] as Map<String, dynamic>?;
          final fontSize =
          (textStyleData?['fontSize'] as num? ?? 14).toDouble();
          final color = textStyleData?['color'] != null
              ? Color(textStyleData!['color']) : AppTheme.textPrimary;
          widgets.add(Positioned(
            left: left, top: top,
            child: Transform.scale(
              scale: stickerScale * scale, alignment: Alignment.topLeft,
              child: type == 'emoji'
                  ? Text(text, style: const TextStyle(fontSize: 48))
                  : Text(text, style: TextStyle(
                  fontSize: fontSize, color: color,
                  fontWeight: FontWeight.w500)),
            ),
          ));
        }
      }
      return widgets;
    } catch (e) {
      return [];
    }
  }

  Widget _buildThumbnailList() {
    return Container(
      height: 86 + MediaQuery.of(context).padding.bottom,
      color: AppTheme.navDark,
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8, top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final isSelected = index == _currentPage;
          return GestureDetector(
            onTap: () => _pageController.animateToPage(index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52, height: 60,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFAF7F2)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSelected
                        ? AppTheme.terracotta
                        : Colors.white.withOpacity(0.15),
                    width: isSelected ? 2.5 : 1),
                boxShadow: [if (isSelected) BoxShadow(
                    color: AppTheme.terracotta.withOpacity(0.4),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories_rounded, size: 16,
                      color: isSelected
                          ? AppTheme.terracotta : Colors.white54),
                  const SizedBox(height: 3),
                  Text('${index + 1}', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppTheme.textPrimary : Colors.white70)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getMonth(int month) {
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return months[month - 1];
  }
}

class DrawingPath {
  List<Offset> points;
  Color color;
  double strokeWidth;

  DrawingPath({required this.points, required this.color,
    required this.strokeWidth});

  factory DrawingPath.fromJson(Map<String, dynamic> json) => DrawingPath(
    points: (json['points'] as List).map((p) =>
        Offset((p['x'] as num).toDouble(),
            (p['y'] as num).toDouble())).toList(),
    color: Color(json['color'] as int),
    strokeWidth: (json['strokeWidth'] as num).toDouble(),
  );
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final double scale;
  DrawingPainter(this.paths, [this.scale = 0.6]);

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in paths) {
      if (path.points.isEmpty) continue;
      final paint = Paint()
        ..color = path.color
        ..strokeWidth = path.strokeWidth * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final drawPath = Path();
      drawPath.moveTo(path.points.first.dx * scale,
          path.points.first.dy * scale);
      for (int i = 1; i < path.points.length; i++) {
        drawPath.lineTo(
            path.points[i].dx * scale, path.points[i].dy * scale);
      }
      canvas.drawPath(drawPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

class DottedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4C5B0).withOpacity(0.4)
      ..style = PaintingStyle.fill;
    const spacing = 20.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}