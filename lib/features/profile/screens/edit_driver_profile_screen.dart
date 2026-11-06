/// شاشة تعديل بيانات السائق
/// 
/// تسمح للسائق بتعديل بياناته أثناء فترة الانتظار أو مراجعة الحساب
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../widgets/driver_vehicle_form_widget.dart';

/// شاشة تعديل بيانات السائق
class EditDriverProfileScreen extends StatefulWidget {
  const EditDriverProfileScreen({super.key});

  @override
  State<EditDriverProfileScreen> createState() => _EditDriverProfileScreenState();
}

class _EditDriverProfileScreenState extends State<EditDriverProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _carNumberController = TextEditingController();
  final TextEditingController _carTypeController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carColorController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  File? _newImage;
  String? _currentImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _userData;
  
  final UserService _userService = UserService.instance;
  final StorageService _storageService = StorageService.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _carNumberController.dispose();
    _carTypeController.dispose();
    _carModelController.dispose();
    _carColorController.dispose();
    super.dispose();
  }

  /// تحميل بيانات المستخدم
  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final user = await _userService.getUser(uid);
        if (user != null && mounted) {
          setState(() {
            _userData = user;
            _nameController.text = user.name;
            _emailController.text = user.email ?? '';
            _addressController.text = user.address ?? '';
            _carNumberController.text = user.carNumber ?? '';
            _carTypeController.text = user.carType ?? '';
            _carModelController.text = user.carModel ?? '';
            _carColorController.text = user.carColor ?? '';
            _currentImageUrl = user.profilePhotoUrl;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('حدث خطأ في تحميل البيانات', isError: true);
      }
    }
  }

  /// حفظ التغييرات
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userData == null) return;

    setState(() => _isSaving = true);

    try {
      String? newPhotoUrl = _currentImageUrl;
      if (_newImage != null) {
        newPhotoUrl = await _storageService.uploadProfilePhoto(
          _newImage!,
          _userData!.uid,
        );
      }

      final updatedUser = _userData!.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty 
            ? _emailController.text.trim() 
            : null,
        address: _addressController.text.trim().isNotEmpty 
            ? _addressController.text.trim() 
            : null,
        carNumber: _carNumberController.text.trim(),
        carType: _carTypeController.text.trim(),
        carModel: _carModelController.text.trim(),
        carColor: _carColorController.text.trim(),
        profilePhotoUrl: newPhotoUrl,
      );

      await _userService.saveUser(updatedUser);

      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('تم حفظ التغييرات بنجاح', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('حدث خطأ في حفظ البيانات', isError: true);
      }
    }
  }

  /// اختيار صورة جديدة
  Future<void> _pickImage() async {
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
              title: const Text(AppStrings.chooseFromGallery, style: TextStyle(fontFamily: 'Cairo')),
              onTap: () async {
                Navigator.pop(context);
                final image = await _storageService.pickImageFromGallery();
                if (image != null) setState(() => _newImage = image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text(AppStrings.takePhoto, style: TextStyle(fontFamily: 'Cairo')),
              onTap: () async {
                Navigator.pop(context);
                final image = await _storageService.pickImageFromCamera();
                if (image != null) setState(() => _newImage = image);
              },
            ),
          ],
        ),
      ),
    );
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

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fullNameError;
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.length < 3) return AppStrings.fullNameError;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.editProfile,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LoadingOverlay(
              isLoading: _isSaving,
              message: AppStrings.saving,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPhotoAvatar(),
                      const SizedBox(height: 24),
                      CustomTextField(
                        label: '${AppStrings.fullNameField} *',
                        hint: AppStrings.fullNameHint,
                        controller: _nameController,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: _validateFullName,
                      ),
                      const SizedBox(height: 16),
                      DriverVehicleFormWidget(
                        carTypeController: _carTypeController,
                        carModelController: _carModelController,
                        carColorController: _carColorController,
                        carNumberController: _carNumberController,
                      ),
                      const SizedBox(height: 16),
                      Directionality(
                        textDirection: ui.TextDirection.ltr,
                        child: CustomTextField(
                          label: AppStrings.emailField,
                          hint: AppStrings.emailHint,
                          controller: _emailController,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: AppStrings.addressField,
                        hint: AppStrings.addressHint,
                        controller: _addressController,
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: AppStrings.save,
                        onPressed: _saveChanges,
                        isLoading: _isSaving,
                        icon: Icons.check_rounded,
                        height: 54,
                        borderRadius: 16,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoAvatar() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
                image: _newImage != null
                    ? DecorationImage(
                        image: FileImage(_newImage!),
                        fit: BoxFit.cover,
                      )
                    : _currentImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_currentImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: (_newImage == null && _currentImageUrl == null)
                  ? const Icon(Icons.person_rounded, size: 48, color: AppColors.primary)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.textOnPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
