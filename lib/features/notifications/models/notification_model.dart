
import 'package:cloud_firestore/cloud_firestore.dart';

/// أنواع الجمهور المستهدف للإشعارات
enum NotificationAudience {
  customer, // للمستخدمين العاديين فقط
  driver,   // للسواق فقط
  all,      // للجميع
  private,  // لشخص محدد
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;

  /// قائمة UIDs للمستخدمين الذين قرأوا هذا الإشعار
  final List<String> readBy;

  final String? type; // 'system', 'discount', 'update', 'promo', etc.
  final NotificationAudience audience;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.readBy = const [],
    this.type,
    this.audience = NotificationAudience.all,
  });

  /// هل قرأ هذا المستخدم الإشعار؟
  bool isReadBy(String uid) => readBy.contains(uid);

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    final rawReadBy = map['readBy'];
    List<String> parsedReadBy = [];
    if (rawReadBy is List) {
      parsedReadBy = rawReadBy.map((e) => e.toString()).toList();
    }

    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: parsedReadBy,
      type: map['type'],
      audience: _parseAudience(map['audience']),
    );
  }

  static NotificationAudience _parseAudience(String? value) {
    switch (value) {
      case 'customer':
        return NotificationAudience.customer;
      case 'driver':
        return NotificationAudience.driver;
      case 'private':
        return NotificationAudience.private;
      case 'all':
      default:
        return NotificationAudience.all;
    }
  }

  static String audienceToString(NotificationAudience audience) {
    switch (audience) {
      case NotificationAudience.customer:
        return 'customer';
      case NotificationAudience.driver:
        return 'driver';
      case NotificationAudience.private:
        return 'private';
      case NotificationAudience.all:
        return 'all';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'readBy': readBy,
      'type': type,
      'audience': audienceToString(audience),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    List<String>? readBy,
    String? type,
    NotificationAudience? audience,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      readBy: readBy ?? this.readBy,
      type: type ?? this.type,
      audience: audience ?? this.audience,
    );
  }
}
