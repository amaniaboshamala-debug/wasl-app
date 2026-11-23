import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/applications/presentation/cubit/my_applications_cubit.dart';
import 'package:wasl/features/applications/presentation/widgets/application_card.dart';

/// طلباتي: كل الطلبات اللي قدّمتيها وحالتها.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  static const _filters = <String, bool Function(VolunteerApplication)?>{
    'الكل': null,
    'قيد المراجعة': _pending,
    'مقبولة': _accepted,
    'منتهية': _finished,
  };
  static bool _pending(VolunteerApplication a) => a.status == ApplicationStatus.pending;
  static bool _accepted(VolunteerApplication a) => a.status == ApplicationStatus.accepted;
  static bool _finished(VolunteerApplication a) => !a.isActive;

  String _filter = 'الكل';

  @override
  void initState() {
    super.initState();
    context.read<MyApplicationsCubit>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MyApplicationsCubit>();
    final state = context.watch<MyApplicationsCubit>().state;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: cubit.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          children: [
            const Text('طلباتي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const Text('الفرص اللي قدّمتِ عليها وحالة كل طلب', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 14),
            ...switch (state) {
              ListLoading<VolunteerApplication>() => [const SkeletonList(count: 3)],
              ListError<VolunteerApplication>(:final message) => [
                  MessageView(
                    icon: Icons.wifi_off_outlined,
                    title: 'ما قدرنا نحمّل طلباتك',
                    subtitle: message,
                    actionLabel: 'حاولي مرة تانية',
                    onAction: cubit.refresh,
                  ),
                ],
              ListLoaded<VolunteerApplication>(:final items, :final fromCache, :final savedAt) =>
                _loaded(items, fromCache, savedAt),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _loaded(List<VolunteerApplication> all, bool fromCache, DateTime? savedAt) {
    if (all.isEmpty) {
      return [
        const SizedBox(height: 40),
        MessageView(
          icon: Icons.assignment_outlined,
          title: 'لسا ما قدّمتِ على ولا فرصة',
          subtitle: 'شوفي الفرص المتاحة وقدّمي على اللي بتناسبك.',
          actionLabel: 'تصفّحي الفرص',
          onAction: () => context.go(Routes.opportunities),
        ),
      ];
    }
    final where = _filters[_filter];
    final shown = where == null ? all : all.where(where).toList();
    return [
      if (fromCache) CacheNotice(savedAt: savedAt),
      FilterChips(
        options: _filters.keys.skip(1).toList(),
        selected: _filter == 'الكل' ? null : _filter,
        onChanged: (f) => setState(() => _filter = f ?? 'الكل'),
      ),
      const SizedBox(height: 12),
      if (shown.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: Text('ما في طلبات هون', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
        )
      else
        for (final a in shown) Padding(padding: const EdgeInsets.only(bottom: 12), child: ApplicationCard(a)),
    ];
  }
}
