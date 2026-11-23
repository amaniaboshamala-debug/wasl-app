import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/attendance/data/attendance_repository.dart';
import 'package:wasl/features/attendance/domain/volunteer_record.dart';
import 'package:wasl/features/attendance/presentation/record_pdf.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_state.dart';
import 'package:wasl/features/profile/presentation/cubit/profile_cubit.dart';

/// سجلّي التطوعي: الساعات والشارات والشهادات والسيرة التطوعية PDF.
class MyRecordScreen extends StatefulWidget {
  const MyRecordScreen({super.key});

  @override
  State<MyRecordScreen> createState() => _MyRecordScreenState();
}

class _MyRecordScreenState extends State<MyRecordScreen> {
  late Future<VolunteerRecord> _future = context.read<AttendanceRepository>().myRecord();
  bool _making = false;

  Future<void> _reload() async {
    final f = context.read<AttendanceRepository>().myRecord();
    setState(() => _future = f);
    await f.then((_) {}, onError: (_) {}); // الخطأ بيبين بالشاشة نفسها
  }

  Future<void> _pdf(Future<void> Function() make) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _making = true);
    try {
      await make();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('ما قدرنا نجهّز الملف، تأكدي من النت وحاولي مرة تانية.')));
    } finally {
      if (mounted) setState(() => _making = false);
    }
  }

  void _certificate(VolunteerCertificate c) => _pdf(() async {
        final bytes = await RecordPdf.certificate(c);
        await RecordPdf.share(bytes, 'شهادة-${c.code}.pdf');
      });

  void _cv(VolunteerRecord record) {
    final auth = context.read<AuthCubit>().state;
    final user = auth is Authenticated ? auth.user : null;
    final profile = context.read<ProfileCubit>().profile;
    final name = (profile?.name.isNotEmpty ?? false) ? profile!.name : (user?.name ?? '');
    _pdf(() async {
      final bytes = await RecordPdf.cv(name: name, email: user?.email ?? '', profile: profile, record: record);
      await RecordPdf.share(bytes, 'سيرتي-التطوعية.pdf');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('سجلّي التطوعي')),
        body: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<VolunteerRecord>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return ListView(padding: const EdgeInsets.all(16), children: const [SkeletonList(count: 3)]);
              }
              if (snap.hasError) {
                return ListView(children: [
                  MessageView(
                    icon: Icons.wifi_off_outlined,
                    title: 'ما قدرنا نحمّل سجلّك',
                    subtitle: snap.error.toString(),
                    actionLabel: 'حاولي مرة تانية',
                    onAction: _reload,
                  ),
                ]);
              }
              return _body(snap.data!);
            },
          ),
        ),
      );

  Widget _body(VolunteerRecord r) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Stats(r),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _making ? null : () => _cv(r),
            icon: _making
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('نزّلي سيرتي التطوعية (PDF)'),
          ),
          const SizedBox(height: 20),
          SectionHeader('الشارات (${r.earnedCount} من ${r.badges.length})'),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
            children: [for (final b in r.badges) _BadgeTile(b)],
          ),
          const SizedBox(height: 20),
          const SectionHeader('شهاداتي'),
          const SizedBox(height: 8),
          if (r.certificates.isEmpty)
            const _Hint('لما مؤسسة تصدرلك شهادة على فرصة فيها "📜 شهادة"، بتطلع هون وبتقدري تنزّليها PDF.')
          else
            for (final c in r.certificates)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: _making ? null : () => _certificate(c),
                  child: Row(children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.goldSoft,
                      child: Icon(Icons.workspace_premium_outlined, color: AppColors.goldDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${c.issuedBy} · ${VolunteerRecord.formatHours(c.hours)} ساعة · ${DateAr.day(c.issuedAt)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ]),
                    ),
                    const Icon(Icons.download_outlined, color: AppColors.primary),
                  ]),
                ),
              ),
          const SizedBox(height: 20),
          const SectionHeader('فرصي'),
          const SizedBox(height: 8),
          if (r.entries.isEmpty)
            _Hint('لما تنقبلي بفرصة وتسجّلي حضورك، ساعاتك بتنحسب هون.', action: () => context.go(Routes.opportunities))
          else
            for (final e in r.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: e.opportunityId.isEmpty ? null : () => context.push(Routes.opportunityDetails(e.opportunityId)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text([e.orgName, if (e.date != null) DateAr.day(e.date!)].where((s) => s.isNotEmpty).join(' · '),
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ]),
                    ),
                    e.done
                        ? StatusChip('${VolunteerRecord.formatHours(e.hours)} ساعة',
                            color: AppColors.primaryDark, background: AppColors.primarySoft)
                        : const StatusChip('لسا', color: Color(0xFF7A3E00), background: AppColors.orangeSoft),
                  ]),
                ),
              ),
        ],
      );
}

class _Stats extends StatelessWidget {
  final VolunteerRecord r;
  const _Stats(this.r);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(28)),
        child: Row(children: [
          _stat(VolunteerRecord.formatHours(r.totalHours), 'ساعة تطوع'),
          _stat('${r.done.length}', 'فرصة'),
          _stat('${r.certificates.length}', 'شهادة'),
        ]),
      );

  Widget _stat(String v, String label) => Expanded(
        child: Column(children: [
          Text(v, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
      );
}

class _BadgeTile extends StatelessWidget {
  final AchievementBadge b;
  const _BadgeTile(this.b);

  @override
  Widget build(BuildContext context) => Tooltip(
        message: b.hint,
        triggerMode: TooltipTriggerMode.tap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: b.earned ? AppColors.goldSoft : const Color(0xFFF1EFEA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: b.earned ? AppColors.gold : AppColors.line, width: b.earned ? 1.5 : 1),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Opacity(opacity: b.earned ? 1 : 0.35, child: Text(b.emoji, style: const TextStyle(fontSize: 30))),
            const SizedBox(height: 4),
            Text(b.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: b.earned ? AppColors.ink : AppColors.muted)),
            if (!b.earned) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: b.progress,
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: const Color(0xFFE2DED4),
              ),
            ],
          ]),
        ),
      );
}

class _Hint extends StatelessWidget {
  final String text;
  final VoidCallback? action;
  const _Hint(this.text, {this.action});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: const TextStyle(color: AppColors.muted, height: 1.6)),
          if (action != null)
            TextButton(onPressed: action, child: const Text('شوفي الفرص')),
        ]),
      );
}
