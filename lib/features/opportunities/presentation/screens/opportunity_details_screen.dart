import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/applications/presentation/cubit/my_applications_cubit.dart';
import 'package:wasl/features/applications/presentation/widgets/withdraw_dialog.dart';
import 'package:wasl/features/auth/domain/entities/app_user.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_state.dart';
import 'package:wasl/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:wasl/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';
import 'package:wasl/features/opportunities/presentation/cubit/opportunities_cubit.dart';
import 'package:wasl/features/opportunities/presentation/widgets/opportunity_card.dart';
import 'package:wasl/features/reports/presentation/report_button.dart';

/// تفاصيل الفرصة، وتحت زر التقديم (أو حالة طلبك إذا قدّمتِ).
class OpportunityDetailsScreen extends StatefulWidget {
  final String id;
  final Opportunity? initial;
  const OpportunityDetailsScreen({super.key, required this.id, this.initial});

  @override
  State<OpportunityDetailsScreen> createState() => _OpportunityDetailsScreenState();
}

class _OpportunityDetailsScreenState extends State<OpportunityDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OpportunitiesCubit>().ensureLoaded();
    context.read<MyApplicationsCubit>().ensureLoaded();
  }

  Opportunity? _find(ListState<Opportunity> s) {
    if (s is! ListLoaded<Opportunity>) return null;
    for (final e in s.items) {
      if (e.id == widget.id) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OpportunitiesCubit>().state;
    // بنفضّل النسخة الأحدث من القائمة (عدد المقاعد بيتغيّر)، وإلا اللي وصلت من الكرت
    final item = _find(state) ?? widget.initial;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: state is ListLoading<Opportunity>
            ? const Center(child: CircularProgressIndicator())
            : const MessageView(
                icon: Icons.search_off,
                title: 'ما لقينا هاي الفرصة',
                subtitle: 'ممكن تكون سكّرت أو انحذفت.',
              ),
      );
    }

    final type = opportunityTypeStyle(item.type);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الفرصة'),
        actions: [
          FavoriteButton(type: FavoriteType.opportunity, id: item.id),
          ReportButton(itemType: 'opportunity', itemId: item.id),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          OrgName(item.organizationName, verified: item.organizationVerified, fontSize: 14),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            StatusChip(item.typeLabel, color: type.fg, background: type.bg),
            StatusChip(
              item.seatsLabel,
              color: item.isOpen ? const Color(0xFF7A3E00) : AppColors.muted,
              background: item.isOpen ? AppColors.orangeSoft : const Color(0xFFEEECE6),
            ),
          ]),
          const SizedBox(height: 16),
          AppCard(
            child: Column(children: [
              DetailRow(item.isRemote ? Icons.wifi : Icons.location_on_outlined, 'المكان',
                  item.isRemote ? 'عن بُعد' : [item.location, item.region].where((s) => s.isNotEmpty).join(' · ')),
              if (item.date != null) ...[
                const Divider(height: 20),
                DetailRow(Icons.calendar_today_outlined, 'الموعد', DateAr.day(item.date!)),
              ],
              if (item.duration.isNotEmpty) ...[
                const Divider(height: 20),
                DetailRow(Icons.timelapse, 'المدة', item.duration),
              ],
              if (item.applyDeadline != null) ...[
                const Divider(height: 20),
                DetailRow(Icons.schedule, 'آخر موعد للتقديم', DateAr.day(item.applyDeadline!)),
              ],
              const Divider(height: 20),
              DetailRow(Icons.groups_outlined, 'المتطوعين', '${item.acceptedCount} من ${item.volunteersNeeded}'),
              const Divider(height: 20),
              DetailRow(
                Icons.workspace_premium_outlined,
                'شهادة تطوع',
                item.offersCertificate ? '📜 ${item.certificateLabel}' : 'ما في شهادة لهاي الفرصة',
              ),
            ]),
          ),
          if (item.isPaid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(14)),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, color: AppColors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الأجر أو البدل بتتفقي عليه مع المؤسسة مباشرة. وَصْل ما بيستقبل ولا بيحوّل أي أموال.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF0B4A61)),
                  ),
                ),
              ]),
            ),
          ],
          if (item.tasks.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('شو المطلوب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(item.tasks, style: const TextStyle(height: 1.6)),
          ],
          if (item.skills.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('المهارات المفيدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in item.skills) StatusChip(s, color: AppColors.blue, background: AppColors.blueSoft),
            ]),
          ],
          if (item.initiativeId != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.push(Routes.initiativeDetails(item.initiativeId!)),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('شوفي المبادرة'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: _ApplyBar(item),
        ),
      ),
    );
  }
}

/// الزر تحت: قدّمي · طلبك قيد المراجعة (انسحاب) · اكتمل العدد · للمتطوعين بس
class _ApplyBar extends StatelessWidget {
  final Opportunity item;
  const _ApplyBar(this.item);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final role = auth is Authenticated ? auth.user.role : null;
    final apps = context.watch<MyApplicationsCubit>();
    final mine = apps.forOpportunity(item.id);

    if (role != UserRole.volunteer) {
      return const FilledButton(onPressed: null, child: Text('التقديم على الفرص للمتطوعين بس'));
    }
    if (apps.state is ListLoading) {
      return const FilledButton(onPressed: null, child: Text('لحظة...'));
    }
    if (mine != null && mine.isActive) {
      return Row(children: [
        Expanded(
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
            child: Text('طلبك: ${mine.statusLabel}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            foregroundColor: AppColors.red,
            side: const BorderSide(color: AppColors.red),
          ),
          onPressed: () => confirmWithdraw(context, mine),
          child: const Text('انسحاب'),
        ),
      ]);
    }
    if (mine?.status == ApplicationStatus.rejected) {
      return const FilledButton(onPressed: null, child: Text('ما انقبل طلبك على هاي الفرصة'));
    }
    if (!item.isOpen) {
      return FilledButton(onPressed: null, child: Text(item.seatsLabel));
    }
    return FilledButton.icon(
      onPressed: () => context.push(Routes.applyTo(item.id), extra: item),
      icon: const Icon(Icons.send_outlined),
      label: Text(mine?.status == ApplicationStatus.withdrawn ? 'قدّمي مرة تانية' : 'قدّمي على الفرصة'),
    );
  }
}
