import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wasl/core/network/connectivity_service.dart';
import 'package:wasl/core/presentation/region_cubit.dart';
import 'package:wasl/features/admin/data/admin_repository.dart';
import 'package:wasl/features/applications/data/datasources/applications_remote_data_source.dart';
import 'package:wasl/features/attendance/data/attendance_repository.dart';
import 'package:wasl/features/applications/data/repositories/applications_repository_impl.dart';
import 'package:wasl/features/applications/domain/repositories/applications_repository.dart';
import 'package:wasl/features/applications/presentation/cubit/my_applications_cubit.dart';
import 'package:wasl/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wasl/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:wasl/features/auth/domain/repositories/auth_repository.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wasl/features/favorites/data/datasources/favorites_remote_data_source.dart';
import 'package:wasl/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:wasl/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:wasl/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:wasl/features/initiatives/data/datasources/initiatives_remote_data_source.dart';
import 'package:wasl/features/initiatives/data/repositories/initiatives_repository_impl.dart';
import 'package:wasl/features/initiatives/domain/repositories/initiatives_repository.dart';
import 'package:wasl/features/initiatives/presentation/cubit/initiatives_cubit.dart';
import 'package:wasl/features/needs/data/datasources/needs_remote_data_source.dart';
import 'package:wasl/features/needs/data/repositories/needs_repository_impl.dart';
import 'package:wasl/features/needs/data/repositories/need_offers_repository.dart';
import 'package:wasl/features/needs/domain/repositories/needs_repository.dart';
import 'package:wasl/features/needs/presentation/cubit/needs_cubit.dart';
import 'package:wasl/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:wasl/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:wasl/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:wasl/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wasl/features/opportunities/data/datasources/opportunities_remote_data_source.dart';
import 'package:wasl/features/opportunities/data/repositories/opportunities_repository_impl.dart';
import 'package:wasl/features/opportunities/domain/repositories/opportunities_repository.dart';
import 'package:wasl/features/opportunities/presentation/cubit/opportunities_cubit.dart';
import 'package:wasl/features/organization/data/datasources/org_remote_data_source.dart';
import 'package:wasl/features/organization/data/repositories/org_repository_impl.dart';
import 'package:wasl/features/organization/domain/repositories/org_repository.dart';
import 'package:wasl/features/organization/presentation/cubit/my_org_cubit.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';
import 'package:wasl/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:wasl/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:wasl/features/profile/domain/repositories/profile_repository.dart';
import 'package:wasl/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wasl/features/reports/data/reports_repository.dart';
import 'package:wasl/features/services/data/datasources/services_remote_data_source.dart';
import 'package:wasl/features/services/data/repositories/services_repository_impl.dart';
import 'package:wasl/features/services/domain/repositories/services_repository.dart';
import 'package:wasl/features/services/presentation/cubit/services_cubit.dart';

/// Service Locator: مكان واحد بنسجّل فيه كل الكلاسات.
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<ConnectivityService>(ConnectivityService.new);
  sl.registerLazySingleton<RegionCubit>(RegionCubit.new);

  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl())..checkSession());

  // المبادرات
  sl.registerLazySingleton<InitiativesRemoteDataSource>(() => InitiativesRemoteDataSource(sl()));
  sl.registerLazySingleton<InitiativesRepository>(() => InitiativesRepositoryImpl(sl()));
  sl.registerLazySingleton<InitiativesCubit>(() => InitiativesCubit(sl()));

  // الخدمات
  sl.registerLazySingleton<ServicesRemoteDataSource>(() => ServicesRemoteDataSource(sl()));
  sl.registerLazySingleton<ServicesRepository>(() => ServicesRepositoryImpl(sl()));
  sl.registerLazySingleton<ServicesCubit>(() => ServicesCubit(sl()));

  // الاحتياجات
  sl.registerLazySingleton<NeedsRemoteDataSource>(() => NeedsRemoteDataSource(sl()));
  sl.registerLazySingleton<NeedsRepository>(() => NeedsRepositoryImpl(sl()));
  sl.registerLazySingleton<NeedsCubit>(() => NeedsCubit(sl()));

  // الفرص
  sl.registerLazySingleton<OpportunitiesRemoteDataSource>(() => OpportunitiesRemoteDataSource(sl()));
  sl.registerLazySingleton<OpportunitiesRepository>(() => OpportunitiesRepositoryImpl(sl()));
  sl.registerLazySingleton<OpportunitiesCubit>(() => OpportunitiesCubit(sl()));

  // طلباتي (التقديم والانسحاب)
  sl.registerLazySingleton<ApplicationsRemoteDataSource>(() => ApplicationsRemoteDataSource(sl()));
  sl.registerLazySingleton<ApplicationsRepository>(() => ApplicationsRepositoryImpl(sl()));
  sl.registerLazySingleton<MyApplicationsCubit>(() => MyApplicationsCubit(sl()));

  // لوحة المؤسسة
  sl.registerLazySingleton<OrgRemoteDataSource>(() => OrgRemoteDataSource(sl()));
  sl.registerLazySingleton<OrgRepository>(() => OrgRepositoryImpl(sl()));
  sl.registerLazySingleton<MyOrgCubit>(() => MyOrgCubit(sl()));
  sl.registerLazySingleton<OrgOpportunitiesCubit>(() => OrgOpportunitiesCubit(sl()));
  sl.registerLazySingleton<OrgRequestsCubit>(() => OrgRequestsCubit(sl()));
  sl.registerLazySingleton<OrgInitiativesCubit>(() => OrgInitiativesCubit(sl()));
  sl.registerLazySingleton<OrgServicesCubit>(() => OrgServicesCubit(sl()));

  // عروض المساعدة على الاحتياجات · البلاغات · الإدارة
  sl.registerLazySingleton<NeedOffersRepository>(() => NeedOffersRepository(sl()));
  sl.registerLazySingleton<ReportsRepository>(() => ReportsRepository(sl()));
  sl.registerLazySingleton<AdminRepository>(() => AdminRepository(sl()));
  sl.registerLazySingleton<AttendanceRepository>(() => AttendanceRepository(sl()));

  // حسابي
  sl.registerLazySingleton<ProfileRemoteDataSource>(() => ProfileRemoteDataSource(sl()));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()));
  sl.registerLazySingleton<ProfileCubit>(() => ProfileCubit(sl()));

  // الإشعارات
  sl.registerLazySingleton<NotificationsRemoteDataSource>(() => NotificationsRemoteDataSource(sl()));
  sl.registerLazySingleton<NotificationsRepository>(() => NotificationsRepositoryImpl(sl()));
  sl.registerLazySingleton<NotificationsCubit>(() => NotificationsCubit(sl()));

  // المفضلة
  sl.registerLazySingleton<FavoritesRemoteDataSource>(() => FavoritesRemoteDataSource(sl()));
  sl.registerLazySingleton<FavoritesRepository>(() => FavoritesRepositoryImpl(sl()));
  sl.registerLazySingleton<FavoritesCubit>(() => FavoritesCubit(sl()));

  // كل feature جديدة بتسجّلي هون: DataSource ← Repository ← Cubit
}
