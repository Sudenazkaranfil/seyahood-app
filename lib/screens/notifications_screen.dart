import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../widgets/error_view.dart';
import 'user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final notifications = await NotificationService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _hasError = true; });
    }
  }

  Future<void> _markAllRead() async {
    if (_notifications.every((n) => n.read)) return;
    setState(() {
      _notifications = _notifications
          .map((n) => AppNotification(
                id: n.id,
                type: n.type,
                actorUsername: n.actorUsername,
                actorFirstName: n.actorFirstName,
                actorProfileImageUrl: n.actorProfileImageUrl,
                journalId: n.journalId,
                journalTitle: n.journalTitle,
                read: true,
                createdAt: n.createdAt,
              ))
          .toList();
    });
    try {
      await NotificationService.markAllRead();
    } catch (e) {}
  }

  Future<void> _onTapNotification(AppNotification notification) async {
    if (!notification.read) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = AppNotification(
            id: notification.id,
            type: notification.type,
            actorUsername: notification.actorUsername,
            actorFirstName: notification.actorFirstName,
            actorProfileImageUrl: notification.actorProfileImageUrl,
            journalId: notification.journalId,
            journalTitle: notification.journalTitle,
            read: true,
            createdAt: notification.createdAt,
          );
        }
      });
      try {
        await NotificationService.markRead(notification.id);
      } catch (e) {}
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
        builder: (context) => UserProfileScreen(username: notification.actorUsername)));
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
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
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
                Expanded(
                  child: Text('Bildirimler', style: GoogleFonts.playfairDisplay(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: -0.3)),
                ),
                if (_notifications.any((n) => !n.read))
                  TextButton(
                    onPressed: _markAllRead,
                    child: Text('Tümünü okundu yap',
                        style: AppTheme.sansBody(
                            size: 11.5, weight: FontWeight.w600,
                            color: AppTheme.terracotta)),
                  ),
              ]),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(
                  color: AppTheme.terracotta, strokeWidth: 2.4))
              : _hasError
                  ? ErrorView(onRetry: _load)
                  : _notifications.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppTheme.terracotta,
                          onRefresh: _load,
                          child: _buildList(),
                        ),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.terracottaLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.terracotta.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 38, color: AppTheme.terracotta),
          ),
          const SizedBox(height: 20),
          Text('Henüz Bildirim Yok',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text('Biri seni takip ettiğinde ya da bir ajandanı kaydettiğinde burada görünecek.',
              textAlign: TextAlign.center,
              style: AppTheme.sansBody(size: 13, color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return GestureDetector(
          onTap: () => _onTapNotification(notification),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: notification.read ? Colors.white : AppTheme.terracottaLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border, width: 1.2),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.terracottaLight,
                  border: Border.all(color: AppTheme.terracotta.withOpacity(0.4), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: notification.actorProfileImageUrl != null &&
                          notification.actorProfileImageUrl!.isNotEmpty
                      ? Image.network(notification.actorProfileImageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              notification.type == NotificationType.follow
                                  ? Icons.person_add_rounded
                                  : Icons.bookmark_rounded,
                              color: AppTheme.terracotta, size: 22))
                      : Icon(
                          notification.type == NotificationType.follow
                              ? Icons.person_add_rounded
                              : Icons.bookmark_rounded,
                          color: AppTheme.terracotta, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(notification.message, style: AppTheme.sansBody(
                    size: 13.5, weight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(_relativeTime(notification.createdAt), style: AppTheme.sansBody(
                    size: 11, weight: FontWeight.w500,
                    color: AppTheme.textSecondary)),
              ])),
              if (!notification.read)
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: AppTheme.terracotta, shape: BoxShape.circle),
                ),
            ]),
          ),
        );
      },
    );
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }
}
