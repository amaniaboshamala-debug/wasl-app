import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/category_style.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/services/domain/entities/community_service.dart';

/// ألوان حالة الخدمة: متاحة (أخضر) · محدودة (برتقالي) · متوقفة (رمادي)
(Color, Color) serviceStatusColors(ServiceStatus s) => switch (s) {
      ServiceStatus.available => (AppColors.primaryDark, AppColors.primarySoft),
      ServiceStatus.limited => (const Color(0xFF7A3E00), AppColors.orangeSoft),
      ServiceStatus.paused || ServiceStatus.ended => (const Color(0xFF4A4F4C), const Color(0xFFEEECE6)),
    };

/// كرت الخدمة المجانية: الاسم والحالة والمؤسسة والمكان والمواعيد وآخر تأكيد.
class ServiceCard extends StatelessWidget {
  final CommunityService item;
  const ServiceCard(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(item.category);
    final (fg, bg) = serviceStatusColors(item.status);
    return AppCard(
      onTap: () => context.push(Routes.serviceDetails(item.id), extra: item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: style.soft, borderRadius: BorderRadius.circular(14)),
                child: Icon(style.icon, color: style.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(item.statusLabel, color: fg, background: bg),
                      ],
                    ),
                    const SizedBox(height: 4),
                    OrgName(item.provider, verified: item.providerVerified),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              if (item.region.isNotEmpty) InfoBit(Icons.location_on_outlined, item.region),
              if (item.schedule.isNotEmpty) InfoBit(Icons.schedule, item.schedule),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: item.needsConfirmation ? AppColors.orangeSoft : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: InfoBit(
              item.needsConfirmation ? Icons.help_outline : Icons.sync,
              item.needsConfirmation
                  ? 'بحاجة تأكيد · آخر تأكيد ${DateAr.ago(item.lastConfirmedAt)}'
                  : 'آخر تأكيد ${DateAr.ago(item.lastConfirmedAt)}',
            ),
          ),
        ],
      ),
    );
  }
}
