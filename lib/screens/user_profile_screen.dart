import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../services/journal_service.dart';
import '../models/journal.dart';
import 'explore_screen.dart';
import 'follow_list_screen.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_view.dart';
import '../widgets/plan_badge.dart';
import '../widgets/ad_banner.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _followStatus;
  List<Journal> _journals = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await UserService.getUserProfile(widget.username);
      final followStatus = await UserService.getFollowStatus(widget.username);
      final journals = await JournalService.getPublicJournals();
      final userJournals =
      journals.where((j) => j.username == widget.username).toList();
      setState(() {
        _user = user;
        _followStatus = followStatus;
        _journals = userJournals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final following = await UserService.toggleFollow(widget.username);
      setState(() {
        _followStatus!['following'] = following;
        _followStatus!['followerCount'] =
            (_followStatus!['followerCount'] as int) + (following ? 1 : -1);
      });
    } catch (e) {}
  }

  Map<String, dynamic> _getLevelInfo(int journalCount) {
    if (journalCount <= 3) {
      return {'emoji': '🌱', 'title': 'Yeni Gezgin',
        'color': const Color(0xFF7BAE7F)};
    } else if (journalCount <= 10) {
      return {'emoji': '🗺️', 'title': 'Kaşif',
        'color': const Color(0xFFC46B4E)};
    } else if (journalCount <= 20) {
      return {'emoji': '✈️', 'title': 'Seyyah',
        'color': const Color(0xFF5B8A6F)};
    } else if (journalCount <= 50) {
      return {'emoji': '🌍', 'title': 'Dünya Gezgini',
        'color': const Color(0xFF3D6B9E)};
    } else {
      return {'emoji': '🏆', 'title': 'Efsane Gezgin',
        'color': const Color(0xFFD4A017)};
    }
  }

  String get _displayName {
    final firstName = _user?['firstName'];
    final lastName = _user?['lastName'];
    if (firstName != null && firstName.toString().isNotEmpty) {
      if (lastName != null && lastName.toString().isNotEmpty) {
        return '$firstName $lastName';
      }
      return firstName.toString();
    }
    return widget.username;
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
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
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
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('@${widget.username}',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 16, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: -0.2)),
                      Text('Gezgin Profili', style: AppTheme.sansBody(
                          size: 11, weight: FontWeight.w600,
                          color: AppTheme.terracotta)),
                    ]),
              ]),
            ),
          ),
        ),

        Expanded(
          child: _isLoading
              ? const ProfileSkeletonLoader()
              : _hasError
              ? ErrorView(onRetry: _loadData)
              : SingleChildScrollView(
            child: Column(children: [
              _buildHeader(),
              const SizedBox(height: 8),
              const AdBanner(),
              const SizedBox(height: 4),
              _buildJournalGrid(),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    final isFollowing = _followStatus?['following'] ?? false;
    final followerCount = _followStatus?['followerCount'] ?? 0;
    final followingCount = _followStatus?['followingCount'] ?? 0;
    final level = _getLevelInfo(_journals.length);
    final levelColor = level['color'] as Color;

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(children: [
        // Cover
        Container(
          height: 96,
          decoration: BoxDecoration(color: AppTheme.terracottaLight),
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _CoverDotPainter())),
            Positioned(
              right: -16, bottom: -16,
              child: Icon(Icons.explore_outlined, size: 96,
                  color: AppTheme.terracotta.withOpacity(0.08)),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(children: [
            // Avatar
            Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.terracottaLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: ClipOval(
                  child: _user?['profileImageUrl'] != null
                      ? Image.network(_user!['profileImageUrl'],
                      fit: BoxFit.cover)
                      : const Center(child: Icon(
                      Icons.person_outline_rounded,
                      color: AppTheme.terracotta, size: 40)),
                ),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -18),
              child: Column(children: [
                // İsim + seviye rozeti
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(_displayName,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.4)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: levelColor.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(level['emoji'],
                            style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 4),
                        Text(level['title'], style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800,
                            color: levelColor)),
                      ]),
                    ),
                    PlanBadge(
                        isPlus: _user?['isPlus'] ?? false,
                        isPro: _user?['isPro'] ?? false),
                  ],
                ),

                const SizedBox(height: 3),
                Text('@${widget.username}', style: AppTheme.sansBody(
                    size: 12, weight: FontWeight.w600,
                    color: AppTheme.terracotta)),

                if (_user?['bio'] != null &&
                    _user!['bio'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(_user!['bio'],
                        textAlign: TextAlign.center,
                        style: AppTheme.sansBody(
                            size: 13, color: AppTheme.textSecondary)),
                  ),
                ],

                if (_user?['location'] != null &&
                    _user!['location'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppTheme.terracotta),
                        const SizedBox(width: 4),
                        Text(_user!['location'], style: AppTheme.sansBody(
                            size: 12, weight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                      ]),
                ],

                const SizedBox(height: 18),

                // Stats
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Ajanda', _journals.length.toString(), null),
                      Container(width: 1, height: 32, color: AppTheme.border),
                      _buildStat('Takipçi', followerCount.toString(), () {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (context) => FollowListScreen(
                                username: widget.username,
                                type: 'followers')));
                      }),
                      Container(width: 1, height: 32, color: AppTheme.border),
                      _buildStat('Takip', followingCount.toString(), () {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (context) => FollowListScreen(
                                username: widget.username,
                                type: 'following')));
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Takip butonu
                SizedBox(
                  width: double.infinity, height: 44,
                  child: ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing
                          ? const Color(0xFFFAF7F2) : AppTheme.terracotta,
                      foregroundColor: isFollowing
                          ? AppTheme.textPrimary : Colors.white,
                      side: isFollowing
                          ? BorderSide(color: AppTheme.border, width: 1.5)
                          : null,
                      elevation: isFollowing ? 0 : 3,
                      shadowColor: AppTheme.terracotta.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isFollowing
                            ? Icons.check_rounded
                            : Icons.person_add_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(isFollowing ? 'Takip Ediliyor' : 'Takip Et',
                            style: AppTheme.sansBody(
                                size: 14, weight: FontWeight.w700,
                                color: isFollowing
                                    ? AppTheme.textPrimary : Colors.white)),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        Container(height: 1, color: AppTheme.border),
      ]),
    );
  }

  Widget _buildStat(String label, String value, VoidCallback? onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(children: [
          Text(value, style: GoogleFonts.playfairDisplay(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.sansBody(
              size: 11, weight: FontWeight.w600,
              color: AppTheme.terracotta)),
        ]),
      ),
    );
  }

  Widget _buildJournalGrid() {
    if (_journals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.terracottaLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(Icons.book_outlined,
                      size: 30, color: AppTheme.terracotta),
                ),
                const SizedBox(height: 14),
                Text('Henüz herkese açık ajanda yok',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text('Bu gezgin henüz paylaştığı bir ajanda eklemedi.',
                    style: AppTheme.sansBody(
                        size: 12, color: AppTheme.textSecondary)),
              ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_stories_outlined,
              size: 16, color: AppTheme.terracotta),
          const SizedBox(width: 6),
          Text('$_displayName Ajandaları',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.terracottaLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${_journals.length} ajanda',
                style: AppTheme.sansBody(
                    size: 11, weight: FontWeight.w700,
                    color: AppTheme.terracotta)),
          ),
        ]),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10,
            mainAxisSpacing: 12, childAspectRatio: 0.72,
          ),
          itemCount: _journals.length,
          itemBuilder: (context, index) {
            final journal = _journals[index];
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) =>
                      ExploreJournalScreen(journal: journal))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(4),
                            right: Radius.circular(12)),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(4),
                            right: Radius.circular(12)),
                        child: journal.coverImageUrl != null
                            ? Image.network(journal.coverImageUrl!,
                            fit: BoxFit.cover, width: double.infinity)
                            : _buildFallbackCover(index, journal),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(journal.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTheme.sansBody(
                          size: 11, weight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                ],
              ),
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

  Color _getColor(int index) {
    final colors = [
      const Color(0xFFC46B4E), const Color(0xFF5B8A6F),
      const Color(0xFF7B8FA1), const Color(0xFF8B7355),
      const Color(0xFF6B5A8B), const Color(0xFF8B5030),
    ];
    return colors[index % colors.length];
  }
}

class _CoverDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.terracotta.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    const spacing = 18.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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