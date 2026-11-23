import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/applications/presentation/widgets/withdraw_dialog.dart';
import 'package:wasl/features/attendance/presentation/attendance_qr_sheet.dart';

/// ألوان حالة الطلب: قيد المراجعة (برتقالي) · مقبول (أخضر) · لم يُقبل (أحمر) · انسحبتِ (رمادي)
(Color, Color) applicationStatusColors(ApplicationStatus s) => switch (s) {
      ApplicationStatus.pending => (const Color(0xFF7A3E00), AppColors.orangeSoft),
      ApplicationStatus.accepted => (AppColors.primaryDark, AppColors.primarySoft),
      ApplicationStatus.rejected => (AppColors.red, AppColors.redSoft),
      ApplicationStatus.withdrawn => (const Color(0xFF4A4F4C), const Color(0xFFEEECE6)),
    };

/// كرت طلب بشاشة طلباتي.
class ApplicationCard extends StatelessWidget {
  final VolunteerApplication item;
  const ApplicationCard(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = applicationStatusColors(item.status);
    return AppCard(
      onTap: item.opportunityId.isEmpty ? null : () => context.push(Routes.opportunityDetails(item.opportunityId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                item.opportunityTitle.isEmpty ? 'فرصة' : item.opportunityTitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(item.statusLabel, color: fg, background: bg),
          ]),
          if (item.organizationName.isNotEmpty) ...[
            const SizedBox(height: 4),
            OrgName(item.organizationName),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 14, runSpacing: 6, children: [
            if (item.place.isNotEmpty) InfoBit(Icons.location_on_outlined, item.place),
            if (item.date != null) InfoBit(Icons.calendar_today_outlined, DateAr.day(item.date!)),
            InfoBit(Icons.send_outlined, 'قدّمتِ ${DateAr.ago(item.createdAt)}'),
          ]),
          if (item.status == ApplicationStatus.accepted) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
              child: const Text(
                'مبروك 🎉 المؤسسة رح تتواصل معك بالتفاصيل.',
                style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              onPressed: () => showAttendanceQr(context, item),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('كود الحضور'),
            ),
          ],
          if (item.canWithdraw)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
                onPressed: () => confirmWithdraw(context, item),
                child: const Text('انسحاب'),
              ),
            ),
        ],
      ),
    );
  }
}
