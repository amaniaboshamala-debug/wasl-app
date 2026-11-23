import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/category_style.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/initiatives/domain/entities/initiative.dart';
import 'package:wasl/features/organization/domain/entities/org_initiative.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';
import 'package:wasl/features/services/domain/entities/community_service.dart';
import 'package:wasl/features/services/presentation/widgets/service_card.dart';

/// مبادراتي وخدماتي: تبويبين، وزر إضافة حسب التبويب.
class OrgInitiativesScreen extends StatefulWidget {
  const OrgInitiativesScreen({super.key});

  @override
  State<OrgInitiativesScreen> createState() => _OrgInitiativesScreenState();
}

class _OrgInitiativesScreenState extends State<OrgInitiativesScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));

  @override
  void initState() {
    super.initState();
    context.read<OrgInitiativesCubit>().ensureLoaded();
    context.read<OrgServicesCubit>().ensureLoaded();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onServices = _tabs.index == 1;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(onServices ? Routes.orgNewService : Routes.orgNewInitiative),
        icon: const Icon(Icons.add),
        label: Text(onServices ? 'خدمة جديدة' : 'مبادرة جديدة'),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 20, 18, 4),
          child: Text('مبادراتي وخدماتي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text('اللي بتنشريه هون بيطلع للناس باستكشف', style: TextStyle(color: AppColors.muted)),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFEAE6DC), borderRadius: BorderRadius.circular(12)),
          child: TabBar(
            controller: _tabs,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(9)),
            labelColor: AppColors.ink,
            tabs: const [Tab(text: 'المبادرات', height: 40), Tab(text: 'الخدمات', height: 40)],
          ),
        ),
        Expanded(
          child: TabBarView(controller: _tabs, children: const [_InitiativesTab(), _ServicesTab()]),
        ),
      ]),
    );
  }
}

// ===================== المبادرات =====================

class _InitiativesTab extends StatelessWidget {
  const _InitiativesTab();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrgInitiativesCubit>();
    final state = context.watch<OrgInitiativesCubit>().state;
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
        children: switch (state) {
          ListLoading<OrgInitiative>() => [const SkeletonList(count: 3)],
          ListError<OrgInitiative>(:final message) => [
              MessageView(
                icon: Icons.wifi_off_outlined,
                title: 'ما قدرنا نحمّل مبادراتك',
                subtitle: message,
                actionLabel: 'حاولي مرة تانية',
                onAction: cubit.refresh,
              ),
            ],
          ListLoaded<OrgInitiative>(:final items) when items.isEmpty => [
              const MessageView(
                icon: Icons.flag_outlined,
                title: 'لسا ما نشرتِ ولا مبادرة',
                subtitle: 'المبادرة بتجمع فرصك واحتياجاتك تحت اسم واحد، زي "تعلّم وارتقِ".',
              ),
            ],
          ListLoaded<OrgInitiative>(:final items, :final fromCache, :final savedAt) => [
              if (fromCache) CacheNotice(savedAt: savedAt),
              for (final i in items) Padding(padding: const EdgeInsets.only(bottom: 12), child: _InitiativeTile(i)),
            ],
        },
      ),
    );
  }
}

/// لون وحالة المبادرة عند المؤسسة.
(String, Color, Color) initiativeStatusStyle(InitiativeStatus s) => switch (s) {
      InitiativeStatus.pending => ('قيد المراجعة', const Color(0xFF7A3E00), AppColors.orangeSoft),
      InitiativeStatus.published => ('منشورة', AppColors.primaryDark, AppColors.primarySoft),
      InitiativeStatus.active => ('جارية', AppColors.primaryDark, AppColors.primarySoft),
      InitiativeStatus.completed => ('خلصت', AppColors.blue, AppColors.blueSoft),
      InitiativeStatus.cancelled => ('ملغاة', const Color(0xFF4A4F4C), const Color(0xFFEEECE6)),
    };

class _InitiativeTile extends StatelessWidget {
  final OrgInitiative item;
  const _InitiativeTile(this.item);

  @override
  Widget build(BuildContext context) {
    final i = item.initiative;
    final style = CategoryStyle.of(i.category);
    final (label, fg, bg) = initiativeStatusStyle(i.status);
    return AppCard(
      onTap: () => context.push(Routes.orgInitiative(i.id)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: style.soft, borderRadius: BorderRadius.circular(12)),
            child: Icon(style.icon, color: style.color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(i.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
          StatusChip(label, color: fg, background: bg),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 14, runSpacing: 6, children: [
          if (i.region.isNotEmpty) InfoBit(Icons.location_on_outlined, i.region),
          InfoBit(Icons.calendar_today_outlined, DateAr.range(i.startDate, i.endDate)),
          InfoBit(Icons.inventory_2_outlined, '${item.needs.length} احتياج'),
        ]),
        if (item.pendingOffers > 0) ...[
          const SizedBox(height: 8),
          StatusChip('🤝 ${item.pendingOffers} عرض مساعدة جديد', color: AppColors.orange, background: AppColors.orangeSoft),
        ],
      ]),
    );
  }
}

// ===================== الخدمات =====================

class _ServicesTab extends StatelessWidget {
  const _ServicesTab();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrgServicesCubit>();
    final state = context.watch<OrgServicesCubit>().state;
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
        children: switch (state) {
          ListLoading<CommunityService>() => [const SkeletonList(count: 3)],
          ListError<CommunityService>(:final message) => [
              MessageView(
                icon: Icons.wifi_off_outlined,
                title: 'ما قدرنا نحمّل خدماتك',
                subtitle: message,
                actionLabel: 'حاولي مرة تانية',
                onAction: cubit.refresh,
              ),
            ],
          ListLoaded<CommunityService>(:final items) when items.isEmpty => [
              const MessageView(
                icon: Icons.medical_services_outlined,
                title: 'لسا ما نشرتِ ولا خدمة',
                subtitle: 'خدمة مجانية زي عيادة، أو نقطة شحن، أو دروس، بتطلع للناس القريبين.',
              ),
            ],
          ListLoaded<CommunityService>(:final items, :final fromCache, :final savedAt) => [
              if (fromCache) CacheNotice(savedAt: savedAt),
              for (final s in items) Padding(padding: const EdgeInsets.only(bottom: 12), child: _ServiceTile(s)),
            ],
        },
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final CommunityService item;
  const _ServiceTile(this.item);

  Future<void> _run(BuildContext context, Future<String?> Function() call, String ok) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await call();
    messenger.showSnackBar(SnackBar(content: Text(error ?? ok)));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrgServicesCubit>();
    return Column(children: [
      ServiceCard(item),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
            onPressed: () => _run(context, () => cubit.confirm(item.id), 'تأكّدت إنها متاحة ✓'),
            icon: const Icon(Icons.verified_outlined, size: 18),
            label: const Text('لسا متاحة'),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<ServiceStatus>(
          tooltip: 'غيّري الحالة',
          onSelected: (s) => _run(context, () => cubit.setStatus(item.id, s), 'تغيّرت الحالة'),
          itemBuilder: (_) => const [
            PopupMenuItem(value: ServiceStatus.available, child: Text('متاحة')),
            PopupMenuItem(value: ServiceStatus.limited, child: Text('محدودة')),
            PopupMenuItem(value: ServiceStatus.paused, child: Text('متوقفة مؤقتاً')),
            PopupMenuItem(value: ServiceStatus.ended, child: Text('انتهت')),
          ],
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(children: [Text('الحالة'), Icon(Icons.arrow_drop_down)]),
          ),
        ),
      ]),
    ]);
  }
}
