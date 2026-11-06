import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/stripe_payment_service.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/models/saved_card_model.dart';

/// نافذة إضافة وتشفير بطاقة بنكية جديدة للسائق وحفظها في المحفظة
class AddCardSheet extends StatefulWidget {
  final Future<bool> Function(SavedCardModel card) onSaveCard;

  const AddCardSheet({
    super.key,
    required this.onSaveCard,
  });

  static Future<SavedCardModel?> show(
    BuildContext context, {
    required Future<bool> Function(SavedCardModel card) onSaveCard,
  }) {
    return showModalBottomSheet<SavedCardModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddCardSheet(onSaveCard: onSaveCard),
    );
  }

  @override
  State<AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<AddCardSheet> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  CardFieldInputDetails? _cardDetails;
  bool _isDefault = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  String _detectBrand(String? brand) {
    if (brand == null || brand.isEmpty) return 'Card';
    final b = brand.toLowerCase();
    if (b.contains('visa')) return 'Visa';
    if (b.contains('master')) return 'Mastercard';
    if (b.contains('amex') || b.contains('american')) return 'Amex';
    return brand;
  }

  bool get _isCardComplete => _cardDetails?.complete == true;

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (_errorMessage != null) setState(() => _errorMessage = null);

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال اسم صاحب البطاقة.');
      _nameFocusNode.requestFocus();
      return;
    }

    if (!_isCardComplete) {
      setState(() => _errorMessage = 'يرجى إكمال بيانات البطاقة (الرقم، الانتهاء، ورمز CVC).');
      return;
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) {
      setState(() => _errorMessage = 'يرجى تسجيل الدخول أولاً للمتابعة.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await StripePaymentService.instance.initialize();

      final user = FirebaseAuth.instance.currentUser;
      final userEmail = (user?.email != null && user!.email!.contains('@')) ? user.email : null;
      final userPhone = (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) ? user.phoneNumber : null;

      // 1. طلب SetupIntent من السيرفر لربط بطاقة السائق بحسابه رسمياً في Stripe
      final setupClientSecret = await StripePaymentService.instance.createSetupIntent(
        driverId: currentUid,
        driverName: name,
        driverEmail: userEmail,
      );

      String effectivePaymentMethodId = '';
      String last4 = '4242';
      int expMonth = 12;
      int expYear = 2030;
      String brand = 'Visa';

      if (setupClientSecret != null && setupClientSecret.isNotEmpty) {
        // تأكيد SetupIntent رسمياً عبر Stripe SDK
        final setupIntent = await Stripe.instance.confirmSetupIntent(
          paymentIntentClientSecret: setupClientSecret,
          params: PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(
              billingDetails: BillingDetails(
                name: name,
                email: userEmail,
                phone: userPhone,
              ),
            ),
          ),
        );
        effectivePaymentMethodId = setupIntent.paymentMethodId;
      } else {
        // بديل احتياطي لإنشاء وسيلة الدفع مباشرة
        final paymentMethod = await Stripe.instance.createPaymentMethod(
          params: PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(
              billingDetails: BillingDetails(
                name: name,
                email: userEmail,
                phone: userPhone,
              ),
            ),
          ),
        );
        effectivePaymentMethodId = paymentMethod.id;
        last4 = paymentMethod.card.last4 ?? '4242';
        expMonth = paymentMethod.card.expMonth ?? 12;
        expYear = paymentMethod.card.expYear ?? 2030;
        brand = _detectBrand(paymentMethod.card.brand);

        // ربط وسيلة الدفع بحساب العميل
        await StripePaymentService.instance.attachPaymentMethodToCustomer(
          paymentMethodId: effectivePaymentMethodId,
          driverId: currentUid,
          driverName: name,
          driverEmail: userEmail,
          driverPhone: userPhone,
        );
      }

      if (effectivePaymentMethodId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'تعذر تشفير البطاقة وربطها بحساب الدفع.';
        });
        return;
      }

      final newCard = SavedCardModel(
        id: 'card_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUid,
        brand: brand,
        last4: last4,
        expiryMonth: expMonth,
        expiryYear: expYear,
        holderName: name,
        isDefault: _isDefault,
        paymentMethodId: effectivePaymentMethodId,
        createdAt: DateTime.now(),
      );

      final success = await widget.onSaveCard(newCard);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context, newCard);
      } else {
        setState(() => _errorMessage = 'فشل حفظ البطاقة في قاعدة البيانات.');
      }
    } on StripeException catch (e) {
      debugPrint('❌ [AddCardSheet] StripeException: ${e.error.localizedMessage} (${e.error.code})');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        final rawMsg = (e.error.localizedMessage ?? e.error.message ?? '').toLowerCase();
        if (rawMsg.contains('card_declined') || rawMsg.contains('declined')) {
          _errorMessage = 'البطاقة مرفوضة من البنك المصدر.';
        } else if (rawMsg.contains('expired')) {
          _errorMessage = 'تاريخ انتهاء البطاقة غير صحيح أو منتهي الصلاحية.';
        } else if (rawMsg.contains('cvc') || rawMsg.contains('cvv') || rawMsg.contains('security code')) {
          _errorMessage = 'رمز الأمان CVC غير صحيح.';
        } else if (rawMsg.contains('invalid_number') || rawMsg.contains('incorrect_number')) {
          _errorMessage = 'رقم البطاقة غير صحيح.';
        } else {
          _errorMessage = e.error.localizedMessage ?? e.error.message ?? 'فشل التحقق من بيانات البطاقة لدى Stripe.';
        }
      });
    } catch (e) {
      debugPrint('❌ [AddCardSheet] General error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        final msg = e.toString().toLowerCase();
        if (msg.contains('ioexception') ||
            msg.contains('unable to resolve host') ||
            msg.contains('no address associated') ||
            msg.contains('network') ||
            msg.contains('connection') ||
            msg.contains('socket') ||
            msg.contains('offline')) {
          _errorMessage = 'تعذر الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت في هاتفك والمحاولة مجدداً.';
        } else if (msg.contains('card_declined') || msg.contains('declined')) {
          _errorMessage = 'البطاقة مرفوضة من البنك المصدر.';
        } else {
          _errorMessage = 'حدث خطأ: ${e.toString().replaceAll('Exception:', '').trim()}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: bottomInset + 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إضافة بطاقة بنكية',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'الاسم على البطاقة',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'اكتب اسمك كما يظهر على البطاقة',
                    hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'بيانات البطاقة (الرقم / الانتهاء / CVC)',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _cardDetails?.complete == true ? AppColors.success : AppColors.border,
                      width: _cardDetails?.complete == true ? 1.5 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: CardField(
                    autofocus: false,
                    enablePostalCode: false,
                    cursorColor: AppColors.primary,
                    style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontFamily: 'Cairo'),
                    decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12)),
                    onCardChanged: (details) => setState(() => _cardDetails = details),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: SwitchListTile(
                    title: const Text('تعيين كبطاقة افتراضية للتسديد', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    value: _isDefault,
                    activeThumbColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    onChanged: (val) => setState(() => _isDefault = val),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: AppColors.success),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'بياناتك مشفرة بالكامل ولا يتم تخزين أرقام البطاقات الحساسة وفق معيار PCI-DSS',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                CustomButton(
                  text: 'حفظ البطاقة',
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
