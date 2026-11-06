/// نافذة تسديد المديونية والتسديد الفوري بنقرة واحدة (1-Click Debt Settlement)
///
/// تتيح للسائق التسديد الفوري عبر البطاقات البنكية المحفوظة أو إضافة وحفظ بطاقة جديدة مباشرة
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/driver_cards_service.dart';
import '../../../../core/services/driver_wallet_service.dart';
import '../../../../core/utils/trip_calculation_helper.dart';
import '../../../../core/utils/wallet_currency_helper.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/models/saved_card_model.dart';
import 'add_card_sheet.dart';
import 'debt_cards_selector.dart';

class PayDebtSheet extends StatefulWidget {
  final double currentDebt;
  final String currency;
  final String countryCode;
  final String driverId;
  final String? driverName;
  final String? driverPhone;

  const PayDebtSheet({
    super.key,
    required this.currentDebt,
    required this.currency,
    required this.countryCode,
    required this.driverId,
    this.driverName,
    this.driverPhone,
  });

  static Future<bool?> show(
    BuildContext context, {
    required double currentDebt,
    required String currency,
    required String countryCode,
    required String driverId,
    String? driverName,
    String? driverPhone,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PayDebtSheet(
        currentDebt: currentDebt,
        currency: currency,
        countryCode: countryCode,
        driverId: driverId,
        driverName: driverName,
        driverPhone: driverPhone,
      ),
    );
  }

  @override
  State<PayDebtSheet> createState() => _PayDebtSheetState();
}

class _PayDebtSheetState extends State<PayDebtSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  List<SavedCardModel> _savedCards = [];
  SavedCardModel? _selectedCard;
  bool _isLoadingCards = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final defaultAmount = widget.currentDebt > 0 ? widget.currentDebt : 10000.0;
    _amountController = TextEditingController(text: defaultAmount.toStringAsFixed(0));
    _loadSavedCards();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCards() async {
    try {
      final cards = await DriverCardsService.instance.getSavedCards(widget.driverId);
      if (mounted) {
        setState(() {
          _savedCards = cards;
          _isLoadingCards = false;
          if (cards.isNotEmpty) {
            _selectedCard = cards.firstWhere(
              (c) => c.isDefault,
              orElse: () => cards.first,
            );
          } else {
            _selectedCard = null;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCards = false);
    }
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    if (amount <= 0) return;

    if (_selectedCard == null) {
      await _openAddCardAndPay(amount);
      return;
    }

    await _executePayment(amount: amount, paymentMethodId: _selectedCard!.paymentMethodId);
  }

  Future<void> _openAddCardAndPay(double amount) async {
    final newCard = await AddCardSheet.show(
      context,
      onSaveCard: (card) async {
        final ok = await DriverCardsService.instance.addSavedCard(
          driverId: widget.driverId,
          card: card,
        );
        return ok;
      },
    );

    if (newCard != null && mounted) {
      await _loadSavedCards();
      await _executePayment(amount: amount, paymentMethodId: newCard.paymentMethodId);
    }
  }

  Future<void> _executePayment({required double amount, String? paymentMethodId}) async {
    setState(() => _isLoading = true);
    try {
      final result = await DriverWalletService.instance.payDebt(
        driverId: widget.driverId,
        amount: amount,
        paymentMethodId: paymentMethodId,
        driverName: widget.driverName,
        driverPhone: widget.driverPhone,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (result.success) {
          Navigator.pop(context, true);
          _showToast('تم تسديد المبلغ بنجاح! سيتم تحديث المحفظة فوراً.', isError: false);
        } else if (!result.isCanceled) {
          _showToast(result.errorMessage ?? 'فشلت عملية التسديد.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast('حدث خطأ أثناء معالجة الدفع: $e', isError: true);
      }
    }
  }

  void _showToast(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'تسديد المديونية / شحن المحفظة',
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
              if (widget.currentDebt > 0) ...[
                Row(
                  children: [
                    Expanded(child: _buildPreset('كامل المبلغ', widget.currentDebt, isPrimary: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPreset('النصف (50%)', widget.currentDebt * 0.5)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPreset('الربع (25%)', widget.currentDebt * 0.25)),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ المراد تسديده (${widget.currency})',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'يرجى إدخال المبلغ';
                  final parsed = double.tryParse(v.replaceAll(',', '').trim());
                  if (parsed == null || parsed <= 0) return 'يرجى إدخال مبلغ صالح';
                  final minAmount = WalletCurrencyHelper.getMinAmount(widget.countryCode, widget.currency);
                  if (parsed < minAmount) {
                    final formattedMin = TripCalculationHelper.formatPrice(
                      minAmount,
                      currency: widget.currency,
                      countryCode: widget.countryCode,
                    );
                    return 'الحد الأدنى للسداد هو $formattedMin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ويدجت اختيار وإدارة البطاقات للتسديد
              DebtCardsSelector(
                savedCards: _savedCards,
                selectedCard: _selectedCard,
                isLoadingCards: _isLoadingCards,
                onSelectCard: (card) => setState(() => _selectedCard = card),
                onAddCard: () async {
                  final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
                  await _openAddCardAndPay(amount > 0 ? amount : widget.currentDebt);
                },
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'دفع آمن ومشفّر 100% بالبطاقات البنكية وفق أعلى معايير الأمان المصرفي PCI-DSS عبر Stripe',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // زر التسديد
              CustomButton(
                text: _getButtonText(),
                isLoading: _isLoading,
                icon: _selectedCard != null ? Icons.flash_on_rounded : Icons.add_card_rounded,
                onPressed: _handlePayment,
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonText() {
    if (_selectedCard != null) {
      return 'تسديد فوري بنقرة واحدة (${_selectedCard!.brand} •••• ${_selectedCard!.last4})';
    }
    return 'إضافة بطاقة بنكية ومتابعة التسديد';
  }

  Widget _buildPreset(String label, double amount, {bool isPrimary = false}) {
    return OutlinedButton(
      onPressed: () => setState(() => _amountController.text = amount.toStringAsFixed(0)),
      style: OutlinedButton.styleFrom(
        foregroundColor: isPrimary ? AppColors.primary : AppColors.textPrimary,
        side: BorderSide(color: isPrimary ? AppColors.primary : AppColors.border, width: isPrimary ? 1.5 : 1.0),
        padding: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
          Text(
            TripCalculationHelper.formatPrice(amount, currency: widget.currency, countryCode: widget.countryCode),
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
