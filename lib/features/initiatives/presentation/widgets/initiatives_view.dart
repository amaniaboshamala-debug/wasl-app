import 'package:flutter/material.dart';
import 'package:wasl/core/widgets/filtered_list_view.dart';
import 'package:wasl/features/initiatives/domain/entities/initiative.dart';
import 'package:wasl/features/initiatives/presentation/cubit/initiatives_cubit.dart';
import 'package:wasl/features/initiatives/presentation/widgets/initiative_card.dart';

/// محتوى تبويب "المبادرات" داخل شاشة استكشف.
class InitiativesView extends StatelessWidget {
  final String query;
  const InitiativesView({super.key, this.query = ''});

  @override
  Widget build(BuildContext context) => FilteredListView<Initiative, InitiativesCubit>(
        query: query,
        region: (e) => e.region,
        category: (e) => e.category,
        searchText: (e) => '${e.title} ${e.organizationName} ${e.description}',
        itemBuilder: InitiativeCard.new,
        countLabel: 'مبادرة',
        emptyIcon: Icons.flag_outlined,
        emptyTitle: 'ما في مبادرات هون حالياً',
      );
}
