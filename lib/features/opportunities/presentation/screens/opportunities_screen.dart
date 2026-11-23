import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/regions.dart';
import 'package:wasl/core/widgets/filtered_list_view.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/applications/presentation/cubit/my_applications_cubit.dart';
import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';
import 'package:wasl/features/opportunities/presentation/cubit/opportunities_cubit.dart';
import 'package:wasl/features/opportunities/presentation/widgets/opportunity_card.dart';

/// الفرص: 3 تبويبات (الكل · تطوع · بأجر)، مع بحث ومنطقة.
class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<MyApplicationsCubit>().ensureLoaded();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _list(bool Function(Opportunity)? where) => FilteredListView<Opportunity, OpportunitiesCubit>(
        query: _query,
        where: where,
        region: (e) => e.isRemote ? Regions.everywhere : e.region,
        searchText: (e) => '${e.title} ${e.organizationName} ${e.tasks} ${e.skills.join(' ')}',
        itemBuilder: (e) => _OpportunityWithStatus(e),
        countLabel: 'فرصة',
        emptyIcon: Icons.work_outline,
        emptyTitle: 'ما في فرص هون حالياً',
      );

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 20, 18, 4),
              child: Text('الفرص', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text('تطوع أو عمل مؤقت بأجر', style: TextStyle(color: AppColors.muted)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'ابحثي بالفرصة أو المؤسسة أو المهارة',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'مسح',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _search.clear();
                            _query = '';
                          }),
                        ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFEAE6DC), borderRadius: BorderRadius.circular(12)),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(9)),
                labelColor: AppColors.ink,
                unselectedLabelColor: const Color(0xFF4A5752),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'الكل', height: 40),
                  Tab(text: 'تطوع', height: 40),
                  Tab(text: 'بأجر', height: 40),
                  Tab(text: '📜 شهادة', height: 40),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(children: [
                _list(null),
                _list((e) => e.type == OpportunityType.volunteer),
                _list((e) => e.isPaid),
                _list((e) => e.offersCertificate),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// كرت الفرصة، ولو قدّمتِ عليها بيطلع جنبها حالة طلبك.
class _OpportunityWithStatus extends StatelessWidget {
  final Opportunity item;
  const _OpportunityWithStatus(this.item);

  @override
  Widget build(BuildContext context) {
    context.watch<MyApplicationsCubit>(); // عشان الشارة تتحدّث بعد التقديم
    final mine = context.read<MyApplicationsCubit>().forOpportunity(item.id);
    return OpportunityCard(
      item,
      trailing: mine == null || !mine.isActive
          ? null
          : StatusChip(mine.statusLabel, color: AppColors.primaryDark, background: AppColors.primarySoft),
    );
  }
}
