/// نموذج المستخدم في تطبيق سائق تاكسيكوم
/// 
/// يمثل بيانات المستخدم والسائق المخزنة في Firestore والتخزين المحلي
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

/// فئة نموذج المستخدم
class UserModel {
  /// معرف المستخدم الفريد (من Firebase Auth)
  final String uid;
  
  /// رقم الهاتف
  final String phone;
  
  /// الاسم الكامل
  final String name;
  
  /// البريد الإلكتروني (اختياري)
  final String? email;
  
  /// العنوان (اختياري)
  final String? address;
  
  /// الجنس (اختياري)
  final String? gender;
  
  /// تاريخ الميلاد (اختياري)
  final DateTime? birthDate;
  
  /// نوع المستخدم (driver أو customer)
  final String userType;
  
  /// رابط الصورة الشخصية (للسائق)
  final String? profilePhotoUrl;
  
  /// رقم السيارة (للسائق)
  final String? carNumber;
  
  /// نوع السيارة (للسائق)
  final String? carType;
  
  /// موديل السيارة (للسائق)
  final String? carModel;
  
  /// لون السيارة (للسائق)
  final String? carColor;
  
  /// المحافظة
  final String? province;

  /// كود الدولة (مثل EG, IQ, SY, IR)
  final String? countryCode;
  
  /// هل السائق متاح للعمل (للسائق)
  final bool isOnline;
  
  /// حالة السائق: pending (انتظار), approved (معتمد), rejected (مرفوض)
  final String? driverStatus;
  
  /// رمز FCM للإشعارات
  final String? fcmToken;
  
  /// تاريخ الإنشاء
  final DateTime createdAt;
  
  /// تاريخ آخر تحديث
  final DateTime updatedAt;

  /// المنشئ الأساسي
  UserModel({
    required this.uid,
    required this.phone,
    required this.name,
    this.email,
    this.address,
    this.gender,
    this.birthDate,
    this.userType = 'customer',
    this.profilePhotoUrl,
    this.carNumber,
    this.carType,
    this.carModel,
    this.carColor,
    this.province,
    this.countryCode,
    this.isOnline = false,
    this.driverStatus,
    this.fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// إنشاء نموذج من خريطة (من Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      email: map['email'],
      address: map['address'],
      gender: map['gender'],
      birthDate: map['birthDate'] != null
          ? (map['birthDate'] as Timestamp).toDate()
          : null,
      userType: map['userType'] ?? 'customer',
      profilePhotoUrl: map['profilePhotoUrl'],
      carNumber: map['carNumber'],
      carType: map['carType'],
      carModel: map['carModel'],
      carColor: map['carColor'],
      province: map['province'],
      countryCode: map['countryCode'],
      isOnline: map['isOnline'] ?? false,
      driverStatus: map['driverStatus'],
      fcmToken: map['fcmToken'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// إنشاء نموذج من DocumentSnapshot
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// تحويل النموذج إلى خريطة (للحفظ في Firestore)
  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'name': name,
      'email': email,
      'address': address,
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'userType': userType,
      'profilePhotoUrl': profilePhotoUrl,
      'carNumber': carNumber,
      'carType': carType,
      'carModel': carModel,
      'carColor': carColor,
      'province': province,
      'countryCode': countryCode,
      'isOnline': isOnline,
      'driverStatus': driverStatus,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// إنشاء نسخة معدلة من النموذج
  UserModel copyWith({
    String? uid,
    String? phone,
    String? name,
    String? email,
    String? address,
    String? gender,
    DateTime? birthDate,
    String? userType,
    String? profilePhotoUrl,
    String? carNumber,
    String? carType,
    String? carModel,
    String? carColor,
    String? province,
    String? countryCode,
    bool? isOnline,
    String? driverStatus,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      userType: userType ?? this.userType,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      carNumber: carNumber ?? this.carNumber,
      carType: carType ?? this.carType,
      carModel: carModel ?? this.carModel,
      carColor: carColor ?? this.carColor,
      province: province ?? this.province,
      countryCode: countryCode ?? this.countryCode,
      isOnline: isOnline ?? this.isOnline,
      driverStatus: driverStatus ?? this.driverStatus,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, phone: $phone, name: $name, email: $email, countryCode: $countryCode, province: $province, userType: $userType)';
  }

  /// تحويل النموذج إلى JSON string للتخزين المحلي
  String toJson() {
    return jsonEncode({
      'uid': uid,
      'phone': phone,
      'name': name,
      'email': email,
      'address': address,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'userType': userType,
      'profilePhotoUrl': profilePhotoUrl,
      'carNumber': carNumber,
      'carType': carType,
      'carModel': carModel,
      'carColor': carColor,
      'province': province,
      'countryCode': countryCode,
      'isOnline': isOnline,
      'driverStatus': driverStatus,
      'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    });
  }

  /// إنشاء نموذج من JSON string (للتحميل من التخزين المحلي)
  factory UserModel.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      email: map['email'],
      address: map['address'],
      gender: map['gender'],
      birthDate: map['birthDate'] != null
          ? DateTime.parse(map['birthDate'])
          : null,
      userType: map['userType'] ?? 'customer',
      profilePhotoUrl: map['profilePhotoUrl'],
      carNumber: map['carNumber'],
      carType: map['carType'],
      carModel: map['carModel'],
      carColor: map['carColor'],
      province: map['province'],
      countryCode: map['countryCode'],
      isOnline: map['isOnline'] ?? false,
      driverStatus: map['driverStatus'],
      fcmToken: map['fcmToken'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
