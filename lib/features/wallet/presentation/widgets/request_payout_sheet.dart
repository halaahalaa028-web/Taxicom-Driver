/// نافذة طلب سحب أرباح السائق المستحقة
///
/// تتيح للسائق سحب أرباحه المتاحة إلى حسابه البنكي أو المحفظة الإلكترونية
/// مع فحص الحد الأقصى للمبلغ والتحقق من صحة البيانات
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/trip_calculation_helper.dart';
import '../../../../core/widgets/custom_button.dart';

class RequestPayoutSheet extends StatefulWidget {
  final double availableEarnings;
  final String currency;
  final String countryCode;
  final Future<bool> Function({
    required double amount,
    required String payoutMethod,
    required String accountDetails,
    required String accountHolderName,
  }) onRequest;

  const RequestPayoutSheet({
    super.key,
    required this.availableEarnings,
    required this.currency,
    required this.countryCode,
    required this.onRequest,
  });

  static Future<bool?> show(
    BuildContext context, {
    required double availableEarnings,
    required String currency,
    required String countryCode,
    required Future<bool> Function({
      required double amount,
      required String payoutMethod,
      required String accountDetails,
      required String accountHolderName,
    }) onRequest,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RequestPayoutSheet(
        availableEarnings: availableEarnings,
        currency: currency,
        countryCode: countryCode,
        onRequest: onRequest,
      ),
    );
  }

  @override
  State<RequestPayoutSheet> createState() => _RequestPayoutSheetState();
}

class _RequestPayoutSheetState extends State<RequestPayoutSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  final _accountDetailsController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedMethod = 'bank_transfer';
  bool _isLoading = false;

  final List<Map<String, String>> _methods = [
    {'id': 'bank_transfer', 'name': 'حساب بنكي (IBAN)', 'icon': 'account_balance'},
    {'id': 'zain_cash', 'name': 'زين كاش (Zain Cash)', 'icon': 'phone_android'},
    {'id': 'e_wallet', 'name': 'محفظة إلكترونية أخرى', 'icon': 'account_balance_wallet'},
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.availableEarnings > 0 ? widget.availableEarnings.toStringAsFixed(0) : '0',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountDetailsController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    if (amount <= 0 || amount > widget.availableEarnings) return;

    setState(() => _isLoading = true);

    try {
      final success = await widget.onRequest(
        amount: amount,
        payoutMethod: _selectedMethod,
        accountDetails: _accountDetailsController.text.trim(),
        accountHolderName: _nameController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم إرسال طلب سحب الأرباح بنجاح، وسيتم تحويله قريباً!',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تعذر إرسال الطلب. تحقق من الرصيد المتاح وحاول مجدداً.',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedAvailable = TripCalculationHelper.formatPrice(
      widget.availableEarnings,
      currency: widget.currency,
      countryCode: widget.countryCode,
    );

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'طلب سحب الأرباح المستحقة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // كرت الرصيد المتاح
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الرصيد المتاح للسحب:',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      formattedAvailable,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // حقل المبلغ
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ المطلوب سحبه (${widget.currency})',
                  labelStyle: const TextStyle(fontFamily: 'Cairo'),
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixIcon: TextButton(
                    onPressed: () {
                      _amountController.text = widget.availableEarnings.toStringAsFixed(0);
                    },
                    child: const Text(
                      'كامل الرصيد',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'يرجى إدخال المبلغ';
                  final numVal = double.tryParse(val);
                  if (numVal == null || numVal <= 0) return 'مبلغ غير صالح';
                  if (numVal > widget.availableEarnings) return 'المبلغ يتجاوز الرصيد المتاح';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // اختيار وسيلة التحويل
              const Text(
                'اختر وسيلة التحويل:',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ..._methods.map((m) {
                final isSelected = _selectedMethod == m['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedMethod = m['id']!),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            m['name']!,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // اسم المستفيد
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'اسم صاحب الحساب الثلاثي',
                  labelStyle: const TextStyle(fontFamily: 'Cairo'),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'أدخل اسم صاحب الحساب' : null,
              ),

              const SizedBox(height: 12),

              // رقم الحساب أو الآيبان
              TextFormField(
                controller: _accountDetailsController,
                decoration: InputDecoration(
                  labelText: _selectedMethod == 'bank_transfer'
                      ? 'رقم الآيبان (IBAN) أو رقم الحساب'
                      : 'رقم هاتف المحفظة المسجلة',
                  labelStyle: const TextStyle(fontFamily: 'Cairo'),
                  prefixIcon: const Icon(Icons.numbers_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'أدخل تفاصيل الحساب' : null,
              ),

              const SizedBox(height: 20),

              // زر التأكيد
              CustomButton(
                text: 'تأكيد إرسال الطلب',
                isLoading: _isLoading,
                disabled: widget.availableEarnings <= 0,
                onPressed: _handleSubmit,
                backgroundColor: AppColors.success,
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
