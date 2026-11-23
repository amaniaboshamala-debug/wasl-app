import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';
import 'package:wasl/features/organization/domain/entities/organization.dart';
import 'package:wasl/features/organization/presentation/cubit/my_org_cubit.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';
import 'package:wasl/features/organization/presentation/widgets/org_setup_view.dart';
import 'package:wasl/features/organization/presentation/widgets/request_card.dart';

/// لوحة المؤسسة: الأرقام المهمة، زر "فرصة جديدة"، وآخر الطلبات الجديدة.
/// إذا لسا ما في مؤسسة، بتطلع شاشة الإعداد.
class OrgHomeScreen extends StatefulWidget {
  const OrgHomeScreen({super.key});

  @override
  State<OrgHomeScreen> createState() => _OrgHomeScreenState();
}

class _OrgHomeScreenState extends State<OrgHomeScreen> {
  @override
  void initState() {
    super.initState();
    final org = context.read<MyOrgCubit>();
    if (org.state is! MyOrgReady) org.load();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MyOrgCubit>().state;
    return Scaffold(
      body: switch (state) {
        MyOrgLoading() => const Center(child: CircularProgressIndicator()),
        MyOrgError(:final message) => MessageView(
            icon: Icons.wifi_off_outlined,
            title: 'ما قدرنا نحمّل مؤسستك',
            subtitle: message,
            actionLabel: 'حاولي مرة تانية',
            onAction: context.read<MyOrgCubit>().load,
          ),
        final MyOrgMissing missing => OrgSetupView(missing),
        MyOrgReady(:final org) => _Dashboard(org),
      },
    );
  }
}

class _Dashboard extends StatefulWidget {
  final Organization org;
  const _Dashboard(this.org);

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  @override
  void initState() {
    super.initState();
    context.read<OrgOpportunitiesCubit>().ensureLoaded();
    context.read<OrgRequestsCubit>().ensureLoaded();
  }

  Future<void> _refresh() => Future.wait([
        context.read<MyOrgCubit>().load(),
        context.read<OrgOpportunitiesCubit>().refresh(),
        context.read<OrgRequestsCubit>().refresh(),
      ]);

  @override
  Widget build(BuildContext context) {
    final org = widget.org;
    final oppsState = context.watch<OrgOpportunitiesCubit>().state;
    final reqState = context.watch<OrgRequestsCubit>().state;
    final opps = context.read<OrgOpportunitiesCubit>().items;
    final reqs = context.read<OrgRequestsCubit>().items;

    final openCount = opps.where((o) => o.opportunity.status == OpportunityStatus.open).length;
    final pending = reqs.where((r) => r.isPending).toList();
    final acceptedTotal = opps.fold<int>(0, (sum, o) => sum + o.opportunity.acceptedCount);
    final loading = oppsState is ListLoading || reqState is ListLoading;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: Text(org.initial,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                OrgName(org.name, verified: org.isVerified, fontSize: 16),
                Text(
                  ['حساب مؤسسة', if (org.region.isNotEmpty) org.region].join(' · '),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ]),
            ),
            const NotificationBell(),
          ]),
          if (!org.isVerified) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(14)),
              child: const Row(children: [
                Icon(Icons.hourglass_top_rounded, size: 18, color: AppColors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'مؤسستك قيد التوثيق. بتقدري تنشري فرص من هلأ، والعلامة ✓ بتطلع بعد التوثيق.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7A3E00)),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            _Stat(Icons.work_outline, '$openCount', 'فرص مفتوحة', AppColors.primary, AppColors.primarySoft,
                loading: loading),
            const SizedBox(width: 10),
            _Stat(Icons.inbox_outlined, '${pending.length}', 'طلبات جديدة', AppColors.orange, AppColors.orangeSoft,
                loading: loading),
            const SizedBox(width: 10),
            _Stat(Icons.groups_outlined, '$acceptedTotal', 'متطوعين مقبولين', AppColors.blue, AppColors.blueSoft,
                loading: loading),
          ]),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => context.push(Routes.orgNewOpportunity),
            icon: const Icon(Icons.add),
            label: const Text('انشري فرصة جديدة'),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                onPressed: () => context.push(Routes.orgNewInitiative),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('مبادرة'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                onPressed: () => context.push(Routes.orgNewService),
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text('خدمة'),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => context.push(Routes.orgScan),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('مسح حضور المتطوعين'),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            'طلبات بانتظار المراجعة',
            onSeeAll: pending.length > 2 ? () => context.go(Routes.orgRequests) : null,
          ),
          const SizedBox(height: 8),
          if (reqState is ListLoading)
            const SkeletonList(count: 1, height: 170)
          else if (pending.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                opps.isEmpty ? 'انشري أول فرصة، وطلبات المتطوعين بتوصلك هون 🤍' : 'ما في طلبات جديدة هلأ ✓',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            )
          else
            for (final r in pending.take(2)) Padding(padding: const EdgeInsets.only(bottom: 12), child: RequestCard(r)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color soft;
  final bool loading;
  const _Stat(this.icon, this.value, this.label, this.color, this.soft, {this.loading = false});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(loading ? '–' : value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ),
      );
}
