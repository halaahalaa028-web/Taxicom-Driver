/// تبويب دخل المشاوير والأداء التشغيلي للسائق
///
/// يعرض صافي أرباح المشاوير، إجمالي ما دفعه الركاب، عمولات المنصة المستقطعة،
/// ودخل اليوم والأسبوع والشهر بديناميكية تامة لكل رحلة
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/payment_helper.dart';
import '../../../driver/widgets/earnings_balance_card.dart';
import '../../../driver/widgets/earnings_stats_grid.dart';
import '../../../trips/models/trip_request_model.dart';
import 'earnings_trip_card.dart';
import 'today_earnings_breakdown_card.dart';

class EarningsTabView extends StatefulWidget {
  const EarningsTabView({super.key});

  @override
  State<EarningsTabView> createState() => _EarningsTabViewState();
}

class _EarningsTabViewState extends State<EarningsTabView> {
  bool _isLoading = true;

  // صافي أرباح السائق لمختلف الفترات
  double _totalNetEarnings = 0.0;
  double _todayNetEarnings = 0.0;
  double _weekNetEarnings = 0.0;
  double _monthNetEarnings = 0.0;

  // إجمالي ما دفعه الركاب (Gross Fare)
  double _totalGrossFare = 0.0;
  double _todayGrossFare = 0.0;
  double _weekGrossFare = 0.0;
  double _monthGrossFare = 0.0;

  // إجمالي عمولات المنصة المستقطعة (Commission)
  double _totalCommission = 0.0;
  double _todayCommission = 0.0;
  double _weekCommission = 0.0;
  double _monthCommission = 0.0;

  // تفصيل كاش اليوم وأرباح المحفظة
  double _todayCashCollected = 0.0;
  double _todayCashNet = 0.0;
  int _todayCashTripsCount = 0;

  double _todayElectronicNet = 0.0;
  double _todayElectronicGross = 0.0;
  int _todayElectronicTripsCount = 0;

  // عدد المشاوير
  int _todayTripsCount = 0;
  int _completedTripsCount = 0;
  List<TripRequestModel> _recentTrips = [];

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      if (mounted) setState(() => _isLoading = true);

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
      final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final startOfMonth = DateTime(now.year, now.month, 1);

      final snapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('driverId', isEqualTo: user.uid)
          .get();

      double totalNet = 0.0;
      double todayNet = 0.0;
      double weekNet = 0.0;
      double monthNet = 0.0;

      double totalGross = 0.0;
      double todayGross = 0.0;
      double weekGross = 0.0;
      double monthGross = 0.0;

      double totalComm = 0.0;
      double todayComm = 0.0;
      double weekComm = 0.0;
      double monthComm = 0.0;

      double todayCashCollected = 0.0;
      double todayCashNet = 0.0;
      int todayCashTripsCount = 0;

      double todayElectronicNet = 0.0;
      double todayElectronicGross = 0.0;
      int todayElectronicTripsCount = 0;

      int todayAllCount = 0;
      int completedCount = 0;
      final List<TripRequestModel> allTrips = [];

      for (var doc in snapshot.docs) {
        final trip = TripRequestModel.fromMap(doc.data(), doc.id);
        allTrips.add(trip);
      }

      allTrips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final List<TripRequestModel> recentCompleted = [];

      for (var trip in allTrips) {
        final isCompleted = trip.status == TripStatus.completed;
        final date = trip.createdAt;
        final isToday = date.isAfter(startOfToday) || date.isAtSameMomentAs(startOfToday);
        final isWeek = date.isAfter(startOfWeekDay) || date.isAtSameMomentAs(startOfWeekDay);
        final isMonth = date.isAfter(startOfMonth) || date.isAtSameMomentAs(startOfMonth);

        if (isToday) {
          todayAllCount++;
        }

        if (isCompleted) {
          completedCount++;

          // حساب القيم ديناميكياً من وثيقة الرحلة
          final netEarning = trip.effectiveNetDriverEarnings;
          final grossFare = trip.effectiveOriginalPrice;
          final commission = trip.effectiveCommissionAmount;

          totalNet += netEarning;
          totalGross += grossFare;
          totalComm += commission;

          if (isToday) {
            todayNet += netEarning;
            todayGross += grossFare;
            todayComm += commission;

            // فرز وسيلة الدفع لليوم (كاش مستلم باليد مقابل إلكتروني بالمحفظة)
            final isCash = PaymentHelper.isCashPayment(trip.paymentMethod);
            if (isCash) {
              todayCashCollected += grossFare;
              todayCashNet += netEarning;
              todayCashTripsCount++;
            } else {
              todayElectronicNet += netEarning;
              todayElectronicGross += grossFare;
              todayElectronicTripsCount++;
            }
          }

          if (isWeek) {
            weekNet += netEarning;
            weekGross += grossFare;
            weekComm += commission;
          }

          if (isMonth) {
            monthNet += netEarning;
            monthGross += grossFare;
            monthComm += commission;
          }

          if (recentCompleted.length < 25) {
            recentCompleted.add(trip);
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalNetEarnings = totalNet;
          _todayNetEarnings = todayNet;
          _weekNetEarnings = weekNet;
          _monthNetEarnings = monthNet;

          _totalGrossFare = totalGross;
          _todayGrossFare = todayGross;
          _weekGrossFare = weekGross;
          _monthGrossFare = monthGross;

          _totalCommission = totalComm;
          _todayCommission = todayComm;
          _weekCommission = weekComm;
          _monthCommission = monthComm;

          _todayCashCollected = todayCashCollected;
          _todayCashNet = todayCashNet;
          _todayCashTripsCount = todayCashTripsCount;

          _todayElectronicNet = todayElectronicNet;
          _todayElectronicGross = todayElectronicGross;
          _todayElectronicTripsCount = todayElectronicTripsCount;

          _todayTripsCount = todayAllCount;
          _completedTripsCount = completedCount;
          _recentTrips = recentCompleted;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading earnings in tab: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = _recentTrips.isNotEmpty ? _recentTrips.first.currency : null;
    final countryCode = _recentTrips.isNotEmpty ? _recentTrips.first.countryCode : null;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEarningsData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة ملخص صافي دخل المشاوير وتفصيل الأجرة والعمولة
            EarningsBalanceCard(
              netEarnings: _totalNetEarnings,
              grossFare: _totalGrossFare,
              commissionAmount: _totalCommission,
              todayEarnings: _todayNetEarnings,
              todayGrossFare: _todayGrossFare,
              todayCommission: _todayCommission,
              todayTripsCount: _todayTripsCount,
              currency: currency,
              countryCode: countryCode,
            ),

            const SizedBox(height: 14),

            // بطاقة تفصيل دخل اليوم بين الكاش المستلم باليد وأرباح المحفظة
            TodayEarningsBreakdownCard(
              cashCollected: _todayCashCollected,
              cashNet: _todayCashNet,
              cashTripsCount: _todayCashTripsCount,
              electronicNet: _todayElectronicNet,
              electronicGross: _todayElectronicGross,
              electronicTripsCount: _todayElectronicTripsCount,
              currency: currency,
              countryCode: countryCode,
            ),

            const SizedBox(height: 14),

            // شبكة إحصائيات الأداء (صافي الأسبوع، صافي الشهر، الرحلات المنجزة)
            EarningsStatsGrid(
              weekEarnings: _weekNetEarnings,
              monthEarnings: _monthNetEarnings,
              completedTripsCount: _completedTripsCount,
              weekGrossFare: _weekGrossFare,
              monthGrossFare: _monthGrossFare,
              weekCommission: _weekCommission,
              monthCommission: _monthCommission,
              currency: currency,
              countryCode: countryCode,
            ),

            const SizedBox(height: 24),

            // عنوان سجل المشاوير المكتملة
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تفاصيل المشاوير وصافي الدخل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_recentTrips.isEmpty)
              _buildEmptyTripsState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentTrips.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final trip = _recentTrips[index];
                  return EarningsTripCard(trip: trip);
                },
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTripsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 48,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'لا توجد رحلات مكتملة بعد',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
