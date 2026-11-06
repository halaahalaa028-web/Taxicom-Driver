/// خدمة المحادثة
///
/// توفر وظائف التعامل مع رسائل المحادثة في Firestore
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';

/// خدمة المحادثة
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// الحصول على مرجع مجموعة الرسائل لرحلة معينة
  CollectionReference<Map<String, dynamic>> _messagesCollection(String tripId) {
    return _firestore.collection('trips').doc(tripId).collection('messages');
  }

  /// إرسال رسالة جديدة
  Future<void> sendMessage({
    required String tripId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    await _messagesCollection(tripId).add({
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  /// الاستماع للرسائل في الوقت الفعلي
  Stream<List<ChatMessageModel>> watchMessages(String tripId) {
    return _messagesCollection(
      tripId,
    ).orderBy('createdAt', descending: false).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// تحديد الرسائل كمقروءة
  Future<void> markAsRead({
    required String tripId,
    required String currentUserId,
  }) async {
    // الحصول على جميع الرسائل غير المقروءة
    final allUnreadMessages = await _messagesCollection(
      tripId,
    ).where('isRead', isEqualTo: false).get();

    // تصفية الرسائل التي أرسلها الآخرون فقط
    final messagesToMark = allUnreadMessages.docs
        .where((doc) => doc.data()['senderId'] != currentUserId)
        .toList();

    if (messagesToMark.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in messagesToMark) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// الحصول على عدد الرسائل غير المقروءة
  Stream<int> watchUnreadCount({
    required String tripId,
    required String currentUserId,
  }) {
    // الاستماع لجميع الرسائل وتصفيتها على جانب العميل
    return _messagesCollection(tripId).snapshots().map((snapshot) {
      // عد الرسائل غير المقروءة التي أرسلها الطرف الآخر
      return snapshot.docs.where((doc) {
        final data = doc.data();
        return data['isRead'] == false && data['senderId'] != currentUserId;
      }).length;
    });
  }
}
