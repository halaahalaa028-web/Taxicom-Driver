/// شاشة الأرباح والمشاوير للسائق (توجيه للمركز المالي الموحد)
///
/// تم دمج هذه الشاشة بالكامل داخل [DriverWalletScreen] مع فتح تبويب الأرباح مباشرة
library;

import 'package:flutter/material.dart';
import '../../wallet/presentation/screens/driver_wallet_screen.dart';

/// ويدجت متوافق مع النظام القديم يفتح تبويب الأرباح في الشاشة الموحدة
class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DriverWalletScreen(initialTabIndex: 1);
  }
}
