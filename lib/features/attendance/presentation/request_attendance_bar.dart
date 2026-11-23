import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/attendance/data/attendance_repository.dart';
import 'package:wasl/features/attendance/domain/volunteer_record.dart';
import 'package:wasl/features/organization/domain/entities/org_request.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';

/// جوّا كرت الطلب المقبول عند المؤسسة: الساعات + تسجيل يدوي + إصدار الشهادة.
class RequestAttendanceBar extends StatefulWidget {
  final OrgRequest item;
  const RequestAttendanceBar(this.item, {super.key});

  @override
  State<RequestAttendanceBar> createState() => _RequestAttendanceBarState();
}

class _RequestAttendanceBarState extends State<RequestAttendanceBar> {
  bool _busy = false;

  Future<void> _run(Future<String> Function(AttendanceRepository repo) call) async {
    final repo = context.read<AttendanceRepository>();
    final requests = context.read<OrgRequestsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final ok = await call(repo);
      await requests.refresh();
      messenger.showSnackBar(SnackBar(content: Text(ok)));
    } on AttendanceException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addHours() async {
    final controller = TextEditingController();
    final hours = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سجّلي ساعات'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('قديش تطوّع ${widget.item.shortName}؟', style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: const InputDecoration(labelText: 'عدد الساعات', hintText: 'مثلاً 3 أو 4.5'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () {
              final h = double.tryParse(controller.text.trim());
              if (h != null && h > 0 && h <= 24) Navigator.pop(ctx, h);
            },
            child: const Text('سجّلي'),
          ),
        ],
      ),
    );
    // بنستنى الـ dialog يسكّر قبل ما نمسح الخانة
    Future.delayed(const Duration(milliseconds: 500), controller.dispose);
    if (hours == null || !mounted) return;
    await _run((repo) async {
      await repo.recordHours(widget.item.id, hours);
      return 'انضافت ${VolunteerRecord.formatHours(hours)} ساعة ✓';
    });
  }

  Future<void> _issue() => _run((repo) async {
        final code = await repo.issueCertificate(widget.item.id);
        return 'الشهادة طلعت للمتطوع 📜 ($code)';
      });

  @override
  Widget build(BuildContext context) {
    final r = widget.item;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.timer_outlined, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text('${VolunteerRecord.formatHours(r.hours)} ساعة', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          if (r.checkedIn) const StatusChip('موجود هلّق', color: AppColors.primaryDark, background: AppColors.primarySoft),
          if (r.certificateCode != null) ...[
            const SizedBox(width: 6),
            const StatusChip('📜 شهادته طلعت', color: AppColors.goldDark, background: AppColors.goldSoft),
          ],
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: _busy ? null : _addHours,
            icon: const Icon(Icons.more_time, size: 18),
            label: const Text('سجّلي ساعات'),
          ),
          if (r.offersCertificate)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), foregroundColor: AppColors.goldDark),
              onPressed: _busy || r.hours <= 0 ? null : _issue,
              icon: const Icon(Icons.workspace_premium_outlined, size: 18),
              label: Text(r.certificateCode == null ? 'أصدري الشهادة' : 'حدّثي الشهادة'),
            ),
        ]),
      ]),
    );
  }
}
