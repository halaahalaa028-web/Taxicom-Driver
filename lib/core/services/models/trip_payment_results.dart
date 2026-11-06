/// نماذج نتائج عمليات الدفع والحجز المالي للرحلات
library;

/// نتيجة تسوية وإنهاء الرحلة السحابية ذرياً
class TripCompletionResult {
  final bool success;
  final bool fallbackToCash;
  final String? errorMessage;
  final String? reason;
  final double? driverEarnings;
  final double? platformCommission;

  const TripCompletionResult({
    required this.success,
    this.fallbackToCash = false,
    this.errorMessage,
    this.reason,
    this.driverEarnings,
    this.platformCommission,
  });
}

/// نتيجة الحجز المالي المسبق لبطاقة الراكب (Pre-Auth Hold)
class TripHoldResult {
  final bool success;
  final bool fallbackToCash;
  final String? errorMessage;
  final String? reason;
  final String? paymentIntentId;

  const TripHoldResult({
    required this.success,
    this.fallbackToCash = false,
    this.errorMessage,
    this.reason,
    this.paymentIntentId,
  });
}
