import 'package:flutter/material.dart';
import 'package:wasl/core/di/injection.dart';
import 'package:wasl/core/network/connectivity_service.dart';
import 'package:wasl/core/theme/app_colors.dart';

/// شريط بيظهر فوق الشاشة لما ينقطع النت.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: sl<ConnectivityService>().onStatusChange,
      initialData: true,
      builder: (context, snapshot) {
        if (snapshot.data ?? true) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: AppColors.orangeSoft,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: const Text(
            'أنت غير متصلة · بنعرض آخر بيانات محفوظة',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}
