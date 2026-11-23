import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/attendance/domain/volunteer_record.dart';

/// كود الحضور تبع المتطوع: بيورجيه للمؤسسة بأول الدوام وآخره.
Future<void> showAttendanceQr(BuildContext context, VolunteerApplication app) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('كود الحضور', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(app.opportunityTitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.gold, width: 1.5),
              ),
              child: QrImageView(
                data: AttendanceQr.encode(app.id),
                size: 230,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primaryDark),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.ink),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'ورجيه للمسؤول بالمؤسسة لما توصلي (دخول) ولما تخلّصي (خروج)، وساعاتك بتنحسب لحالها ⏱️',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.primaryDark),
              ),
            ),
          ]),
        ),
      ),
    );
