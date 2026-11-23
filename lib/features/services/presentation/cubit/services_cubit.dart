import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/features/services/domain/entities/community_service.dart';
import 'package:wasl/features/services/domain/repositories/services_repository.dart';

/// قائمة الخدمات. وحدة بس بكل التطبيق، فالرئيسية واستكشف بيشاركوا نفس البيانات.
class ServicesCubit extends ListCubit<CommunityService> {
  ServicesCubit(ServicesRepository repo) : super(repo.getActive);
}
