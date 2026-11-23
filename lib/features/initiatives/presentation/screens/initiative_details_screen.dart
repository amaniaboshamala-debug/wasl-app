import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/category_style.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/app_network_image.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:wasl/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:wasl/features/initiatives/domain/entities/initiative.dart';
import 'package:wasl/features/initiatives/presentation/cubit/initiatives_cubit.dart';
import 'package:wasl/features/needs/presentation/cubit/needs_cubit.dart';
import 'package:wasl/features/reports/presentation/report_button.dart';
import 'package:wasl/features/needs/presentation/widgets/need_card.dart';

/// تفاصيل المبادرة. بتوصلها المبادرة جاهزة من الكرت،
/// وإذا انفتحت من رابط أو من كرت احتياج، بتدوّر عليها بالقائمة المحمّلة.
class InitiativeDetailsScreen extends StatefulWidget {
  final String id;
  final Initiative? initial;
  const InitiativeDetailsScreen({super.key, required this.id, this.initial});

  @override
  State<InitiativeDetailsScreen> createState() => _InitiativeDetailsScreenState();
}

class _InitiativeDetailsScreenState extends State<InitiativeDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InitiativesCubit>().ensureLoaded();
    context.read<NeedsCubit>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InitiativesCubit>().state;
    final item = widget.initial ?? _find(state);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: state is ListLoading<Initiative>
            ? const Center(child: CircularProgressIndicator())
            : const MessageView(
                icon: Icons.search_off,
                title: 'ما لقينا هاي المبادرة',
                subtitle: 'ممكن تكون انتهت أو انحذفت.',
              ),
      );
    }
    return _Details(item);
  }

  Initiative? _find(ListState<Initiative> s) {
    if (s is! ListLoaded<Initiative>) return null;
    for (final e in s.items) {
      if (e.id == widget.id) return e;
    }
    return null;
  }
}

class _Details extends StatelessWidget {
  final Initiative item;
  const _Details(this.item);

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(item.category);
    final needs = context.watch<NeedsCubit>().items.where((n) => n.initiativeId == item.id).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            actions: [
              FavoriteButton(type: FavoriteType.initiative, id: item.id),
              ReportButton(itemType: 'initiative', itemId: item.id),
            ],
            expandedHeight: 180,
            backgroundColor: style.soft,
            flexibleSpace: FlexibleSpaceBar(
              background: item.imageUrl?.isNotEmpty == true
                  ? AppNetworkImage(url: item.imageUrl, borderRadius: BorderRadius.zero)
                  : Center(child: Icon(style.icon, size: 64, color: style.color)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            sliver: SliverList.list(children: [
              Wrap(spacing: 8, children: [
                StatusChip(item.category, color: AppColors.primaryDark, background: AppColors.primarySoft),
                StatusChip(item.statusLabel, color: Colors.white, background: AppColors.primary),
              ]),
              const SizedBox(height: 10),
              Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              OrgName(item.organizationName, verified: item.organizationVerified, fontSize: 14),
              const SizedBox(height: 16),
              AppCard(
                child: Column(children: [
                  DetailRow(Icons.location_on_outlined, 'المكان', item.region.isEmpty ? 'بيتحدد لاحقاً' : item.region),
                  const Divider(height: 20),
                  DetailRow(Icons.calendar_today_outlined, 'الموعد', DateAr.range(item.startDate, item.endDate)),
                  if (item.volunteersNeeded > 0) ...[
                    const Divider(height: 20),
                    DetailRow(Icons.groups_outlined, 'المتطوعين', 'بحاجة ${item.volunteersNeeded} متطوع'),
                  ],
                  const Divider(height: 20),
                  DetailRow(
                    Icons.workspace_premium_outlined,
                    'شهادة تطوع',
                    item.offersCertificate ? '📜 ${item.certificateLabel}' : 'ما في شهادة لهاي المبادرة',
                  ),
                ]),
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('عن المبادرة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(item.description, style: const TextStyle(height: 1.6)),
              ],
              if (item.skills.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('المهارات المطلوبة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in item.skills) StatusChip(s, color: AppColors.blue, background: AppColors.blueSoft),
                  ],
                ),
              ],
              if (needs.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('شو محتاجة المبادرة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                for (final n in needs) Padding(padding: const EdgeInsets.only(bottom: 10), child: NeedCard(n)),
              ],
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: FilledButton.icon(
            onPressed: () => context.go(Routes.opportunities),
            icon: const Icon(Icons.volunteer_activism_outlined),
            label: const Text('شوفي فرص التطوع'),
          ),
        ),
      ),
    );
  }
}
