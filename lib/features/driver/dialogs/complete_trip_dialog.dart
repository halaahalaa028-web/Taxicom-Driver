import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/driver_commission_service.dart';
import '../../../core/utils/payment_helper.dart';
import '../../../core/utils/trip_calculation_helper.dart';
import '../../trips/models/trip_request_model.dart';

/// نافذة تأكيد إكمال الرحلة مع تفاصيل استقطاع العمولة 15% وصافي أرباح السائق 85%
class CompleteTripDialog extends StatefulWidget {
  final TripRequestModel trip;

  const CompleteTripDialog({
    super.key,
    required this.trip,
  });

  static Future<bool?> show(BuildContext context, {required TripRequestModel trip}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CompleteTripDialog(trip: trip),
    );
  }

  @override
  State<CompleteTripDialog> createState() => _CompleteTripDialogState();
}

class _CompleteTripDialogState extends State<CompleteTripDialog> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final totalFare = trip.effectiveOriginalPrice;
    final rate = trip.effectiveCommissionRate;
    final isZeroCommission = rate <= 0.0001;
    final ratePercent = (rate * 100).toStringAsFixed((rate * 100 % 1 == 0) ? 0 : 1);
    final driverPercent = ((1.0 - rate) * 100).toStringAsFixed(((1.0 - rate) * 100 % 1 == 0) ? 0 : 1);
    final commission = DriverCommissionService.instance.calculatePlatformCommission(totalFare, rate);
    final netEarnings = DriverCommissionService.instance.calculateDriverEarnings(totalFare, rate);

    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success),
          SizedBox(width: 8),
          Text(
            'تأكيد إكمال الرحلة والفاتورة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هل وصلت للوجهة وتريد إنهاء الرحلة واستلام الأجرة؟',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // إجمالي قيمة الرحلة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'إجمالي الأجرة:',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        TripCalculationHelper.formatPrice(
                          totalFare,
                          currency: trip.currency,
                          countryCode: trip.countryCode,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // عمولة المنصة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 16,
                            color: isZeroCommission ? AppColors.textSecondary : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isZeroCommission
                                ? 'عمولة المنصة (0% - عرض):'
                                : 'عمولة المنصة ($ratePercent%):',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isZeroCommission
                            ? TripCalculationHelper.formatPrice(
                                0.0,
                                currency: trip.currency,
                                countryCode: trip.countryCode,
                              )
                            : '- ${TripCalculationHelper.formatPrice(
                                commission,
                                currency: trip.currency,
                                countryCode: trip.countryCode,
                              )}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isZeroCommission ? AppColors.textSecondary : AppColors.error,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // صافي أرباح السائق
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isZeroCommission
                              ? 'صافي أرباحك (100%):'
                              : 'صافي أرباحك ($driverPercent%):',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          TripCalculationHelper.formatPrice(
                            netEarnings,
                            currency: trip.currency,
                            countryCode: trip.countryCode,
                          ),
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

                  // وسيلة الدفع المحددة
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'وسيلة الدفع:',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: PaymentHelper.isWalletPayment(trip.paymentMethod)
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : PaymentHelper.isCardPayment(trip.paymentMethod)
                                  ? Colors.purple.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          PaymentHelper.isWalletPayment(trip.paymentMethod)
                              ? '📱 المحفظة الإلكترونية'
                              : PaymentHelper.isCardPayment(trip.paymentMethod)
                                  ? '💳 بطاقة بنكية'
                                  : '💵 نقداً (كاش)',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: PaymentHelper.isWalletPayment(trip.paymentMethod)
                                ? AppColors.primary
                                : PaymentHelper.isCardPayment(trip.paymentMethod)
                                    ? Colors.purple
                                    : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (trip.hasDiscount) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          PaymentHelper.isElectronicPayment(trip.paymentMethod)
                              ? 'المبلغ المدفوع إلكترونياً:'
                              : 'المطلوب تحصيله نقداً:',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          TripCalculationHelper.formatPrice(
                            trip.price,
                            currency: trip.currency,
                            countryCode: trip.countryCode,
                          ),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'خصم الكوبون (مدعوم من التطبيق):',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.orange),
                        ),
                        Text(
                          '-${TripCalculationHelper.formatPrice(
                            trip.discountAmount!,
                            currency: trip.currency,
                            countryCode: trip.countryCode,
                          )}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              PaymentHelper.isWalletPayment(trip.paymentMethod)
                  ? '✅ تم دفع الأجرة من محفظة الراكب إلكترونياً. لا تطلب أي مبلغ نقدي من الراكب. سيتم إيداع صافي أرباحك (${TripCalculationHelper.formatPrice(netEarnings, currency: trip.currency, countryCode: trip.countryCode)}) في محفظتك مباشرة.'
                  : PaymentHelper.isCardPayment(trip.paymentMethod)
                      ? '💳 تم دفع الأجرة بالبطاقة البنكية إلكترونياً. لا تطلب أي مبلغ نقدي من الراكب. سيتم إيداع صافي أرباحك (${TripCalculationHelper.formatPrice(netEarnings, currency: trip.currency, countryCode: trip.countryCode)}) في محفظتك مباشرة.'
                      : isZeroCommission
                          ? '💵 استلم المبلغ نقداً من الراكب (${TripCalculationHelper.formatPrice(trip.price, currency: trip.currency, countryCode: trip.countryCode)})، والرحلة معفاة من عمولة المنصة بالكامل (0%).'
                          : '💵 استلم المبلغ نقداً من الراكب (${TripCalculationHelper.formatPrice(trip.price, currency: trip.currency, countryCode: trip.countryCode)})، وسيتم استقطاع عمولة المنصة $ratePercent% من محفظتك تلقائياً وتحديث سجل مديونيتك.',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: PaymentHelper.isElectronicPayment(trip.paymentMethod)
                    ? AppColors.success
                    : AppColors.textSecondary,
                fontWeight: PaymentHelper.isElectronicPayment(trip.paymentMethod)
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  setState(() => _isSubmitting = true);
                  Navigator.pop(context, true);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('نعم، تأكيد وإكمال', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    ),
    );
  }
}
