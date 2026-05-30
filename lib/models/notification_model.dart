class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String type;
  final int? refId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.refId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'],
        userId: json['userId'],
        title: json['title'],
        body: json['body'],
        type: json['type'] ?? 'GENERAL',
        refId: json['refId'],
        isRead: json['isRead'] ?? false,
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      );

  String get iconEmoji {
    switch (type) {
      case 'KYC_APPROVED': return '✅';
      case 'KYC_REJECTED': return '❌';
      case 'PACKAGE_ACTIVATED': return '⭐';
      case 'BILL_ISSUED': return '📄';
      case 'BILL_OVERDUE': return '⚠️';
      case 'CONTRACT_SIGNED': return '📋';
      case 'CONTRACT_EXPIRING': return '⏳';
      case 'CONTRACT_TERMINATED': return '🚫';
      case 'MAINTENANCE_ASSIGNED': return '🔧';
      case 'ROOM_RESERVED': return '🏠';
      default: return '🔔';
    }
  }
}
