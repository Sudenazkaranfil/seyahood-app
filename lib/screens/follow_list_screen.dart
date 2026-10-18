import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../widgets/error_view.dart';
import 'user_profile_screen.dart';
import '../l10n/app_strings.dart';

class FollowListScreen extends StatefulWidget {
  final String username;
  final String type;

  const FollowListScreen({
    super.key,
    required this.username,
    required this.type,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final username = await StorageService.getUsername();
    setState(() => _currentUsername = username);
  }

  Future<void> _loadUsers() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final users = widget.type == 'followers'
          ? await UserService.getFollowers(widget.username)
          : await UserService.getFollowing(widget.username);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFollowers = widget.type == 'followers';
    final title = isFollowers
        ? context.tr('followList.titleFollowers')
        : context.tr('followList.titleFollowing');

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
                      Text(title, style: GoogleFonts.playfairDisplay(
                          fontSize: 17, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: -0.3)),
                      Text('@${widget.username}',
                          style: AppTheme.sansBody(
                              size: 11, weight: FontWeight.w600,
                              color: AppTheme.terracotta)),
                    ]),
              ]),
            ),
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(
              color: AppTheme.terracotta, strokeWidth: 2.4))
              : _hasError
              ? ErrorView(onRetry: _loadUsers)
              : _users.isEmpty
              ? _buildEmptyState(isFollowers)
              : _buildUserList(),
        ),
      ]),
    );
  }

  Widget _buildEmptyState(bool isFollowers) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.terracottaLight,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.terracotta.withOpacity(0.3), width: 2),
            ),
            child: Icon(
                isFollowers
                    ? Icons.people_outline_rounded
                    : Icons.explore_outlined,
                size: 38, color: AppTheme.terracotta),
          ),
          const SizedBox(height: 20),
          Text(
              isFollowers
                  ? context.tr('followList.emptyFollowersTitle')
                  : context.tr('followList.emptyFollowingTitle'),
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
              isFollowers
                  ? context.tr('followList.emptyFollowersSubtitle')
                  : context.tr('followList.emptyFollowingSubtitle'),
              textAlign: TextAlign.center,
              style: AppTheme.sansBody(
                  size: 13, color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final fullName =
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
        final username = user['username'] ?? '';
        final profileImageUrl = user['profileImageUrl'];
        final isMe = username == _currentUsername;

        return GestureDetector(
          onTap: () {
            if (isMe) {
              Navigator.popUntil(context, ModalRoute.withName('/home'));
            } else {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) =>
                      UserProfileScreen(username: username)));
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isMe
                      ? AppTheme.terracotta.withOpacity(0.4) : AppTheme.border,
                  width: isMe ? 1.5 : 1.2),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.terracottaLight,
                  border: Border.all(
                      color: AppTheme.terracotta.withOpacity(0.4), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? Image.network(profileImageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.person_rounded,
                          color: AppTheme.terracotta, size: 26))
                      : Icon(Icons.person_rounded,
                      color: AppTheme.terracotta, size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (fullName.isNotEmpty)
                  Text(fullName, style: AppTheme.sansBody(
                      size: 15, weight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Row(children: [
                  Text('@$username', style: AppTheme.sansBody(
                      size: 13, weight: FontWeight.w600,
                      color: AppTheme.terracotta)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppTheme.terracotta : AppTheme.terracottaLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isMe
                        ? context.tr('followList.you')
                        : context.tr('common.travelerFallback'),
                        style: AppTheme.sansBody(
                            size: 9, weight: FontWeight.w600,
                            color: isMe
                                ? Colors.white : AppTheme.terracotta)),
                  ),
                ]),
              ])),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Icon(
                    isMe
                        ? Icons.person_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: AppTheme.textSecondary, size: 13),
              ),
            ]),
          ),
        );
      },
    );
  }
}