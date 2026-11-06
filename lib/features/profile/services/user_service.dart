/// خدمة المستخدم
/// 
/// توفر وظائف التعامل مع بيانات المستخدم في Firestore
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// فئة خدمة المستخدم
class UserService {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // مفتاح التخزين المحلي
  static const String _userCacheKey = 'cached_user_data';
  
  // Singleton pattern
  UserService._();
  static final UserService _instance = UserService._();
  static UserService get instance => _instance;

  /// بيانات المستخدم المحفوظة في الذاكرة (Cache)
  UserModel? _cachedUser;

  /// الحصول على بيانات المستخدم من الكاش
  UserModel? get cachedUser => _cachedUser;

  /// حفظ بيانات المستخدم في التخزين المحلي
  Future<void> _saveUserToLocalStorage(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userCacheKey, user.toJson());
    } catch (e) {
      // تجاهل الأخطاء - التخزين المحلي اختياري
    }
  }

  /// تحميل بيانات المستخدم من التخزين المحلي (متاحة للاستخدام الخارجي)
  Future<UserModel?> loadUserFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userCacheKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final user = UserModel.fromJson(jsonString);
        // تحديث الكاش في الذاكرة أيضاً
        _cachedUser = user;
        return user;
      }
    } catch (e) {
      // تجاهل الأخطاء - سيتم التحميل من Firestore
    }
    return null;
  }

  /// مسح بيانات المستخدم من التخزين المحلي
  Future<void> _clearLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCacheKey);
    } catch (e) {
      // تجاهل الأخطاء
    }
  }

  /// تحميل بيانات المستخدم الحالي وحفظها في الكاش
  /// يتم استدعاؤها مرة واحدة عند بدء التطبيق
  /// تُحمّل البيانات المحفوظة محلياً أولاً ثم تُحدّث من الخادم
  Future<void> loadCurrentUser(String uid) async {
    // 1. تحميل البيانات المحفوظة محلياً أولاً (للعرض الفوري)
    final localUser = await loadUserFromLocalStorage();
    if (localUser != null && localUser.uid == uid) {
      _cachedUser = localUser;
    }
    
    // 2. محاولة التحميل من Firebase
    try {
      final serverUser = await getUser(uid);
      if (serverUser != null) {
        _cachedUser = serverUser;
        // 3. تحديث التخزين المحلي بالبيانات الجديدة
        await _saveUserToLocalStorage(serverUser);
      }
    } catch (e) {
      // في حالة الفشل - نستخدم البيانات المحفوظة محلياً (إن وجدت)
      // _cachedUser سيظل يحتوي على البيانات المحلية
    }
  }

  /// تحديث الكاش بعد تعديل بيانات المستخدم
  Future<void> updateCache(UserModel user) async {
    _cachedUser = user;
    await _saveUserToLocalStorage(user);
  }

  /// مسح الكاش (عند تسجيل الخروج)
  Future<void> clearCache() async {
    _cachedUser = null;
    await _clearLocalStorage();
  }

  /// مرجع مجموعة المستخدمين
  CollectionReference get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  /// حفظ مستخدم جديد
  /// 
  /// [user] - نموذج المستخدم
  Future<void> saveUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('فشل في حفظ البيانات: ${e.toString()}');
    }
  }

  /// الحصول على مستخدم بواسطة المعرف
  /// 
  /// [uid] - معرف المستخدم
  /// Returns - نموذج المستخدم أو null
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      
      return null;
    } catch (e) {
      throw Exception('فشل في جلب البيانات: ${e.toString()}');
    }
  }

  /// تحديث بيانات المستخدم
  /// 
  /// [user] - نموذج المستخدم المحدث
  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).update(user.toMap());
    } catch (e) {
      throw Exception('فشل في تحديث البيانات: ${e.toString()}');
    }
  }

  /// التحقق من وجود المستخدم
  /// 
  /// [uid] - معرف المستخدم
  Future<bool> userExists(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// بث تغييرات بيانات المستخدم
  /// 
  /// [uid] - معرف المستخدم
  Stream<UserModel?> userStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    }).asBroadcastStream();
  }

  /// حذف المستخدم
  /// 
  /// [uid] - معرف المستخدم
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('فشل في حذف البيانات: ${e.toString()}');
    }
  }

  /// تحديث حالة توفر السائق (متاح للعمل أم لا)
  /// 
  /// [uid] - معرف السائق
  /// [isOnline] - الحالة الجديدة
  Future<void> setDriverOnlineStatus(String uid, bool isOnline) async {
    try {
      await _usersCollection.doc(uid).update({
        'isOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // تحديث الكاش
      if (_cachedUser != null && _cachedUser!.uid == uid) {
        _cachedUser = _cachedUser!.copyWith(isOnline: isOnline);
      }
    } catch (e) {
      throw Exception('فشل في تحديث حالة التوفر: ${e.toString()}');
    }
  }
}
