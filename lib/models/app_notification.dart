enum NotificationType { follow, journalSave, unknown }

class AppNotification {
  final int id;
  final NotificationType type;
  final String actorUsername;
  final String? actorFirstName;
  final String? actorProfileImageUrl;
  final int? journalId;
  final String? journalTitle;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.actorUsername,
    this.actorFirstName,
    this.actorProfileImageUrl,
    this.journalId,
    this.journalTitle,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    final journal = json['journal'] as Map<String, dynamic>?;
    return AppNotification(
      id: json['id'],
      type: _parseType(json['type']),
      actorUsername: actor?['username'] ?? '',
      actorFirstName: actor?['firstName'],
      actorProfileImageUrl: actor?['profileImageUrl'],
      journalId: journal?['id'],
      journalTitle: journal?['title'],
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static NotificationType _parseType(String? raw) {
    switch (raw) {
      case 'FOLLOW':
        return NotificationType.follow;
      case 'JOURNAL_SAVE':
        return NotificationType.journalSave;
      default:
        return NotificationType.unknown;
    }
  }

  String get actorDisplayName =>
      (actorFirstName != null && actorFirstName!.isNotEmpty) ? actorFirstName! : actorUsername;

  String get message {
    switch (type) {
      case NotificationType.follow:
        return '$actorDisplayName seni takip etmeye başladı';
      case NotificationType.journalSave:
        return '$actorDisplayName "${journalTitle ?? ''}" ajandanı kaydetti';
      case NotificationType.unknown:
        return '$actorDisplayName bir etkileşimde bulundu';
    }
  }
}
