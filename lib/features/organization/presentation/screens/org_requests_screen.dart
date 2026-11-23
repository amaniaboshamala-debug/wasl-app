import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/organization/domain/entities/org_request.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';
import 'package:wasl/features/organization/presentation/widgets/request_card.dart';

/// الطلبات: الجديدة أول، وتصفية حسب الحالة.
class OrgRequestsScreen extends StatefulWidget {
  const OrgRequestsScreen({super.key});

  @override
  State<OrgRequestsScreen> createState() => _OrgRequestsScreenState();
}

class _OrgRequestsScreenState extends State<OrgRequestsScreen> {
  static const _filters = {
    'جديدة': ApplicationStatus.pending,
    'مقبولة': ApplicationStatus.accepted,
    'مرفوضة': ApplicationStatus.rejected,
  };
  String? _filter = 'جديدة'; // null = الكل

  @override
  void initState() {
    super.initState();
    context.read<OrgRequestsCubit>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrgRequestsCubit>();
    final state = context.watch<OrgRequestsCubit>().state;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: cubit.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          children: [
            Row(children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('الطلبات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  Text('المتطوعين اللي قدّموا على فرصك', style: TextStyle(color: AppColors.muted)),
                ]),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                onPressed: () => context.push(Routes.orgScan),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('مسح الحضور'),
              ),
            ]),
            const SizedBox(height: 14),
            ...switch (state) {
              ListLoading<OrgRequest>() => [const SkeletonList(count: 3, height: 170)],
              ListError<OrgRequest>(:final message) => [
                  MessageView(
                    icon: Icons.wifi_off_outlined,
                    title: 'ما قدرنا نحمّل الطلبات',
                    subtitle: message,
                    actionLabel: 'حاولي مرة تانية',
                    onAction: cubit.refresh,
                  ),
                ],
              ListLoaded<OrgRequest>(:final items, :final fromCache, :final savedAt) => [
                  if (fromCache) CacheNotice(savedAt: savedAt),
                  FilterChips(
                    options: _filters.keys.toList(),
                    selected: _filter,
                    onChanged: (c) => setState(() => _filter = c),
                  ),
                  const SizedBox(height: 12),
                  ..._list(items),
                ],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _list(List<OrgRequest> all) {
    final shown = _filter == null ? all : all.where((r) => r.status == _filters[_filter]).toList();
    if (shown.isEmpty) {
      return [
        MessageView(
          icon: Icons.inbox_outlined,
          title: _filter == 'جديدة' ? 'ما في طلبات جديدة' : 'ما في طلبات هون',
          subtitle: _filter == 'جديدة' ? 'لما حدا يقدّم على فرصة من فرصك، بيطلع هون.' : null,
        ),
      ];
    }
    return [for (final r in shown) Padding(padding: const EdgeInsets.only(bottom: 12), child: RequestCard(r))];
  }
}
