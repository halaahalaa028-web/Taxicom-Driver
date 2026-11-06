import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

/// خدمة الإشعارات
///
/// تجلب الإشعارات من Firebase Firestore مع تصفية حسب الجمهور المستهدف،
/// وتتبع حالة القراءة حقيقياً في قاعدة البيانات عبر حقل [readBy].
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// عدد الإشعارات لكل صفحة
  static const int _pageSize = 10;

  // ──────────────────────────────────────────────────────────────
  // جلب الإشعارات مع Pagination
  // ──────────────────────────────────────────────────────────────

  /// جلب صفحة من إشعارات السائق (أو الجميع)
  ///
  /// [lastDoc] — آخر وثيقة في الصفحة السابقة، أو null للصفحة الأولى.
  Future<List<NotificationModel>> fetchDriverNotificationsPage(
    String driverId, {
    DocumentSnapshot? lastDoc,
  }) async {
    var query = _firestore
        .collection('notifications')
        .where('audience', whereIn: ['driver', 'all'])
        .orderBy('timestamp', descending: true)
        .limit(_pageSize);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// جلب صفحة من إشعارات المستخدم (أو الجميع)
  ///
  /// [lastDoc] — آخر وثيقة في الصفحة السابقة، أو null للصفحة الأولى.
  Future<List<NotificationModel>> fetchCustomerNotificationsPage(
    String customerId, {
    DocumentSnapshot? lastDoc,
  }) async {
    var query = _firestore
        .collection('notifications')
        .where('audience', whereIn: ['customer', 'all'])
        .orderBy('timestamp', descending: true)
        .limit(_pageSize);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// جلب المرجع الكامل للوثائق (مع DocumentSnapshot) للسائق — لدعم الـ cursor
  Future<QuerySnapshot> fetchDriverNotificationsSnapshot(
    String driverId, {
    DocumentSnapshot? lastDoc,
  }) async {
    var query = _firestore
        .collection('notifications')
        .where('audience', whereIn: ['driver', 'all'])
        .orderBy('timestamp', descending: true)
        .limit(_pageSize);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.get();
  }

  /// جلب المرجع الكامل للوثائق (مع DocumentSnapshot) للمستخدم — لدعم الـ cursor
  Future<QuerySnapshot> fetchCustomerNotificationsSnapshot(
    String customerId, {
    DocumentSnapshot? lastDoc,
  }) async {
    var query = _firestore
        .collection('notifications')
        .where('audience', whereIn: ['customer', 'all'])
        .orderBy('timestamp', descending: true)
        .limit(_pageSize);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.get();
  }

  /// جلب المرجع الكامل للإشعارات الشخصية (private) لمستخدم محدد (سائق أو راكب)
  Future<QuerySnapshot> fetchPersonalNotificationsSnapshot(
    String userId, {
    DocumentSnapshot? lastDoc,
  }) async {
    var query = _firestore
        .collection('notifications')
        .where('audience', isEqualTo: 'private')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(_pageSize);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.get();
  }

  // ──────────────────────────────────────────────────────────────
  // تعيين الإشعارات كمقروءة في قاعدة البيانات
  // ──────────────────────────────────────────────────────────────

  /// تعيين إشعار واحد كمقروء لمستخدم معين
  ///
  /// يضيف [uid] إلى حقل [readBy] في وثيقة الإشعار باستخدام arrayUnion
  /// لضمان عدم التكرار وأمان الكتابة المتزامنة.
  Future<void> markAsRead(String uid, String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'readBy': FieldValue.arrayUnion([uid])});
      debugPrint('✅ [NotificationService] Marked as read: $notificationId');
    } catch (e) {
      debugPrint('❌ [NotificationService] Error marking as read ($notificationId): $e');
    }
  }

  /// تعيين قائمة إشعارات كمقروءة دفعةً واحدة (Batch Write)
  ///
  /// يُستخدم عند فتح شاشة الإشعارات لأول مرة لتعيين جميع الإشعارات المحملة.
  Future<void> markAllAsRead(String uid, List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;

    final batch = _firestore.batch();
    for (final id in notificationIds) {
      final ref = _firestore.collection('notifications').doc(id);
      batch.update(ref, {'readBy': FieldValue.arrayUnion([uid])});
    }

    try {
      await batch.commit();
      debugPrint('✅ [NotificationService] Marked ${notificationIds.length} notifications as read');
    } catch (e) {
      debugPrint('❌ [NotificationService] Error marking multiple as read: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // عدد الإشعارات غير المقروءة (Stream)
  // ──────────────────────────────────────────────────────────────

  /// عدد الإشعارات غير المقروءة للسائق (Stream حي)
  ///
  /// يستمع لآخر [_pageSize] إشعار ويعدّ منها التي لا تحتوي uid السائق في readBy.
  Stream<int> getUnreadCountStream(String driverId) {
    return _firestore
        .collection('notifications')
        .where('audience', whereIn: ['driver', 'all'])
        .orderBy('timestamp', descending: true)
        .limit(_pageSize)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawReadBy = data['readBy'];
        final readBy = rawReadBy is List
            ? rawReadBy.map((e) => e.toString()).toList()
            : <String>[];
        if (!readBy.contains(driverId)) count++;
      }
      return count;
    });
  }

  /// عدد الإشعارات غير المقروءة للمستخدم (Stream حي)
  Stream<int> getCustomerUnreadCountStream(String customerId) {
    return _firestore
        .collection('notifications')
        .where('audience', whereIn: ['customer', 'all'])
        .orderBy('timestamp', descending: true)
        .limit(_pageSize)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawReadBy = data['readBy'];
        final readBy = rawReadBy is List
            ? rawReadBy.map((e) => e.toString()).toList()
            : <String>[];
        if (!readBy.contains(customerId)) count++;
      }
      return count;
    });
  }

  /// عدد الإشعارات الشخصية غير المقروءة (Stream حي)
  Stream<int> getPersonalUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('audience', isEqualTo: 'private')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(_pageSize)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawReadBy = data['readBy'];
        final readBy = rawReadBy is List
            ? rawReadBy.map((e) => e.toString()).toList()
            : <String>[];
        if (!readBy.contains(userId)) count++;
      }
      return count;
    });
  }

  // ──────────────────────────────────────────────────────────────
  // توافق مع الكود القديم (deprecated — kept for safety)
  // ──────────────────────────────────────────────────────────────

  /// @deprecated استخدم markAllAsRead بدلاً منه
  Future<void> markCustomerNotificationAsRead(
      String customerId, String notificationId) async {
    await markAsRead(customerId, notificationId);
  }
}
