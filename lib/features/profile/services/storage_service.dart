/// خدمة رفع الصور على Firebase Storage
/// 
/// تدير عمليات رفع وضغط الصور
library;

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// خدمة التخزين
class StorageService {
  StorageService._();
  
  /// Instance وحيد من الخدمة
  static final StorageService instance = StorageService._();
  
  /// Firebase Storage reference
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Image Picker
  final ImagePicker _picker = ImagePicker();
  
  /// اختيار صورة من المعرض مع ضغط 90%
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 10, // ضغط 90% (quality 10 = 90% compression)
      maxWidth: 800,
      maxHeight: 800,
    );
    
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
  
  /// التقاط صورة من الكاميرا مع ضغط 90%
  Future<File?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 10, // ضغط 90% (quality 10 = 90% compression)
      maxWidth: 800,
      maxHeight: 800,
    );
    
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
  
  /// رفع صورة الملف الشخصي على Firebase Storage
  /// 
  /// [imageFile] ملف الصورة
  /// [userId] معرف المستخدم
  /// 
  /// يرجع رابط الصورة المرفوعة
  Future<String> uploadProfilePhoto(File imageFile, String userId) async {
    try {
      // مسار الصورة في Storage
      final String path = 'profile_photos/$userId.jpg';
      
      // إنشاء reference
      final Reference ref = _storage.ref().child(path);
      
      // رفع الصورة
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // انتظار اكتمال الرفع
      final TaskSnapshot snapshot = await uploadTask;
      
      // الحصول على رابط التحميل
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('فشل رفع الصورة: $e');
    }
  }
  
  /// حذف صورة الملف الشخصي
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      final String path = 'profile_photos/$userId.jpg';
      final Reference ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      // تجاهل الخطأ إذا كانت الصورة غير موجودة
    }
  }
}
