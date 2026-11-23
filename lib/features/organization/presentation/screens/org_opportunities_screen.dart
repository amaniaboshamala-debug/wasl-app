import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';
import 'package:wasl/features/opportunities/presentation/cubit/opportunities_cubit.dart';
import 'package:wasl/features/organization/domain/entities/org_opportunity.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';

/// فرصي: كل الفرص اللي نشرتها المؤسسة، وحالة كل وحدة، وتسكير أو إعادة فتح.
class OrgOpportunitiesScreen extends StatefulWidget {
  const OrgOpportunitiesScreen({super.key});

  @override
  State<OrgOpportunitiesScreen> createState() => _OrgOpportunitiesScreenState();
}

class _OrgOpportunitiesScreenState extends State<OrgOpportunitiesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrgOpportunitiesCubit>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrgOpportunitiesCubit>();
    final state = context.watch<OrgOpportunitiesCubit>().state;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.orgNewOpportunity),
        icon: const Icon(Icons.add),
        label: const Text('فرصة جديدة'),
      ),
      body: RefreshIndicator(
        onRefresh: cubit.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 96),
          children: [
            const Text('فرصي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const Text('الفرص اللي نشرتيها وحالتها', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 14),
            ...switch (state) {
              ListLoading<OrgOpportunity>() => [const SkeletonList(count: 3)],
              ListError<OrgOpportunity>(:final message) => [
                  MessageView(
                    icon: Icons.wifi_off_outlined,
                    title: 'ما قدرنا نحمّل فرصك',
                    subtitle: message,
                    actionLabel: 'حاولي مرة تانية',
                    onAction: cubit.refresh,
                  ),
                ],
              ListLoaded<OrgOpportunity>(:final items, :final fromCache, :final savedAt) => [
                  if (fromCache) CacheNotice(savedAt: savedAt),
                  if (items.isEmpty)
                    const MessageView(
                      icon: Icons.work_outline,
                      title: 'لسا ما نشرتِ ولا فرصة',
                      subtitle: 'اضغطي "فرصة جديدة" تحت، وبتطلع للمتطوعين فوراً.',
                    )
                  else
                    for (final o in items)
                      Padding(padding: const EdgeInsets.only(bottom: 12), child: _OrgOpportunityCard(o)),
                ],
            },
          ],
        ),
      ),
    );
  }
}

class _OrgOpportunityCard extends StatelessWidget {
  final OrgOpportunity item;
  const _OrgOpportunityCard(this.item);

  static (String, Color, Color) _status(OpportunityStatus s) => switch (s) {
        OpportunityStatus.open => ('مفتوحة', AppColors.primaryDark, AppColors.primarySoft),
        OpportunityStatus.full => ('اكتمل العدد', AppColors.blue, AppColors.blueSoft),
        OpportunityStatus.expired => ('انتهى التقديم', const Color(0xFF4A4F4C), const Color(0xFFEEECE6)),
        OpportunityStatus.closed => ('مسكّرة', const Color(0xFF4A4F4C), const Color(0xFFEEECE6)),
      };

  Future<void> _toggle(BuildContext context, bool open) async {
    final cubit = context.read<OrgOpportunitiesCubit>();
    final publicList = context.read<OpportunitiesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final error = await cubit.setOpen(item.opportunity.id, open);
    if (error == null) publicList.refresh();
    messenger.showSnackBar(SnackBar(content: Text(error ?? (open ? 'رجعت الفرصة مفتوحة' : 'سكّرتِ الفرصة'))));
  }

  @override
  Widget build(BuildContext context) {
    final o = item.opportunity;
    final (label, fg, bg) = _status(o.status);
    final canReopen = o.status == OpportunityStatus.closed &&
        (o.applyDeadline == null || !o.applyDeadline!.isBefore(DateUtils.dateOnly(DateTime.now())));
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(o.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          StatusChip(label, color: fg, background: bg),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 14, runSpacing: 6, children: [
          InfoBit(o.isRemote ? Icons.wifi : Icons.location_on_outlined, o.placeLabel),
          if (o.applyDeadline != null) InfoBit(Icons.schedule, 'التقديم حتى ${DateAr.day(o.applyDeadline!)}'),
          InfoBit(Icons.groups_outlined, '${o.acceptedCount} من ${o.volunteersNeeded} مقبولين'),
        ]),
        const SizedBox(height: 10),
        ProgressLine(
          value: o.volunteersNeeded == 0 ? 0 : o.acceptedCount / o.volunteersNeeded,
          label: '${o.acceptedCount}/${o.volunteersNeeded}',
        ),
        const SizedBox(height: 6),
        Row(children: [
          if (item.pendingCount > 0)
            TextButton.icon(
              onPressed: () => context.go(Routes.orgRequests),
              icon: const Icon(Icons.inbox_outlined, size: 18),
              label: Text('${item.pendingCount} طلب جديد'),
            ),
          const Spacer(),
          if (o.status == OpportunityStatus.open || o.status == OpportunityStatus.full)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
              onPressed: () => _toggle(context, false),
              child: const Text('تسكير'),
            )
          else if (canReopen)
            TextButton(onPressed: () => _toggle(context, true), child: const Text('إعادة فتح')),
        ]),
      ]),
    );
  }
}
