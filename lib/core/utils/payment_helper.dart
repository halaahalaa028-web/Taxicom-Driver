/// أداة مساعدة مركزية للتعامل مع وسائل الدفع المختلفة
library;

import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

/// فئة مساعدة لفحص وتنسيق وسيلة الدفع عبر تطبيق السائق
class PaymentHelper {
  PaymentHelper._();

  /// هل وسيلة الدفع نقدية (كاش)
  static bool isCashPayment(String? paymentMethod) {
    if (paymentMethod == null || paymentMethod.isEmpty) return true;
    return paymentMethod.toLowerCase() == 'cash';
  }

  /// هل وسيلة الدفع من المحفظة الإلكترونية
  static bool isWalletPayment(String? paymentMethod) {
    if (paymentMethod == null) return false;
    return paymentMethod.toLowerCase() == 'wallet';
  }

  /// هل وسيلة الدفع بطاقة بنكية (فيزا/ماستركارد/Stripe)
  static bool isCardPayment(String? paymentMethod) {
    if (paymentMethod == null) return false;
    final method = paymentMethod.toLowerCase();
    return method == 'card' || method == 'stripe' || method.startsWith('card:');
  }

  /// هل وسيلة الدفع عبر Apple Pay
  static bool isApplePay(String? paymentMethod) {
    if (paymentMethod == null) return false;
    final method = paymentMethod.toLowerCase();
    return method == 'apple_pay' || method == 'applepay';
  }

  /// هل وسيلة الدفع إلكترونية (محفظة أو بطاقة أو Apple Pay) وليست نقداً
  static bool isElectronicPayment(String? paymentMethod) {
    if (paymentMethod == null || paymentMethod.isEmpty) return false;
    return !isCashPayment(paymentMethod);
  }

  /// الحصول على عنوان وسيلة الدفع مترجماً للعرض
  static String getPaymentMethodTitle(BuildContext context, String? paymentMethod) {
    final loc = AppLocalizations.of(context);
    if (paymentMethod == null || paymentMethod.isEmpty || isCashPayment(paymentMethod)) {
      return loc.cash;
    }
    if (isWalletPayment(paymentMethod)) {
      return loc.walletPayment;
    }
    if (isCardPayment(paymentMethod)) {
      return loc.creditCard;
    }
    if (isApplePay(paymentMethod)) {
      return loc.applePay;
    }
    return loc.cash;
  }

  /// الحصول على أيقونة وسيلة الدفع المناسبة
  static IconData getPaymentMethodIcon(String? paymentMethod) {
    if (paymentMethod == null || paymentMethod.isEmpty || isCashPayment(paymentMethod)) {
      return Icons.payments_rounded;
    }
    if (isWalletPayment(paymentMethod)) {
      return Icons.account_balance_wallet_rounded;
    }
    if (isCardPayment(paymentMethod)) {
      return Icons.credit_card_rounded;
    }
    if (isApplePay(paymentMethod)) {
      return Icons.phone_android_rounded;
    }
    return Icons.payments_rounded;
  }
}
