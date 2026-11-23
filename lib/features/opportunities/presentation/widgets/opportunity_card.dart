import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';

/// لون وأيقونة نوع الفرصة: تطوع (رمادي) · بأجر (أزرق) · تطوع مع بدل (برتقالي)
({IconData icon, Color fg, Color bg}) opportunityTypeStyle(OpportunityType t) => switch (t) {
      OpportunityType.volunteer => (icon: Icons.favorite_outline, fg: const Color(0xFF4A4F4C), bg: const Color(0xFFEEECE6)),
      OpportunityType.paid => (icon: Icons.payments_outlined, fg: const Color(0xFF0B4A61), bg: AppColors.blueSoft),
      OpportunityType.volunteerAllowance =>
        (icon: Icons.directions_bus_outlined, fg: const Color(0xFF7A3E00), bg: AppColors.orangeSoft),
    };

/// كرت الفرصة: العنوان والمؤسسة والمكان والموعد، ونوعها (تطوع / بأجر) وكم مقعد باقي.
class OpportunityCard extends StatelessWidget {
  final Opportunity item;
  final Widget? trailing; // مثلاً شارة "قدّمتِ"
  const OpportunityCard(this.item, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final type = opportunityTypeStyle(item.type);
    return AppCard(
      onTap: () => context.push(Routes.opportunityDetails(item.id), extra: item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: type.bg, borderRadius: BorderRadius.circular(14)),
                child: Icon(item.isRemote ? Icons.laptop_outlined : Icons.work_outline, color: type.fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    OrgName(item.organizationName, verified: item.organizationVerified),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              InfoBit(item.isRemote ? Icons.wifi : Icons.location_on_outlined, item.placeLabel),
              if (item.date != null) InfoBit(Icons.calendar_today_outlined, DateAr.day(item.date!)),
              if (item.date == null && item.duration.isNotEmpty) InfoBit(Icons.calendar_today_outlined, item.duration),
              if (item.applyDeadline != null) InfoBit(Icons.schedule, 'التقديم حتى ${DateAr.day(item.applyDeadline!)}'),
            ],
          ),
          if (item.offersCertificate) ...[
            const SizedBox(height: 8),
            const CertificateChip(),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: type.bg, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(type.icon, size: 13, color: type.fg),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(item.typeLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: type.fg)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              Text(
                item.seatsLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: item.isOpen ? const Color(0xFF7A3E00) : AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
