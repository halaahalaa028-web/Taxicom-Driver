import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_provinces.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/user_model.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/province_city_picker.dart';
import '../../settings/widgets/widgets.dart';

/// شاشة تفاصيل الملف الشخصي
class ProfileDetailsScreen extends StatefulWidget {
  final UserModel user;

  const ProfileDetailsScreen({super.key, required this.user});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  late UserModel _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  Future<void> _updateField(String key, dynamic value) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .update({
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (key == 'address') {
        _currentUser = _currentUser.copyWith(address: value as String);
      } else if (key == 'gender') {
        _currentUser = _currentUser.copyWith(gender: value as String);
      } else if (key == 'province') {
        _currentUser = _currentUser.copyWith(province: value as String);
      }
      
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).saveSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).generalError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditAddressDialog() {
    final controller = TextEditingController(text: _currentUser.address);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).addressField),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).addressHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _updateField('address', controller.text);
              }
            },
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );
  }

  void _showEditGenderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return SimpleDialog(
          title: Text(l10n.genderField),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _updateField('gender', 'male');
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(l10n.male),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _updateField('gender', 'female');
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(l10n.female),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditProvinceDialog() {
    final countryCode = _currentUser.countryCode ?? AppProvinces.detectCountryCodeFromPhone(_currentUser.phone);
    final provinces = AppProvinces.getProvincesForCountry(countryCode);

    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);

        return SimpleDialog(
          title: Text(
            l10n.provinceField,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          children: provinces.map((item) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _updateField('province', item.id);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                child: Text(
                  item.nameAr,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDriver = _currentUser.userType == 'driver';
    final countryCode = _currentUser.countryCode ?? AppProvinces.detectCountryCodeFromPhone(_currentUser.phone);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.profileTitle,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileImage(context),
                  const SizedBox(height: 16),
                  Text(
                    _currentUser.name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    PhoneFormatter.format(_currentUser.phone),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ProfileInfoCard(
                    title: l10n.personalData,
                    children: [
                      ProfileInfoRow(
                        icon: Icons.map_outlined, 
                        label: l10n.provinceField, 
                        value: ProvinceCityPicker.getProvinceName(_currentUser.province, countryCode),
                        onEdit: _showEditProvinceDialog,
                      ),
                      ProfileInfoRow(
                        icon: Icons.location_on_outlined,
                        label: l10n.addressFieldRequired,
                        value: _currentUser.address ?? '-',
                        onEdit: _showEditAddressDialog,
                      ),
                      ProfileInfoRow(
                        icon: Icons.person_outline,
                        label: l10n.genderFieldRequired,
                        value: _currentUser.gender == 'male' 
                            ? l10n.male 
                            : (_currentUser.gender == 'female' ? l10n.female : (_currentUser.gender ?? '-')),
                        onEdit: _showEditGenderDialog,
                      ),
                      if (_currentUser.birthDate != null)
                        ProfileInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: l10n.birthDateFieldRequired,
                          value: DateFormat('yyyy/MM/dd').format(_currentUser.birthDate!),
                        ),
                    ],
                  ),
                  if (isDriver) ...[
                    const SizedBox(height: 20),
                    ProfileInfoCard(
                      title: l10n.carInfo,
                      children: [
                        ProfileInfoRow(icon: Icons.directions_car_outlined, label: l10n.carTypeField, value: _currentUser.carType ?? '-'),
                        ProfileInfoRow(icon: Icons.onetwothree_outlined, label: l10n.carModelField, value: _currentUser.carModel ?? '-'),
                        ProfileInfoRow(icon: Icons.palette_outlined, label: l10n.carColorField, value: _currentUser.carColor ?? '-'),
                        ProfileInfoRow(icon: Icons.confirmation_number_outlined, label: l10n.carNumberField, value: _currentUser.carNumber ?? '-'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  DeleteAccountSection(
                    onTap: () => DeleteAccountDialog.show(context),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: _currentUser.profilePhotoUrl != null && _currentUser.profilePhotoUrl!.isNotEmpty
            ? Image.network(
                _currentUser.profilePhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person,
                  size: 60,
                  color: AppColors.textSecondary,
                ),
              )
            : const Icon(
                Icons.person,
                size: 60,
                color: AppColors.primary,
              ),
      ),
    );
  }
}
