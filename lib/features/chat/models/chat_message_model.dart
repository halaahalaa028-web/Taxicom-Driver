/// نموذج رسالة المحادثة
/// 
/// يمثل رسالة واحدة في محادثة الرحلة
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج رسالة المحادثة
class ChatMessageModel {
  /// معرف الرسالة
  final String id;
  
  /// معرف المرسل
  final String senderId;
  
  /// اسم المرسل
  final String senderName;
  
  /// نص الرسالة
  final String message;
  
  /// وقت الإرسال
  final DateTime createdAt;
  
  /// هل تم قراءة الرسالة
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  /// إنشاء من Firestore
  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ChatMessageModel(
      id: documentId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  /// تحويل إلى خريطة للحفظ
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  /// نسخة محدثة
  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? message,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
