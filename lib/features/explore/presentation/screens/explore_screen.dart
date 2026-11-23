import 'package:flutter/material.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/features/initiatives/presentation/widgets/initiatives_view.dart';
import 'package:wasl/features/needs/presentation/widgets/needs_view.dart';
import 'package:wasl/features/services/presentation/widgets/services_view.dart';

/// استكشف = 3 تبويبات: مبادرات · خدمات · احتياجات، مع بحث واحد للكل.
class ExploreScreen extends StatefulWidget {
  final int initialTab;
  const ExploreScreen({super.key, this.initialTab = 0});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab.clamp(0, 2),
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 20, 18, 4),
              child: Text('استكشف', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text('المبادرات والخدمات والاحتياجات في منطقتك', style: TextStyle(color: AppColors.muted)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'ابحثي بالاسم أو المؤسسة',
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
                tabs: const [Tab(text: 'المبادرات', height: 40), Tab(text: 'الخدمات', height: 40), Tab(text: 'الاحتياجات', height: 40)],
              ),
            ),
            Expanded(
              child: TabBarView(children: [
                InitiativesView(query: _query),
                ServicesView(query: _query),
                NeedsView(query: _query),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
