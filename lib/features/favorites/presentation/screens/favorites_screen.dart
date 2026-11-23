import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:wasl/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:wasl/features/initiatives/presentation/cubit/initiatives_cubit.dart';
import 'package:wasl/features/initiatives/presentation/widgets/initiative_card.dart';
import 'package:wasl/features/opportunities/presentation/cubit/opportunities_cubit.dart';
import 'package:wasl/features/opportunities/presentation/widgets/opportunity_card.dart';
import 'package:wasl/features/services/presentation/cubit/services_cubit.dart';
import 'package:wasl/features/services/presentation/widgets/service_card.dart';

/// المفضلة: الفرص والمبادرات والخدمات اللي حفظتيها.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FavoritesCubit>().ensureLoaded();
    context.read<OpportunitiesCubit>().ensureLoaded();
    context.read<InitiativesCubit>().ensureLoaded();
    context.read<ServicesCubit>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesCubit>();
    context.watch<OpportunitiesCubit>();
    context.watch<InitiativesCubit>();
    context.watch<ServicesCubit>();

    final oppIds = fav.idsOf(FavoriteType.opportunity);
    final iniIds = fav.idsOf(FavoriteType.initiative);
    final srvIds = fav.idsOf(FavoriteType.service);
    final opps = context.read<OpportunitiesCubit>().items.where((e) => oppIds.contains(e.id)).toList();
    final inis = context.read<InitiativesCubit>().items.where((e) => iniIds.contains(e.id)).toList();
    final srvs = context.read<ServicesCubit>().items.where((e) => srvIds.contains(e.id)).toList();

    Widget gap(Widget w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w);

    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: opps.isEmpty && inis.isEmpty && srvs.isEmpty
          ? const MessageView(
              icon: Icons.bookmark_border,
              title: 'لسا ما حفظتِ شي',
              subtitle: 'اضغطي 🔖 بصفحة أي فرصة أو مبادرة أو خدمة، وبتلاقيها هون.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                if (opps.isNotEmpty) ...[
                  const SectionHeader('فرص'),
                  for (final o in opps) gap(OpportunityCard(o)),
                ],
                if (inis.isNotEmpty) ...[
                  const SectionHeader('مبادرات'),
                  for (final i in inis) gap(InitiativeCard(i)),
                ],
                if (srvs.isNotEmpty) ...[
                  const SectionHeader('خدمات'),
                  for (final s in srvs) gap(ServiceCard(s)),
                ],
              ],
            ),
    );
  }
}
