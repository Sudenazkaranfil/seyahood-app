import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';
import '../services/journal_service.dart';
import '../services/subscription_service.dart';
import '../widgets/limit_reached_sheet.dart';
import '../models/journal.dart';
import '../widgets/app_nav_bar.dart';
import 'journal_detail_screen.dart';
import 'explore_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'premium_screen.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_view.dart';
import '../widgets/ad_banner.dart';
import '../services/notification_service.dart';
import 'notifications_screen.dart';
import '../l10n/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _username;
  String? _firstName;
  String? _profileImageUrl;
  int _selectedIndex = 0;
  List<Journal> _myJournals = [];
  List<Journal> _savedJournals = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isFreePlan = true;
  int _unreadNotificationCount = 0;

  static const String baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) setState(() => _unreadNotificationCount = count);
    } catch (e) {}
  }

  Future<void> _loadData() async {
    final username = await StorageService.getUsername();
    final token = await StorageService.getToken();
    setState(() => _username = username ?? context.tr('common.travelerFallback'));

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _profileImageUrl = data['profileImageUrl'];
          _firstName = data['firstName'];
        });
      }
    } catch (e) {}

    try {
      final subscription = await SubscriptionService.instance.getStatus();
      setState(() => _isFreePlan = !subscription.isPlus && !subscription.isPro);
    } catch (e) {}

    await _loadJournals();
  }

  Future<void> _loadJournals() async {
    try {
      final myJournals = await JournalService.getJournals();
      final savedJournals = await JournalService.getSavedJournals();
      setState(() {
        _myJournals = myJournals;
        _savedJournals = savedJournals;
        _isLoading = false;
      });
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        await StorageService.clearAll();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _createJournal(String title, String visibility) async {
    try {
      final journal = await JournalService.createJournal(title, visibility);
      setState(() => _myJournals.add(journal));
      if (mounted) {
        await Navigator.push(context, MaterialPageRoute(
            builder: (context) => JournalDetailScreen(journal: journal)));
        await _loadJournals();
      }
    } on LimitReachedException catch (_) {
      if (mounted) showLimitReachedSheet(context, limitType: 'journal');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('home.createJournalFailed'))));
    }
  }

  Future<bool?> _showDeleteConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('home.deleteJournal.title'),
            style: GoogleFonts.playfairDisplay(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
            context.tr('home.deleteJournal.content'),
            style: AppTheme.sansBody(size: 14, color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('home.deleteJournal.cancel'),
                style: AppTheme.sansBody(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Text(context.tr('home.deleteJournal.confirm')),
          ),
        ],
      ),
    );
  }

  void _showCreateJournalDialog() {
    final titleController = TextEditingController();
    String selectedVisibility = 'PRIVATE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.brown.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('home.newJournal.title'),
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                autofocus: true,
                style: AppTheme.sansBody(),
                decoration: InputDecoration(
                  labelText: context.tr('home.newJournal.titleFieldLabel'),
                  labelStyle: AppTheme.sansBody(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.terracotta, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setModalState(() => selectedVisibility = 'PUBLIC'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedVisibility == 'PUBLIC'
                            ? AppTheme.terracotta : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: selectedVisibility == 'PUBLIC'
                                ? AppTheme.terracotta : AppTheme.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(context.tr('home.newJournal.public'),
                          style: AppTheme.sansBody(
                              size: 13, weight: FontWeight.w700,
                              color: selectedVisibility == 'PUBLIC'
                                  ? Colors.white : AppTheme.textPrimary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setModalState(() => selectedVisibility = 'PRIVATE'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedVisibility == 'PRIVATE'
                            ? AppTheme.navDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: selectedVisibility == 'PRIVATE'
                                ? AppTheme.navDark : AppTheme.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(context.tr('home.newJournal.private'),
                          style: AppTheme.sansBody(
                              size: 13, weight: FontWeight.w700,
                              color: selectedVisibility == 'PRIVATE'
                                  ? Colors.white : AppTheme.textPrimary)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;
                    Navigator.pop(context);
                    await _createJournal(title, selectedVisibility);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(context.tr('home.newJournal.startButton'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildJournalsTab();
      case 1: return const ExploreScreen();
      case 2: return const MapScreen();
      case 3: return ProfileScreen(onProfileUpdated: () => _loadData());
      default: return _buildJournalsTab();
    }
  }

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().toLocal().hour;
    if (hour < 12) return context.tr('home.greeting.morning');
    if (hour < 18) return context.tr('home.greeting.afternoon');
    return context.tr('home.greeting.evening');
  }

  String _getDate(BuildContext context) {
    final dayKeys = ['common.day.mon', 'common.day.tue', 'common.day.wed',
      'common.day.thu', 'common.day.fri', 'common.day.sat', 'common.day.sun'];
    final monthKeys = ['common.month.jan', 'common.month.feb', 'common.month.mar',
      'common.month.apr', 'common.month.may', 'common.month.jun',
      'common.month.jul', 'common.month.aug', 'common.month.sep',
      'common.month.oct', 'common.month.nov', 'common.month.dec'];
    final now = DateTime.now();
    return '${now.day} ${context.tr(monthKeys[now.month - 1])}, '
        '${context.tr(dayKeys[now.weekday - 1])}';
  }

  Widget _buildJournalsTab() {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppTheme.terracotta,
        onRefresh: _loadJournals,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              if (_isLoading)
                const HomeSkeletonLoader()
              else if (_hasError)
                ErrorView(onRetry: _loadJournals)
              else ...[
                if (_myJournals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildHeroCard(_myJournals.first),
                  ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildQuickPromptCard(),
                ),
                const SizedBox(height: 16),
                const AdBanner(),
                const SizedBox(height: 8),
                _buildJournalsSection(),
                if (_savedJournals.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSavedSection(),
                ],
                if (_myJournals.isEmpty) _buildEmptyState(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 3),
              child: Container(
                width: 44, height: 44,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFC4956A), Color(0xFFEADBCE), Color(0xFFC46B4E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipOval(
                  child: _profileImageUrl != null
                      ? Image.network(_profileImageUrl!, fit: BoxFit.cover)
                      : Container(
                      color: AppTheme.terracottaLight,
                      child: Icon(Icons.person_outline,
                          color: AppTheme.terracotta, size: 22)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(_getGreeting(context),
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 13, fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary)),
                const SizedBox(width: 4),
                Text(_firstName ?? _username ?? context.tr('common.travelerFallback'),
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
              ]),
              Text(_getDate(context),
                  style: AppTheme.sansBody(
                      size: 11, weight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
            ]),
          ]),
          Row(children: [
            if (_isFreePlan) ...[
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const PremiumScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.terracotta,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('👑', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(context.tr('common.goProAction'), style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: Colors.white)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Stack(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.navDark,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: Color(0xFFEADBCE), size: 20),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const NotificationsScreen()));
                    _loadUnreadNotificationCount();
                  },
                ),
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 2, top: 2,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.navDark, width: 1.5),
                    ),
                  ),
                ),
            ]),
          ]),
        ],
      ),
    );
  }

  Widget _buildHeroCard(Journal journal) {
    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push(context, MaterialPageRoute(
            builder: (context) => JournalDetailScreen(journal: journal)));
        if (updated == true) await _loadJournals();
      },
      child: Container(
        height: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border, width: 1),
          boxShadow: [BoxShadow(
            color: const Color(0xFF2A1D15).withOpacity(0.18),
            blurRadius: 32, offset: const Offset(0, 14),
          )],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(fit: StackFit.expand, children: [
            journal.coverImageUrl != null
                ? Image.network(journal.coverImageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackCover(journal))
                : _buildFallbackCover(journal),
            if (journal.coverImageUrl != null)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.85)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    stops: const [0.4, 0.65, 1.0],
                  ),
                ),
              ),
            Positioned(
              top: 14, left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome, size: 13,
                      color: Color(0xFFC46B4E)),
                  const SizedBox(width: 4),
                  Text(context.tr('home.lastTripBadge'), style: AppTheme.sansBody(
                      size: 11, weight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
                ]),
              ),
            ),
            Positioned(
              top: 14, right: 14,
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_border_rounded,
                    size: 18, color: Color(0xFF1C110A)),
              ),
            ),
            Positioned(
              bottom: 18, left: 18, right: 18,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: journal.visibility == 'PUBLIC'
                        ? const Color(0xFFBBEECE)
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    journal.visibility == 'PUBLIC'
                        ? context.tr('home.visibility.publicLong')
                        : context.tr('home.visibility.privateLong'),
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5,
                        color: journal.visibility == 'PUBLIC'
                            ? const Color(0xFF0A3D1E) : Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(journal.title,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: journal.coverImageUrl != null
                            ? Colors.white : AppTheme.textPrimary,
                        shadows: journal.coverImageUrl != null ? [Shadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2))] : null)),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.location_on, size: 14,
                      color: journal.coverImageUrl != null
                          ? const Color(0xFFFFDCBF) : AppTheme.terracotta),
                  const SizedBox(width: 4),
                  Text(context.tr('home.travelLabel'), style: AppTheme.sansBody(
                      size: 12, weight: FontWeight.w600,
                      color: journal.coverImageUrl != null
                          ? const Color(0xFFFFDCBF) : AppTheme.terracotta)),
                  const SizedBox(width: 10),
                  Text(
                      journal.visibility == 'PUBLIC'
                          ? context.tr('home.visibility.sharedSuffix')
                          : context.tr('home.visibility.privateSuffix'),
                      style: AppTheme.sansBody(size: 11,
                          color: journal.coverImageUrl != null
                              ? Colors.white.withOpacity(0.85)
                              : AppTheme.textSecondary)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildFallbackCover(Journal journal) {
    return Container(
      color: const Color(0xFFFAF7F2),
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(painter: _DotGridPainter(), size: Size.infinite),
        Text(
          journal.title.isNotEmpty ? journal.title[0].toUpperCase() : 'M',
          style: GoogleFonts.playfairDisplay(
              fontSize: 100, fontWeight: FontWeight.bold,
              color: AppTheme.terracotta.withOpacity(0.12)),
        ),
      ]),
    );
  }

  Widget _buildQuickPromptCard() {
    return GestureDetector(
      onTap: _showCreateJournalDialog,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.navDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.terracotta.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_note_rounded,
                color: AppTheme.terracotta, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('home.quickPrompt.title'),
                    style: AppTheme.sansBody(
                        size: 13, weight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(context.tr('home.quickPrompt.subtitle'),
                    style: AppTheme.sansBody(
                        size: 11, color: Colors.white.withOpacity(0.6))),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.terracotta,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(context.tr('home.quickPrompt.startButton'),
                style: AppTheme.sansBody(
                    size: 12, weight: FontWeight.w700, color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  Widget _buildJournalsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Text(context.tr('home.myJournals'),
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.navDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('(${_myJournals.length})',
                style: AppTheme.sansBody(
                    size: 11, weight: FontWeight.w700,
                    color: const Color(0xFFEADBCE))),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showCreateJournalDialog,
            child: Row(children: [
              Text(context.tr('home.addNew'),
                  style: AppTheme.sansBody(
                      size: 12, weight: FontWeight.w700,
                      color: AppTheme.terracotta)),
              const SizedBox(width: 2),
              Icon(Icons.add, size: 16, color: AppTheme.terracotta),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      _myJournals.isEmpty
          ? const SizedBox()
          : SizedBox(
        height: 195,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _myJournals.length,
          itemBuilder: (context, index) =>
              _buildJournalCard(_myJournals[index]),
        ),
      ),
    ]);
  }

  Widget _buildJournalCard(Journal journal) {
    return Dismissible(
      key: Key('journal_${journal.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      confirmDismiss: (direction) => _showDeleteConfirmDialog(),
      onDismissed: (direction) async {
        final idx = _myJournals.indexWhere((j) => j.id == journal.id);
        if (idx != -1) {
          final removed = _myJournals[idx];
          setState(() => _myJournals.removeAt(idx));
          try {
            await JournalService.deleteJournal(journal.id);
          } catch (e) {
            setState(() => _myJournals.insert(idx, removed));
          }
        }
      },
      child: GestureDetector(
        onTap: () async {
          final updated = await Navigator.push(context, MaterialPageRoute(
              builder: (context) => JournalDetailScreen(journal: journal)));
          if (updated == true) await _loadJournals();
        },
        onLongPress: () async {
          final shouldDelete = await _showDeleteConfirmDialog();
          if (shouldDelete != true) return;
          final idx = _myJournals.indexWhere((j) => j.id == journal.id);
          if (idx == -1) return;
          final removed = _myJournals[idx];
          setState(() => _myJournals.removeAt(idx));
          try {
            await JournalService.deleteJournal(journal.id);
          } catch (e) {
            setState(() => _myJournals.insert(idx, removed));
          }
        },
        child: Container(
          width: 175,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                height: 110, width: double.infinity,
                child: Stack(fit: StackFit.expand, children: [
                  journal.coverImageUrl != null
                      ? Image.network(journal.coverImageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildFallbackCover(journal))
                      : _buildFallbackCover(journal),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                          journal.visibility == 'PUBLIC'
                              ? context.tr('home.visibility.publicShort')
                              : context.tr('home.visibility.privateShort'),
                          style: AppTheme.sansBody(
                              size: 9, weight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(journal.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${journal.createdAt.day}.${journal.createdAt.month}.${journal.createdAt.year}',
                              style: AppTheme.sansBody(
                                  size: 10, color: AppTheme.textSecondary)),
                          Text(context.trf('home.saveCountLabel',
                              {'count': journal.saveCount.toString()}),
                              style: AppTheme.sansBody(
                                  size: 10, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(context.tr('home.savedJournals'),
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
      ),
      const SizedBox(height: 10),
      ..._savedJournals.map((journal) => Dismissible(
        key: Key('saved_${journal.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.bookmark_remove_outlined,
              color: Colors.white, size: 22),
        ),
        onDismissed: (direction) async {
          try {
            await JournalService.toggleSave(journal.id);
            setState(() => _savedJournals.remove(journal));
          } catch (e) {
            setState(() => _savedJournals.add(journal));
          }
        },
        child: GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
                builder: (context) =>
                    ExploreJournalScreen(journal: journal)));
            await _loadJournals();
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border, width: 0.5),
              boxShadow: [AppTheme.softShadow],
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16)),
                child: SizedBox(
                  width: 72, height: 72,
                  child: journal.coverImageUrl != null
                      ? Image.network(journal.coverImageUrl!, fit: BoxFit.cover)
                      : _buildFallbackCover(journal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(journal.title,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 3),
                Text('@${journal.username ?? ''}',
                    style: AppTheme.sansBody(
                        size: 11, color: AppTheme.terracotta,
                        weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.visibility_outlined, size: 11,
                      color: AppTheme.textSecondary.withOpacity(0.6)),
                  const SizedBox(width: 3),
                  Text('${journal.viewCount}',
                      style: AppTheme.sansBody(size: 10,
                          color: AppTheme.textSecondary.withOpacity(0.6))),
                  const SizedBox(width: 8),
                  Icon(Icons.bookmark_outline, size: 11,
                      color: AppTheme.textSecondary.withOpacity(0.6)),
                  const SizedBox(width: 3),
                  Text('${journal.saveCount}',
                      style: AppTheme.sansBody(size: 10,
                          color: AppTheme.textSecondary.withOpacity(0.6))),
                ]),
              ])),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right,
                    color: AppTheme.textSecondary, size: 18),
              ),
            ]),
          ),
        ),
      )).toList(),
    ]);
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppTheme.navDark,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.book_outlined, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(context.tr('home.empty.title'),
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(context.tr('home.empty.subtitle'),
              textAlign: TextAlign.center,
              style: AppTheme.sansBody(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showCreateJournalDialog,
            icon: const Icon(Icons.add, size: 16),
            label: Text(context.tr('home.empty.createButton')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: _buildBody(),
      bottomNavigationBar: AppNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 5) {
            _showCreateJournalDialog();
          } else {
            setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC4956A).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    const spacing = 14.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}