import 'package:flutter/material.dart';
import 'package:wasl/core/widgets/filtered_list_view.dart';
import 'package:wasl/features/services/domain/entities/community_service.dart';
import 'package:wasl/features/services/presentation/cubit/services_cubit.dart';
import 'package:wasl/features/services/presentation/widgets/service_card.dart';

/// محتوى تبويب "الخدمات" داخل شاشة استكشف.
class ServicesView extends StatelessWidget {
  final String query;
  const ServicesView({super.key, this.query = ''});

  @override
  Widget build(BuildContext context) => FilteredListView<CommunityService, ServicesCubit>(
        query: query,
        region: (e) => e.region,
        category: (e) => e.category,
        searchText: (e) => '${e.name} ${e.provider} ${e.description}',
        itemBuilder: ServiceCard.new,
        countLabel: 'خدمة',
        emptyIcon: Icons.medical_services_outlined,
        emptyTitle: 'ما في خدمات هون حالياً',
      );
}
