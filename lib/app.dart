import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wasl/core/di/injection.dart';
import 'package:wasl/core/presentation/region_cubit.dart';
import 'package:wasl/core/router/app_router.dart';
import 'package:wasl/core/theme/app_theme.dart';
import 'package:wasl/features/admin/data/admin_repository.dart';
import 'package:wasl/features/attendance/data/attendance_repository.dart';
import 'package:wasl/features/applications/presentation/cubit/my_applications_cubit.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_state.dart';
import 'package:wasl/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:wasl/features/initiatives/presentation/cubit/initiatives_cubit.dart';
import 'package:wasl/features/needs/data/repositories/need_offers_repository.dart';
import 'package:wasl/features/needs/presentation/cubit/needs_cubit.dart';
import 'package:wasl/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wasl/features/opportunities/presentation/cubit/opportunities_cubit.dart';
import 'package:wasl/features/organization/presentation/cubit/my_org_cubit.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';
import 'package:wasl/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wasl/features/reports/data/reports_repository.dart';
import 'package:wasl/features/services/presentation/cubit/services_cubit.dart';

class WaslApp extends StatefulWidget {
  const WaslApp({super.key});

  @override
  State<WaslApp> createState() => _WaslAppState();
}

class _WaslAppState extends State<WaslApp> {
  final _authCubit = sl<AuthCubit>();
  // بنعمل الراوتر مرة وحدة بس، عشان ما يرجع لأول شاشة كل ما الشاشة تنبني من جديد
  late final _router = AppRouter.create(_authCubit);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: sl<RegionCubit>()),
        BlocProvider.value(value: sl<InitiativesCubit>()),
        BlocProvider.value(value: sl<ServicesCubit>()),
        BlocProvider.value(value: sl<NeedsCubit>()),
        BlocProvider.value(value: sl<OpportunitiesCubit>()),
        BlocProvider.value(value: sl<MyApplicationsCubit>()),
        BlocProvider.value(value: sl<MyOrgCubit>()),
        BlocProvider.value(value: sl<OrgOpportunitiesCubit>()),
        BlocProvider.value(value: sl<OrgRequestsCubit>()),
        BlocProvider.value(value: sl<ProfileCubit>()),
        BlocProvider.value(value: sl<NotificationsCubit>()),
        BlocProvider.value(value: sl<FavoritesCubit>()),
        BlocProvider.value(value: sl<OrgInitiativesCubit>()),
        BlocProvider.value(value: sl<OrgServicesCubit>()),
        RepositoryProvider.value(value: sl<NeedOffersRepository>()),
        RepositoryProvider.value(value: sl<ReportsRepository>()),
        RepositoryProvider.value(value: sl<AdminRepository>()),
        RepositoryProvider.value(value: sl<AttendanceRepository>()),
      ],
      // لما الحساب يتغيّر (خروج أو دخول بحساب تاني)، بنفضّي البيانات الخاصة فيه عشان تتحمّل للحساب الجديد
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (a, b) => _userId(a) != _userId(b),
        listener: (_, __) {
          sl<MyApplicationsCubit>().reset();
          sl<MyOrgCubit>().reset();
          sl<OrgOpportunitiesCubit>().reset();
          sl<OrgRequestsCubit>().reset();
          sl<ProfileCubit>().reset();
          sl<NotificationsCubit>().reset();
          sl<FavoritesCubit>().reset();
          sl<OrgInitiativesCubit>().reset();
          sl<OrgServicesCubit>().reset();
        },
        child: MaterialApp.router(
          title: 'وَصْل',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
  }

  static String? _userId(AuthState s) => s is Authenticated ? s.user.id : null;
}
