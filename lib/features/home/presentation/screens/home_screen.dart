import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/presentation/region_cubit.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/theme/app_theme.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/utils/regions.dart';
import 'package:wasl/core/widgets/illustrations.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/applications/presentation/cubit/my_applications_cubit.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_state.dart';
import 'package:wasl/features/initiatives/presentation/cubit/initiatives_cubit.dart';
import 'package:wasl/features/initiatives/presentation/widgets/initiative_card.dart';
import 'package:wasl/features/needs/presentation/cubit/needs_cubit.dart';
import 'package:wasl/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:wasl/features/needs/presentation/widgets/need_card.dart';
import 'package:wasl/features/services/domain/entities/community_service.dart';
import 'package:wasl/features/services/presentation/cubit/services_cubit.dart';
import 'package:wasl/features/services/presentation/widgets/service_card.dart';

/// الرئيسية: ترحيب، بحث، اختصارات، وأقرب المبادرات والخدمات والاحتياجات العاجلة.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InitiativesCubit>().ensureLoaded();
    context.read<ServicesCubit>().ensureLoaded();
    context.read<NeedsCubit>().ensureLoaded();
    context.read<MyApplicationsCubit>().ensureLoaded();
  }

  Future<void> _refreshAll() => Future.wait([
        context.read<InitiativesCubit>().refresh(),
        context.read<ServicesCubit>().refresh(),
        context.read<NeedsCubit>().refresh(),
        context.read<MyApplicationsCubit>().refresh(),
      ]);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final fullName = auth is Authenticated ? auth.user.name.trim() : '';
    final firstName = fullName.isEmpty ? '' : fullName.split(' ').first;
    final region = context.watch<RegionCubit>().state;

    final initiativesState = context.watch<InitiativesCubit>().state;
    final servicesState = context.watch<ServicesCubit>().state;
    final needsState = context.watch<NeedsCubit>().state;

    final initiatives = context.read<InitiativesCubit>().items.where((e) => Regions.matches(e.region, region)).take(2);
    final services = context
        .read<ServicesCubit>()
        .items
        .where((e) => Regions.matches(e.region, region) && e.status != ServiceStatus.paused)
        .take(3);
    final needs = context.read<NeedsCubit>().items.where((e) => Regions.matches(e.region, region) && e.isUrgent).take(2);

    context.watch<MyApplicationsCubit>();
    final upcoming = _nextAccepted(context.read<MyApplicationsCubit>().items);

    final offline = [initiativesState, servicesState, needsState].whereType<ListLoaded>().any((s) => s.fromCache);
    final savedAt = initiativesState is ListLoaded ? (initiativesState as ListLoaded).savedAt : null;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            // الشريط العلوي: الصورة · الترحيب · المنطقة · الإشعارات
            Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.peach,
                  child: Text(
                    firstName.isEmpty ? 'و' : String.fromCharCode(firstName.runes.first),
                    style: AppTheme.heading(size: 18, weight: FontWeight.w700, color: const Color(0xFF8A3E22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_greeting(), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                    Text(firstName.isEmpty ? 'أهلاً فيكِ' : firstName, style: AppTheme.heading(size: 20)),
                  ]),
                ),
                const RegionButton(compact: true),
                const SizedBox(width: 8),
                const NotificationBell(),
              ],
            ),
            const SizedBox(height: 16),

            // الكرت الترحيبي مع الرسمة
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(28)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('كل إيد بتفرق', style: AppTheme.heading(size: 22, weight: FontWeight.w700, color: const Color(0xFF24453A))),
                Text(
                  initiatives.isEmpty ? 'اكتشفي مبادرات وفرص حواليكِ' : 'في مبادرات وفرص قريبة منك بتستناكِ',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF3D5B50)),
                ),
                const Illustration(Illustration.hero, label: 'متطوعتين ماسكين قلب', height: 160),
              ]),
            ),
            const SizedBox(height: 14),

            // البحث: بيفتح استكشف
            Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.go(Routes.explore),
                child: const SizedBox(
                  height: 52,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Icon(Icons.search, color: AppColors.muted),
                      SizedBox(width: 10),
                      Text('شو بتدوري عليه اليوم؟', style: TextStyle(color: AppColors.muted, fontSize: 15)),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // الاختصارات
            Row(
              children: [
                _Shortcut(Icons.flag_outlined, 'المبادرات', AppColors.primary, AppColors.primarySoft,
                    () => context.go(Routes.exploreTab(0))),
                _Shortcut(Icons.medical_services_outlined, 'الخدمات', AppColors.blue, AppColors.blueSoft,
                    () => context.go(Routes.exploreTab(1))),
                _Shortcut(Icons.inventory_2_outlined, 'الاحتياجات', AppColors.orange, AppColors.orangeSoft,
                    () => context.go(Routes.exploreTab(2))),
                _Shortcut(Icons.bookmark_outline, 'المفضلة', AppColors.orange, AppColors.peach,
                    () => context.push(Routes.favorites)),
              ],
            ),
            const SizedBox(height: 16),
            const _TipCard(),
            const SizedBox(height: 18),
            if (upcoming != null) ...[
              _UpcomingCard(upcoming),
              const SizedBox(height: 16),
            ],
            if (offline) CacheNotice(savedAt: savedAt),

            // مبادرات قريبة
            SectionHeader('مبادرات قريبة منك', onSeeAll: () => context.go(Routes.exploreTab(0))),
            const SizedBox(height: 8),
            ..._section(
              state: initiativesState,
              items: [for (final e in initiatives) InitiativeCard(e)],
              empty: 'ما في مبادرات مفتوحة بمنطقتك هلأ',
              skeletonHeight: 190,
            ),
            const SizedBox(height: 10),

            // خدمات متاحة
            SectionHeader('خدمات مجانية قريبة', onSeeAll: () => context.go(Routes.exploreTab(1))),
            const SizedBox(height: 8),
            ..._section(
              state: servicesState,
              items: [for (final e in services) ServiceCard(e)],
              empty: 'ما في خدمات متاحة بمنطقتك هلأ',
              skeletonHeight: 150,
            ),
            const SizedBox(height: 10),

            // احتياجات عاجلة
            SectionHeader('احتياجات عاجلة', onSeeAll: () => context.go(Routes.exploreTab(2))),
            const SizedBox(height: 8),
            ..._section(
              state: needsState,
              items: [for (final e in needs) NeedCard(e)],
              empty: 'ما في احتياجات عاجلة بمنطقتك 🤍',
              skeletonHeight: 120,
            ),
          ],
        ),
      ),
    );
  }

  static String _greeting() => DateTime.now().hour < 12 ? 'صباح الخير' : 'مساء الخير';

  /// أقرب فرصة انقبلتِ فيها ولسا ما صارت.
  static VolunteerApplication? _nextAccepted(List<VolunteerApplication> apps) {
    final now = DateTime.now().subtract(const Duration(hours: 12));
    final list = apps.where((a) => a.status == ApplicationStatus.accepted && a.date != null && a.date!.isAfter(now)).toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));
    return list.isEmpty ? null : list.first;
  }

  /// كل قسم: هيكل رمادي وقت التحميل · رسالة خطأ · الكروت · أو "ما في شي".
  List<Widget> _section({
    required ListState state,
    required List<Widget> items,
    required String empty,
    required double skeletonHeight,
  }) {
    if (state is ListLoading) return [SkeletonList(count: 1, height: skeletonHeight)];
    if (state is ListError) {
      return [
        _Hint(state.message, action: 'حاولي مرة تانية', onAction: _refreshAll),
      ];
    }
    if (items.isEmpty) return [_Hint(empty)];
    return [for (final w in items) Padding(padding: const EdgeInsets.only(bottom: 12), child: w)];
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color soft;
  final VoidCallback onTap;
  const _Shortcut(this.icon, this.label, this.color, this.soft, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(20)),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}

class _Hint extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const _Hint(this.text, {this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 13))),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ]),
      );
}

/// "نشاطك القادم": أقرب فرصة انقبلتِ فيها.
class _UpcomingCard extends StatelessWidget {
  final VolunteerApplication app;
  const _UpcomingCard(this.app);

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push(Routes.opportunityDetails(app.opportunityId)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 52,
                height: 56,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${app.date!.day}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, height: 1)),
                  Text(DateAr.month(app.date!), style: const TextStyle(fontSize: 11, color: Colors.white)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('نشاطك القادم', style: TextStyle(fontSize: 12, color: Color(0xFFDCEDE6))),
                  Text(app.opportunityTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  if (app.place.isNotEmpty)
                    Text(app.place, style: const TextStyle(fontSize: 12, color: Color(0xFFDCEDE6))),
                ]),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ]),
          ),
        ),
      );
}

/// نصيحة اليوم: بتفتح ركن التوعية.
class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: () => context.push(Routes.awareness),
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          const Illustration(Illustration.shield, label: 'درع حماية', width: 68, height: 68),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('نصيحة اليوم', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.orange)),
              Text('وَصْل ما بيطلب منك فلوس أبداً', style: AppTheme.heading(size: 15)),
              const Text('إذا حدا طلب تحويل باسم مبادرة، بلّغي عنه',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
          const Icon(Icons.chevron_left, color: AppColors.muted),
        ]),
      );
}
