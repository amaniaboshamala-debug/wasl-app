import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/widgets/floating_nav.dart';
import 'package:wasl/core/widgets/offline_banner.dart';

/// الهيكل اللي فيه شريط التنقل السفلي للمستخدم والمتطوع.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [const OfflineBanner(), Expanded(child: shell)]),
      ),
      bottomNavigationBar: FloatingNav(
        child: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'استكشف'),
          NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined), label: 'الفرص'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'طلباتي'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
      ),
    );
  }
}
