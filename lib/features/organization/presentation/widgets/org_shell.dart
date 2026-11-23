import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/widgets/floating_nav.dart';
import 'package:wasl/core/widgets/offline_banner.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';

/// الهيكل اللي فيه شريط التنقل السفلي لحساب المؤسسة.
class OrgShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const OrgShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    context.watch<OrgRequestsCubit>();
    final pending = context.read<OrgRequestsCubit>().pendingCount;
    context.watch<OrgInitiativesCubit>();
    final offers = context.read<OrgInitiativesCubit>().pendingOffers;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [const OfflineBanner(), Expanded(child: shell)]),
      ),
      bottomNavigationBar: FloatingNav(
        child: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: offers > 0,
              label: Text('$offers'),
              backgroundColor: AppColors.orange,
              child: const Icon(Icons.flag_outlined),
            ),
            label: 'مبادراتي',
          ),
          const NavigationDestination(icon: Icon(Icons.work_outline), label: 'فرصي'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              backgroundColor: AppColors.orange,
              child: const Icon(Icons.inbox_outlined),
            ),
            label: 'الطلبات',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
      ),
    );
  }
}
