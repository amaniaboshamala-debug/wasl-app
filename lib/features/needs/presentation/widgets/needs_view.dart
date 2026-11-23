import 'package:flutter/material.dart';
import 'package:wasl/core/widgets/filtered_list_view.dart';
import 'package:wasl/features/needs/domain/entities/need.dart';
import 'package:wasl/features/needs/presentation/cubit/needs_cubit.dart';
import 'package:wasl/features/needs/presentation/widgets/need_card.dart';

/// محتوى تبويب "الاحتياجات" داخل شاشة استكشف.
class NeedsView extends StatelessWidget {
  final String query;
  const NeedsView({super.key, this.query = ''});

  @override
  Widget build(BuildContext context) => FilteredListView<Need, NeedsCubit>(
        query: query,
        region: (e) => e.region,
        category: (e) => e.type,
        searchText: (e) => '${e.type} ${e.description} ${e.initiativeTitle} ${e.organizationName}',
        itemBuilder: NeedCard.new,
        countLabel: 'احتياج',
        emptyIcon: Icons.inventory_2_outlined,
        emptyTitle: 'ما في احتياجات مفتوحة هون',
      );
}
