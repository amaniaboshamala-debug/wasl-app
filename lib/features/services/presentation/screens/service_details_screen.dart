import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/category_style.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:wasl/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:wasl/features/reports/presentation/report_button.dart';
import 'package:wasl/features/services/domain/entities/community_service.dart';
import 'package:wasl/features/services/presentation/cubit/services_cubit.dart';
import 'package:wasl/features/services/presentation/widgets/service_card.dart';

/// تفاصيل الخدمة المجانية: مين بيستفيد، المواعيد، وكيف تستفيدي.
class ServiceDetailsScreen extends StatefulWidget {
  final String id;
  final CommunityService? initial;
  const ServiceDetailsScreen({super.key, required this.id, this.initial});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ServicesCubit>().ensureLoaded();
  }

  CommunityService? _find(ListState<CommunityService> s) {
    if (s is! ListLoaded<CommunityService>) return null;
    for (final e in s.items) {
      if (e.id == widget.id) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ServicesCubit>().state;
    final item = widget.initial ?? _find(state);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: state is ListLoading<CommunityService>
            ? const Center(child: CircularProgressIndicator())
            : const MessageView(
                icon: Icons.search_off,
                title: 'ما لقينا هاي الخدمة',
                subtitle: 'ممكن تكون انتهت أو انحذفت.',
              ),
      );
    }

    final style = CategoryStyle.of(item.category);
    final (fg, bg) = serviceStatusColors(item.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الخدمة'),
        actions: [
          FavoriteButton(type: FavoriteType.service, id: item.id),
          ReportButton(itemType: 'service', itemId: item.id),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: style.soft, borderRadius: BorderRadius.circular(18)),
                child: Icon(style.icon, size: 30, color: style.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    OrgName(item.provider, verified: item.providerVerified, fontSize: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, children: [
            StatusChip(item.statusLabel, color: fg, background: bg),
            if (item.category.isNotEmpty)
              StatusChip(item.category, color: AppColors.primaryDark, background: AppColors.primarySoft),
          ]),
          const SizedBox(height: 14),
          if (item.needsConfirmation || item.status == ServiceStatus.paused)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(14)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.status == ServiceStatus.paused
                          ? 'الخدمة متوقفة مؤقتاً. تواصلي مع المؤسسة قبل ما تروحي.'
                          : 'ما حدا أكّد إن الخدمة لسا شغّالة من أسبوع أو أكتر. تأكدي قبل ما تروحي.',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF7A3E00)),
                    ),
                  ),
                ],
              ),
            ),
          if (item.description.isNotEmpty) ...[
            Text(item.description, style: const TextStyle(height: 1.6)),
            const SizedBox(height: 14),
          ],
          AppCard(
            child: Column(children: [
              DetailRow(Icons.location_on_outlined, 'المكان', item.region.isEmpty ? 'غير محدد' : item.region),
              if (item.schedule.isNotEmpty) ...[
                const Divider(height: 20),
                DetailRow(Icons.schedule, 'المواعيد', item.schedule),
              ],
              if (item.beneficiaries.isNotEmpty) ...[
                const Divider(height: 20),
                DetailRow(Icons.people_outline, 'مين بيستفيد', item.beneficiaries),
              ],
              const Divider(height: 20),
              DetailRow(Icons.sync, 'آخر تأكيد إنها متاحة', DateAr.ago(item.lastConfirmedAt)),
            ]),
          ),
          if (item.howToBenefit.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('كيف تستفيدي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(item.howToBenefit, style: const TextStyle(height: 1.6)),
          ],
        ],
      ),
    );
  }
}
