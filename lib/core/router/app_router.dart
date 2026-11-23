import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/widgets/main_shell.dart';
import 'package:wasl/features/admin/presentation/admin_screen.dart';
import 'package:wasl/features/applications/presentation/screens/my_requests_screen.dart';
import 'package:wasl/features/attendance/presentation/my_record_screen.dart';
import 'package:wasl/features/attendance/presentation/scan_screen.dart';
import 'package:wasl/features/awareness/awareness_screen.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_state.dart';
import 'package:wasl/features/auth/presentation/screens/check_email_screen.dart';
import 'package:wasl/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:wasl/features/auth/presentation/screens/login_screen.dart';
import 'package:wasl/features/auth/presentation/screens/new_password_screen.dart';
import 'package:wasl/features/auth/presentation/screens/role_screen.dart';
import 'package:wasl/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:wasl/features/auth/presentation/screens/welcome_screen.dart';
import 'package:wasl/features/explore/presentation/screens/explore_screen.dart';
import 'package:wasl/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:wasl/features/home/presentation/screens/home_screen.dart';
import 'package:wasl/features/initiatives/domain/entities/initiative.dart';
import 'package:wasl/features/initiatives/presentation/screens/initiative_details_screen.dart';
import 'package:wasl/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';
import 'package:wasl/features/opportunities/presentation/screens/apply_screen.dart';
import 'package:wasl/features/opportunities/presentation/screens/opportunities_screen.dart';
import 'package:wasl/features/opportunities/presentation/screens/opportunity_details_screen.dart';
import 'package:wasl/features/organization/presentation/screens/new_initiative_screen.dart';
import 'package:wasl/features/organization/presentation/screens/new_opportunity_screen.dart';
import 'package:wasl/features/organization/presentation/screens/new_service_screen.dart';
import 'package:wasl/features/organization/presentation/screens/org_initiative_screen.dart';
import 'package:wasl/features/organization/presentation/screens/org_initiatives_screen.dart';
import 'package:wasl/features/organization/presentation/screens/org_home_screen.dart';
import 'package:wasl/features/organization/presentation/screens/org_opportunities_screen.dart';
import 'package:wasl/features/organization/presentation/screens/org_requests_screen.dart';
import 'package:wasl/features/organization/presentation/widgets/org_shell.dart';
import 'package:wasl/features/profile/presentation/screens/edit_org_screen.dart';
import 'package:wasl/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:wasl/features/profile/presentation/screens/profile_screen.dart';
import 'package:wasl/features/services/domain/entities/community_service.dart';
import 'package:wasl/features/services/presentation/screens/service_details_screen.dart';

class AppRouter {
  static const _authPages = [Routes.welcome, Routes.login, Routes.signUp, Routes.forgotPassword];

  static GoRouter create(AuthCubit auth) {
    return GoRouter(
      initialLocation: Routes.welcome,
      refreshListenable: _StreamListenable(auth.stream),
      redirect: (context, state) {
        final s = auth.state;
        final here = state.matchedLocation;
        if (s is AuthInitial || s is AuthLoading) return null;
        if (s is PasswordRecovery) return here == Routes.newPassword ? null : Routes.newPassword;
        if (s is AwaitingEmailConfirmation) return here == Routes.checkEmail ? null : Routes.checkEmail;
        if (s is! Authenticated) return _authPages.contains(here) ? null : Routes.welcome;
        if (s.user.role == null) return here == Routes.role ? null : Routes.role;
        if (_authPages.contains(here) || here == Routes.role || here == Routes.checkEmail || here == Routes.newPassword) {
          return s.user.isAdmin ? Routes.admin : (s.user.isOrganization ? Routes.orgHome : Routes.home);
        }
        // الإدارة إلها لوحتها، وبتقدر تفتح التفاصيل والإشعارات
        if (s.user.isAdmin) {
          final allowed = here == Routes.admin || here == Routes.notifications || Routes.isDetails(here);
          return allowed ? null : Routes.admin;
        }
        if (here == Routes.admin) return s.user.isOrganization ? Routes.orgHome : Routes.home;
        // حساب المؤسسة إله شاشاته، والمتطوع والمستخدم إلهم شاشاتهم
        final inOrgArea = Routes.isOrgArea(here);
        const shared = {Routes.notifications, Routes.editProfile, Routes.awareness}; // شاشات للكل
        if (s.user.isOrganization && !inOrgArea && !shared.contains(here) && !Routes.isDetails(here)) {
          return Routes.orgHome;
        }
        if (!s.user.isOrganization && inOrgArea) return Routes.home;
        return null;
      },
      routes: [
        GoRoute(path: '/', redirect: (_, __) => Routes.welcome),
        GoRoute(path: Routes.welcome, builder: (_, __) => const WelcomeScreen()),
        GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: Routes.signUp, builder: (_, __) => const SignUpScreen()),
        GoRoute(path: Routes.role, builder: (_, __) => const RoleScreen()),
        GoRoute(path: Routes.checkEmail, builder: (_, __) => const CheckEmailScreen()),
        GoRoute(path: Routes.newPassword, builder: (_, __) => const NewPasswordScreen()),
        GoRoute(
          path: Routes.forgotPassword,
          builder: (_, state) => ForgotPasswordScreen(initialEmail: (state.extra as String?) ?? ''),
        ),
        GoRoute(path: Routes.notifications, builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: Routes.favorites, builder: (_, __) => const FavoritesScreen()),
        GoRoute(path: Routes.orgNewOpportunity, builder: (_, __) => const NewOpportunityScreen()),
        GoRoute(path: Routes.orgEdit, builder: (_, __) => const EditOrgScreen()),
        GoRoute(path: Routes.orgNewInitiative, builder: (_, __) => const NewInitiativeScreen()),
        GoRoute(path: Routes.orgNewService, builder: (_, __) => const NewServiceScreen()),
        GoRoute(
          path: Routes.orgInitiativePattern,
          builder: (_, state) => OrgInitiativeScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(path: Routes.admin, builder: (_, __) => const AdminScreen()),
        GoRoute(path: Routes.orgScan, builder: (_, __) => const ScanScreen()),
        GoRoute(path: Routes.myRecord, builder: (_, __) => const MyRecordScreen()),
        GoRoute(path: Routes.awareness, builder: (_, __) => const AwarenessScreen()),
        GoRoute(path: Routes.editProfile, builder: (_, __) => const EditProfileScreen()),
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => OrgShell(shell: shell),
          branches: [
            _branch(Routes.orgHome, const OrgHomeScreen()),
            _branch(Routes.orgInitiatives, const OrgInitiativesScreen()),
            _branch(Routes.orgOpportunities, const OrgOpportunitiesScreen()),
            _branch(Routes.orgRequests, const OrgRequestsScreen()),
            _branch(Routes.orgProfile, const ProfileScreen()),
          ],
        ),
        GoRoute(
          path: Routes.initiativeDetailsPattern,
          builder: (_, state) => InitiativeDetailsScreen(
            id: state.pathParameters['id']!,
            initial: state.extra is Initiative ? state.extra as Initiative : null,
          ),
        ),
        GoRoute(
          path: Routes.opportunityDetailsPattern,
          builder: (_, state) => OpportunityDetailsScreen(
            id: state.pathParameters['id']!,
            initial: state.extra is Opportunity ? state.extra as Opportunity : null,
          ),
        ),
        GoRoute(
          path: Routes.applyPattern,
          // نموذج التقديم بيحتاج الفرصة نفسها، فإذا انفتح من رابط بنرجع لصفحة الفرصة
          redirect: (_, state) =>
              state.extra is Opportunity ? null : Routes.opportunityDetails(state.pathParameters['id']!),
          builder: (_, state) => ApplyScreen(opportunity: state.extra! as Opportunity),
        ),
        GoRoute(
          path: Routes.serviceDetailsPattern,
          builder: (_, state) => ServiceDetailsScreen(
            id: state.pathParameters['id']!,
            initial: state.extra is CommunityService ? state.extra as CommunityService : null,
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => MainShell(shell: shell),
          branches: [
            _branch(Routes.home, const HomeScreen()),
            StatefulShellBranch(routes: [
              GoRoute(
                path: Routes.explore,
                builder: (_, state) {
                  // ?tab=1 بيفتح على تبويب الخدمات مثلاً
                  final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '');
                  return ExploreScreen(key: ValueKey('explore-$tab'), initialTab: tab ?? 0);
                },
              ),
            ]),
            _branch(Routes.opportunities, const OpportunitiesScreen()),
            _branch(Routes.myRequests, const MyRequestsScreen()),
            _branch(Routes.profile, const ProfileScreen()),
          ],
        ),
      ],
    );
  }

  static StatefulShellBranch _branch(String path, Widget page) =>
      StatefulShellBranch(routes: [GoRoute(path: path, builder: (_, __) => page)]);
}

/// بيخلّي الـ Router يعيد فحص redirect كل ما تتغير حالة الدخول.
class _StreamListenable extends ChangeNotifier {
  late final StreamSubscription _sub;
  _StreamListenable(Stream stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
