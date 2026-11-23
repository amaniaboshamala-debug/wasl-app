import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/applications/presentation/widgets/application_card.dart';
import 'package:wasl/features/attendance/presentation/request_attendance_bar.dart';
import 'package:wasl/features/opportunities/presentation/cubit/opportunities_cubit.dart';
import 'package:wasl/features/organization/domain/entities/org_request.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';

/// كرت طلب متطوع عند المؤسسة: مين، على أي فرصة، مهاراته وأيامه، وزرّين قبول ورفض.
class RequestCard extends StatefulWidget {
  final OrgRequest item;
  const RequestCard(this.item, {super.key});

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  bool _busy = false;

  Future<void> _decide(bool accept) async {
    final r = widget.item;
    if (!accept) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('رفض الطلب'),
          content: Text('أكيد بدك ترفضي طلب ${r.shortName} على «${r.opportunityTitle}»؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red, minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('رفض'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
    }
    final requests = context.read<OrgRequestsCubit>();
    final opportunities = context.read<OrgOpportunitiesCubit>();
    final publicList = context.read<OpportunitiesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final error = await requests.decide(r.id, accept: accept);
    if (error == null) {
      opportunities.refresh(); // عدد المقبولين والطلبات بيتغيّر
      publicList.refresh();
    }
    if (mounted) setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(
      content: Text(error ?? (accept ? 'قبلتِ ${r.shortName} ✅' : 'رفضتِ الطلب')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.item;
    final (fg, bg) = applicationStatusColors(r.status);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.blueSoft,
              child: Text(
                r.shortName.isEmpty ? '؟' : String.fromCharCode(r.shortName.runes.first),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0B4A61)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.volunteerName.isEmpty ? 'متطوع' : r.volunteerName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(
                  [if (r.volunteerRegion.isNotEmpty) r.volunteerRegion, DateAr.ago(r.createdAt)].join(' · '),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ]),
            ),
            if (!r.isPending) StatusChip(_label(r.status), color: fg, background: bg),
          ]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
            child: Text('على: ${r.opportunityTitle}', style: const TextStyle(fontSize: 12, color: Color(0xFF3B4A44))),
          ),
          if (r.skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final s in r.skills) StatusChip(s, color: AppColors.blue, background: AppColors.blueSoft),
            ]),
          ],
          if (r.availableDays.isNotEmpty) ...[
            const SizedBox(height: 8),
            InfoBit(Icons.event_available_outlined, 'متاح: ${r.availableDays.join('، ')}'),
          ],
          if (r.bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${r.bio}"', style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF3B4A44))),
          ],
          // رقم الجوال بيبين بعد القبول بس
          if (r.status == ApplicationStatus.accepted && r.phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri(scheme: 'tel', path: r.phone)),
              icon: const Icon(Icons.call_outlined),
              label: Text(r.phone, textDirection: TextDirection.ltr),
            ),
          ],
          if (r.status == ApplicationStatus.accepted) RequestAttendanceBar(r),
          if (r.isPending) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: _busy ? null : () => _decide(true),
                  icon: const Icon(Icons.check),
                  label: const Text('قبول'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: Color(0xFFE5C4BF)),
                  ),
                  onPressed: _busy ? null : () => _decide(false),
                  icon: const Icon(Icons.close),
                  label: const Text('رفض'),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  static String _label(ApplicationStatus s) => switch (s) {
        ApplicationStatus.pending => 'جديد',
        ApplicationStatus.accepted => 'مقبول',
        ApplicationStatus.rejected => 'مرفوض',
        ApplicationStatus.withdrawn => 'انسحب',
      };
}
