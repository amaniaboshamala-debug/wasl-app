import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/category_style.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/app_network_image.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/initiatives/domain/entities/initiative.dart';

/// كرت المبادرة: صورة أو أيقونة التصنيف فوق، وتحتها العنوان والمؤسسة والمكان والموعد.
class InitiativeCard extends StatelessWidget {
  final Initiative item;
  const InitiativeCard(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(item.category);
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(Routes.initiativeDetails(item.id), extra: item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.imageUrl?.isNotEmpty == true)
                  AppNetworkImage(url: item.imageUrl, height: 96, borderRadius: BorderRadius.zero)
                else
                  ColoredBox(color: style.soft, child: Icon(style.icon, size: 44, color: style.color)),
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: StatusChip(item.category, color: AppColors.primaryDark, background: AppColors.primarySoft),
                ),
                PositionedDirectional(
                  top: 12,
                  end: 12,
                  child: StatusChip(item.statusLabel, color: Colors.white, background: AppColors.primary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                OrgName(item.organizationName, verified: item.organizationVerified, fontSize: 13),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    if (item.region.isNotEmpty) InfoBit(Icons.location_on_outlined, item.region),
                    InfoBit(Icons.calendar_today_outlined, DateAr.range(item.startDate, item.endDate)),
                    if (item.volunteersNeeded > 0)
                      InfoBit(Icons.groups_outlined, 'بحاجة ${item.volunteersNeeded} متطوع'),
                  ],
                ),
                if (item.offersCertificate) ...[
                  const SizedBox(height: 8),
                  const CertificateChip(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
