import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/services/data/datasources/services_remote_data_source.dart';
import 'package:wasl/features/services/data/models/community_service_model.dart';
import 'package:wasl/features/services/domain/entities/community_service.dart';
import 'package:wasl/features/services/domain/repositories/services_repository.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource _remote;
  ServicesRepositoryImpl(this._remote);

  @override
  Future<Result<CachedList<CommunityService>>> getActive() => fetchWithCache(
        cacheKey: 'services_active',
        remote: _remote.fetchActive,
        parse: CommunityServiceModel.fromJson,
      );
}
