/// شاشة إعداد الملف الشخصي للسائق الجديد
/// 
/// شاشة لإكمال بيانات السائق والمركبة للمستخدمين الجدد بعد التحقق من رقم الهاتف
/// تدعم التحديد التلقائي للدولة ومحافظاتها المعتمدة
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_provinces.dart';
import '../../../core/services/country_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/notification_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../widgets/driver_personal_info_form_widget.dart';
import '../widgets/driver_profile_photo_widget.dart';
import '../widgets/driver_vehicle_form_widget.dart';
import '../../driver/screens/driver_pending_screen.dart';

/// شاشة إعداد الملف الشخصي للسائق
class ProfileSetupScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isDriver;

  const ProfileSetupScreen({
    super.key,
    required this.phoneNumber,
    this.isDriver = true,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // متحكمات بيانات السائق
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _carNumberController = TextEditingController();
  final TextEditingController _carTypeController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carColorController = TextEditingController();

  late String _countryCode;
  late String _selectedProvince;
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  File? _selectedImage;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  final UserService _userService = UserService.instance;
  final StorageService _storageService = StorageService.instance;

  @override
  void initState() {
    super.initState();
    _countryCode = AppProvinces.detectCountryCodeFromPhone(widget.phoneNumber);
    _selectedProvince = AppProvinces.getDefaultProvinceForCountry(_countryCode);
    CountryService.instance.selectCountryByCode(_countryCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _carNumberController.dispose();
    _carTypeController.dispose();
    _carModelController.dispose();
    _carColorController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('اختيار من المعرض', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () async {
                Navigator.pop(context);
                final image = await _storageService.pickImageFromGallery();
                if (image != null) setState(() => _selectedImage = image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('التقاط صورة', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () async {
                Navigator.pop(context);
                final image = await _storageService.pickImageFromCamera();
                if (image != null) setState(() => _selectedImage = image);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime(DateTime.now().year - 18, 12, 31),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _selectedBirthDate = picked);
  }

  Future<void> _saveProfile() async {
    // 1. التحقق من الاسم
    if (_nameController.text.trim().isEmpty ||
        _nameController.text.trim().split(RegExp(r'\s+')).length < 3) {
      _showSnackBar('يرجى إدخال الاسم الثلاثي واللقب كاملاً', isError: true);
      _formKey.currentState?.validate();
      return;
    }

    // 2. التحقق من الجنس
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      _showSnackBar('يرجى اختيار الجنس (ذكر / أنثى) للمتابعة', isError: true);
      _formKey.currentState?.validate();
      return;
    }

    // 3. التحقق من بيانات المركبة
    if (_carTypeController.text.trim().isEmpty ||
        _carModelController.text.trim().isEmpty ||
        _carColorController.text.trim().isEmpty ||
        _carNumberController.text.trim().isEmpty) {
      _showSnackBar('يرجى إكمال كافة بيانات المركبة المطلوبة (*)', isError: true);
      _formKey.currentState?.validate();
      return;
    }

    // 4. التحقق العام
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('يرجى ملء جميع الحقول المطلوبة والمؤشرة بعلامة (*)', isError: true);
      return;
    }

    // 5. الشروط والأحكام
    if (!_acceptedTerms) {
      _showSnackBar('يرجى الموافقة على الشروط والأحكام للمتابعة', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('لم يتم العثور على جلسة المستخدم');

      String? profilePhotoUrl;
      if (_selectedImage != null) {
        profilePhotoUrl = await _storageService.uploadProfilePhoto(
          _selectedImage!,
          currentUser.uid,
        );
      }

      final user = UserModel(
        uid: currentUser.uid,
        phone: widget.phoneNumber,
        name: _nameController.text.trim(),
        gender: _selectedGender,
        birthDate: _selectedBirthDate,
        province: _selectedProvince,
        countryCode: _countryCode,
        userType: 'driver',
        driverStatus: 'pending',
        profilePhotoUrl: profilePhotoUrl,
        carNumber: _carNumberController.text.trim(),
        carType: _carTypeController.text.trim(),
        carModel: _carModelController.text.trim(),
        carColor: _carColorController.text.trim(),
      );

      await _userService.saveUser(user);
      await SessionService.instance.registerDevice(currentUser.uid, 'driver');
      await NotificationService.instance.updateFcmTokenOnLogin();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DriverPendingScreen()),
          (route) => false,
        );
        await SessionService.instance.startSessionListener(currentUser.uid, 'driver');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'تسجيل بيانات السائق',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'جاري حفظ بيانات السائق ورفع المستندات...',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DriverProfilePhotoWidget(
                    selectedImage: _selectedImage,
                    onPickImage: _pickProfileImage,
                  ),
                  const SizedBox(height: 20),
                  DriverPersonalInfoFormWidget(
                    nameController: _nameController,
                    selectedProvince: _selectedProvince,
                    countryCode: _countryCode,
                    selectedGender: _selectedGender,
                    selectedBirthDate: _selectedBirthDate,
                    onProvinceChanged: (val) => setState(() => _selectedProvince = val),
                    onGenderChanged: (val) => setState(() => _selectedGender = val),
                    onSelectBirthDate: _selectBirthDate,
                  ),
                  const SizedBox(height: 20),
                  DriverVehicleFormWidget(
                    carTypeController: _carTypeController,
                    carModelController: _carModelController,
                    carColorController: _carColorController,
                    carNumberController: _carNumberController,
                  ),
                  const SizedBox(height: 20),
                  _buildTermsSection(),
                  const SizedBox(height: 28),
                  CustomButton(
                    text: 'إرسال طلب الانضمام',
                    onPressed: _saveProfile,
                    isLoading: _isLoading,
                    icon: Icons.check_circle_outline_rounded,
                    borderRadius: 16,
                    height: 54,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
    return Row(
      children: [
        Checkbox(
          value: _acceptedTerms,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
        ),
        const Expanded(
          child: Text(
            'أوافق على الشروط والأحكام الخاصة بسائقي تاكسيكوم',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
          ),
        ),
      ],
    );
  }
}
